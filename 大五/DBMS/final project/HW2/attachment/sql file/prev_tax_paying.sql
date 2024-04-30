-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb1
-- Generation Time: Apr 30, 2024 at 01:12 AM
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
-- Table structure for table `prev_tax_paying`
--

CREATE TABLE `prev_tax_paying` (
  `prev_tax_paying_status_no` int(11) NOT NULL CHECK (`prev_tax_paying_status_no` > 0),
  `prev_tax_paying_type_no` int(11) NOT NULL CHECK (`prev_tax_paying_type_no` > 0),
  `prev_tax_paying_number` int(11) NOT NULL CHECK (`prev_tax_paying_number` > 0),
  `prev_tax_penality_number` int(11) NOT NULL CHECK (`prev_tax_penality_number` > 0),
  `prev_tax_penality_paid_number` int(11) NOT NULL CHECK (`prev_tax_penality_paid_number` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
