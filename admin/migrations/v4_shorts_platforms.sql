-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Shorts multi-platform migration v4
--
-- Adds Facebook support to the `shorts` table so admin can post videos from
-- YouTube, Instagram, AND Facebook (plus keeps legacy Telegram for safety).
--
-- Idempotent & MySQL 5.7+ safe. Run after v2/v3.
-- ═══════════════════════════════════════════════════════════════════════

-- 1) Make sure the `platform` column exists (older installs may not have it).
DELIMITER $$
DROP PROCEDURE IF EXISTS tunnl_v4_add_col$$
CREATE PROCEDURE tunnl_v4_add_col(
    IN p_table VARCHAR(64),
    IN p_col   VARCHAR(64),
    IN p_def   VARCHAR(500)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_table
          AND COLUMN_NAME  = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_col, '` ', p_def);
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL tunnl_v4_add_col('shorts', 'platform',      "ENUM('youtube','instagram','facebook','telegram') NOT NULL DEFAULT 'youtube'");
CALL tunnl_v4_add_col('shorts', 'youtube_url',   'VARCHAR(500) DEFAULT ""');
CALL tunnl_v4_add_col('shorts', 'thumbnail_url', 'VARCHAR(500) DEFAULT ""');
CALL tunnl_v4_add_col('shorts', 'category',      'VARCHAR(100) DEFAULT ""');
CALL tunnl_v4_add_col('shorts', 'duration',      'INT DEFAULT 0');

DROP PROCEDURE IF EXISTS tunnl_v4_add_col;

-- 2) Widen the `platform` enum to include facebook (keeps existing values).
ALTER TABLE `shorts`
  MODIFY COLUMN `platform`
  ENUM('youtube','instagram','facebook','telegram') NOT NULL DEFAULT 'youtube';

-- 3) Backfill platform for any legacy rows that only have a URL.
UPDATE `shorts`
SET `platform` = CASE
    WHEN LOWER(COALESCE(youtube_url, url)) LIKE '%instagram%' THEN 'instagram'
    WHEN LOWER(COALESCE(youtube_url, url)) LIKE '%facebook%'  THEN 'facebook'
    WHEN LOWER(COALESCE(youtube_url, url)) LIKE '%fb.watch%'  THEN 'facebook'
    WHEN LOWER(COALESCE(youtube_url, url)) LIKE '%t.me%'      THEN 'telegram'
    WHEN LOWER(COALESCE(youtube_url, url)) LIKE '%telegram%'  THEN 'telegram'
    ELSE 'youtube'
END
WHERE (platform IS NULL OR platform = '')
  AND COALESCE(youtube_url, url, '') <> '';
