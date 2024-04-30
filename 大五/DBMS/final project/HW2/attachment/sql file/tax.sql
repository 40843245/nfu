-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb1
-- Generation Time: Apr 30, 2024 at 01:01 AM
-- Server version: 10.7.8-MariaDB-1:10.7.8+maria~ubu2004
-- PHP Version: 8.0.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tax`
--

-- --------------------------------------------------------

--
-- Table structure for table `account_list`
--

CREATE TABLE `account_list` (
  `account_no` int(11) NOT NULL CHECK (`account_no` > 0),
  `account_name` varchar(20) NOT NULL CHECK (`account_name` <> convert(char(0x10) using utf8mb4)),
  `password_name` varchar(20) NOT NULL CHECK (`password_name` <> convert(char(0x10) using utf8mb4) and octet_length(`password_name`) >= 8),
  `email_name` varchar(20) NOT NULL CHECK (`email_name` <> convert(char(0x10) using utf8mb4) and octet_length(`email_name`) >= 8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `account_list`
--
DELIMITER $$
CREATE TRIGGER `email_name_validation` BEFORE INSERT ON `account_list` FOR EACH ROW BEGIN
IF NOT(NEW.email_name LIKE '%@gmail.com' OR
NEW.email_name LIKE '%@gm.nfu.edu.tw')
THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email!'; 
END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `try_login_result` BEFORE INSERT ON `account_list` FOR EACH ROW BEGIN
IF NEW.account_name = NEW.password_name
THEN
UPDATE try_login SET try_login.try_login_times = 0;
UPDATE try_login SET try_login.prev_success_login_time = NOW();
ELSE
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'login fail!'; 
UPDATE try_login SET try_login.prev_try_login_time = try_login.prev_try_login_time + 1;
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `administrator`
--

CREATE TABLE `administrator` (
  `administrator_no` int(11) NOT NULL CHECK (`administrator_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `advanced_operation_info`
--

CREATE TABLE `advanced_operation_info` (
  `advanced_operation_info_no` smallint(6) NOT NULL CHECK (`advanced_operation_info_no` > 0),
  `advanced_operation_info_type_no` smallint(6) NOT NULL CHECK (`advanced_operation_info_type_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `advanced_operation_info_mapping`
--

CREATE TABLE `advanced_operation_info_mapping` (
  `advanced_operation_info_type_no` smallint(6) NOT NULL CHECK (`advanced_operation_info_type_no` > 0),
  `advanced_operation_info_type_name` varchar(20) NOT NULL CHECK (`advanced_operation_info_type_name` <> convert(char(0x10) using utf8mb4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `earning_no`
--

CREATE TABLE `earning_no` (
  `earning_no` int(11) NOT NULL CHECK (`earning_no` > 0),
  `earning_type_no` int(11) NOT NULL CHECK (`earning_type_no` > 0),
  `income_number` int(11) NOT NULL CHECK (`income_number` >= 0),
  `income_deduction_type_no` int(11) NOT NULL CHECK (`income_deduction_type_no` > 0),
  `income_deduction_number` int(11) NOT NULL CHECK (`income_deduction_number` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `earning_no_list`
--

CREATE TABLE `earning_no_list` (
  `earning_nos` int(11) NOT NULL CHECK (`earning_nos` > 0),
  `earning_no` int(11) NOT NULL CHECK (`earning_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `earning_type_mapping`
--

CREATE TABLE `earning_type_mapping` (
  `earning_type_no` int(11) NOT NULL CHECK (`earning_type_no` > 0),
  `earning_type_name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `form`
--

CREATE TABLE `form` (
  `form_no` int(11) NOT NULL CHECK (`form_no` > 0),
  `spouse_status` tinyint(1) NOT NULL,
  `earning_nos` int(11) NOT NULL,
  `prev_tax_paying_status_nos` int(11) NOT NULL,
  `prev_tax_returning_status_nos` int(11) NOT NULL,
  `prev_tax_rebating_status_nos` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `general_user`
--

CREATE TABLE `general_user` (
  `general_user_no` int(11) NOT NULL CHECK (`general_user_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `home_address_no`
--

CREATE TABLE `home_address_no` (
  `home_address_no` int(11) NOT NULL CHECK (`home_address_no` > 0),
  `country_no` smallint(6) NOT NULL CHECK (`country_no` > 0 and `country_no` < 1000),
  `post_code` smallint(6) NOT NULL CHECK (`post_code` > 0 and `post_code` < 1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `id_card`
--

CREATE TABLE `id_card` (
  `id_card_no` int(11) NOT NULL,
  `name` varchar(10) NOT NULL,
  `home_address_no` int(11) NOT NULL CHECK (`home_address_no` > 0),
  `birth_date` datetime NOT NULL,
  `registration_date` datetime NOT NULL,
  `id_no` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `id_card`
--

INSERT INTO `id_card` (`id_card_no`, `name`, `home_address_no`, `birth_date`, `registration_date`, `id_no`) VALUES
(1, '2', 3, '2024-04-29 05:58:42', '2024-04-29 05:58:42', 4),
(201, '211', 221, '2024-04-29 05:57:51', '2024-04-29 05:57:51', 231),
(1001, '1002', 1003, '2024-04-29 06:07:27', '2024-04-29 06:07:27', 1004),
(1101, '1102', 1103, '2024-04-29 06:09:28', '2024-04-29 06:09:28', 1104),
(1201, '1211', 1221, '2024-04-20 05:51:34', '2024-04-20 05:51:34', 1231);

--
-- Triggers `id_card`
--
DELIMITER $$
CREATE TRIGGER `data_validation` BEFORE INSERT ON `id_card` FOR EACH ROW BEGIN 
IF  

NEW.birth_date > NOW() OR  

NEW.registration_date > NOW() OR 

NEW.birth_date > NEW.registration_date 

 

THEN 
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid data!'; 
END IF; 
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `login_info`
--

CREATE TABLE `login_info` (
  `login_info_no` smallint(6) NOT NULL CHECK (`login_info_no` > 0),
  `login_success_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `login_fail_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `login_info_nos`
--

CREATE TABLE `login_info_nos` (
  `login_info_nos` smallint(6) NOT NULL CHECK (`login_info_nos` > 0),
  `login_info_no` smallint(6) NOT NULL CHECK (`login_info_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `logout_info`
--

CREATE TABLE `logout_info` (
  `logout_info_no` smallint(6) NOT NULL CHECK (`logout_info_no` > 0),
  `logout_success_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `logout_fail_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `log_info`
--

CREATE TABLE `log_info` (
  `log_info_no` smallint(6) NOT NULL,
  `login_info_no` smallint(6) NOT NULL CHECK (`login_info_no` > 0),
  `logout_info_no` smallint(6) NOT NULL CHECK (`logout_info_no` > 0),
  `verification_info_no` smallint(6) NOT NULL CHECK (`verification_info_no` > 0),
  `operation_info_no` smallint(6) NOT NULL CHECK (`operation_info_no` > 0),
  `advanced_operation_info_no` smallint(6) NOT NULL CHECK (`advanced_operation_info_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `log_info_list`
--

CREATE TABLE `log_info_list` (
  `user_no` smallint(6) NOT NULL CHECK (`user_no` > 0),
  `log_info_nos` smallint(6) NOT NULL CHECK (`log_info_nos` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `operation_info`
--

CREATE TABLE `operation_info` (
  `operation_info_no` smallint(6) NOT NULL CHECK (`operation_info_no` > 0),
  `operation_info_type_no` smallint(6) NOT NULL CHECK (`operation_info_type_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `operation_info_mapping`
--

CREATE TABLE `operation_info_mapping` (
  `operation_info_type_no` smallint(6) NOT NULL CHECK (`operation_info_type_no` > 0),
  `operation_info_type_name` varchar(20) NOT NULL CHECK (`operation_info_type_name` <> convert(char(0x10) using utf8mb4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_paying`
--

CREATE TABLE `prev_tax_paying` (
  `prev_tax_paying_status_no` int(11) NOT NULL CHECK (`prev_tax_paying_status_no` > 0),
  `prev_tax_paying_type_no` int(11) NOT NULL CHECK (`prev_tax_paying_type_no` > 0),
  `prev_tax_paying_number` int(11) NOT NULL CHECK (`prev_tax_paying_number` > 0),
  `prev_tax_penality_number` int(11) NOT NULL CHECK (`prev_tax_penality_number` > 0),
  `prev_tax_penality_paid_number` int(11) NOT NULL CHECK (`prev_tax_penality_paid_number` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_paying_list`
--

CREATE TABLE `prev_tax_paying_list` (
  `prev_tax_paying_status_nos` int(11) NOT NULL CHECK (`prev_tax_paying_status_nos` > 0),
  `prev_tax_paying_status_no` int(11) NOT NULL CHECK (`prev_tax_paying_status_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_rebating`
--

CREATE TABLE `prev_tax_rebating` (
  `prev_tax_rebating_status_no` int(11) NOT NULL CHECK (`prev_tax_rebating_status_no` > 0),
  `prev_tax_rebating_year_diff` int(11) NOT NULL CHECK (`prev_tax_rebating_year_diff` > 0 and `prev_tax_rebating_year_diff` <= 3),
  `prev_tax_rebating_number` int(11) NOT NULL CHECK (`prev_tax_rebating_number` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_rebating_list`
--

CREATE TABLE `prev_tax_rebating_list` (
  `prev_tax_rebating_status_nos` int(11) NOT NULL CHECK (`prev_tax_rebating_status_nos` > 0),
  `prev_tax_rebating_status_no` int(11) NOT NULL CHECK (`prev_tax_rebating_status_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `taxpayer`
--

CREATE TABLE `taxpayer` (
  `taxpayer_no` int(11) NOT NULL CHECK (`taxpayer_no` > 0),
  `form_no` int(11) NOT NULL CHECK (`form_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `try_login`
--

CREATE TABLE `try_login` (
  `try_login_times` int(11) NOT NULL,
  `prev_try_login_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `prev_success_login_time` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `verification_info`
--

CREATE TABLE `verification_info` (
  `verification_info_no` smallint(6) NOT NULL CHECK (`verification_info_no` > 0),
  `verification_info_type_no` smallint(6) NOT NULL CHECK (`verification_info_type_no` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `verification_operation_info_mapping`
--

CREATE TABLE `verification_operation_info_mapping` (
  `verification_info_type_no` smallint(6) NOT NULL CHECK (`verification_info_type_no` > 0),
  `verification_info_type_name` varchar(20) NOT NULL CHECK (`verification_info_type_name` <> convert(char(0x10) using utf8mb4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account_list`
--
ALTER TABLE `account_list`
  ADD UNIQUE KEY `account_no` (`account_no`),
  ADD UNIQUE KEY `account_name` (`account_name`),
  ADD UNIQUE KEY `password_name` (`password_name`),
  ADD UNIQUE KEY `email_name` (`email_name`);

--
-- Indexes for table `administrator`
--
ALTER TABLE `administrator`
  ADD UNIQUE KEY `administrator_no` (`administrator_no`);

--
-- Indexes for table `advanced_operation_info`
--
ALTER TABLE `advanced_operation_info`
  ADD UNIQUE KEY `advanced_operation_info_no` (`advanced_operation_info_no`);

--
-- Indexes for table `advanced_operation_info_mapping`
--
ALTER TABLE `advanced_operation_info_mapping`
  ADD UNIQUE KEY `advanced_operation_info_type_no` (`advanced_operation_info_type_no`);

--
-- Indexes for table `earning_type_mapping`
--
ALTER TABLE `earning_type_mapping`
  ADD UNIQUE KEY `earning_type_no` (`earning_type_no`),
  ADD UNIQUE KEY `earning_type_name` (`earning_type_name`);

--
-- Indexes for table `form`
--
ALTER TABLE `form`
  ADD UNIQUE KEY `form_no` (`form_no`),
  ADD UNIQUE KEY `earning_no` (`earning_nos`);

--
-- Indexes for table `general_user`
--
ALTER TABLE `general_user`
  ADD UNIQUE KEY `general_user_no` (`general_user_no`);

--
-- Indexes for table `home_address_no`
--
ALTER TABLE `home_address_no`
  ADD UNIQUE KEY `home_address_no` (`home_address_no`),
  ADD UNIQUE KEY `country_no` (`country_no`),
  ADD UNIQUE KEY `post_code` (`post_code`);

--
-- Indexes for table `id_card`
--
ALTER TABLE `id_card`
  ADD UNIQUE KEY `id_card_no` (`id_card_no`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `home_address_no` (`home_address_no`),
  ADD UNIQUE KEY `birth_date` (`birth_date`),
  ADD UNIQUE KEY `registration_date` (`registration_date`),
  ADD UNIQUE KEY `id_no` (`id_no`);

--
-- Indexes for table `login_info`
--
ALTER TABLE `login_info`
  ADD UNIQUE KEY `login_info_no` (`login_info_no`);

--
-- Indexes for table `login_info_nos`
--
ALTER TABLE `login_info_nos`
  ADD UNIQUE KEY `login_info_nos` (`login_info_nos`),
  ADD UNIQUE KEY `login_info_no` (`login_info_no`);

--
-- Indexes for table `logout_info`
--
ALTER TABLE `logout_info`
  ADD UNIQUE KEY `logout_info_no` (`logout_info_no`);

--
-- Indexes for table `log_info_list`
--
ALTER TABLE `log_info_list`
  ADD UNIQUE KEY `user_no` (`user_no`);

--
-- Indexes for table `operation_info`
--
ALTER TABLE `operation_info`
  ADD UNIQUE KEY `operation_info_no` (`operation_info_no`);

--
-- Indexes for table `operation_info_mapping`
--
ALTER TABLE `operation_info_mapping`
  ADD UNIQUE KEY `operation_info_type_no` (`operation_info_type_no`);

--
-- Indexes for table `prev_tax_rebating_list`
--
ALTER TABLE `prev_tax_rebating_list`
  ADD UNIQUE KEY `prev_tax_rebating_status_no` (`prev_tax_rebating_status_no`);

--
-- Indexes for table `taxpayer`
--
ALTER TABLE `taxpayer`
  ADD UNIQUE KEY `taxpayer_no` (`taxpayer_no`),
  ADD UNIQUE KEY `form_no` (`form_no`);

--
-- Indexes for table `try_login`
--
ALTER TABLE `try_login`
  ADD UNIQUE KEY `try_login_times` (`try_login_times`);

--
-- Indexes for table `verification_info`
--
ALTER TABLE `verification_info`
  ADD UNIQUE KEY `verification_info_no` (`verification_info_no`);

--
-- Indexes for table `verification_operation_info_mapping`
--
ALTER TABLE `verification_operation_info_mapping`
  ADD UNIQUE KEY `verification_info_type_no` (`verification_info_type_no`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `id_card`
--
ALTER TABLE `id_card`
  MODIFY `id_card_no` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1202;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
