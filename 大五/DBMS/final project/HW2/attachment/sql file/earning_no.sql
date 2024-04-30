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
-- Table structure for table `earning_no`
--

CREATE TABLE `earning_no` (
  `earning_no` int(11) NOT NULL CHECK (`earning_no` > 0),
  `earning_type_no` int(11) NOT NULL CHECK (`earning_type_no` > 0),
  `income_number` int(11) NOT NULL CHECK (`income_number` >= 0),
  `income_deduction_type_no` int(11) NOT NULL CHECK (`income_deduction_type_no` > 0),
  `income_deduction_number` int(11) NOT NULL CHECK (`income_deduction_number` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
