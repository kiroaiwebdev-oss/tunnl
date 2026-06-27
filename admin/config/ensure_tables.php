<?php
// ─────────────────────────────────────────────────────────────────────────
// Self-healing schema bootstrap.
//
// Auto-creates the coupon + MCQ-exam tables (and the extra transactions
// columns) the first time any page/API loads, so a fresh database never
// throws a 500 "table doesn't exist" error. Fully idempotent and wrapped in
// try/catch so it can NEVER break a request — if the DB user lacks CREATE
// privilege it just silently no-ops and the calling code's own try/catch
// shows an empty state.
//
// Included from config/db.php, so it runs for both the admin panel and the
// mobile-app APIs.
// ─────────────────────────────────────────────────────────────────────────

if (!isset($pdo) || !($pdo instanceof PDO)) return;
if (defined('TUNNL_TABLES_ENSURED')) return;
define('TUNNL_TABLES_ENSURED', true);

try {
    // Helper: does a table already exist?
    $tableExists = function (string $name) use ($pdo): bool {
        $q = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.TABLES
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?"
        );
        $q->execute([$name]);
        return (int)$q->fetchColumn() > 0;
    };

    // ── coupons ──────────────────────────────────────
    $couponsExisted = $tableExists('coupons');
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `coupons` (
            `id`             INT AUTO_INCREMENT PRIMARY KEY,
            `code`           VARCHAR(50)  NOT NULL,
            `description`    VARCHAR(255) DEFAULT '',
            `discount_type`  ENUM('percent','flat') NOT NULL DEFAULT 'percent',
            `discount_value` DECIMAL(10,2) NOT NULL DEFAULT 0,
            `min_amount`     INT DEFAULT 0,
            `max_discount`   INT DEFAULT 0,
            `usage_limit`    INT DEFAULT 0,
            `used_count`     INT DEFAULT 0,
            `per_user_limit` INT DEFAULT 1,
            `expires_at`     DATE DEFAULT NULL,
            `is_active`      TINYINT DEFAULT 1,
            `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uniq_code` (`code`),
            KEY `idx_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // ── coupon_redemptions ───────────────────────────
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `coupon_redemptions` (
            `id`           INT AUTO_INCREMENT PRIMARY KEY,
            `coupon_id`    INT NOT NULL,
            `code`         VARCHAR(50) NOT NULL,
            `user_id`      INT NOT NULL,
            `order_id`     VARCHAR(200) DEFAULT '',
            `discount`     INT DEFAULT 0,
            `final_amount` INT DEFAULT 0,
            `status`       ENUM('pending','success') DEFAULT 'pending',
            `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            KEY `idx_coupon` (`coupon_id`),
            KEY `idx_user`   (`user_id`),
            KEY `idx_order`  (`order_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // ── mcq_exams ────────────────────────────────────
    $mcqExisted = $tableExists('mcq_exams');
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `mcq_exams` (
            `id`             INT AUTO_INCREMENT PRIMARY KEY,
            `exam_name`      VARCHAR(100) NOT NULL,
            `exam_full_name` VARCHAR(200) DEFAULT '',
            `exam_category`  ENUM('SSC','RAILWAY','BANK','DEFENCE','OTHER') DEFAULT 'OTHER',
            `icon`           VARCHAR(50)  DEFAULT 'school',
            `icon_url`       VARCHAR(255) DEFAULT '',
            `difficulty`     ENUM('Easy','Medium','Hard') DEFAULT 'Medium',
            `is_premium`     TINYINT DEFAULT 0,
            `is_active`      TINYINT DEFAULT 1,
            `sort_order`     INT DEFAULT 1,
            `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uniq_mcq_exam_name` (`exam_name`),
            KEY `idx_mcq_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");

    // ── transactions: add coupon columns if missing ──
    foreach ([
        ['coupon_code', "VARCHAR(50) DEFAULT ''"],
        ['discount',    "INT DEFAULT 0"],
    ] as $col) {
        $chk = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND COLUMN_NAME = ?"
        );
        $chk->execute([$col[0]]);
        if ((int)$chk->fetchColumn() === 0) {
            // Wrapped individually so one failure doesn't block the other.
            try { $pdo->exec("ALTER TABLE `transactions` ADD COLUMN `{$col[0]}` {$col[1]}"); }
            catch (Throwable $e) { /* ignore */ }
        }
    }

    // ── Seed defaults ONLY on first creation (never resurrect deleted rows) ──
    if (!$couponsExisted) {
        try {
            $pdo->exec("
                INSERT IGNORE INTO `coupons`
                  (`code`, `description`, `discount_type`, `discount_value`, `usage_limit`, `is_active`)
                VALUES ('WELCOME50', 'Launch offer — 50% off', 'percent', 50, 0, 1)
            ");
        } catch (Throwable $e) { /* ignore */ }
    }
    if (!$mcqExisted) {
        try {
            $pdo->exec("
                INSERT IGNORE INTO `mcq_exams`
                  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `difficulty`, `is_premium`, `is_active`, `sort_order`)
                VALUES
                  ('SSC',     'Staff Selection Commission', 'SSC',     'school',          'Medium', 0, 1, 1),
                  ('Railway', 'Railway Recruitment Board',  'RAILWAY', 'train',           'Medium', 0, 1, 2),
                  ('Banking', 'Banking (IBPS / SBI)',       'BANK',    'account_balance', 'Medium', 0, 1, 3)
            ");
        } catch (Throwable $e) { /* ignore */ }
    }
    // ── tech_reports: user-submitted technical error reports ──
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `tech_reports` (
            `id`          INT AUTO_INCREMENT PRIMARY KEY,
            `user_id`     INT          DEFAULT NULL,
            `name`        VARCHAR(120) DEFAULT '',
            `phone`       VARCHAR(20)  DEFAULT '',
            `message`     TEXT         NOT NULL,
            `app_version` VARCHAR(30)  DEFAULT '',
            `status`      ENUM('open','resolved') DEFAULT 'open',
            `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    // ── weekly challenge: per-day entries (7-day aggregate) ──
    if ($tableExists('challenge_entries')) {
        foreach ([
            'day_number' => 'INT DEFAULT 1',
            'correct'    => 'INT DEFAULT 0',
            'wrong'      => 'INT DEFAULT 0',
            'accuracy'   => 'DECIMAL(5,2) DEFAULT 0',
        ] as $col => $type) {
            try {
                $chk = $pdo->prepare(
                    "SELECT COUNT(*) FROM information_schema.COLUMNS
                     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'challenge_entries' AND COLUMN_NAME = ?"
                );
                $chk->execute([$col]);
                if ((int)$chk->fetchColumn() === 0) {
                    $pdo->exec("ALTER TABLE `challenge_entries` ADD COLUMN `{$col}` {$type}");
                }
            } catch (Throwable $e) { /* ignore */ }
        }
        // Widen the unique key to (challenge_id, user_id, day_number) so a user
        // can submit once per day across the 7-day challenge.
        try {
            $idx = $pdo->query(
                "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS cols
                 FROM information_schema.STATISTICS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'challenge_entries'
                   AND INDEX_NAME = 'unique_entry'"
            )->fetch();
            $cols = $idx['cols'] ?? '';
            if ($cols !== '' && strpos($cols, 'day_number') === false) {
                $pdo->exec("ALTER TABLE `challenge_entries` DROP INDEX `unique_entry`");
                $pdo->exec("ALTER TABLE `challenge_entries` ADD UNIQUE KEY `unique_entry` (`challenge_id`,`user_id`,`day_number`)");
            }
        } catch (Throwable $e) { /* ignore */ }
    }

    // ── questions: bilingual (Hindi) columns for language switching ──
    // Lets admin store Hindi versions; the app toggles EN/HI per question.
    foreach ([
        'question_text_hi' => "TEXT",
        'option_a_hi'      => "TEXT",
        'option_b_hi'      => "TEXT",
        'option_c_hi'      => "TEXT",
        'option_d_hi'      => "TEXT",
        'explanation_hi'   => "TEXT",
        // Previous-Year tagging entered at question add / CSV import time.
        // The app shows "<exam_name> · <exam_year>" above each PYQ question.
        'exam_name'        => "VARCHAR(120) DEFAULT ''",
        'exam_year'        => "VARCHAR(20) DEFAULT ''",
    ] as $col => $type) {
        try {
            $chk = $pdo->prepare(
                "SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'questions' AND COLUMN_NAME = ?"
            );
            $chk->execute([$col]);
            if ((int)$chk->fetchColumn() === 0) {
                $pdo->exec("ALTER TABLE `questions` ADD COLUMN `{$col}` {$type} NULL");
            }
        } catch (Throwable $e) { /* ignore */ }
    }

    // ── exams: add per-exam custom icon image (icon_url) if missing ──
    // Lets the admin upload a custom icon per exam (Practice Sets + Previous
    // Year). The app shows this image when present, else falls back to the
    // built-in Material icon mapped from the `icon` column.
    foreach (['mcq_exams', 'py_exams'] as $examTable) {
        try {
            if (!$tableExists($examTable)) continue;
            $chk = $pdo->prepare(
                "SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = 'icon_url'"
            );
            $chk->execute([$examTable]);
            if ((int)$chk->fetchColumn() === 0) {
                $pdo->exec("ALTER TABLE `{$examTable}` ADD COLUMN `icon_url` VARCHAR(255) DEFAULT '' AFTER `icon`");
            }
        } catch (Throwable $e) { /* ignore */ }
    }

    // ── tricks.category: widen enum → VARCHAR so admins can add custom
    //    categories (PERCENTAGE, ALGEBRA, …) without "Data truncated" errors ──
    try {
        $tc = $pdo->prepare(
            "SELECT DATA_TYPE FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tricks' AND COLUMN_NAME = 'category'"
        );
        $tc->execute();
        $type = strtolower((string)$tc->fetchColumn());
        if ($type === 'enum') {
            $pdo->exec("ALTER TABLE `tricks` MODIFY `category` VARCHAR(50) NOT NULL DEFAULT 'SHORTCUTS'");
        }
        // is_premium flag — lets admin mark a trick premium-only
        $tp = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tricks' AND COLUMN_NAME = 'is_premium'"
        );
        $tp->execute();
        if ((int)$tp->fetchColumn() === 0) {
            $pdo->exec("ALTER TABLE `tricks` ADD COLUMN `is_premium` TINYINT DEFAULT 0");
        }
        // image_url — lets admin attach an illustrative image to a trick that
        // the app shows at the top of the article.
        $ti = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tricks' AND COLUMN_NAME = 'image_url'"
        );
        $ti->execute();
        if ((int)$ti->fetchColumn() === 0) {
            $pdo->exec("ALTER TABLE `tricks` ADD COLUMN `image_url` VARCHAR(255) DEFAULT ''");
        }
        // article_blocks — JSON array of rich content blocks (text / heading /
        // image / video) so an article can interleave media anywhere. The app
        // renders these in order; falls back to article_content when empty.
        $tab = $pdo->prepare(
            "SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tricks' AND COLUMN_NAME = 'article_blocks'"
        );
        $tab->execute();
        if ((int)$tab->fetchColumn() === 0) {
            $pdo->exec("ALTER TABLE `tricks` ADD COLUMN `article_blocks` LONGTEXT NULL");
        }
    } catch (Throwable $e) { /* ignore */ }

    // ── sets/questions: allow the 'tricks' practice category ──────────
    // A dedicated set category for the "Tunnl Tricks" practice MCQs (the
    // 50-question set users attempt after reading the trick chapters). We
    // widen the category enum to include 'tricks' if it isn't already there.
    foreach (['sets', 'questions'] as $catTable) {
        try {
            if (!$tableExists($catTable)) continue;
            $ct = $pdo->prepare(
                "SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = 'category'"
            );
            $ct->execute([$catTable]);
            $colType = strtolower((string)$ct->fetchColumn());
            // Only act on enum columns that don't yet contain 'tricks'.
            if (strpos($colType, 'enum') === 0 && strpos($colType, "'tricks'") === false) {
                if ($catTable === 'sets') {
                    $pdo->exec("ALTER TABLE `sets` MODIFY COLUMN `category`
                        ENUM('mcq','simplification','previous_year','tunnlity','tricks')
                        NOT NULL DEFAULT 'mcq'");
                } else {
                    $pdo->exec("ALTER TABLE `questions` MODIFY COLUMN `category`
                        ENUM('mcq','simplification','previous_year','daily_practice','tunnlity','tricks')
                        NOT NULL");
                }
            }
        } catch (Throwable $e) { /* ignore */ }
    }
} catch (Throwable $e) {
    // Never break the request. The calling page/API has its own fallback.
}
