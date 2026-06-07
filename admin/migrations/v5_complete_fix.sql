-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Complete schema fix v5  (run ONCE on the live DB)
--
-- Why: the admin code + mobile API reference several columns that were never
-- present in the original tunnel.sql and were not all covered by v2. This
-- migration is fully idempotent and safe to re-run.
--
-- Fixes:
--   • weekly_challenges.description / time_limit  (challenge create crash)
--   • challenge_entries.correct / wrong / accuracy / prize_won  (submit crash)
--   • re-ensures every column the content APIs read (sets/questions/py_exams/
--     shorts/users/daily_practice) so a partially-migrated DB is healed.
-- ═══════════════════════════════════════════════════════════════════════

DELIMITER $$
DROP PROCEDURE IF EXISTS tunnl_v5_add_col$$
CREATE PROCEDURE tunnl_v5_add_col(
    IN p_table VARCHAR(64),
    IN p_col   VARCHAR(64),
    IN p_def   VARCHAR(500)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = p_table
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table AND COLUMN_NAME = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- ── WEEKLY CHALLENGES (fixes "Unknown column 'description'") ──
CALL tunnl_v5_add_col('weekly_challenges', 'description',  'TEXT NULL');
CALL tunnl_v5_add_col('weekly_challenges', 'time_limit',   'INT DEFAULT 600');
CALL tunnl_v5_add_col('weekly_challenges', 'prize_amount', 'DECIMAL(10,2) DEFAULT 0.00');
CALL tunnl_v5_add_col('weekly_challenges', 'start_date',   'DATE DEFAULT NULL');
CALL tunnl_v5_add_col('weekly_challenges', 'end_date',     'DATE DEFAULT NULL');

-- ── CHALLENGE ENTRIES (fixes submit crash) ──
CALL tunnl_v5_add_col('challenge_entries', 'correct',        'INT DEFAULT 0');
CALL tunnl_v5_add_col('challenge_entries', 'wrong',          'INT DEFAULT 0');
CALL tunnl_v5_add_col('challenge_entries', 'accuracy',       'DECIMAL(5,2) DEFAULT 0.00');
CALL tunnl_v5_add_col('challenge_entries', 'prize_won',      'DECIMAL(10,2) DEFAULT NULL');
CALL tunnl_v5_add_col('challenge_entries', 'payment_status', 'VARCHAR(20) DEFAULT "pending"');

-- ── USERS ──
CALL tunnl_v5_add_col('users', 'standard',      'VARCHAR(100) DEFAULT ""');
CALL tunnl_v5_add_col('users', 'profile_image', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_v5_add_col('users', 'max_streak',    'INT DEFAULT 0');
CALL tunnl_v5_add_col('users', 'is_active',     'TINYINT DEFAULT 1');
CALL tunnl_v5_add_col('users', 'fcm_token',     'VARCHAR(255) DEFAULT NULL');

-- ── SETS ──
CALL tunnl_v5_add_col('sets', 'exam_id',         'INT DEFAULT NULL');
CALL tunnl_v5_add_col('sets', 'subtitle',        'VARCHAR(255) DEFAULT ""');
CALL tunnl_v5_add_col('sets', 'is_active',       'TINYINT DEFAULT 1');
CALL tunnl_v5_add_col('sets', 'is_locked',       'TINYINT DEFAULT 0');
CALL tunnl_v5_add_col('sets', 'is_premium',      'TINYINT DEFAULT 0');
CALL tunnl_v5_add_col('sets', 'level',           'VARCHAR(20) DEFAULT "beginner"');
CALL tunnl_v5_add_col('sets', 'total_questions', 'INT DEFAULT 20');

-- ── QUESTIONS ──
CALL tunnl_v5_add_col('questions', 'time_limit', 'INT DEFAULT 30');
CALL tunnl_v5_add_col('questions', 'order_num',  'INT DEFAULT 1');
CALL tunnl_v5_add_col('questions', 'is_active',  'TINYINT DEFAULT 1');

-- ── PY_EXAMS ──
CALL tunnl_v5_add_col('py_exams', 'icon',       'VARCHAR(50) DEFAULT "school"');
CALL tunnl_v5_add_col('py_exams', 'exam_year',  'INT DEFAULT NULL');
CALL tunnl_v5_add_col('py_exams', 'exam_date',  'DATE DEFAULT NULL');
CALL tunnl_v5_add_col('py_exams', 'is_premium', 'TINYINT DEFAULT 0');
CALL tunnl_v5_add_col('py_exams', 'is_active',  'TINYINT DEFAULT 1');

-- ── DAILY PRACTICE ──
CALL tunnl_v5_add_col('daily_practice', 'xp_reward',  'INT DEFAULT 50');
CALL tunnl_v5_add_col('daily_practice', 'time_limit', 'INT DEFAULT 600');
CALL tunnl_v5_add_col('daily_practice', 'category',   'VARCHAR(50) DEFAULT "mcq"');
CALL tunnl_v5_add_col('daily_practice', 'difficulty', 'VARCHAR(20) DEFAULT "medium"');

-- daily_practice_questions: code uses `order_num`, original schema had
-- `order_number`. Add order_num so assignment + fetch (ORDER BY dpq.order_num)
-- work. challenge_questions already uses order_num (created by v2).
CALL tunnl_v5_add_col('daily_practice_questions', 'order_num', 'INT DEFAULT 1');

-- ── SHORTS (multi-platform) ──
CALL tunnl_v5_add_col('shorts', 'platform',      "ENUM('youtube','instagram','facebook','telegram') NOT NULL DEFAULT 'youtube'");
CALL tunnl_v5_add_col('shorts', 'youtube_url',   'VARCHAR(500) DEFAULT ""');
CALL tunnl_v5_add_col('shorts', 'thumbnail_url', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_v5_add_col('shorts', 'category',      'VARCHAR(100) DEFAULT ""');
CALL tunnl_v5_add_col('shorts', 'duration',      'INT DEFAULT 0');

DROP PROCEDURE IF EXISTS tunnl_v5_add_col;

-- Widen shorts platform enum to include facebook (safe even if already set).
ALTER TABLE `shorts`
  MODIFY COLUMN `platform`
  ENUM('youtube','instagram','facebook','telegram') NOT NULL DEFAULT 'youtube';

-- Backfill youtube_url from legacy url column.
UPDATE `shorts`
SET `youtube_url` = `url`
WHERE (`youtube_url` IS NULL OR `youtube_url` = '')
  AND `url` IS NOT NULL AND `url` != '';

-- Backfill daily_practice_questions.order_num from legacy order_number
-- (guarded: only runs if the legacy column actually exists).
SET @has_on := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'daily_practice_questions'
    AND COLUMN_NAME = 'order_number'
);
SET @sql := IF(@has_on > 0,
  'UPDATE `daily_practice_questions` SET `order_num` = `order_number` WHERE (`order_num` IS NULL OR `order_num` = 0) AND `order_number` IS NOT NULL',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
