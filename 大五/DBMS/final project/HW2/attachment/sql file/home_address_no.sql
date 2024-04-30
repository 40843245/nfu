-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb1
-- Generation Time: Apr 30, 2024 at 01:11 AM
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
-- Table structure for table `home_address_no`
--

CREATE TABLE `home_address_no` (
  `home_address_no` int(11) NOT NULL CHECK (`home_address_no` > 0),
  `country_no` smallint(6) NOT NULL CHECK (`country_no` > 0 and `country_no` < 1000),
  `post_code` smallint(6) NOT NULL CHECK (`post_code` > 0 and `post_code` < 1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `home_address_no`
--
ALTER TABLE `home_address_no`
  ADD UNIQUE KEY `home_address_no` (`home_address_no`),
  ADD UNIQUE KEY `country_no` (`country_no`),
  ADD UNIQUE KEY `post_code` (`post_code`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
