-- ═══════════════════════════════════════════════════════════════════════
-- TUNNL — Dummy testing data
--
-- Run this AFTER v2_align_schema.sql.
-- Adds:
--   • 4 banners
--   • 5 MCQ sets × 10 questions each = 50 MCQ questions
--   • 2 simplification sets × 5 questions each = 10 questions
--   • 4 PYQ exams (with sets + questions)
--   • 8 tricks (mix of free + premium)
--   • 6 shorts
--   • 7 days of daily dose
--
-- Idempotent — safe to re-run. Uses exam_name / set_number / order_num
-- to dedupe so it won't create duplicates if you run it twice.
-- ═══════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────
-- BANNERS (carousel on dashboard)
-- ───────────────────────────────────────────────────────
INSERT INTO `carousel_banners` (`title`, `subtitle`, `image_url`, `action_value`, `is_active`, `sort_order`)
SELECT '5000+ Speed Math MCQs',
       'Daily practice se exam crack karo',
       'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
       'mcq', 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `carousel_banners` WHERE title = '5000+ Speed Math MCQs');

INSERT INTO `carousel_banners` (`title`, `subtitle`, `image_url`, `action_value`, `is_active`, `sort_order`)
SELECT 'Tunnel Tricks',
       'Smart shortcuts to solve in seconds',
       'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800',
       'tricks', 1, 2
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `carousel_banners` WHERE title = 'Tunnel Tricks');

INSERT INTO `carousel_banners` (`title`, `subtitle`, `image_url`, `action_value`, `is_active`, `sort_order`)
SELECT 'Previous Year Papers',
       'SSC, Railway, Banking — sab cover',
       'https://images.unsplash.com/photo-1606326608606-aa0b62935f2b?w=800',
       'previous_year', 1, 3
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `carousel_banners` WHERE title = 'Previous Year Papers');

INSERT INTO `carousel_banners` (`title`, `subtitle`, `image_url`, `action_value`, `is_active`, `sort_order`)
SELECT 'Premium @ ₹50',
       'Lifetime access — sab unlocked',
       'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
       'premium', 1, 4
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `carousel_banners` WHERE title = 'Premium @ ₹50');

-- ───────────────────────────────────────────────────────
-- 5000 SPEED MATH MCQ — 5 sets × 10 questions
-- ───────────────────────────────────────────────────────
INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 1, 'Set 01 — Basic Arithmetic', 'beginner', 10, 0, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=1);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 2, 'Set 02 — Speed Drills', 'beginner', 10, 0, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=2);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 3, 'Set 03 — Mixed Concepts', 'intermediate', 10, 0, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=3);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 4, 'Set 04 — Advanced Speed', 'intermediate', 10, 0, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=4);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'mcq', '', 5, 'Set 05 — Master Level', 'advanced', 10, 0, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='mcq' AND set_number=5);

-- ── Set 1 questions ────────────────────────────────────
INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 25 × 4?', '90', '100', '110', '120', 'B', '25 × 4 = 100. Easy multiplication.', 'easy', 30, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 25 × 4?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 15% of 200?', '25', '30', '35', '40', 'B', '15% of 200 = 200 × 0.15 = 30', 'easy', 30, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 15% of 200?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'Square of 12 is?', '124', '144', '154', '164', 'B', '12² = 12 × 12 = 144', 'easy', 30, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Square of 12 is?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', '125 ÷ 5 = ?', '15', '20', '25', '30', 'C', '125 ÷ 5 = 25', 'easy', 30, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '125 ÷ 5 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 7 × 8?', '54', '56', '58', '60', 'B', '7 × 8 = 56 (basic multiplication table)', 'easy', 30, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 7 × 8?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 50% of 80?', '30', '35', '40', '45', 'C', '50% of 80 = 80/2 = 40', 'easy', 30, 6, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 50% of 80?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 36 + 47?', '73', '83', '93', '103', 'B', '36 + 47 = 83', 'easy', 30, 7, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 36 + 47?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 9 × 11?', '89', '99', '109', '119', 'B', '9 × 11 = 99 (use 11-trick: 9_(0+9)_9 → wait, simpler: 9×11=99)', 'easy', 30, 8, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 9 × 11?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 100 - 37?', '53', '63', '73', '83', 'B', '100 - 37 = 63', 'easy', 30, 9, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 100 - 37?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=1), 'mcq', 'What is 144 ÷ 12?', '10', '11', '12', '13', 'C', '144 ÷ 12 = 12 (since 12² = 144)', 'easy', 30, 10, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'What is 144 ÷ 12?');

-- ── Set 2 questions ────────────────────────────────────
INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '35² = ?', '1125', '1225', '1325', '1425', 'B', '35² → 3×4=12, append 25 → 1225', 'easy', 25, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '35² = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '23 × 11 = ?', '233', '253', '273', '293', 'B', '11-trick: 2_(2+3)_3 = 253', 'easy', 25, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '23 × 11 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '20% of 350 = ?', '60', '70', '80', '90', 'B', '20% = 1/5, so 350/5 = 70', 'easy', 25, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '20% of 350 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '75 + 49 = ?', '114', '124', '134', '144', 'B', '75 + 49 = 124', 'easy', 25, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '75 + 49 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '16 × 25 = ?', '350', '400', '450', '500', 'B', '16 × 25 = 16 × 100/4 = 400', 'medium', 25, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '16 × 25 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', 'Square root of 169 = ?', '11', '12', '13', '14', 'C', '13 × 13 = 169', 'easy', 25, 6, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Square root of 169 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '450 ÷ 9 = ?', '40', '45', '50', '55', 'C', '450 ÷ 9 = 50', 'easy', 25, 7, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '450 ÷ 9 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '12 × 15 = ?', '170', '180', '190', '200', 'B', '12 × 15 = 180', 'medium', 25, 8, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '12 × 15 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '88 - 39 = ?', '39', '49', '59', '69', 'B', '88 - 39 = 49', 'easy', 25, 9, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '88 - 39 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=2), 'mcq', '45² = ?', '1925', '2025', '2125', '2225', 'B', '45² → 4×5=20, append 25 → 2025', 'medium', 25, 10, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '45² = ?');

-- ── Set 3 questions (Premium) ──────────────────────────
INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', 'If 3x + 7 = 22, then x = ?', '3', '5', '7', '15', 'B', '3x = 22 - 7 = 15, so x = 5', 'medium', 30, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'If 3x + 7 = 22, then x = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '24 × 26 = ?', '604', '624', '644', '664', 'B', 'Use (25-1)(25+1) = 625 - 1 = 624', 'medium', 30, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '24 × 26 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '37.5% of 800 = ?', '250', '300', '350', '400', 'B', '37.5% = 3/8, so 800 × 3/8 = 300', 'medium', 30, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '37.5% of 800 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '5! = ?', '60', '100', '120', '150', 'C', '5! = 5×4×3×2×1 = 120', 'medium', 30, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '5! = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', 'LCM of 12 and 18 = ?', '24', '30', '36', '48', 'C', '12 = 2²×3, 18 = 2×3². LCM = 2²×3² = 36', 'medium', 30, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'LCM of 12 and 18 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '⅔ of 120 = ?', '60', '70', '80', '90', 'C', '120 × 2/3 = 80', 'medium', 30, 6, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '⅔ of 120 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '64² = ?', '4006', '4096', '4126', '4196', 'B', '64² = (60+4)² = 3600 + 480 + 16 = 4096', 'medium', 30, 7, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '64² = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', 'HCF of 18 and 24 = ?', '4', '6', '8', '12', 'B', '18 = 2×3², 24 = 2³×3. HCF = 2×3 = 6', 'medium', 30, 8, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'HCF of 18 and 24 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', '125 × 8 = ?', '900', '1000', '1100', '1200', 'B', '125 × 8 = 1000 (since 125 = 1000/8)', 'medium', 30, 9, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '125 × 8 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=3), 'mcq', 'Cube of 7 = ?', '243', '343', '443', '543', 'B', '7³ = 7×7×7 = 49×7 = 343', 'medium', 30, 10, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Cube of 7 = ?');

-- ── Set 4 questions (Premium, intermediate) ────────────
INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'A train covers 240 km in 4 hrs. Speed?', '40 km/h', '50 km/h', '60 km/h', '70 km/h', 'C', 'Speed = Distance/Time = 240/4 = 60 km/h', 'medium', 35, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'A train covers 240 km in 4 hrs. Speed?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Simple interest on ₹1000 @ 5% for 2 years = ?', '₹50', '₹100', '₹150', '₹200', 'B', 'SI = PRT/100 = 1000×5×2/100 = 100', 'medium', 35, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Simple interest on ₹1000 @ 5% for 2 years = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Profit on ₹100 sold at ₹125 = ?', '20%', '25%', '30%', '35%', 'B', 'Profit % = (25/100)×100 = 25%', 'medium', 35, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Profit on ₹100 sold at ₹125 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Average of 10, 20, 30, 40, 50?', '20', '25', '30', '35', 'C', 'Avg = 150/5 = 30', 'medium', 35, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Average of 10, 20, 30, 40, 50?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Ratio 12:18 simplifies to?', '1:2', '2:3', '3:4', '4:5', 'B', 'GCD of 12,18 is 6. So 12:18 = 2:3', 'medium', 35, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Ratio 12:18 simplifies to?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Compound interest on ₹1000 @ 10% for 2 years = ?', '₹200', '₹210', '₹220', '₹230', 'B', 'CI = 1000(1.1)² - 1000 = 1210 - 1000 = 210', 'hard', 35, 6, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Compound interest on ₹1000 @ 10% for 2 years = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'A man buys at ₹80, sells at ₹100. Profit %?', '20%', '25%', '30%', '35%', 'B', 'Profit = 20, % = (20/80)×100 = 25%', 'medium', 35, 7, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'A man buys at ₹80, sells at ₹100. Profit %?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', '25% as fraction = ?', '1/2', '1/3', '1/4', '1/5', 'C', '25/100 = 1/4', 'easy', 35, 8, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '25% as fraction = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Area of square with side 8 cm?', '32', '48', '64', '128', 'C', 'Area = side² = 8² = 64', 'easy', 35, 9, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Area of square with side 8 cm?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=4), 'mcq', 'Perimeter of rectangle 6×4 = ?', '10', '20', '24', '30', 'B', 'P = 2(L+B) = 2(6+4) = 20', 'easy', 35, 10, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Perimeter of rectangle 6×4 = ?');

-- ── Set 5 questions (Premium, advanced) ────────────────
INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'A and B together do work in 12 days, A alone in 20. B alone?', '20 days', '25 days', '30 days', '35 days', 'C', '1/12 - 1/20 = 5/60 - 3/60 = 2/60 = 1/30. So B = 30 days', 'hard', 40, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'A and B together do work in 12 days, A alone in 20. B alone?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'Mixture of milk:water 4:1, total 25L. Water?', '4L', '5L', '6L', '7L', 'B', 'Water = 25 × 1/5 = 5L', 'medium', 40, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Mixture of milk:water 4:1, total 25L. Water?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', '15% of 250 + 25% of 80 = ?', '47.5', '57.5', '67.5', '77.5', 'B', '37.5 + 20 = 57.5', 'hard', 40, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '15% of 250 + 25% of 80 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'Speed in km/h to m/s: multiply by?', '5/18', '18/5', '3/10', '10/3', 'A', 'km/h × 5/18 = m/s', 'medium', 40, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Speed in km/h to m/s: multiply by?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'A boat: speed 10 km/h still, 5 km/h current. Downstream speed?', '5', '10', '15', '20', 'C', 'Downstream = 10+5 = 15 km/h', 'medium', 40, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'A boat: speed 10 km/h still, 5 km/h current. Downstream speed?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', '√625 = ?', '15', '20', '25', '30', 'C', '25 × 25 = 625', 'easy', 40, 6, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '√625 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'Discount on ₹500 @ 10% = ?', '₹40', '₹50', '₹60', '₹70', 'B', '500 × 10/100 = 50', 'easy', 40, 7, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Discount on ₹500 @ 10% = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', '4 men finish job in 15 days. 6 men?', '8 days', '10 days', '12 days', '14 days', 'B', '4×15 = 6×x → x = 60/6 = 10', 'medium', 40, 8, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '4 men finish job in 15 days. 6 men?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'Probability of getting 6 on a die = ?', '1/2', '1/3', '1/4', '1/6', 'D', 'Favourable=1, Total=6 → 1/6', 'easy', 40, 9, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Probability of getting 6 on a die = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='mcq' AND set_number=5), 'mcq', 'log₁₀(100) = ?', '0', '1', '2', '10', 'C', '10² = 100, so log = 2', 'hard', 40, 10, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'log₁₀(100) = ?');

-- ───────────────────────────────────────────────────────
-- 500 SIMPLIFICATION — 2 sets × 5 questions
-- ───────────────────────────────────────────────────────
INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'simplification', '', 1, 'Simplification 01 — Basics', 'beginner', 5, 0, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='simplification' AND set_number=1);

INSERT INTO `sets` (`category`, `exam_name`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'simplification', '', 2, 'Simplification 02 — Advanced', 'intermediate', 5, 0, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `sets` WHERE category='simplification' AND set_number=2);

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='simplification' AND set_number=1), 'simplification', 'Simplify: 24 + 36 ÷ 6 × 2', '20', '32', '36', '60', 'C', 'BODMAS: 36÷6=6, ×2=12, +24=36', 'medium', 30, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'Simplify: 24 + 36 ÷ 6 × 2');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='simplification' AND set_number=1), 'simplification', '(15 × 8) - (3 × 12) = ?', '76', '84', '94', '104', 'B', '120 - 36 = 84', 'easy', 30, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '(15 × 8) - (3 × 12) = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='simplification' AND set_number=1), 'simplification', '½ + ⅓ = ?', '⅔', '⅚', '¾', '⁵⁄₆', 'B', '½ + ⅓ = 3/6 + 2/6 = 5/6', 'medium', 30, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '½ + ⅓ = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='simplification' AND set_number=1), 'simplification', '√144 + √169 = ?', '23', '25', '27', '29', 'B', '12 + 13 = 25', 'easy', 30, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '√144 + √169 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='simplification' AND set_number=1), 'simplification', '(8² - 6²) = ?', '24', '28', '32', '36', 'B', 'Use a²-b² = (a-b)(a+b) = 2×14 = 28', 'easy', 30, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = '(8² - 6²) = ?');

-- ───────────────────────────────────────────────────────
-- TRICKS — 8 (mix of free + premium-feel)
-- ───────────────────────────────────────────────────────
INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 1, 'Multiplication by 11', 'Add the digits, place between',
       'MULTIPLICATION', 'Beginner', 0, 1,
       'For any 2-digit number × 11: add the two digits and place the sum between them.\n\nExample: 35 × 11 → 3 _ (3+5) _ 5 → 385\n\nIf sum > 9, carry over. 78 × 11 → 7 _ 15 _ 8 → 858 (carry 1).',
       3, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 1);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 2, 'Square of numbers ending in 5', 'No paper, no pen — one rule',
       'SQUARES', 'Beginner', 0, 1,
       'Multiply leading digit(s) by next number, append 25.\n\n• 35² → 3×4 = 12 → 1225\n• 65² → 6×7 = 42 → 4225\n• 105² → 10×11 = 110 → 11025\n\nWorks for ANY number ending in 5.',
       3, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 2);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 3, 'Multiplication by 9', 'Subtract from next 10',
       'MULTIPLICATION', 'Beginner', 0, 1,
       'For any number × 9: multiply by 10 and subtract the original.\n\n• 9 × 7 = 70 - 7 = 63\n• 9 × 23 = 230 - 23 = 207\n• 9 × 156 = 1560 - 156 = 1404\n\nFastest method ever for 9-table.',
       2, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 3);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 4, 'Division by 5', 'Double, then move decimal',
       'DIVISION', 'Beginner', 0, 1,
       'To divide by 5, double the number and divide by 10.\n\n• 75 ÷ 5 → 75×2 = 150 → 15.0\n• 240 ÷ 5 → 480 → 48\n• 113 ÷ 5 → 226 → 22.6\n\nMuch faster than long division.',
       2, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 4);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 5, '15% Tip Trick', 'Restaurant tip in 3 seconds',
       'SHORTCUTS', 'Intermediate', 0, 1,
       'Find 15% of any bill quickly:\n\n1. Find 10% (move decimal one left)\n2. Halve that = 5%\n3. Add them = 15%\n\nExample: 15% of ₹240 → 24 + 12 = ₹36',
       3, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 5);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 6, 'Square close to 50/100', 'Use base technique',
       'SQUARES', 'Intermediate', 0, 1,
       'For numbers near 100: subtract from 100, square it, base = original-(diff).\n\n• 98² → 100-98=2. Base: 98-2=96. Square of diff: 04. Result: 9604.\n• 103² → 103-100=3. Base: 103+3=106. Square: 09. Result: 10609.',
       4, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 6);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 7, 'Quick Percentage', 'Convert any % to fraction',
       'FRACTIONS', 'Intermediate', 0, 1,
       'Memorize these fraction equivalents and percentages become trivial:\n\n• 12.5% = 1/8\n• 16.66% = 1/6\n• 25% = 1/4\n• 33.33% = 1/3\n• 37.5% = 3/8\n• 50% = 1/2\n• 66.66% = 2/3\n• 75% = 3/4\n• 87.5% = 7/8',
       5, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 7);

INSERT INTO `tricks` (`chapter_number`, `title`, `subtitle`, `category`, `difficulty`, `has_video`, `has_article`, `article_content`, `read_duration`, `is_new`, `is_active`)
SELECT 8, 'Cube of 2-digit numbers', 'Vedic math shortcut',
       'SQUARES', 'Advanced', 0, 1,
       'Cube of any 2-digit number using ratio + addition:\n\nFor 23³: ratio 2:3 → 8 : 12 : 18 : 27\nNow double middle two: +24 : +36\nAdd: 8, 36, 54, 27 → carry → 12167\n\n23³ = 12167. Verify: 23×23×23 = 12167. ✓',
       6, 0, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `tricks` WHERE chapter_number = 8);

-- ───────────────────────────────────────────────────────
-- SHORTS — 6 entries
-- ───────────────────────────────────────────────────────
INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'youtube', 'Square of 35 in 2 seconds',
       'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ',
       'TRICKS', 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'Square of 35 in 2 seconds');

INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'youtube', 'Multiply by 11 — fastest method',
       'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ',
       'TRICKS', 1, 2
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'Multiply by 11 — fastest method');

INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'youtube', 'Divide by 5 in 1 step',
       'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ',
       'TRICKS', 1, 3
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'Divide by 5 in 1 step');

INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'instagram', 'SSC CGL strategy 2024',
       'https://www.instagram.com/reel/abcd1234/',
       'https://www.instagram.com/reel/abcd1234/',
       'EXAM_TIPS', 1, 4
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'SSC CGL strategy 2024');

INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'youtube', '15% tip in 3 seconds',
       'https://youtu.be/dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ',
       'TRICKS', 1, 5
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = '15% tip in 3 seconds');

INSERT INTO `shorts` (`platform`, `title`, `url`, `youtube_url`, `category`, `is_active`, `order_number`)
SELECT 'telegram', 'Daily quiz channel',
       'https://t.me/tunnelmath', 'https://t.me/tunnelmath',
       'COMMUNITY', 1, 6
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `shorts` WHERE title = 'Daily quiz channel');

-- ───────────────────────────────────────────────────────
-- DAILY DOSE — past + today + future (7 days)
-- ───────────────────────────────────────────────────────
INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT CURDATE(), 'Square of 35',
       'Numbers ending in 5: multiply leading digits by next, append 25.',
       'shortcut', '35² → 3×4 = 12, append 25 → 1225',
       'Works for any 2 or 3-digit number ending in 5.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = CURDATE());

INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'Multiply by 11',
       'Add the digits, place sum between them.',
       'shortcut', '23 × 11 → 2_(2+3)_3 → 253',
       'If sum > 9, carry over: 78 × 11 → 7_15_8 → 858.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY));

INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Divide by 5',
       'Double the number, then divide by 10.',
       'shortcut', '85 ÷ 5 → 170 → 17',
       'Easier than long division for any 2 or 3 digit number.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = DATE_SUB(CURDATE(), INTERVAL 2 DAY));

INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT DATE_ADD(CURDATE(), INTERVAL 1 DAY), 'Multiply by 9',
       'Multiply by 10 and subtract original.',
       'shortcut', '9 × 17 → 170 - 17 = 153',
       'Works for any × 9 problem in your head.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY));

INSERT INTO `daily_dose` (`dose_date`, `title`, `content`, `type`, `example`, `tip`, `is_active`)
SELECT DATE_ADD(CURDATE(), INTERVAL 2 DAY), '15% Tip',
       'Find 10%, halve it, add. Done.',
       'shortcut', '15% of ₹240 → 24 + 12 = ₹36',
       'Restaurants, discounts, anywhere.', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_dose` WHERE dose_date = DATE_ADD(CURDATE(), INTERVAL 2 DAY));

-- ───────────────────────────────────────────────────────
-- PREVIOUS YEAR — 4 exams + sets + questions
-- ───────────────────────────────────────────────────────
-- (py_exams already seeded by v2 migration; here we add sets + questions)

-- SSC CGL 2024 — Set 1
INSERT INTO `sets` (`category`, `exam_name`, `exam_id`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'previous_year', 'SSC CGL', (SELECT id FROM `py_exams` WHERE exam_name='SSC CGL' LIMIT 1),
       1, 'SSC CGL 2024 — Tier 1 Quant', 'intermediate', 5, 0, 0, 1
FROM DUAL
WHERE EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='SSC CGL')
  AND NOT EXISTS (
    SELECT 1 FROM `sets`
    WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1
  );

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1 LIMIT 1),
       'previous_year', 'SSC CGL 2024: Sum of first 50 odd natural numbers?', '1500', '2500', '3500', '4500', 'B',
       'Sum of first n odd numbers = n². So 50² = 2500.', 'medium', 60, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'SSC CGL 2024: Sum of first 50 odd natural numbers?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1 LIMIT 1),
       'previous_year', 'SSC CGL: A man invests ₹5000 @ 8% SI for 3 years. Amount?', '₹5800', '₹6000', '₹6200', '₹6400', 'C',
       'SI = 5000×8×3/100 = 1200. Amount = 5000+1200 = 6200.', 'medium', 60, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'SSC CGL: A man invests ₹5000 @ 8% SI for 3 years. Amount?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1 LIMIT 1),
       'previous_year', 'SSC CGL: Average of 5 numbers is 30. If one number is removed, avg = 25. Removed?', '40', '50', '60', '70', 'B',
       'Total: 5×30=150. After: 4×25=100. Removed = 50.', 'medium', 60, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'SSC CGL: Average of 5 numbers is 30. If one number is removed, avg = 25. Removed?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1 LIMIT 1),
       'previous_year', 'SSC CGL: 30% of 50% of 200 = ?', '20', '30', '40', '50', 'B',
       '50% of 200 = 100. 30% of 100 = 30.', 'easy', 60, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'SSC CGL: 30% of 50% of 200 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='SSC CGL' AND set_number=1 LIMIT 1),
       'previous_year', 'SSC CGL: Pipe A fills tank in 6h, B in 4h. Together?', '2.0h', '2.4h', '2.8h', '3.0h', 'B',
       '1/6 + 1/4 = 2/12 + 3/12 = 5/12. Time = 12/5 = 2.4h.', 'medium', 60, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'SSC CGL: Pipe A fills tank in 6h, B in 4h. Together?');

-- RRB NTPC — Set 1
INSERT INTO `sets` (`category`, `exam_name`, `exam_id`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'previous_year', 'RRB NTPC', (SELECT id FROM `py_exams` WHERE exam_name='RRB NTPC' LIMIT 1),
       1, 'RRB NTPC 2024 — Maths Set', 'beginner', 5, 0, 0, 1
FROM DUAL
WHERE EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='RRB NTPC')
  AND NOT EXISTS (
    SELECT 1 FROM `sets`
    WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1
  );

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1 LIMIT 1),
       'previous_year', 'RRB NTPC: A train 200m crosses pole in 10 sec. Speed?', '20 m/s', '40 m/s', '60 m/s', '80 m/s', 'A',
       'Speed = 200/10 = 20 m/s.', 'easy', 60, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'RRB NTPC: A train 200m crosses pole in 10 sec. Speed?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1 LIMIT 1),
       'previous_year', 'RRB NTPC: Ratio of ages of A:B = 3:5. Sum=40. A''s age?', '12', '15', '18', '20', 'B',
       'Total parts = 8. A = 40 × 3/8 = 15.', 'easy', 60, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text LIKE 'RRB NTPC: Ratio of ages of A:B%');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1 LIMIT 1),
       'previous_year', 'RRB NTPC: HCF of 36 and 48 = ?', '4', '6', '12', '18', 'C',
       '36=2²×3², 48=2⁴×3. HCF=2²×3=12.', 'easy', 60, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'RRB NTPC: HCF of 36 and 48 = ?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1 LIMIT 1),
       'previous_year', 'RRB NTPC: 5 years ago, age was 25. Now?', '20', '25', '30', '35', 'C',
       '25 + 5 = 30.', 'easy', 60, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'RRB NTPC: 5 years ago, age was 25. Now?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='RRB NTPC' AND set_number=1 LIMIT 1),
       'previous_year', 'RRB NTPC: 25% of 60 + 30% of 40?', '20', '25', '27', '30', 'C',
       '15 + 12 = 27.', 'medium', 60, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'RRB NTPC: 25% of 60 + 30% of 40?');

-- IBPS PO — Set 1 (Premium)
INSERT INTO `sets` (`category`, `exam_name`, `exam_id`, `set_number`, `title`, `level`, `total_questions`, `is_locked`, `is_premium`, `is_active`)
SELECT 'previous_year', 'IBPS PO', (SELECT id FROM `py_exams` WHERE exam_name='IBPS PO' LIMIT 1),
       1, 'IBPS PO 2024 — Quant Aptitude', 'advanced', 5, 0, 1, 1
FROM DUAL
WHERE EXISTS (SELECT 1 FROM `py_exams` WHERE exam_name='IBPS PO')
  AND NOT EXISTS (
    SELECT 1 FROM `sets`
    WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1
  );

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1 LIMIT 1),
       'previous_year', 'IBPS PO: CI on ₹10000 @ 10% for 2 years compounded annually?', '₹2000', '₹2100', '₹2200', '₹2300', 'B',
       '10000(1.1)² - 10000 = 12100 - 10000 = 2100.', 'hard', 75, 1, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'IBPS PO: CI on ₹10000 @ 10% for 2 years compounded annually?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1 LIMIT 1),
       'previous_year', 'IBPS PO: Profit % if CP=160, SP=200?', '20%', '25%', '30%', '40%', 'B',
       'Profit=40, % = 40/160 × 100 = 25%.', 'medium', 75, 2, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'IBPS PO: Profit % if CP=160, SP=200?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1 LIMIT 1),
       'previous_year', 'IBPS PO: 3 boats: 2:3:5, total 30L. Smallest?', '4L', '6L', '8L', '10L', 'B',
       'Parts=10. Smallest = 30 × 2/10 = 6L.', 'medium', 75, 3, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'IBPS PO: 3 boats: 2:3:5, total 30L. Smallest?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1 LIMIT 1),
       'previous_year', 'IBPS PO: A alone 12d, B alone 8d. Together?', '4d', '4.8d', '5d', '6d', 'B',
       '1/12+1/8=2/24+3/24=5/24. Time=24/5=4.8d.', 'medium', 75, 4, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'IBPS PO: A alone 12d, B alone 8d. Together?');

INSERT INTO `questions` (`set_id`, `category`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `time_limit`, `order_num`, `is_active`)
SELECT (SELECT id FROM `sets` WHERE category='previous_year' AND exam_name='IBPS PO' AND set_number=1 LIMIT 1),
       'previous_year', 'IBPS PO: log₂(64) = ?', '4', '5', '6', '7', 'C',
       '2⁶ = 64, so log₂(64) = 6.', 'hard', 75, 5, 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `questions` WHERE question_text = 'IBPS PO: log₂(64) = ?');

-- ───────────────────────────────────────────────────────
-- DAILY PRACTICE — today's practice for testing
-- ───────────────────────────────────────────────────────
INSERT INTO `daily_practice` (`practice_date`, `title`, `total_questions`, `xp_reward`, `difficulty`, `is_active`)
SELECT CURDATE(), 'Today''s Speed Practice', 5, 50, 'medium', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `daily_practice` WHERE practice_date = CURDATE());

INSERT INTO `daily_practice_questions` (`practice_id`, `question_id`, `order_number`)
SELECT (SELECT id FROM `daily_practice` WHERE practice_date = CURDATE() LIMIT 1),
       q.id, q.order_num
FROM `questions` q
JOIN `sets` s ON q.set_id = s.id
WHERE s.category='mcq' AND s.set_number=1
  AND NOT EXISTS (
    SELECT 1 FROM `daily_practice_questions` dpq
    WHERE dpq.practice_id = (SELECT id FROM `daily_practice` WHERE practice_date = CURDATE() LIMIT 1)
      AND dpq.question_id = q.id
  )
ORDER BY q.order_num
LIMIT 5;
