-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Apr 28, 2026 at 03:57 AM
-- Server version: 11.8.6-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u758083880_test`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('super_admin','admin','editor') DEFAULT 'admin',
  `last_login` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`id`, `username`, `password_hash`, `role`, `last_login`, `created_at`) VALUES
(1, 'admin', '$2y$10$6Jpy57i6a/PL19PiK4VCXOTBcM0S.jelAirk4T.10XEJteAEdzH2u', 'super_admin', '2026-04-11 07:56:47', '2026-04-11 07:07:28');

-- --------------------------------------------------------

--
-- Table structure for table `app_settings`
--

CREATE TABLE `app_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `app_settings`
--

INSERT INTO `app_settings` (`setting_key`, `setting_value`, `updated_at`) VALUES
('about_us', 'About us text here...', '2026-04-11 07:07:27'),
('app_name', 'Tunnel', '2026-04-11 09:21:09'),
('app_tagline', 'Master Math. Crack Exams.', '2026-04-11 07:07:27'),
('contact_email', 'support@mathvoid.app', '2026-04-11 07:07:27'),
('contact_phone', '+91 XXXXXXXXXX', '2026-04-11 07:07:27'),
('daily_dose_active', '1', '2026-04-11 07:07:27'),
('daily_dose_text', 'Aaj ka tip yahan aayega!', '2026-04-11 07:07:27'),
('force_update', '', '2026-04-11 09:21:09'),
('instagram_url', '', '2026-04-11 07:07:27'),
('maintenance_mode', '', '2026-04-11 09:21:09'),
('min_app_version', '1.0.0', '2026-04-11 07:07:27'),
('premium_price', '50', '2026-04-11 07:07:27'),
('primary_color', '#00e5ff', '2026-04-11 09:21:09'),
('privacy_policy', 'Your privacy policy text here...', '2026-04-11 07:07:27'),
('telegram_url', '', '2026-04-11 07:07:27'),
('youtube_url', '', '2026-04-11 07:07:27');

-- --------------------------------------------------------

--
-- Table structure for table `carousel_banners`
--

CREATE TABLE `carousel_banners` (
  `id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `subtitle` varchar(200) NOT NULL,
  `image_url` varchar(500) DEFAULT '',
  `action_value` varchar(50) DEFAULT 'mcq',
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `carousel_banners`
--

INSERT INTO `carousel_banners` (`id`, `title`, `subtitle`, `image_url`, `action_value`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'NEW! SSC CGL 2024', 'Previous year papers live now', '', 'previous_year', 1, 1, '2026-04-18 10:20:47', '2026-04-18 10:20:47'),
(2, 'TUNNEL TRICKS', '8 powerful math shortcuts added', '', 'tricks', 1, 2, '2026-04-18 10:20:47', '2026-04-18 10:20:47'),
(3, 'SOLVE & EARN', 'Win rewards — top 3 get prizes!', '', 'solve_earn', 1, 3, '2026-04-18 10:20:47', '2026-04-18 10:20:47'),
(4, 'UPGRADE TO PREMIUM', 'Full access for just Rs.50 only', '', 'premium', 1, 4, '2026-04-18 10:20:47', '2026-04-18 10:20:47'),
(5, '5000 MCQs UPDATED', 'New speed math questions added', '', 'mcq', 1, 5, '2026-04-18 10:20:47', '2026-04-18 10:20:47');

-- --------------------------------------------------------

--
-- Table structure for table `challenge_entries`
--

CREATE TABLE `challenge_entries` (
  `id` int(11) NOT NULL,
  `challenge_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `score` int(11) DEFAULT 0,
  `time_taken` int(11) DEFAULT 0,
  `rank_position` int(11) DEFAULT 0,
  `prize_amount` int(11) DEFAULT 0,
  `prize_paid` tinyint(4) DEFAULT 0,
  `submitted_at` timestamp NULL DEFAULT current_timestamp(),
  `is_winner` tinyint(1) DEFAULT 0,
  `winner_announced_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_dose`
--

CREATE TABLE `daily_dose` (
  `id` int(11) NOT NULL,
  `dose_date` date NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` text NOT NULL,
  `image_url` varchar(500) DEFAULT '',
  `category` varchar(100) DEFAULT 'General',
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_practice`
--

CREATE TABLE `daily_practice` (
  `id` int(11) NOT NULL,
  `practice_date` date NOT NULL,
  `title` varchar(200) DEFAULT 'Daily Practice',
  `total_questions` int(11) DEFAULT 20,
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_practice_questions`
--

CREATE TABLE `daily_practice_questions` (
  `id` int(11) NOT NULL,
  `practice_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `order_number` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `sent_to` enum('all','premium','specific') DEFAULT 'all',
  `user_id` int(11) DEFAULT NULL,
  `is_sent` tinyint(4) DEFAULT 0,
  `sent_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `target` enum('all','premium','free') DEFAULT 'all',
  `type` varchar(50) DEFAULT 'general',
  `sent_count` int(11) DEFAULT 0,
  `status` enum('sent','failed','pending') DEFAULT 'sent'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `otp_store`
--

CREATE TABLE `otp_store` (
  `phone` varchar(15) NOT NULL,
  `otp` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `py_exams`
--

CREATE TABLE `py_exams` (
  `id` int(11) NOT NULL,
  `exam_name` varchar(100) NOT NULL,
  `exam_full_name` varchar(200) DEFAULT '',
  `exam_category` enum('SSC','RAILWAY','BANK','DEFENCE','OTHER') DEFAULT 'SSC',
  `difficulty` enum('Easy','Medium','Hard') DEFAULT 'Medium',
  `total_sets` int(11) DEFAULT 0,
  `years_covered` varchar(100) DEFAULT '',
  `is_active` tinyint(4) DEFAULT 1,
  `order_number` int(11) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `exam_id` int(11) DEFAULT NULL,
  `total_questions` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `py_exam_sets`
--

CREATE TABLE `py_exam_sets` (
  `id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `set_name` varchar(255) NOT NULL,
  `year` int(11) DEFAULT NULL,
  `total_q` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `questions`
--

CREATE TABLE `questions` (
  `id` int(11) NOT NULL,
  `set_id` int(11) NOT NULL,
  `category` enum('mcq','simplification','previous_year','daily_practice') NOT NULL,
  `question_text` text NOT NULL,
  `option_a` varchar(500) NOT NULL,
  `option_b` varchar(500) NOT NULL,
  `option_c` varchar(500) NOT NULL,
  `option_d` varchar(500) NOT NULL,
  `correct_option` enum('A','B','C','D') NOT NULL,
  `explanation` text DEFAULT '',
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `image_url` varchar(500) DEFAULT '',
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sets`
--

CREATE TABLE `sets` (
  `id` int(11) NOT NULL,
  `category` enum('mcq','simplification','previous_year') NOT NULL,
  `exam_name` varchar(100) DEFAULT '',
  `set_number` int(11) NOT NULL,
  `title` varchar(200) DEFAULT '',
  `level` enum('beginner','intermediate','advanced','expert') DEFAULT 'beginner',
  `total_questions` int(11) DEFAULT 50,
  `is_locked` tinyint(4) DEFAULT 0,
  `is_premium` tinyint(4) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shorts`
--

CREATE TABLE `shorts` (
  `id` int(11) NOT NULL,
  `platform` enum('youtube','instagram','telegram') NOT NULL,
  `title` varchar(200) NOT NULL,
  `url` varchar(500) NOT NULL,
  `thumbnail_url` varchar(500) DEFAULT '',
  `order_number` int(11) DEFAULT 1,
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `razorpay_order_id` varchar(200) DEFAULT '',
  `razorpay_payment_id` varchar(200) DEFAULT '',
  `amount` int(11) NOT NULL,
  `status` enum('created','paid','failed') DEFAULT 'created',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tricks`
--

CREATE TABLE `tricks` (
  `id` int(11) NOT NULL,
  `chapter_number` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `subtitle` varchar(300) DEFAULT '',
  `category` enum('MULTIPLICATION','DIVISION','SQUARES','FRACTIONS','SHORTCUTS') NOT NULL,
  `difficulty` enum('Beginner','Intermediate','Advanced') DEFAULT 'Beginner',
  `has_video` tinyint(4) DEFAULT 0,
  `video_url` varchar(500) DEFAULT '',
  `video_duration` int(11) DEFAULT 0,
  `has_article` tinyint(4) DEFAULT 1,
  `article_content` longtext DEFAULT '',
  `read_duration` int(11) DEFAULT 5,
  `is_new` tinyint(4) DEFAULT 0,
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) DEFAULT '',
  `phone` varchar(15) NOT NULL,
  `is_premium` tinyint(4) DEFAULT 0,
  `premium_expiry` date DEFAULT NULL,
  `total_xp` int(11) DEFAULT 0,
  `current_streak` int(11) DEFAULT 0,
  `last_active` date DEFAULT NULL,
  `rank_position` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_set_progress`
--

CREATE TABLE `user_set_progress` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `set_id` int(11) NOT NULL,
  `category` varchar(50) NOT NULL,
  `questions_done` int(11) DEFAULT 0,
  `is_completed` tinyint(4) DEFAULT 0,
  `progress_pct` decimal(5,2) DEFAULT 0.00,
  `last_attempted` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_test_history`
--

CREATE TABLE `user_test_history` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `category` enum('mcq','simplification','previous_year','daily_practice','solve_earn') NOT NULL,
  `set_id` int(11) DEFAULT 0,
  `exam_name` varchar(100) DEFAULT '',
  `score` int(11) DEFAULT 0,
  `total_questions` int(11) DEFAULT 0,
  `correct` int(11) DEFAULT 0,
  `wrong` int(11) DEFAULT 0,
  `skipped` int(11) DEFAULT 0,
  `accuracy` decimal(5,2) DEFAULT 0.00,
  `time_taken` int(11) DEFAULT 0,
  `avg_time_per_q` decimal(5,2) DEFAULT 0.00,
  `xp_earned` int(11) DEFAULT 0,
  `completed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `weekly_challenges`
--

CREATE TABLE `weekly_challenges` (
  `id` int(11) NOT NULL,
  `week_start` date NOT NULL,
  `week_end` date NOT NULL,
  `title` varchar(200) DEFAULT 'Weekly Challenge',
  `total_questions` int(11) DEFAULT 20,
  `prize_1st` int(11) DEFAULT 500,
  `prize_2nd` int(11) DEFAULT 300,
  `prize_3rd` int(11) DEFAULT 200,
  `prize_4th` int(11) DEFAULT 100,
  `prize_5th` int(11) DEFAULT 50,
  `status` enum('upcoming','active','ended','results_declared') DEFAULT 'upcoming',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `prize_amount` decimal(10,2) DEFAULT 0.00,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `app_settings`
--
ALTER TABLE `app_settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Indexes for table `carousel_banners`
--
ALTER TABLE `carousel_banners`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `challenge_entries`
--
ALTER TABLE `challenge_entries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_entry` (`challenge_id`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `daily_dose`
--
ALTER TABLE `daily_dose`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `dose_date` (`dose_date`);

--
-- Indexes for table `daily_practice`
--
ALTER TABLE `daily_practice`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `practice_date` (`practice_date`);

--
-- Indexes for table `daily_practice_questions`
--
ALTER TABLE `daily_practice_questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `practice_id` (`practice_id`),
  ADD KEY `question_id` (`question_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `otp_store`
--
ALTER TABLE `otp_store`
  ADD PRIMARY KEY (`phone`);

--
-- Indexes for table `py_exams`
--
ALTER TABLE `py_exams`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `py_exam_sets`
--
ALTER TABLE `py_exam_sets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `exam_id` (`exam_id`);

--
-- Indexes for table `questions`
--
ALTER TABLE `questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_set_category` (`set_id`,`category`);

--
-- Indexes for table `sets`
--
ALTER TABLE `sets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_category_level` (`category`,`level`);

--
-- Indexes for table `shorts`
--
ALTER TABLE `shorts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `tricks`
--
ALTER TABLE `tricks`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`);

--
-- Indexes for table `user_set_progress`
--
ALTER TABLE `user_set_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_set` (`user_id`,`set_id`,`category`);

--
-- Indexes for table `user_test_history`
--
ALTER TABLE `user_test_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_category` (`user_id`,`category`);

--
-- Indexes for table `weekly_challenges`
--
ALTER TABLE `weekly_challenges`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `carousel_banners`
--
ALTER TABLE `carousel_banners`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `challenge_entries`
--
ALTER TABLE `challenge_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_dose`
--
ALTER TABLE `daily_dose`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_practice`
--
ALTER TABLE `daily_practice`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_practice_questions`
--
ALTER TABLE `daily_practice_questions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `py_exams`
--
ALTER TABLE `py_exams`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `py_exam_sets`
--
ALTER TABLE `py_exam_sets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `questions`
--
ALTER TABLE `questions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sets`
--
ALTER TABLE `sets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shorts`
--
ALTER TABLE `shorts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tricks`
--
ALTER TABLE `tricks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_set_progress`
--
ALTER TABLE `user_set_progress`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_test_history`
--
ALTER TABLE `user_test_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `weekly_challenges`
--
ALTER TABLE `weekly_challenges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `challenge_entries`
--
ALTER TABLE `challenge_entries`
  ADD CONSTRAINT `challenge_entries_ibfk_1` FOREIGN KEY (`challenge_id`) REFERENCES `weekly_challenges` (`id`),
  ADD CONSTRAINT `challenge_entries_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `daily_practice_questions`
--
ALTER TABLE `daily_practice_questions`
  ADD CONSTRAINT `daily_practice_questions_ibfk_1` FOREIGN KEY (`practice_id`) REFERENCES `daily_practice` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_practice_questions_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `py_exam_sets`
--
ALTER TABLE `py_exam_sets`
  ADD CONSTRAINT `py_exam_sets_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `py_exams` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `user_set_progress`
--
ALTER TABLE `user_set_progress`
  ADD CONSTRAINT `user_set_progress_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_test_history`
--
ALTER TABLE `user_test_history`
  ADD CONSTRAINT `user_test_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
