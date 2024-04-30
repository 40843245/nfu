-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb1
-- Generation Time: Apr 30, 2024 at 01:10 AM
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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
