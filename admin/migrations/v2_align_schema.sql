-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Schema alignment migration v2
--
-- Run this once on your live database. Idempotent — safe to re-run.
-- It adds every column the PHP APIs expect but that's missing in the
-- original tunnel.sql dump, plus seeds defaults so the app stops crashing.
-- ═══════════════════════════════════════════════════════════════════════

-- ── USERS ───────────────────────────────────────────────
ALTER TABLE `users`
  ADD COLUMN IF NOT EXISTS `standard`      VARCHAR(100) DEFAULT ''  AFTER `name`,
  ADD COLUMN IF NOT EXISTS `profile_image` VARCHAR(500) DEFAULT ''  AFTER `standard`,
  ADD COLUMN IF NOT EXISTS `max_streak`    INT          DEFAULT 0   AFTER `current_streak`,
  ADD COLUMN IF NOT EXISTS `is_active`     TINYINT      DEFAULT 1   AFTER `fcm_token`;

-- ── CHALLENGE_ENTRIES (winner declaration was crashing) ─
ALTER TABLE `challenge_entries`
  ADD COLUMN IF NOT EXISTS `prize_won`      DECIMAL(10,2) DEFAULT NULL                                  AFTER `prize_amount`,
  ADD COLUMN IF NOT EXISTS `payment_status` ENUM('pending','paid','failed') DEFAULT 'pending'           AFTER `prize_paid`,
  ADD COLUMN IF NOT EXISTS `paid_at`        TIMESTAMP NULL DEFAULT NULL                                 AFTER `payment_status`;

-- ── WEEKLY_CHALLENGES — allow 'completed' status ────────
ALTER TABLE `weekly_challenges`
  MODIFY COLUMN `status` ENUM('upcoming','active','ended','results_declared','completed')
    DEFAULT 'upcoming';

-- ── DAILY DOSE — daily_dose vs daily_doses naming + new fields
-- API was querying `daily_doses` but table is `daily_dose`. Add a view
-- so both names work, plus add the new fields.
ALTER TABLE `daily_dose`
  ADD COLUMN IF NOT EXISTS `type`      VARCHAR(50)  DEFAULT 'tip' AFTER `content`,
  ADD COLUMN IF NOT EXISTS `example`   TEXT         NULL          AFTER `type`,
  ADD COLUMN IF NOT EXISTS `tip`       TEXT         NULL          AFTER `example`,
  ADD COLUMN IF NOT EXISTS `has_video` TINYINT      DEFAULT 0     AFTER `tip`,
  ADD COLUMN IF NOT EXISTS `video_url` VARCHAR(500) DEFAULT ''    AFTER `has_video`;

-- Compatibility view so old API code that queries daily_doses still works
DROP VIEW IF EXISTS `daily_doses`;
CREATE VIEW `daily_doses` AS SELECT * FROM `daily_dose`;

-- ── SHORTS — old schema had `url`, new wants `youtube_url`+meta ─
ALTER TABLE `shorts`
  ADD COLUMN IF NOT EXISTS `youtube_url` VARCHAR(500) DEFAULT '' AFTER `title`,
  ADD COLUMN IF NOT EXISTS `category`    VARCHAR(100) DEFAULT '' AFTER `thumbnail_url`,
  ADD COLUMN IF NOT EXISTS `duration`    INT          DEFAULT 0  AFTER `category`;

-- Backfill youtube_url from url if needed
UPDATE `shorts`
SET `youtube_url` = `url`
WHERE (`youtube_url` IS NULL OR `youtube_url` = '')
  AND `url` IS NOT NULL AND `url` != '';

-- ── PY_EXAMS — icon, year, date, premium flag ───────────
ALTER TABLE `py_exams`
  ADD COLUMN IF NOT EXISTS `icon`       VARCHAR(50)  DEFAULT 'school'  AFTER `exam_category`,
  ADD COLUMN IF NOT EXISTS `exam_year`  INT          DEFAULT NULL      AFTER `icon`,
  ADD COLUMN IF NOT EXISTS `exam_date`  DATE         DEFAULT NULL      AFTER `exam_year`,
  ADD COLUMN IF NOT EXISTS `is_premium` TINYINT      DEFAULT 0         AFTER `difficulty`;

-- ── SETS — exam_id link, is_active, subtitle ────────────
ALTER TABLE `sets`
  ADD COLUMN IF NOT EXISTS `exam_id`   INT          DEFAULT NULL  AFTER `exam_name`,
  ADD COLUMN IF NOT EXISTS `subtitle`  VARCHAR(255) DEFAULT ''    AFTER `title`,
  ADD COLUMN IF NOT EXISTS `is_active` TINYINT      DEFAULT 1     AFTER `is_premium`;

-- Backfill: link existing previous_year sets to py_exams by exam_name
UPDATE `sets` s
JOIN `py_exams` e ON s.exam_name = e.exam_name AND s.category = 'previous_year'
SET s.exam_id = e.id
WHERE s.exam_id IS NULL;

-- ── QUESTIONS — time_limit, order_num ───────────────────
ALTER TABLE `questions`
  ADD COLUMN IF NOT EXISTS `time_limit` INT DEFAULT 30 AFTER `difficulty`,
  ADD COLUMN IF NOT EXISTS `order_num`  INT DEFAULT 1  AFTER `time_limit`;

-- ── TRANSACTIONS — type, plan, note ─────────────────────
ALTER TABLE `transactions`
  ADD COLUMN IF NOT EXISTS `type` VARCHAR(50) DEFAULT 'razorpay' AFTER `amount`,
  ADD COLUMN IF NOT EXISTS `plan` VARCHAR(50) DEFAULT 'lifetime' AFTER `type`,
  ADD COLUMN IF NOT EXISTS `note` VARCHAR(255) DEFAULT ''        AFTER `status`,
  MODIFY COLUMN `status` ENUM('created','pending','paid','success','failed') DEFAULT 'pending';

-- ── APP SETTINGS — Razorpay + plan defaults ─────────────
INSERT IGNORE INTO `app_settings` (`setting_key`, `setting_value`) VALUES
  ('razorpay_enabled',        '0'),
  ('razorpay_key_id',         ''),
  ('razorpay_key_secret',     ''),
  ('premium_yearly_price',    '499'),
  ('premium_lifetime_price',  '50'),
  ('about_us_html',           '<p>Tunnl helps you crack speed math.</p>');

-- ═══════════════════════════════════════════════════════════════════════
-- SAMPLE SEED DATA — only inserted when tables are empty / record missing
-- ═══════════════════════════════════════════════════════════════════════

-- Sample tricks (only if tricks table is empty)
INSERT INTO `tricks`
  (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 1, 'Multiplication by 11', 'The forgotten 11-trick every aspirant must know',
       'MULTIPLICATION', 'Beginner', 0, 1,
       'To multiply any 2-digit number by 11, add the two digits and place the sum between them. Example: 35 × 11 → 3 (3+5) 5 = 385.',
       3, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `tricks` LIMIT 1);

INSERT INTO `tricks`
  (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 2, 'Square of numbers ending in 5', 'No paper, no pen — just one rule',
       'SQUARES', 'Beginner', 0, 1,
       'Multiply the leading digit(s) by the next number, then append 25. Example: 65² → 6×7 = 42, append 25 → 4225.',
       3, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 2);

-- Sample previous-year exams (only if py_exams is empty)
INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`, `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'SSC CGL',  'SSC Combined Graduate Level',          'SSC',     'school',          2024, 'Hard',   0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` LIMIT 1);

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`, `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'RRB NTPC','Railway Recruitment Board NTPC',         'RAILWAY', 'train',           2024, 'Medium', 0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='RRB NTPC');

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`, `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'IBPS PO', 'IBPS Probationary Officer',              'BANK',    'account_balance', 2024, 'Hard',   1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='IBPS PO');

INSERT INTO `py_exams`
  (`exam_name`, `exam_full_name`, `exam_category`, `icon`, `exam_year`, `difficulty`, `is_premium`, `is_active`, `total_sets`)
SELECT 'CDS', 'Combined Defence Services',                  'DEFENCE', 'security',        2024, 'Hard',   1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='CDS');

-- Sample sets for the 5000-MCQ category (only if sets is empty)
INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 1, 'Set 01 — Foundation', 'beginner', 50, 0, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=1);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 2, 'Set 02 — Speed Drills', 'beginner', 50, 0, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=2);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 3, 'Set 03 — Mixed Bag', 'intermediate', 50, 0, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=3);

-- Sample shorts (only if empty)
INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`)
SELECT 'youtube', 'Multiply by 11 — fastest trick', 'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ', 'TRICKS', 1
WHERE NOT EXISTS (SELECT 1 FROM `shorts` LIMIT 1);

-- Sample daily dose for today (only if no record for today)
INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT CURDATE(), 'Square of 35', 'Numbers ending in 5 — multiply leading digits by next, append 25.',
       'shortcut', '35² → 3×4 = 12, append 25 → 1225',
       'Works for any two- or three-digit number ending in 5.', 1
WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = CURDATE());
