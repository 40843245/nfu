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

--
-- Indexes for dumped tables
--

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
