-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Schema alignment migration v2
--
-- Idempotent. MySQL 5.7+ compatible (does NOT use `IF NOT EXISTS` on
-- ALTER TABLE since that needs MySQL 8.0+).
--
-- Strategy: stored procedure that adds a column ONLY if it doesn't exist.
-- ═══════════════════════════════════════════════════════════════════════

DELIMITER $$

DROP PROCEDURE IF EXISTS tunnl_add_col$$
CREATE PROCEDURE tunnl_add_col(
    IN p_table  VARCHAR(64),
    IN p_col    VARCHAR(64),
    IN p_def    VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_table
          AND COLUMN_NAME  = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DROP PROCEDURE IF EXISTS tunnl_modify_col$$
CREATE PROCEDURE tunnl_modify_col(
    IN p_table  VARCHAR(64),
    IN p_col    VARCHAR(64),
    IN p_def    VARCHAR(500)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_table
          AND COLUMN_NAME  = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` MODIFY COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- ═══════════════════════════════════════════════════════════════════════
-- MISSING TABLES (referenced in PHP but absent from original tunnel.sql)
-- ═══════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `challenge_questions` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `challenge_id` INT NOT NULL,
    `question_id`  INT NOT NULL,
    `order_num`    INT DEFAULT 1,
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY (`challenge_id`),
    KEY (`question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `otp_logs` (
    `id`         INT AUTO_INCREMENT PRIMARY KEY,
    `phone`      VARCHAR(20) NOT NULL,
    `otp`        VARCHAR(10) NOT NULL,
    `is_used`    TINYINT DEFAULT 0,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY (`phone`),
    KEY (`is_used`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_daily_practice` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`      INT NOT NULL,
    `practice_id`  INT NOT NULL,
    `score`        INT DEFAULT 0,
    `correct`      INT DEFAULT 0,
    `wrong`        INT DEFAULT 0,
    `accuracy`     DECIMAL(5,2) DEFAULT 0.00,
    `time_taken`   INT DEFAULT 0,
    `xp_earned`    INT DEFAULT 0,
    `completed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_user_practice` (`user_id`, `practice_id`),
    KEY (`user_id`),
    KEY (`practice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- daily_practice extra columns the API uses
CALL tunnl_add_col('daily_practice', 'xp_reward',  'INT DEFAULT 50');
CALL tunnl_add_col('daily_practice', 'difficulty', 'VARCHAR(20) DEFAULT "medium"');

-- ── USERS ───────────────────────────────────────────────
CALL tunnl_add_col('users', 'standard',      'VARCHAR(100) DEFAULT ""');
CALL tunnl_add_col('users', 'profile_image', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_add_col('users', 'max_streak',    'INT DEFAULT 0');
CALL tunnl_add_col('users', 'is_active',     'TINYINT DEFAULT 1');

-- ── CHALLENGE_ENTRIES (winner declaration was crashing) ─
CALL tunnl_add_col('challenge_entries', 'prize_won',      'DECIMAL(10,2) DEFAULT NULL');
CALL tunnl_add_col('challenge_entries', 'payment_status', 'VARCHAR(20) DEFAULT "pending"');
CALL tunnl_add_col('challenge_entries', 'paid_at',        'TIMESTAMP NULL DEFAULT NULL');

-- ── WEEKLY_CHALLENGES — allow 'completed' status ────────
CALL tunnl_modify_col(
    'weekly_challenges',
    'status',
    'ENUM("upcoming","active","ended","results_declared","completed") DEFAULT "upcoming"'
);

-- ── DAILY DOSE — extend with the new fields the API expects ─
CALL tunnl_add_col('daily_dose', 'type',      'VARCHAR(50) DEFAULT "tip"');
CALL tunnl_add_col('daily_dose', 'example',   'TEXT NULL');
CALL tunnl_add_col('daily_dose', 'tip',       'TEXT NULL');
CALL tunnl_add_col('daily_dose', 'has_video', 'TINYINT DEFAULT 0');
CALL tunnl_add_col('daily_dose', 'video_url', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_add_col('daily_dose', 'image_url', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_add_col('daily_dose', 'category',  'VARCHAR(100) DEFAULT ""');

-- Compatibility VIEW so old code that still references `daily_doses` works
DROP VIEW IF EXISTS `daily_doses`;
CREATE VIEW `daily_doses` AS SELECT * FROM `daily_dose`;

-- ── SHORTS — old schema had `url`, new code wants `youtube_url`+meta ─
CALL tunnl_add_col('shorts', 'youtube_url',   'VARCHAR(500) DEFAULT ""');
CALL tunnl_add_col('shorts', 'category',      'VARCHAR(100) DEFAULT ""');
CALL tunnl_add_col('shorts', 'duration',      'INT DEFAULT 0');
CALL tunnl_add_col('shorts', 'thumbnail_url', 'VARCHAR(500) DEFAULT ""');

-- Backfill youtube_url from url if needed
UPDATE `shorts`
SET `youtube_url` = `url`
WHERE (`youtube_url` IS NULL OR `youtube_url` = '')
  AND `url` IS NOT NULL AND `url` != '';

-- ── PY_EXAMS — icon, year, date, premium flag ───────────
CALL tunnl_add_col('py_exams', 'icon',       'VARCHAR(50) DEFAULT "school"');
CALL tunnl_add_col('py_exams', 'exam_year',  'INT DEFAULT NULL');
CALL tunnl_add_col('py_exams', 'exam_date',  'DATE DEFAULT NULL');
CALL tunnl_add_col('py_exams', 'is_premium', 'TINYINT DEFAULT 0');
CALL tunnl_add_col('py_exams', 'is_active',  'TINYINT DEFAULT 1');

-- ── SETS — exam_id link, is_active, subtitle ────────────
CALL tunnl_add_col('sets', 'exam_id',         'INT DEFAULT NULL');
CALL tunnl_add_col('sets', 'subtitle',        'VARCHAR(255) DEFAULT ""');
CALL tunnl_add_col('sets', 'is_active',       'TINYINT DEFAULT 1');
CALL tunnl_add_col('sets', 'is_locked',       'TINYINT DEFAULT 0');
CALL tunnl_add_col('sets', 'is_premium',      'TINYINT DEFAULT 0');
CALL tunnl_add_col('sets', 'level',           'VARCHAR(20) DEFAULT "beginner"');
CALL tunnl_add_col('sets', 'total_questions', 'INT DEFAULT 0');

-- Backfill: link existing previous_year sets to py_exams by exam_name
UPDATE `sets` s
JOIN `py_exams` e
  ON s.exam_name = e.exam_name
 AND s.category  = 'previous_year'
SET s.exam_id = e.id
WHERE s.exam_id IS NULL;

-- ── QUESTIONS — time_limit, order_num ───────────────────
CALL tunnl_add_col('questions', 'time_limit', 'INT DEFAULT 30');
CALL tunnl_add_col('questions', 'order_num',  'INT DEFAULT 1');
CALL tunnl_add_col('questions', 'is_active',  'TINYINT DEFAULT 1');

-- ── TRANSACTIONS — type, plan, note + status enum widened ─
CALL tunnl_add_col('transactions', 'type', 'VARCHAR(50) DEFAULT "razorpay"');
CALL tunnl_add_col('transactions', 'plan', 'VARCHAR(50) DEFAULT "lifetime"');
CALL tunnl_add_col('transactions', 'note', 'VARCHAR(255) DEFAULT ""');
CALL tunnl_modify_col(
    'transactions',
    'status',
    'ENUM("created","pending","paid","success","failed") DEFAULT "pending"'
);

-- ── APP SETTINGS — Razorpay + plan defaults ─────────────
INSERT IGNORE INTO `app_settings` (`setting_key`, `setting_value`) VALUES
  ('razorpay_enabled',        '1'),
  ('razorpay_key_id',         ''),
  ('razorpay_key_secret',     ''),
  ('premium_price',           '50'),
  ('premium_yearly_price',    '499'),
  ('premium_lifetime_price',  '50'),
  ('about_us_html',           '<p>Tunnl helps you crack speed math.</p>'),
  ('app_name',                'Tunnl'),
  ('app_tagline',             'Master Speed Math');

-- ═══════════════════════════════════════════════════════════════════════
-- SAMPLE SEED DATA — only inserted when records are missing
-- ═══════════════════════════════════════════════════════════════════════

INSERT INTO `tricks`
  (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`,
   `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 1, 'Multiplication by 11',
       'The forgotten 11-trick every aspirant must know',
       'MULTIPLICATION', 'Beginner', 0, 1,
       'To multiply any 2-digit number by 11, add the two digits and place the sum between them. Example: 35 × 11 → 3 (3+5) 5 = 385.',
       3, 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 1);

INSERT INTO `tricks`
  (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`,
   `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 2, 'Square of numbers ending in 5',
       'No paper, no pen — just one rule',
       'SQUARES', 'Beginner', 0, 1,
       'Multiply the leading digit(s) by the next number, then append 25. Example: 65² → 6×7 = 42, append 25 → 4225.',
       3, 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 2);

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`,
   `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'SSC CGL', 'SSC Combined Graduate Level',     'SSC',     'school',          2024, 'Hard',   0, 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='SSC CGL');

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`,
   `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'RRB NTPC','Railway Recruitment Board NTPC',  'RAILWAY', 'train',           2024, 'Medium', 0, 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='RRB NTPC');

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`,
   `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'IBPS PO', 'IBPS Probationary Officer',       'BANK',    'account_balance', 2024, 'Hard',   1, 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='IBPS PO');

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`,
   `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'CDS', 'Combined Defence Services',           'DEFENCE', 'security',        2024, 'Hard',   1, 1, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='CDS');

INSERT INTO `sets`
  (`category`, `exam_name`, `set_number`, `title`, `level`,
   `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 1, 'Set 01 — Foundation', 'beginner', 50, 0, 0, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=1);

INSERT INTO `sets`
  (`category`, `exam_name`, `set_number`, `title`, `level`,
   `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 2, 'Set 02 — Speed Drills', 'beginner', 50, 0, 0, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=2);

INSERT INTO `sets`
  (`category`, `exam_name`, `set_number`, `title`, `level`,
   `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 3, 'Set 03 — Mixed Bag', 'intermediate', 50, 0, 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=3);

INSERT INTO `shorts`
  (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`)
SELECT 'youtube', 'Multiply by 11 — fastest trick',
       'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ',
       'TRICKS', 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'Multiply by 11 — fastest trick');

INSERT INTO `daily_dose`
  (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT CURDATE(), 'Square of 35',
       'Numbers ending in 5 — multiply leading digits by next, append 25.',
       'shortcut', '35² → 3×4 = 12, append 25 → 1225',
       'Works for any two- or three-digit number ending in 5.', 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = CURDATE());

-- ═══════════════════════════════════════════════════════════════════════
-- Cleanup
-- ═══════════════════════════════════════════════════════════════════════
DROP PROCEDURE IF EXISTS tunnl_add_col;
DROP PROCEDURE IF EXISTS tunnl_modify_col;
