-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: mariadb1
-- Generation Time: May 13, 2024 at 05:53 AM
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

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`%` PROCEDURE `ADD_FIELD` (IN `table_name1` TEXT, IN `view_name1` TEXT, IN `field_name1` TEXT, IN `new_field_name1` TEXT)  DETERMINISTIC BEGIN
	SET @select_cmd = 
    	CONCAT_WS('',
                  ' SELECT ',
                  ' * ',
                  ' , ',
                  CONVERT(field_name1,CHAR),
                  ' AS ',
                  CONVERT(new_field_name1,CHAR),
                  ' FROM ',
                  CONVERT(table_name1,CHAR)
                  );
                  
                 
	SET @view_cmd = 
    	CONCAT_WS('',
                  'CREATE OR REPLACE VIEW ',
                  CONVERT(view_name1,CHAR),
                  ' AS '
                 );
     
    SET @all_cmd = 
    	CONCAT_WS('',
                  @view_cmd,
                  '(',
                  @select_cmd,
                  ' ) ',
                  ' ; '
                 );
                 
    PREPARE stmt FROM @all_cmd;
    EXECUTE stmt;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `COUNT_DOWN` (IN `counter` INT, IN `event_name` TEXT CHARSET utf8mb4, IN `timezone_hour` INT, IN `task` TEXT CHARSET utf8mb4, IN `on_completion_preserve` BOOLEAN)  DETERMINISTIC BEGIN
	SET @prefix =
    CONCAT_WS('',
             'CREATE OR REPLACE EVENT ',
             event_name,
             ' ON SCHEDULE '
    );
    
    SET @schedule = 
    CONCAT_WS('',
            ' AT CURRENT_TIMESTAMP + INTERVAL ',
            timezone_hour,
            ' HOUR ',
            ' + INTERVAL ',
            counter,
            ' SECOND '
    );
    
   	SET @on_completion_preserve_str = ' ON COMPLETION PRESERVE ';

    SET @do_task = 
    CONCAT_WS('',
              ' DO ',
              task
    );
    
    SET @sql = '';
    
    SET @sql = 
    CONCAT_WS('',
              @sql,
              @prefix,
              @schedule
    );
    
    IF
    	on_completion_preserve = 1
    THEN
        SET @sql = 
        CONCAT_WS('',
                  @sql,
                  @on_completion_preserve_str
        );
    END IF;
    
    SET @sql = 
    CONCAT_WS('',
              @sql,
              @do_task
    );
    
    /* print message @sql. */
    SELECT @sql;
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `DELETE_LOGIN_DATA` (IN `user_no` INT)  DETERMINISTIC BEGIN
	DELETE FROM `tax`.`login_info` 
    WHERE
    	`tax`.`login_info`.`user_no` = user_no;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `FAILED_TRYLOGIN` (IN `user_no` TEXT CHARSET utf8mb4)  DETERMINISTIC BEGIN
	DECLARE max_consecutive_failed_login INT DEFAULT -1;
    DECLARE try_login_times INT DEFAULT -1;
    DECLARE number_of_record INT DEFAULT -1;
    DECLARE updated_val INT DEFAULT -1;
    
    IF 
    	`user_no` <= 0 
    THEN 
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'invalid argument user_no in routine FAILED_TRYLOGIN.';
	END IF;
    
    SET @has_locked = `tax`.`HAS_LOCKED`(@user_no);
    
    IF 
    	@has_locked = 0
    THEN
        SELECT COUNT(`try_login`.`try_login_times`),
        `try_login`.`try_login_times`
            INTO @number_of_record , @try_login_times 
            FROM `try_login`
            WHERE
                `try_login`.`user_no` = `user_no`
            LIMIT 1;

        SELECT 
            `lock_login_setting`.`max_consecutive_failed_login` 
            INTO @max_consecutive_failed_login
            FROM `lock_login_setting`
            LIMIT 1;

        SET @updated_val = 
            INC_CLAMP(@try_login_times,
                       1,
                       0,
                       @max_consecutive_failed_login
                       );
        UPDATE `try_login` 
            SET `try_login`.`try_login_times` = @updated_val 
            WHERE
                `try_login`.`user_no` = `user_no`
        ;
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `FAILED_VERIFICATION` (IN `user_no` INT)  DETERMINISTIC BEGIN
	DECLARE failed_verification_time INT DEFAULT -1;
    DECLARE max_failed_verification INT DEFAULT -1;
    DECLARE failed_verification_step INT DEFAULT -1;
    DECLARE updated_val INT DEFAULT -1;
    
	SELECT `tax`.`failed_verification`.`failed_verification_time` 
    	INTO @failed_verification_time
        FROM `tax`.`failed_verification`
        WHERE
        	`tax`.`failed_verification`.`user_no` = `user_no`;
         
    IF 
    	@failed_verification_time > 0
    THEN 
    	SELECT `tax`.`failed_verification_setting`.`max_failed_verification`,
        `tax`.`failed_verification_setting`.`failed_verification_step`
        INTO @max_failed_verification,
        	@failed_verification_step
        FROM `tax`.`failed_verification_setting`
        LIMIT 1;
        
        SET @updated_val =            	
        	INC_CLAMP(@failed_verification_time,
                          @failed_verification_step,
                          0,
                          @max_failed_verification
                         );
        UPDATE `tax`.`failed_verification`
        	SET `tax`.`failed_verification`.`failed_verification_time` = 
@updated_val
            WHERE
            	`tax`.`failed_verification`.`user_no` = `user_no`;
        
    ELSE
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'NO found with specified user_no in the routine FAILED_VERIFICATION.';
    END IF;
    
    IF 
    	@updated_val >= @max_failed_verification
    THEN
    	CALL `tax`.`FAILED_TRYLOGIN`(`user_no`);
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `INSERT_LOG_DATA` (IN `user_no` INT, IN `id` INT)  DETERMINISTIC BEGIN
    DECLARE msg VARCHAR(255);
    
    SET @log_name = `tax`.`GET_LOG_NAME`(`id`);
    SET @priv_no = `tax`.`GET_PRIV_NO`(`user_no`);
    SET @priv_name = `tax`.`GET_PRIV_NAME`(@priv_no);
    SET @now = CONVERT(NOW(),CHAR);
    
    
    SET @has_error = 0;
    SET @error_msg = '';
   	
    IF
    	@log_name != '' AND
        @priv_name != ''
    THEN 
    	SET @has_error = 0;
    ELSE 
    	SET @has_error = 1;
        SET @error_msg = 'At least one of these keys does NOT have a value or valid value.';
        SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = @error_msg;
    END IF;
    
    IF 
    	@has_error = 0
    THEN
    	SET @msg = 
        	CONVERT(CONCAT_WS('',
                      'The user no ',
                      CONVERT(`user_no`,CHAR),
                      ' (',
                      CONVERT(@priv_no,CHAR),
                      ',',
                      @priv_name,
                      ') ',
                      ' completes an operation about ',
                      @log_name,
                      ' at ',
            		  CONVERT(@now,CHAR),
                      '.',
                      ';'
                     ),CHAR);
    ELSE 
    	SET @msg = 
        	CONCAT_WS('',
                      'The user no',
                      CONVERT(`user_no`,CHAR),
                      ' gets an error,',
                      ' the error message:',
        			  @error_msg,
                      ';'
                     );
    END IF;
    
	INSERT INTO `tax`.`log_asText`
    (`tax`.`log_asText`.`user_no`,
     `tax`.`log_asText`.`last_written`,
     `tax`.`log_asText`.`log_text`) 
    VALUES
    ( CONVERT(`user_no`,CHAR),
      CONVERT(@now,CHAR),
   	@msg
    );
    
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `LOCK_LOGIN` (IN `user_no` INT)  DETERMINISTIC BEGIN
	DECLARE max_consecutive_failed_login_locking_time INT DEFAULT -10;
    SELECT `tax`.`lock_login_setting`.`max_consecutive_failed_login_locking_time` 
	INTO @max_consecutive_failed_login_locking_time
    FROM `tax`.`lock_login_setting`
    LIMIT 1;
    
    IF 
    	@max_consecutive_failed_login_locking_time >= 1
    THEN
    	UPDATE `tax`.`try_login` 
        	SET `tax`.`try_login`.`can_login_id` = 2,
            	`tax`.`try_login`.`try_login_times` = 0
            WHERE 
            	`tax`.`try_login`.`user_no` = `user_no`
            ;
        SET @event_name = 'event_name1';
        SET @on_completion_preserve = 1 ;
        SET @task = 
        	CONCAT_WS('',
                      ' UPDATE `tax`.`try_login` 
        					SET `tax`.`try_login`.`can_login_id` = 1
            				WHERE 
            					`tax`.`try_login`.`user_no` = ',
                      	CONVERT(`user_no`,CHAR),
            				' ;'
                     );
		CALL `tax`.`COUNT_DOWN`(
            @max_consecutive_failed_login_locking_time,
            @event_name,
            0, /* don't have to offset although timezone in Taiwan is GTM+8 However, it is evaluated through timezone in London. */
            -- 8, /* timezone in Taiwan is GMT+8 .*/
            @task,
            @on_completion_preserve
        );
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `MOVE_COLUMN` ()  DETERMINISTIC BEGIN
	DECLARE number_of_record INT DEFAULT -1;
    DECLARE bignum INT DEFAULT -1;
    DECLARE key_str TEXT;
    DECLARE len INT DEFAULT -1;
    DECLARE original_json_array JSON;
    DECLARE temp_json_array JSON;
    DECLARE new_json_array JSON;
    
    SELECT COUNT(*) 
    	INTO @number_of_record 
        FROM `tax`.`view_2`;
	
    IF 
    	@number_of_record <= 0 
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'Either the table does NOT exist or the table consists of NULL, empty elems.';
    END IF;
    
    SELECT JSON_ARRAYAGG(`lower_bound`) 
    	INTO @original_json_array
        FROM `tax`.`view_2`;
    SELECT JSON_REMOVE(@original_json_array,'$[0]')
    	INTO @temp_json_array;
     
    SET @len = JSON_LENGTH(@temp_json_array);
    
    SET @key_str = 
    	CONCAT_WS('',
                  '$[',
                  CONVERT(@len,CHAR),
                  ']'
                 );
                 
    SET @bignum = 1000000;
    SET @new_json_array =
    	JSON_ARRAY_INSERT(@temp_json_array,
					   CONVERT(@key_str,CHAR),
                       @bignum
                      );
                     
    SELECT @new_json_array;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `MOVE_COLUMN_old` (IN `table_name1` TEXT, IN `view_name1` TEXT, IN `field_name1` TEXT, IN `y_offset` INT, IN `y_dir` INT, IN `data_to_be_filled` JSON)  DETERMINISTIC BEGIN
	DECLARE number_of_record INT DEFAULT -1;
    DECLARE number_of_record_needed INT DEFAULT -1;
    DECLARE original_json_array JSON;
    -- DECLARE new_json_array JSON;
    
    SET @need_to_move_column = 1;
    
    SET @cmd_declare =
    	'DECLARE number_of_record INT DEFAULT -1;';
        
    SET @cmd = 
    	CONCAT_WS('',
    			  ' SELECT COUNT(',
                  '`',
                  CONVERT(field_name1,CHAR),
                  '`',
                  ')',
    			  ' INTO ',
                  '?',
    			  ' FROM ',
                  ' `tax`',
                  '.',
                  '`',
                  CONVERT(table_name1,CHAR),
                  '`',
                  ';'
                  );
                  
      SELECT @cmd;
                  
    PREPARE stmt FROM @cmd;             
    EXECUTE stmt USING @number_of_record;
    DEALLOCATE PREPARE stmt;
    
    IF 
    	@number_of_record <= 0 
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'Either the table does NOT exist or the table consists of NULL, empty elems.';
    END IF;
   
    IF 
    	y_offset <= 0 OR
      	y_offset >= @number_of_record
    THEN
    	SET @need_to_move_column = 0;
    END IF;
    
    IF 
    	y_dir = 0 
    THEN
    	SET @need_to_move_column = 0;
    END IF;
    
   	SET @number_of_record_needed = @number_of_record - y_offset;
    
    IF 
    	JSON_LENGTH(data_to_be_filled) != @number_of_record_needed
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'The number of data for row does NOT match the number of row minus the argument y_offset.';
   	END IF;
    
    SET @cmd_2 = 
    	CONCAT_WS('',
                  'SELECT ',
                  'JSON_ARRAYAGG(',
                  CONVERT(field_name1,CHAR),
                  ')',
                  ' INTO ',
                  CONVERT(@original_json_array,CHAR),
                  ' FROM ',
                  CONVERT(table_name1,CHAR),
                  ' ; '
                 );
                 
    PREPARE stmt FROM @cmd_2;             
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
                  
                 
                  
    
	
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `RESET_TRYLOGIN_DATA` (IN `user_no` INT)  DETERMINISTIC BEGIN
	UPDATE `tax`.`try_login`
    	SET `tax`.`try_login`.`try_login_times` = 0
        WHERE 
        	 `tax`.`try_login`.`user_no` = `user_no`
        ;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `SET_PASSWORD` (IN `user_no` INT, IN `pasword_name` TEXT)  DETERMINISTIC BEGIN
    DECLARE old_password_name TEXT DEFAULT NULL;
    
    SELECT `tax`.`account_list`.`password_name`
    	INTO @old_password_name
        FROM `tax`.`account_list`
        WHERE 
        	`tax`.`account_list`.`user_no` = `user_no`
        LIMIT 1;
    
    IF 
    	@old_password_name = NULL
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'The password can NOT found. It may be caused by missing user.';
    END IF;
    
    UPDATE `tax`.`account_list`
    	SET `tax`.`account_list`.`password_name` = @old_password_name
        WHERE 
        	`tax`.`account_list`.`user_no` = `user_no`
        ;        	
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `SORT_TABLE` (IN `view_name1` TEXT, IN `table_name1` TEXT, IN `sort_flag` INT, IN `sort_by` TEXT)  DETERMINISTIC BEGIN
	SET @select_cmd = 
    	CONCAT_WS('',
                  ' SELECT ',
                  ' * ',
                  ' FROM ',
                  CONVERT(table_name1,CHAR)
                  );
                 
	SET @view_cmd = 
    	CONCAT_WS('',
                  'CREATE OR REPLACE VIEW ',
                  CONVERT(view_name1,CHAR),
                  ' AS '
                 );
     
    IF  
    	sort_flag = 1
    THEN
    	SET @select_cmd = 
        	CONCAT_WS('',
                      @select_cmd,
                      ' ORDER BY ',
                      CONVERT(sort_by,CHAR)
                     );
   	ELSEIF
    	sort_flag = 2
    THEN
    	SET @select_cmd = 
        	CONCAT_WS('',
                      @select_cmd,
                      ' ORDER BY ',
                      CONVERT(sort_by,CHAR),
                      ' DESC ' 
                     );
    END IF;
    
    SET @all_cmd = 
    	CONCAT_WS('',
                  @view_cmd,
                  '(',
                  @select_cmd,
                  ' ) ',
                  ' ; '
                 );
                 
    PREPARE stmt FROM @all_cmd;
    EXECUTE stmt;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `SUCCESS_LOGIN` (IN `user_no` INT)  DETERMINISTIC BEGIN
	UPDATE `tax`.`try_login`
    	SET 
        `tax`.`try_login`.`try_login_times` = 0,
        `tax`.`try_login`.`prev_try_login_time` = NOW(),
        `tax`.`try_login`.`prev_success_login_time` = NOW()
        WHERE 
        	`tax`.`try_login`.`user_no` = `user_no` 
        ;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `SUCCESS_LOGOUT` (IN `user_no` INT)  DETERMINISTIC BEGIN
	CALL DELETE_LOGIN_DATA(user_no);
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `SUCCESS_TRYLOGIN` (IN `user_no` INT)  DETERMINISTIC BEGIN
	SET @has_locked = `tax`.`HAS_LOCKED`(user_no);

    IF 
    	@has_locked = 0
    THEN 
    	CALL `tax`.`SUCCESS_LOGIN`(user_no);
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `TRYINSERT_LOG_DATA` (IN `user_no` INT, IN `id` INT)  DETERMINISTIC BEGIN
	DECLARE number_of_record INT DEFAULT -1;
    SELECT COUNT(`tax`.`log_asText`.`user_no`)
    	INTO @number_of_record
    	FROM `tax`.`log_asText`
        WHERE 
        	 `tax`.`log_asText`.`user_no` = `user_no`
        ;
    
    IF 
    	@number_of_record >= 1
    THEN
    	CALL UPDATE_LOG_DATA(user_no,id);
       
     ELSE 
     	CALL INSERT_LOG_DATA(user_no,id);
       
     END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `TRYLOGIN` (IN `account_name` TEXT CHARSET utf8mb4, IN `password_name` TEXT CHARSET utf8mb4)  DETERMINISTIC BEGIN
	DECLARE user_no INT DEFAULT -1;
    DECLARE flag INT DEFAULT -1;
	SET @account_matched = 
    	ACCOUNTMATCHED(account_name,password_name);
    IF
    	@account_matched = 1 
    THEN
    	SET @flag = 0;
        SELECT `account_list`.`user_no` 
            INTO @user_no 
            FROM `account_list` 
            WHERE
            	( `account_list`.`account_name` = account_name 
                 AND 
                 `account_list`.`password_name` = password_name 
                );
             
    ELSE 
    	SET @flag = 1 ;
    	SIGNAL SQLSTATE  '45000' 
        	SET MESSAGE_TEXT = 'login failed. Either input account, or password(, or both) are NOT matched.';
         CALL `tax`.`FAILED_TRYLOGIN`(account_name);
    END IF;
    
    IF 
    	@flag = 0 AND
        @user_no <= 0 
    THEN 
        SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'Can NOT find the responding user no that is a positive integer.';
    ELSE
     	SET @flag = 1;
        -- CALL `SUCCESS_TRYLOGIN`(@user_no);
    END IF;   
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `UPDATE_COLUMN` (IN `table_name1` TEXT, IN `field_name1` TEXT, IN `json` JSON)  DETERMINISTIC BEGIN
	DECLARE number_of_record INT DEFAULT -1;
    
    SET @sql =
    'SELECT COUNT(*) INTO ? FROM ? ; ';
    
    PREPARE stmt FROM @sql;
    
    EXECUTE stmt USING @number_of_record,`table_name1`;
    
    SELECT @number_of_record;
    
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `UPDATE_LOGIN_DATA` (IN `user_no` INT, IN `login_status_id` INT)  DETERMINISTIC BEGIN
	UPDATE `tax`.`login_info`
    	SET 
        	`tax`.`login_info`.`login_status_id` = login_status_id,
            `tax`.`login_info`.`login_datetime` = NOW()
        WHERE 
        	`tax`.`login_info`.`user_no` = user_no;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `UPDATE_LOG_DATA` (IN `user_no` INT, IN `id` INT)  DETERMINISTIC BEGIN
    DECLARE msg VARCHAR(255);
    DECLARE original_msg VARCHAR(255);
    DECLARE new_msg VARCHAR(255);
    
    SET @log_name = `tax`.`GET_LOG_NAME`(`user_no`);
    SET @priv_no = `tax`.`GET_PRIV_NO`(`user_no`);
    SET @priv_name = `tax`.`GET_PRIV_NAME`(@priv_no);
    SET @now = CONVERT(NOW(),CHAR);
    
    
    SET @has_error = 0;
    SET @error_msg = '';
   	
    IF
    	@log_name != '' AND
        @priv_name != ''
    THEN 
    	SET @has_error = 0;
    ELSE 
    	SET @has_error = 1;
        SET @error_msg = 'At least one of these keys does NOT have a value or valid value.';
        SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = @error_msg;
    END IF;
    
    IF 
    	@has_error = 0
    THEN
    	SET @msg = 
        	CONVERT(CONCAT_WS('',
                      'The user no ',
                      CONVERT(`user_no`,CHAR),
                      ' (',
                      CONVERT(@priv_no,CHAR),
                      ',',
                      @priv_name,
                      ') ',
                      ' completes an operation about ',
                      @log_name,
                      ' at ',
            		  CONVERT(@now,CHAR),
                      '.',
                      ';'
                     ),CHAR);
    ELSE 
    	SET @msg = 
        	CONCAT_WS('',
                      'The user no',
                      CONVERT(`user_no`,CHAR),
                      ' gets an error,',
                      ' the error message:',
        			  @error_msg,
                      ';'
                     );
    END IF;
    
    SELECT `tax`.`log_asText`.`log_text` 
    	INTO @original_msg
        FROM `tax`.`log_asText`
        WHERE
        	`tax`.`log_asText`.`user_no` = `user_no`
        LIMIT 1;
    
    SET @new_msg = 
    	CONCAT_WS('',
                 @original_text,
                 ' ',
                 @msg
                 );
	UPDATE `tax`.`log_asText`
    	SET
     		`tax`.`log_asText`.`last_written` = @now,
     		`tax`.`log_asText`.`log_text` = @new_msg
        WHERE 
        	`tax`.`log_asText`.`user_no` = `user_no`
        ;    
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`%` FUNCTION `ACCOUNTMATCHED` (`account_name` TEXT CHARSET utf8mb4, `password_name` TEXT CHARSET utf8mb4) RETURNS TINYINT(1)  BEGIN
	DECLARE ret BOOLEAN DEFAULT FALSE;
    DECLARE number_of_record INT DEFAULT FALSE;
    SELECT COUNT(*) 
    	INTO @number_of_record
    	FROM `account_list` 
        WHERE 
        	( STRCMP(`account_name`,`account_list`.`account_name`) = 0 AND STRCMP(`password_name`,`account_list`.`password_name`) = 0 );    
     IF 
        @number_of_record > 0 
     THEN
        SET @ret = 1;
     ELSE
        SET @ret = 0;
     END IF;
     
     RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `CALC_TAX_NET` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE tax_net INT DEFAULT 0;
    SELECT SUM(GREATEST(`income_number`-`income_deduction_number`,0))
    	INTO @tax_net
    	FROM `tax`.`earning_no`
    	WHERE `tax`.`earning_no`.`user_no` = `user_no`
        ;
    RETURN @tax_net;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `CALC_TAX_TOTAL` (`tax_net` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @lower_bound = 0 ;
    SET @temp_net = tax_net;
    SET @temp_rate = 0;
   
    SET @i = 0;
    SET @need_to_continue = 1;
    SET @number_of_record = 0;
    SET @tax_total = 0;
    
    SELECT COUNT(*) 
    	INTO @number_of_record
        FROM `tax`.`tax_rate_range`;
    
    SET @tax_total = 0;
    SET @i = 1;
    WHILE @need_to_continue = 1
    DO
    	SELECT `tax`.`tax_rate_range`.`lower_bound`,
         		`tax`.`tax_rate_range`.`rate`
        	INTO @lower_bound,
            	@temp_rate
            FROM `tax`.`tax_rate_range`
            WHERE 
            	`tax`.`tax_rate_range`.`level_no` = @i
            LIMIT 1;
        
        SET @tax_total = CONVERT((@tax_total + GREATEST( ( @temp_net - @lower_bound ) , 0 ) * @temp_rate),INT);
		SET @temp_net = GREATEST((@temp_net - @lower_bound),0);
        
        IF 
            @i > @number_of_record OR
            @temp_net <= 0 
        THEN
            SET @need_to_continue = 0;
        END IF;
  		SET @i = @i + 1;                         
	END WHILE;
                               
    RETURN @tax_total;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `CAN_SET_PASSWORD` (`who` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE is_login INT DEFAULT -1;
    DECLARE priv_no INT DEFAULT -1;
    
    SET @is_login = `tax`.`IS_LOGIN`(`who`);
    
    IF 
    	@is_login != 1
    THEN
    	RETURN 0;
    END IF;
    
    SELECT `tax`.`user_type_mapping`.`priv_no` 
    	INTO @priv_no
        FROM `tax`.`user_type_mapping`
        WHERE
        	`tax`.`user_type_mapping`.`user_no` = `who`
        LIMIT 1;
    
    IF
    	@priv_no !=2
    THEN 
    	RETURN 0;
    ELSE 
    	RETURN 1;
    END IF;
    
    
END$$

CREATE DEFINER=`root`@`%` FUNCTION `CITYNO` (`letter1` VARCHAR(1)) RETURNS INT(11) DETERMINISTIC BEGIN 
	DECLARE ret INT DEFAULT -1;
    
    SELECT `city_mapping`.`city_no` 
    	INTO @ret 
        FROM `city_mapping`
        WHERE `city_mapping`.`letter` = letter1
       	;
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `CLAMP` (`lowerlimit` INT, `argv1` INT, `upperlimit` INT) RETURNS INT(11) DETERMINISTIC BEGIN 
	DECLARE ret INT DEFAULT 0;
    SET @res_1 = argv1;
    
    SET @isbetween_res_1 = 
    	ISBETWEEN(lowerlimit,@res_1,upperlimit);
    IF  
    	@isbetween_res_1 = 0
    THEN 
    	SET @ret = @res_1;
    ELSEIF 
    	@isbetween_res_1 = 1
    THEN
    	SET @ret = upperlimit;
    ELSE
    	SET @ret = lowerlimit;
    END IF;
    
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `DATETIMECMP` (`datetime1` DATETIME, `datetime2` DATETIME) RETURNS INT(11)  BEGIN
--  SET @timediff_res_1 = TIMEDIFF(`datetime1`,`datetime2`);
    SET @timediff_res_1 = 
    	CONVERT(TIMEDIFF(`datetime1`,`datetime2`),INT);

    IF 
    	/* check time1 2 time2 */
    	@timediff_res_1 > 0
    THEN 
    	RETURN 1;
    ELSEIF 
    	/* check time1 < time2 */
    	@timediff_res_1 < 0
    THEN 
    
    	RETURN -1;
    ELSE 
     	/* Otherwise i.e. time1 == time2 */
    	RETURN 0;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_ITEMIZED_DEDUCTION_TOTAL` (`form_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @itemized_deduction_total = 0;
    SET @arr = 0 ;
    SELECT `tax`.`itemized_deduction`.`value` 
    	INTO @arr 
        FROM `tax`.`itemized_deduction`
        WHERE 
        	`tax`.`itemized_deduction`.`form_no`= `form_no`;
    
    SET @itemized_deduction_total =
    	`tax`.`JSON_ARRAY_SUM`(@arr);
        
    RETURN @itemized_deduction_total;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_LOCKED` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE can_login_id INT DEFAULT -1;
    SELECT `tax`.`try_login`.`can_login_id` 
    	INTO @can_login_id
        FROM `tax`.`try_login`
        WHERE
        	`tax`.`try_login`.`user_no` = `user_no`
        LIMIT 1;
    
	RETURN @can_login_id;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_LOG_NAME` (`id` INT) RETURNS CHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
	DECLARE ret VARCHAR(255);
    SELECT `tax`.`log_mapping`.`name` 
    	INTO @ret
    	FROM `tax`.`log_mapping`
        WHERE 
        	`tax`.`log_mapping`.`id` = `id`
        LIMIT 1;
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_PRIV_NAME` (`priv_no` INT) RETURNS CHAR(255) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE ret CHAR;
    SELECT `tax`.`priv_mapping`.`priv_name` 
    	INTO @ret
    	FROM `tax`.`priv_mapping`
        WHERE 
        	`tax`.`priv_mapping`.`priv_no` = `priv_no`
        LIMIT 1;
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_PRIV_NO` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE ret INT;
    SELECT `tax`.`user_type_mapping`.`priv_no` 
    	INTO @ret
    	FROM `tax`.`user_type_mapping`
        WHERE 
        	`tax`.`user_type_mapping`.`user_no` = `user_no`
        LIMIT 1;
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_STD_DEDUCTION` (`spouse_status` BOOLEAN) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @spouse_id = spouse_status + 1 ; 
    SET @standard_deduction = 0;
    SELECT `tax`.`standard_deduction_mapping`.`value`
    	INTO @standard_deduction
        FROM `tax`.`standard_deduction_mapping`
        WHERE 
        	`tax`.`standard_deduction_mapping`.`type_id` = @spouse_id;
    
    RETURN @standard_deduction;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_STD_DEDUCTION_TOTAL` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @spouse_status = 0;
    SET @get_std_deduction = 0;
    
    SELECT `tax`.`form`.`spouse_status`
    	INTO @spouse_status
        FROM (`tax`.`form` INNER JOIN `tax`.`user` ON
              `tax`.`form`.`form_no` = `tax`.`user`.`form_no`)
        WHERE
        	`tax`.`user`.`user_no` = `user_no`;
     
    SET @get_std_deduction = 
    	GET_STD_DEDUCTION(@spouse_status);
    
    RETURN @get_std_deduction;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `GET_TOTAL_EARNING` (`earning_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @income_numbers = 0 ;
    SET @income_deduction_numbers = 0;
    SET @i = 0;
    SET @n1 = 0 ;
    SET @n2 = 0;
    SET @total_earning = 0;
    
	SELECT `tax`.`earning_no`.`income_number` ,
    	   `tax`.`earning_no`.`income_deduction_number`
    	INTO @income_numbers,
        	 @income_deduction_numbers
        FROM `tax`.`earning_no`
        WHERE 
        	`tax`.`earning_no`.`earning_no` = `earning_no`;
   
   SET @n1 = JSON_LENGTH(@income_numbers);
   SET @n2 = JSON_LENGTH(@income_deduction_numbers);
   
   IF @n1 != @n2
   THEN
   		SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'The length of income_numbers and income_deduction_numbers are different.';
   ELSE 
   		SET @total_earning = 0;
   		SET @i=1;
        
        WHILE 
        	@i <= @n1
        DO
        	SET @key = 
            	CONCAT_WS('',
                         '$[',
                          CONVERT(@i,CHAR),
                          ']'
                         );
                         
            SET @key1 = @key;
            SET @key2 = @key;
            
        	SET @elem1 = JSON_EXTRACT(@income_numbers,@key1);
            SET @elem2 =
            JSON_EXTRACT(@income_deduction_numbers,@key2);
            
            SET @elem1 = IFNULL(@elem1,0);
            SET @elem2 = IFNULL(@elem2,0);
            
            SET @total_earning = 
            	@total_earning + @elem1 - @elem2 ;
        END WHILE;
   END IF;
   
   RETURN @total_earning;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `HAS_LOCKED` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @get_locked = `tax`.`GET_LOCKED`(@user_no);
    SET @ok = 1;
       
    IF 
    	@get_locked = 2
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'the user with user_no has been locked at present. Please try again later.';
    ELSEIF
    	@get_locked = 3
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'the login status with user_no is unknown at present. Please try again later.';
    ELSEIF
    	@get_locked = -1
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'unknown reason that can not found the login_status with given user_no ';
    ELSE 
    	SET @ok = 0;
    END IF;
    
    RETURN @ok;
    
END$$

CREATE DEFINER=`root`@`%` FUNCTION `INCITY` (`letter1` VARCHAR(1) CHARSET utf8mb4) RETURNS INT(1)  BEGIN
	DECLARE ret INT DEFAULT -1;
    DECLARE num_of_record INT DEFAULT -1;
    
	SELECT COUNT(*) 
    	INTO @num_of_record 
    	FROM `city_mapping` 
        WHERE `city_mapping`.`letter` = letter1
        ;
      
    IF 
    	@num_of_record > 0 
    THEN
     	SET @ret = 1;
    ELSE
    	SET @ret = 0;
    END IF;
    
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `INC_CLAMP` (`argv1` INT, `argv2` INT, `lowerlimit` INT, `upperlimit` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @res_1 = argv1 + argv2;
    SET @ret = CLAMP(lowerlimit,@res_1,upperlimit);
    RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `INGENDER` (`gender_id` TEXT CHARSET utf8mb4) RETURNS TINYINT(1) DETERMINISTIC BEGIN
	DECLARE number_of_record INT DEFAULT -1 ; 
    SELECT COUNT(*) 
    	INTO  @number_of_record
    	FROM `gender_mapping` 
        WHERE 
        	gender_id = `gender_mapping`.`id`;
    IF 
    	@number_of_record > 0 
    THEN
    	RETURN TRUE;
    ELSE
    	RETURN FALSE;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `ISBETWEEN` (`lowerlimit` INT, `target` INT, `upperlimit` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	IF 
    	lowerlimit > upperlimit
    THEN 
    	SIGNAL SQLSTATE '45000' 
        	SET	MESSAGE_TEXT = 'one or more arguments that those value are invalid. The value of argv3 must greater than argv1.';
	END IF;
    
    IF
    	lowerlimit <= target AND
        target <= upperlimit
    THEN
    	RETURN 0;
    ELSEIF 
    	target >= upperlimit
    THEN 
    	RETURN 1;
    ELSE 
    	RETURN -1;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `ISBETWEEN_DOUBLE` (`lowerlimit` DOUBLE, `target` DOUBLE, `upperlimit` DOUBLE) RETURNS INT(11)  BEGIN
	IF 
    	lowerlimit > upperlimit
    THEN 
    	SIGNAL SQLSTATE '45000' 
        	SET	MESSAGE_TEXT = 'one or more arguments that those value are invalid. The value of argv3 must greater than argv1.';
	END IF;
    
    IF
    	lowerlimit <= target AND
        target <= upperlimit
    THEN
    	RETURN 0;
    ELSEIF 
    	target >= upperlimit
    THEN 
    	RETURN 1;
    ELSE 
    	RETURN -1;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `IS_LOGIN` (`user_no` INT) RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE is_login INT DEFAULT -1;
    
    SELECT `tax`.`try_login`.`is_login`
    	INTO @is_login
       	FROM `tax`.`try_login`
        WHERE
        	`tax`.`try_login`.`user_no` = `user_no`
        LIMIT 1;
    
    IF 
    	@is_login = -1
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'can not find the login status of the user. It may be caused by the user is missing. ';
    END IF;
    
    RETURN @is_login;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `JSON_ARRAY_SUM` (`json` JSON) RETURNS INT(11) DETERMINISTIC BEGIN
	SET @i = 0;
    SET @temp_elem = 0;
    SET @temp_key_str = '';
    SET @json = 0 ;
    SET @len = 0;
    SET @total = 0;
	
    SET @json = json;
    SET @len = JSON_LENGTH(@json);
    SET @total = 0;
    SET @i = 0;
    
    WHILE 
    	@i < @len 
    DO
    	SET @temp_key_str = 
        	CONCAT_WS('',
                      '$[',
                      CONVERT(@i,CHAR),
                      ']'
                     );
    	SET @temp_elem = JSON_EXTRACT(@json,@temp_key_str);
        SET @total = @total + CONVERT(@temp_elem,INT);
        SET @i = @i + 1;
    END WHILE;
    RETURN @total;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `LEFTPART` (`str` TEXT CHARSET utf8mb4, `delim` TEXT CHARSET utf8mb4) RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE first_ocurrence INT DEFAULT -1 ;
    DECLARE ret TEXT DEFAULT "ret";
    DECLARE delim_1 TEXT DEFAULT delim;
    DECLARE str_1 TEXT DEFAULT str;
    SET @first_ocurrence = LOCATE(delim,str);
    IF @first_ocurrence > 0 
    THEN
    	SET @ret = CONVERT(LEFT(str,@first_ocurrence - 1) USING 'utf8mb4');
    ELSE
    	SET @ret = CONVERT(str USING 'utf8mb4');
    END IF;
    RETURN @ret; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `LIKEMATCHED` (`expr` TEXT, `reg_str` TEXT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
DECLARE ret BOOLEAN DEFAULT FALSE;

SET @temp = IFNULL(expr LIKE reg_str,"");
IF 
	STRCMP(@temp,"") = 0 OR
    @temp = 0
THEN
	SET @ret = FALSE;
ELSE 
	SET @ret = TRUE;
END IF;
	RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `REACH_MAX_FAILED_LOGIN` (`user_no` INT) RETURNS SMALLINT(6) DETERMINISTIC BEGIN
	DECLARE try_login_times	INT DEFAULT -1;
    DECLARE max_consecutive_failed_login INT DEFAULT -1;
    
    SELECT `tax`.`try_login`.`try_login_times` 
    	INTO @try_login_times	
        FROM `tax`.`try_login`
        WHERE
        	`tax`.`try_login`.`user_no` = `user_no`;
            
    IF 
    	NOT(@try_login_times > 0)
   	THEN
    	RETURN -1;
	END IF;
    
    SELECT `tax`.`lock_login_setting`.`max_consecutive_failed_login`
    	INTO @max_consecutive_failed_login
        FROM `tax`.`lock_login_setting`
        LIMIT 1;
        	
    IF 
    	NOT(@max_consecutive_failed_login > 0 )
    THEN 
    	RETURN -1;
    END IF;
    
    IF 
    	@try_login_times >= @max_consecutive_failed_login
    THEN 
    	RETURN 1;
    ELSE 
    	RETURN 0;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `REDUCE_TAX` (`user_no` INT, `tax_total` INT) RETURNS INT(11)  BEGIN
	SET @unreturned_deduction_total = 0;
    SET @tax_after_reduction = 0;
    SET @standard_deduction_total = 0 ;
    
    SET @arr = 0;
    SET @len = 0;
    SET @i = 0;
    
    SET @tax_after_reduction = tax_total;
    
    SET @standard_deduction_total =
    	`tax`.`GET_STD_DEDUCTION`(`user_no`) ;
   
    SELECT `tax`.`prev_tax_unreturned`.`prev_tax_rebating_value`
    	INTO @arr
        FROM `tax`.`prev_tax_unreturned`
        WHERE 
        	( `tax`.`prev_tax_unreturned`.`user_no` = `user_no` AND
            `tax`.`prev_tax_unreturned`.`prev_tax_rebating_year_diff`  <= 3
            );
    
    SET @unreturned_deduction_total = `tax`.`JSON_ARRAY_SUM`(@arr);
    
    
    RETURN @tax_after_reduction;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `REGEXPMATCHED` (`expr` TEXT CHARSET utf8mb4, `reg_str` TEXT CHARSET utf8mb4) RETURNS TINYINT(1) DETERMINISTIC BEGIN
    DECLARE ret BOOLEAN DEFAULT FALSE;
    SET @temp = IFNULL(expr REGEXP reg_str,"");
    IF 
        STRCMP(@temp,"") = 0 OR
        @temp = 0 
    THEN
        SET @ret = FALSE;
    ELSE 
        SET @ret = TRUE;
    END IF;
        RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `RIGHTPART` (`str` TEXT CHARSET utf8mb4, `delim` TEXT CHARSET utf8mb4) RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
    DECLARE first_ocurrence INT DEFAULT -1 ;
    DECLARE ret TEXT DEFAULT "ret";
    DECLARE delim_1 TEXT DEFAULT delim;
    
    SET @len = LENGTH(str);
    SET @first_ocurrence = LOCATE(delim,str);
    IF  @len - @first_ocurrence > 0 
    THEN
    	SET @ret = CONVERT(RIGHT(str,  @len - ( @first_ocurrence - 1) )  USING 'utf8mb4');
    ELSE
    	SET @ret = CONVERT(str USING 'utf8mb4');
    END IF;
    RETURN @ret; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `SUMPRODUCT` (`argv1` JSON, `argv2` JSON) RETURNS INT(11)  BEGIN
	DECLARE total INT DEFAULT 0 ;
    DECLARE t1 INT DEFAULT 0 ;
    DECLARE t2 INT DEFAULT 0 ;
   
	SET @weights = argv1;
    SET @number = argv2;
    SET @weights_length = JSON_LENGTH(@weights);
    SET @argv1_length = JSON_LENGTH(@number);
    
    SET @i= 0 ;
    SET @total = 0;
    IF @weights_length = @argv1_length
    THEN 
    	WHILE @i <= @argv1_length - 1
        DO
        	SET @str = 
            		CONCAT_WS('',
                             '$[',
                              CONVERT(@i,CHAR),
                              ']'
                             );
        	SET @t1 = JSON_EXTRACT(@weights,@str);
            SET @t2 = JSON_EXTRACT(@number,@str);
            SET @total = @total + @t1 * @t2 ; 
        	
            SET @i = @i + 1;
        END WHILE;
    ELSE
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'The length of argv1 and weights_length are NOT same.';
    END IF;
    RETURN @total;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `TEXTHandler` (`str` TEXT, `msg` TEXT) RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
DECLARE ret TEXT;

IF msg IS NULL
THEN 
SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = "2th argument is NULL which is invalid.";
END IF;
	SET @ret = IFNULL(str,'');
	RETURN @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `TEXT_TO_JSON` (`letter` TEXT) RETURNS TEXT CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC BEGIN
	SET @letter_length = CHAR_LENGTH(IFNULL(`letter`,''));
    IF 
    	 @letter_length <= 0 
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'Invalid data! Can not convert text that is either empty or NUL to JSON data.';
    END IF;
   
    SET @json = '['; 
    SET @i = 0 ;
    WHILE @i <= @letter_length - 2
    DO 
    	SET @c = MID(`letter`,@i+1 ,1);
        SET @json = 
        	CONCAT_WS('',
                      @json,
                      @c,
                      ' ,'          
                     );
        SET @i = @i + 1;
    END WHILE;
    
    SET @c = MID(`letter`,@i+1 ,1);
    SET @json = 
        	CONCAT_WS('',
                      @json,
                      @c,
                      ' ]'
                     );

    RETURN @json;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDACCOUNT` (`new_account_name` TEXT CHARSET utf8mb4, `new_password_name` TEXT CHARSET utf8mb4, `new_email_account` TEXT CHARSET utf8mb4) RETURNS TINYINT(1) DETERMINISTIC SQL SECURITY INVOKER BEGIN

	/*
    reg exp:
    	<email_account> := 
    	<alpha_digit>+@(<private_email_account_endingPart>|
    	<NFU_email_account_endingPart>); 
	*/
    
    /*
    definition 
    */
    DECLARE lower_bound SMALLINT;
    DECLARE upper_bound SMALLINT;
    DECLARE beginPart TEXT;

    /*
    definition of some common, basic re(regular expression)
    */
    -- digit 
    DECLARE digit TEXT;
    -- uppercase letter
    DECLARE uppercase TEXT;
    -- lowercase letter
    DECLARE lowercase TEXT;
    -- letter (i.e.uppercase and lowercase letter)
    DECLARE alpha TEXT;
    -- alnum (i.e. uppercase, lowercase letter and digit)
    DECLARE alpha_digit TEXT;
  	-- commerial_at symbol '@'
    DECLARE commerial_at TEXT;
    -- period symbol '.'
    DECLARE period TEXT;
    
    -- ending part(part after '@') of private email should be
    DECLARE private_email_account_endingPart TEXT;
    -- ending part(part after '@') of school email should be
    DECLARE NFU_email_account_endingPart TEXT;
    -- begin part(part before '@') of any email should be
    DECLARE email_beginPart TEXT;
    

    DECLARE email_account TEXT;
    DECLARE password_name TEXT;
    DECLARE account_name TEXT;

	-- returned value
    DECLARE ret BOOLEAN DEFAULT FALSE;
    
    /*
    set value of variables.
    */
    SET @lower_bound = 8;
    SET @upper_bound = 20;
    
    SET @digit = "[[:digit:]]";
    SET @uppercase = "[[:upper:]]";
    SET @lowercase = "[[:lower:]]";
    SET @alpha = "[[:alpha:]]";
    SET @alpha_digit = "[[:alnum:]]";
    SET @period = "[[.period.]]";
    SET @commerial_at = "[[.@.]]";
    
    --  reg exp to represent format of general email.
    SET @private_email_account_endingPart = 
    	CONCAT_WS("",
                  "gmail",
                  @period,
                  "com"
                 );
               
    --  reg exp to represent format of nfu email.
    SET @NFU_email_account_endingPart = 
    	CONCAT_WS("",
                  "gm",
                  @period,
                  "nfu",
                  @period,
                  "edu",
                  @period,
                  "tw"
                 );
                 
    --  all text of new_email_account before '@'.
    SET @beginPart = 	
     	IFNULL(LEFTPART(new_email_account,"@"),"");                                               
    --  reg exp to represent format first part of an email.
    SET @email_beginPart = 
    	CONCAT_WS("",
                  @alpha_digit,
                  "+"
                 );
                 
	--  reg exp to represent format of an email.
    SET @email_account = 
    	CONCAT_WS("",
                  @email_beginPart,
                  @commerial_at,
                  "(",                
                  @private_email_account_endingPart,
                  "|",
                  @NFU_email_account_endingPart,
                  ")"
                 );
    SET @account_name = 
    	CONCAT_WS("",
        	      @alpha_digit,
            	  "{",
              	  CONVERT(@lower_bound USING utf8mb4),
              	  ",",
              	  CONVERT(@upper_bound USING utf8mb4),
              	  "}"
             	);
             
    SET @password_name = 
    	CONCAT_WS("",
        	      @alpha_digit,
            	  "{",
              	  CONVERT(@lower_bound USING utf8mb4),
              	  ",",
              	  CONVERT(@upper_bound USING utf8mb4),
              	  "}"
             	);
    
    SET @beginPart_regexp = 
    	CONCAT_WS("",
        	     "%",
            	 @beginPart,
             	"%"
             	);
             
    SET @reg_res_1 = 
  		tax.REGEXPMATCHED(new_account_name,@account_name);
    SET @reg_res_2 = 						
    	tax.REGEXPMATCHED(new_password_name,@password_name);

        
    SET @reg_res_3 = 						
    	tax.LIKEMATCHED(new_account_name,@beginPart_regexp);
    SET @reg_res_4 = 						
    	tax.LIKEMATCHED(new_password_name,@beginPart_regexp);
        
    SET @strcmp_res_1 = 
    	STRCMP(new_account_name,@beginPart);
    SET @strcmp_res_2 = 
    	STRCMP(new_password_name,@beginPart);
        
    /* 
    check input is valid. 
    (i.e. satisfy all of the following rules. )
    */
    IF
    /* 
    check input account name is valid. 
    (i.e. satisfy the rule of account name. )
    */
    ( 
        @reg_res_1 = 1 AND 
     	( 
            STRCMP(@beginPart,"") = 0 OR 	
            ( @reg_res_3 != 1 AND @strcmp_res_1 != 0 ) 
        ) 
    )
    AND
    /* 
    check input password name is valid.
    (i.e. satisfy the rule of password name. )
    */
    (
        @reg_res_2 = 1  AND 
     	(
            STRCMP(@beginPart,"") = 0 OR 	
            ( @reg_res_4 != 1 AND @strcmp_res_1 != 0 ) 
        )
    )
    THEN
        SET @ret = TRUE;
    ELSE
		SET @ret = FALSE;
    END IF;
    /* if you want to return value @ret.*/
    RETURN @ret;
    /* if you want to print a table with value @ret. */
    -- SELECT @ret;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDIDCARD` (`id_card_no` TEXT CHARSET utf8mb4, `new_birth_date` DATETIME, `new_registration_date` DATETIME) RETURNS TINYINT(1)  BEGIN
	IF 
    	VALIDIDCARDNO(`id_card_no`) != TRUE OR
        VALIDIDCARDDATE(`new_birth_date`,`new_registration_date`) != TRUE
    THEN
    	RETURN FALSE;
    ELSE 
    	RETURN TRUE;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDIDCARDDATE` (`new_birth_date` DATETIME, `new_registration_date` DATETIME) RETURNS TINYINT(1)  BEGIN 
    IF  
        `new_birth_date` > NOW() OR  
        `new_registration_date` > NOW() OR 
        `new_birth_date` > `new_registration_date` 
    THEN 
        RETURN FALSE;
    ELSE 
    	RETURN TRUE;
    END IF; 
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDIDCARDNO` (`id_card_no` TEXT CHARSET utf8mb4) RETURNS TINYINT(1) DETERMINISTIC BEGIN
	SET @reg_res_1 = VALIDIDCARDNO_REGEXP(`id_card_no`);
    IF 
    	@reg_res_1 != 1
    THEN
    	RETURN FALSE;
    END IF;
    
    SET @second_letter = MID(`id_card_no`,2,1);
    SET @in_gender = INGENDER(@second_letter);
    
    IF 
    	@in_gender != 1
    THEN
    	RETURN FALSE;
    END IF;   
    
    SET @first_letter = LEFT(`id_card_no`,1);
    SET @first_letter_no = CITYNO(@first_letter);
    IF 
    	@first_letter_no = -1
    THEN
    	RETURN FALSE;
    END IF;
    
    SET @new_letters = 
    	CONCAT_WS('',
                 CONVERT(@first_letter_no DIV 10, CHAR),
                 CONVERT(@first_letter_no MOD 10, CHAR),
            	 CONVERT(MID(`id_card_no`,2,9),CHAR)
                 );
    SET @weights = JSON_ARRAY(1, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1);
    SET @numbers = TEXT_TO_JSON(@new_letters);
    
    SET @sumproduct_res = SUMPRODUCT(@weights,@numbers);
	
    IF 
    	@sumproduct_res MOD 10 = 0
    THEN 
    	RETURN TRUE;
    ELSE 
    	RETURN FALSE;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDIDCARDNO_REGEXP` (`id_card_no` TEXT CHARSET utf8mb4) RETURNS TINYINT(6)  BEGIN

    DECLARE ret TINYINT DEFAULT 0;

    SET @reg_str="[[:upper:]][[:digit:]]{9,9}";

    SET @reg_res_1 = REGEXPMATCHED(id_card_no,@reg_str); 

    return @reg_res_1;

END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDRATIO` (`ratio` FLOAT) RETURNS TINYINT(1) DETERMINISTIC BEGIN
	SET @is_between = `tax`.`ISBETWEEN_DOUBLE`(0.0,ratio,1.0);
    IF 
    	@is_between = 0
    THEN
    	RETURN TRUE;
    ELSE
    	RETURN FALSE;
    END IF;
END$$

CREATE DEFINER=`root`@`%` FUNCTION `VALIDUSERNAME` (`username` TEXT) RETURNS INT(11) DETERMINISTIC BEGIN
	
    SET @alpha_digit = "[[:alnum:]]";
	SET @lower_bound = 8;
    SET @uppeer_bound = 20;
    SET @reg_exp = 
    	CONCAT_WS('',
                 @alpha_digit,
                 '{',
                  CONVERT(@lower_bound,CHAR),
                  ',',
                  CONVERT(@uppeer_bound,CHAR),
                  '}'
                 );
    SET @regexp_res_1 = REGEXPMATCHED(username,@reg_exp);
    RETURN @regexp_res_1;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `account_list`
--

CREATE TABLE `account_list` (
  `user_no` int(11) NOT NULL,
  `account_name` text NOT NULL,
  `password_name` text NOT NULL,
  `email_name` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account_list`
--

INSERT INTO `account_list` (`user_no`, `account_name`, `password_name`, `email_name`) VALUES
(1, 'user40843245', 'password40843245', '40843245@gm.nfu.edu.tw');

-- --------------------------------------------------------

--
-- Table structure for table `city_mapping`
--

CREATE TABLE `city_mapping` (
  `letter` varchar(1) NOT NULL,
  `city` varchar(10) NOT NULL,
  `city_no` smallint(6) NOT NULL CHECK (`city_no` >= 10 and `city_no` <= 35)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `city_mapping`
--

INSERT INTO `city_mapping` (`letter`, `city`, `city_no`) VALUES
('A', '台北市', 10),
('B', '台中市', 11),
('C', '基隆市', 12),
('D', '台南市', 13),
('E', '高雄市', 14),
('F', '新北市', 15),
('G', '宜蘭縣', 16),
('H', '桃園市', 17),
('I', '嘉義市', 34),
('J', '新竹縣', 18),
('K', '苗栗縣', 19),
('L', '台中縣', 20),
('M', '南投縣', 21),
('N', '彰化縣', 22),
('O', '新竹市', 35),
('P', '雲林縣', 23),
('Q', '嘉義縣', 24),
('R', '台南縣', 25),
('S', '高雄縣', 26),
('T', '屏東縣', 27),
('U', '花蓮縣', 28),
('V', '台東縣', 29),
('W', '金門縣', 32),
('X', '澎湖縣', 30),
('Y', '陽明山管理局', 31),
('Z', '連江縣', 33);

-- --------------------------------------------------------

--
-- Table structure for table `city_unused_mapping`
--

CREATE TABLE `city_unused_mapping` (
  `letter` varchar(1) NOT NULL,
  `original_city` varchar(10) NOT NULL,
  `new_city` varchar(10) NOT NULL,
  `new_city_no` smallint(6) NOT NULL CHECK (`new_city_no` >= 10 and `new_city_no` <= 35)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `city_unused_mapping`
--

INSERT INTO `city_unused_mapping` (`letter`, `original_city`, `new_city`, `new_city_no`) VALUES
('L', '台中縣', '台中市', 20),
('R', '台南縣', '台南市', 25),
('S', '高雄縣', '高雄市', 26),
('Y', '陽明山管理局', '台北市', 31);

-- --------------------------------------------------------

--
-- Table structure for table `earning_no`
--

CREATE TABLE `earning_no` (
  `form_no` int(11) NOT NULL,
  `type_id` int(11) NOT NULL DEFAULT 1,
  `income_number` int(11) NOT NULL,
  `income_deduction_type_no` int(11) NOT NULL DEFAULT 1,
  `income_deduction_number` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `earning_type_mapping`
--

CREATE TABLE `earning_type_mapping` (
  `id` int(1) NOT NULL,
  `name` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `earning_type_mapping`
--

INSERT INTO `earning_type_mapping` (`id`, `name`) VALUES
(1, 'salary earning'),
(2, 'rent earning'),
(3, 'yield earning'),
(4, 'interest earning'),
(5, 'operating earning'),
(6, 'working earning'),
(7, 'assets trading earning'),
(8, 'reward trading'),
(9, 'retirement earning'),
(10, 'other earning');

-- --------------------------------------------------------

--
-- Table structure for table `failed_verification`
--

CREATE TABLE `failed_verification` (
  `user_no` int(11) NOT NULL,
  `failed_verification_time` smallint(6) NOT NULL CHECK (`failed_verification_time` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `failed_verification_setting`
--

CREATE TABLE `failed_verification_setting` (
  `max_failed_verification` int(11) NOT NULL CHECK (`max_failed_verification` >= 3 and `max_failed_verification` <= 5),
  `number_of_verification` smallint(6) NOT NULL CHECK (`number_of_verification` >= 0 and `number_of_verification` <= 5),
  `failed_verification_step` smallint(6) NOT NULL CHECK (`failed_verification_step` >= 1 and `failed_verification_step` <= 2)
) ;

--
-- Dumping data for table `failed_verification_setting`
--

INSERT INTO `failed_verification_setting` (`max_failed_verification`, `number_of_verification`, `failed_verification_step`) VALUES
(5, 0, 2);

-- --------------------------------------------------------

--
-- Table structure for table `form`
--

CREATE TABLE `form` (
  `form_no` int(11) NOT NULL CHECK (`form_no` > 0),
  `spouse_status` tinyint(1) NOT NULL,
  `total_earning` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `form`
--

INSERT INTO `form` (`form_no`, `spouse_status`, `total_earning`) VALUES
(1, 0, 0);

--
-- Triggers `form`
--
DELIMITER $$
CREATE TRIGGER `valid_form_no_trigger` BEFORE INSERT ON `form` FOR EACH ROW BEGIN
	IF 
    	NEW.`form_no` < 0 
    THEN 
    	SIGNAL SQLSTATE '45000'
        	SET MESSAGE_TEXT = 'Invalid form no.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `form_info_mapping`
--

CREATE TABLE `form_info_mapping` (
  `id` int(1) NOT NULL,
  `name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `form_info_mapping`
--

INSERT INTO `form_info_mapping` (`id`, `name`) VALUES
(1, 'fill form'),
(2, 'import form'),
(3, 'export form'),
(4, 'calculate tax'),
(6, 'export tax');

-- --------------------------------------------------------

--
-- Table structure for table `gender_mapping`
--

CREATE TABLE `gender_mapping` (
  `id` int(1) NOT NULL,
  `name` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `gender_mapping`
--

INSERT INTO `gender_mapping` (`id`, `name`) VALUES
(1, 'male'),
(2, 'female');

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
  `form_no` int(11) NOT NULL,
  `id_card_no` varchar(10) NOT NULL,
  `name` varchar(10) NOT NULL,
  `home_address_no` int(11) NOT NULL CHECK (`home_address_no` > 0),
  `birth_date` datetime NOT NULL,
  `registration_date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `id_card`
--
DELIMITER $$
CREATE TRIGGER `id_card_info_validation_trigger` BEFORE INSERT ON `id_card` FOR EACH ROW BEGIN 
    SET @res_1 = 
    	VALIDIDCARD(
            `NEW`.`id_card_no`,
            `NEW`.`birth_date`,
            `NEW`.`registration_date`
        );
    IF  
		@res_1 != TRUE
    THEN 
    	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid data!'; 
    END IF; 
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `itemized_deduction`
--

CREATE TABLE `itemized_deduction` (
  `form_no` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `itemized_deduction`
--

INSERT INTO `itemized_deduction` (`form_no`, `id`, `value`) VALUES
(1, 2, 1000);

-- --------------------------------------------------------

--
-- Table structure for table `itemized_deduction_mapping`
--

CREATE TABLE `itemized_deduction_mapping` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `itemized_deduction_mapping`
--

INSERT INTO `itemized_deduction_mapping` (`id`, `name`) VALUES
(1, 'special deduction for salary'),
(2, 'special deduction for disabled'),
(3, 'special deduction for kindergartan'),
(4, 'special deduction for school fee'),
(5, 'special deduction for saving and investment'),
(6, 'special deduction for LTC');

-- --------------------------------------------------------

--
-- Table structure for table `lock_login_setting`
--

CREATE TABLE `lock_login_setting` (
  `max_consecutive_failed_login` bigint(20) NOT NULL CHECK (`max_consecutive_failed_login` >= 0),
  `max_consecutive_failed_login_locking_time` bigint(20) NOT NULL CHECK (`max_consecutive_failed_login_locking_time` >= 30 and `max_consecutive_failed_login_locking_time` <= 86400)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lock_login_setting`
--

INSERT INTO `lock_login_setting` (`max_consecutive_failed_login`, `max_consecutive_failed_login_locking_time`) VALUES
(5, 60);

-- --------------------------------------------------------

--
-- Table structure for table `log_asText`
--

CREATE TABLE `log_asText` (
  `user_no` int(11) NOT NULL,
  `opeartion_type_id` int(1) NOT NULL,
  `operation_status_id` int(1) NOT NULL,
  `last_written` datetime NOT NULL,
  `log_text` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `log_mapping`
--

CREATE TABLE `log_mapping` (
  `id` int(1) NOT NULL,
  `name` text NOT NULL,
  `priv_no` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `log_mapping`
--

INSERT INTO `log_mapping` (`id`, `name`, `priv_no`) VALUES
(3, 'tax', 2),
(4, 'login', 2),
(5, 'logout', 2),
(6, 'verification', 2),
(8, 'change passowrd', 3);

-- --------------------------------------------------------

--
-- Table structure for table `operation_mapping`
--

CREATE TABLE `operation_mapping` (
  `no` int(1) NOT NULL,
  `status` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `operation_mapping`
--

INSERT INTO `operation_mapping` (`no`, `status`) VALUES
(2, 'fail'),
(1, 'success'),
(3, 'unknown');

-- --------------------------------------------------------

--
-- Table structure for table `penality_id_mapping`
--

CREATE TABLE `penality_id_mapping` (
  `id` int(1) NOT NULL,
  `name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `penality_id_mapping`
--

INSERT INTO `penality_id_mapping` (`id`, `name`) VALUES
(1, '滯納金'),
(2, '怠報金'),
(3, '滯延金'),
(4, '一般罰金');

-- --------------------------------------------------------

--
-- Table structure for table `postal_code_mapping`
--

CREATE TABLE `postal_code_mapping` (
  `city` varchar(3) NOT NULL,
  `area` varchar(5) NOT NULL,
  `postal_code` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `postal_code_mapping`
--

INSERT INTO `postal_code_mapping` (`city`, `area`, `postal_code`) VALUES
('基隆市', '七堵區', 206),
('澎湖縣', '七美鄉', 883),
('臺南市', '七股區', 724),
('屏東縣', '三地門鄉', 901),
('新北市', '三峽區', 237),
('宜蘭縣', '三星鄉', 266),
('高雄市', '三民區', 807),
('苗栗縣', '三灣鄉', 352),
('苗栗縣', '三義鄉', 367),
('新北市', '三芝區', 252),
('新北市', '三重區', 241),
('臺南市', '下營區', 735),
('臺中市', '中區', 400),
('新北市', '中和區', 235),
('嘉義縣', '中埔鄉', 606),
('桃園市', '中壢區', 320),
('南投縣', '中寮鄉', 541),
('臺北市', '中山區', 104),
('臺北市', '中正區', 100),
('臺南市', '中西區', 700),
('屏東縣', '九如鄉', 904),
('雲林縣', '二崙鄉', 649),
('彰化縣', '二林鎮', 526),
('彰化縣', '二水鄉', 530),
('新竹縣', '五峰鄉', 311),
('宜蘭縣', '五結鄉', 268),
('新北市', '五股區', 248),
('臺南市', '仁德區', 717),
('基隆市', '仁愛區', 200),
('南投縣', '仁愛鄉', 546),
('高雄市', '仁武區', 814),
('彰化縣', '伸港鄉', 509),
('屏東縣', '佳冬鄉', 931),
('臺南市', '佳里區', 722),
('屏東縣', '來義鄉', 922),
('臺北市', '信義區', 110),
('南投縣', '信義鄉', 556),
('雲林縣', '元長鄉', 655),
('屏東縣', '內埔鄉', 912),
('臺北市', '內湖區', 114),
('高雄市', '內門區', 845),
('桃園市', '八德區', 334),
('新北市', '八里區', 249),
('苗栗縣', '公館鄉', 363),
('臺南市', '六甲區', 734),
('嘉義縣', '六腳鄉', 615),
('高雄市', '六龜區', 844),
('宜蘭縣', '冬山鄉', 269),
('高雄市', '前金區', 801),
('高雄市', '前鎮區', 806),
('臺中市', '北區', 404),
('新竹縣', '北埔鄉', 314),
('臺中市', '北屯區', 406),
('臺北市', '北投區', 112),
('彰化縣', '北斗鎮', 521),
('雲林縣', '北港鎮', 651),
('連江縣', '北竿鄉', 210),
('臺南市', '北門區', 727),
('臺東縣', '卑南鄉', 954),
('花蓮縣', '卓溪鄉', 982),
('苗栗縣', '卓蘭鎮', 369),
('臺南市', '南化區', 716),
('臺中市', '南區', 402),
('臺中市', '南屯區', 408),
('屏東縣', '南州鄉', 926),
('苗栗縣', '南庄鄉', 353),
('南投縣', '南投市', 540),
('臺北市', '南港區', 115),
('宜蘭縣', '南澳鄉', 272),
('連江縣', '南竿鄉', 209),
('雲林縣', '口湖鄉', 653),
('雲林縣', '古坑鄉', 646),
('花蓮縣', '吉安鄉', 973),
('南投縣', '名間鄉', 551),
('臺中市', '后里區', 421),
('臺中市', '和平區', 424),
('彰化縣', '和美鎮', 508),
('宜蘭縣', '員山鄉', 264),
('彰化縣', '員林市', 510),
('臺南市', '善化區', 741),
('雲林縣', '四湖鄉', 654),
('南投縣', '國姓鄉', 544),
('新北市', '土城區', 236),
('雲林縣', '土庫鎮', 633),
('新北市', '坪林區', 232),
('彰化縣', '埔心鄉', 513),
('南投縣', '埔里鎮', 545),
('彰化縣', '埔鹽鄉', 516),
('彰化縣', '埤頭鄉', 523),
('臺北市', '士林區', 111),
('宜蘭縣', '壯圍鄉', 263),
('花蓮縣', '壽豐鄉', 974),
('臺中市', '外埔區', 438),
('臺南市', '大內區', 742),
('臺北市', '大同區', 103),
('宜蘭縣', '大同鄉', 267),
('桃園市', '大園區', 337),
('彰化縣', '大城鄉', 527),
('嘉義縣', '大埔鄉', 607),
('雲林縣', '大埤鄉', 631),
('臺北市', '大安區', 106),
('高雄市', '大寮區', 831),
('彰化縣', '大村鄉', 515),
('嘉義縣', '大林鎮', 622),
('高雄市', '大樹區', 840),
('臺東縣', '大武鄉', 965),
('苗栗縣', '大湖鄉', 364),
('桃園市', '大溪區', 335),
('臺中市', '大甲區', 437),
('高雄市', '大社區', 815),
('臺中市', '大肚區', 432),
('臺中市', '大里區', 412),
('臺中市', '大雅區', 428),
('嘉義縣', '太保市', 612),
('臺中市', '太平區', 411),
('臺東縣', '太麻里鄉', 963),
('臺南市', '學甲區', 726),
('臺南市', '安南區', 709),
('臺南市', '安定區', 745),
('臺南市', '安平區', 708),
('基隆市', '安樂區', 205),
('臺南市', '官田區', 720),
('宜蘭縣', '宜蘭市', 260),
('花蓮縣', '富里鄉', 983),
('新竹縣', '寶山鄉', 300),
('臺南市', '將軍區', 725),
('高雄市', '小港區', 812),
('新竹縣', '尖石鄉', 313),
('屏東縣', '屏東市', 900),
('臺南市', '山上區', 743),
('新竹縣', '峨眉鄉', 315),
('屏東縣', '崁頂鄉', 924),
('雲林縣', '崙背鄉', 637),
('高雄市', '左營區', 813),
('臺南市', '左鎮區', 713),
('嘉義縣', '布袋鎮', 625),
('新北市', '平溪區', 226),
('桃園市', '平鎮區', 324),
('臺東縣', '延平鄉', 953),
('高雄市', '彌陀區', 827),
('彰化縣', '彰化市', 500),
('臺南市', '後壁區', 731),
('苗栗縣', '後龍鎮', 356),
('桃園市', '復興區', 336),
('屏東縣', '恆春鎮', 946),
('臺東縣', '成功鎮', 961),
('臺北市', '文山區', 116),
('雲林縣', '斗六市', 640),
('雲林縣', '斗南鎮', 630),
('臺南市', '新化區', 712),
('屏東縣', '新園鄉', 932),
('花蓮縣', '新城鄉', 971),
('屏東縣', '新埤鄉', 925),
('桃園市', '新屋區', 327),
('臺南市', '新市區', 744),
('新北市', '新店區', 231),
('嘉義縣', '新港鄉', 616),
('臺南市', '新營區', 730),
('臺中市', '新社區', 426),
('新竹縣', '新竹縣', 305),
('高雄市', '新興區', 800),
('新北市', '新莊區', 242),
('新竹縣', '新豐鄉', 304),
('高雄市', '旗山區', 842),
('高雄市', '旗岡山區', 820),
('高雄市', '旗津區', 805),
('屏東縣', '春日鄉', 942),
('澎湖縣', '望安鄉', 882),
('嘉義縣', '朴子市', 613),
('高雄市', '杉林區', 846),
('臺中市', '東勢區', 423),
('雲林縣', '東勢鄉', 635),
('臺中市', '東區', 401),
('臺南市', '東山區', 733),
('連江縣', '東引鄉', 212),
('臺東縣', '東河鄉', 959),
('屏東縣', '東港鎮', 928),
('嘉義縣', '東石鄉', 614),
('臺北市', '松山區', 105),
('屏東縣', '枋寮鄉', 940),
('屏東縣', '枋山鄉', 941),
('雲林縣', '林內鄉', 643),
('新北市', '林口區', 244),
('高雄市', '林園區', 832),
('屏東縣', '林邊鄉', 927),
('臺南市', '柳營區', 736),
('桃園市', '桃園區', 330),
('高雄市', '桃源區', 848),
('嘉義縣', '梅山鄉', 603),
('高雄市', '梓官區', 826),
('臺中市', '梧棲區', 435),
('桃園市', '楊梅區', 326),
('高雄市', '楠梓區', 811),
('臺南市', '楠西區', 715),
('新北市', '樹林區', 238),
('高雄市', '橋頭區', 825),
('新竹縣', '橫山鄉', 312),
('臺南市', '歸仁區', 711),
('嘉義縣', '民雄鄉', 621),
('嘉義縣', '水上鄉', 608),
('雲林縣', '水林鄉', 652),
('南投縣', '水里鄉', 553),
('新北市', '永和區', 234),
('高雄市', '永安區', 828),
('臺南市', '永康區', 710),
('彰化縣', '永靖鄉', 512),
('新北市', '汐止區', 221),
('臺東縣', '池上鄉', 958),
('臺中市', '沙鹿區', 433),
('苗栗縣', '泰安鄉', 365),
('新北市', '泰山區', 243),
('屏東縣', '泰武鄉', 921),
('臺東縣', '海端鄉', 957),
('新北市', '淡水區', 251),
('新北市', '深坑區', 222),
('臺中市', '清水區', 436),
('高雄市', '湖內區', 829),
('新竹縣', '湖口鄉', 303),
('澎湖縣', '湖西鄉', 885),
('嘉義縣', '溪口鄉', 623),
('彰化縣', '溪州鄉', 524),
('彰化縣', '溪湖鎮', 514),
('屏東縣', '滿州鄉', 947),
('臺中市', '潭子區', 427),
('屏東縣', '潮州鎮', 920),
('金門縣', '烈嶼鄉', 894),
('新北市', '烏來區', 233),
('金門縣', '烏坵鄉', 896),
('臺中市', '烏日區', 414),
('高雄市', '燕巢區', 824),
('屏東縣', '牡丹鄉', 945),
('屏東縣', '獅子鄉', 943),
('苗栗縣', '獅潭鄉', 354),
('臺南市', '玉井區', 714),
('花蓮縣', '玉里鎮', 981),
('屏東縣', '琉球鄉', 929),
('花蓮縣', '瑞穗鄉', 978),
('新北市', '瑞芳區', 224),
('屏東縣', '瑪家鄉', 903),
('彰化縣', '田中鎮', 520),
('高雄市', '田寮區', 823),
('彰化縣', '田尾鄉', 522),
('高雄市', '甲仙區', 847),
('嘉義縣', '番路鄉', 602),
('澎湖縣', '白沙鄉', 884),
('臺南市', '白河區', 732),
('臺中市', '石岡區', 422),
('新北市', '石碇區', 223),
('新北市', '石門區', 253),
('宜蘭縣', '礁溪鄉', 262),
('彰化縣', '社頭鄉', 511),
('臺中市', '神岡區', 429),
('彰化縣', '福興鄉', 506),
('花蓮縣', '秀林鄉', 972),
('彰化縣', '秀水鄉', 504),
('新竹縣', '竹北市', 302),
('苗栗縣', '竹南鎮', 350),
('彰化縣', '竹塘鄉', 525),
('南投縣', '竹山鎮', 557),
('嘉義縣', '竹崎鄉', 604),
('新竹縣', '竹東鎮', 310),
('屏東縣', '竹田鄉', 911),
('臺東縣', '綠島鄉', 951),
('彰化縣', '線西鄉', 507),
('宜蘭縣', '羅東鎮', 265),
('高雄市', '美濃區', 843),
('嘉義縣', '義竹鄉', 624),
('臺東縣', '臺東市', 950),
('雲林縣', '臺西鄉', 636),
('新竹縣', '芎林鄉', 307),
('彰化縣', '芬園鄉', 502),
('彰化縣', '花壇鄉', 503),
('花蓮縣', '花蓮市', 970),
('彰化縣', '芳苑鄉', 528),
('苗栗縣', '苑裡鎮', 358),
('高雄市', '苓雅區', 802),
('苗栗縣', '苗栗市', 360),
('高雄市', '茂林區', 851),
('高雄市', '茄萣區', 852),
('南投縣', '草屯鎮', 542),
('連江縣', '莒光鄉', 211),
('雲林縣', '莿桐鄉', 647),
('屏東縣', '萬丹鄉', 913),
('屏東縣', '萬巒鄉', 923),
('花蓮縣', '萬榮鄉', 979),
('臺北市', '萬華區', 108),
('新北市', '萬里區', 207),
('新北市', '蘆洲區', 247),
('桃園市', '蘆竹區', 338),
('宜蘭縣', '蘇澳鎮', 270),
('臺東縣', '蘭嶼鄉', 952),
('雲林縣', '虎尾鎮', 632),
('雲林縣', '褒忠鄉', 634),
('臺中市', '西區', 403),
('臺中市', '西屯區', 407),
('澎湖縣', '西嶼鄉', 881),
('臺南市', '西港區', 723),
('苗栗縣', '西湖鄉', 368),
('雲林縣', '西螺鎮', 648),
('桃園市', '觀音區', 328),
('臺中市', '豐原區', 420),
('花蓮縣', '豐濱鄉', 977),
('新北市', '貢寮區', 228),
('高雄市', '路竹區', 821),
('屏東縣', '車城鄉', 944),
('苗栗縣', '通霄鎮', 357),
('苗栗縣', '造橋鄉', 361),
('臺東縣', '達仁鄉', 966),
('高雄市', '那瑪夏區', 849),
('屏東縣', '里港鄉', 905),
('金門縣', '金城鎮', 893),
('金門縣', '金寧鄉', 892),
('新北市', '金山區', 208),
('臺東縣', '金峰鄉', 964),
('金門縣', '金沙鎮', 890),
('金門縣', '金湖鎮', 891),
('宜蘭縣', '釣魚臺列', 290),
('苗栗縣', '銅鑼鄉', 366),
('屏東縣', '長治鄉', 908),
('臺東縣', '長濱鄉', 962),
('臺東縣', '關山鎮', 956),
('臺南市', '關廟區', 718),
('新竹縣', '關西鎮', 306),
('高雄市', '阿蓮區', 822),
('嘉義縣', '阿里山鄉', 605),
('南投縣', '集集鎮', 552),
('新北市', '雙溪區', 227),
('臺中市', '霧峰區', 413),
('屏東縣', '霧臺鄉', 902),
('苗栗縣', '頭份市', 351),
('宜蘭縣', '頭城鎮', 261),
('苗栗縣', '頭屋鄉', 362),
('澎湖縣', '馬公市', 880),
('屏東縣', '高樹鄉', 906),
('南投縣', '魚池鄉', 555),
('高雄市', '鳥松區', 833),
('高雄市', '鳳山區', 830),
('花蓮縣', '鳳林鎮', 975),
('新北市', '鶯歌區', 239),
('屏東縣', '鹽埔鄉', 907),
('高雄市', '鹽埕區', 803),
('臺南市', '鹽水區', 737),
('彰化縣', '鹿港鎮', 505),
('嘉義縣', '鹿草鄉', 611),
('南投縣', '鹿谷鄉', 558),
('臺東縣', '鹿野鄉', 955),
('屏東縣', '麟洛鄉', 909),
('雲林縣', '麥寮鄉', 638),
('臺南市', '麻豆區', 721),
('高雄市', '鼓山區', 804),
('臺中市', '龍井區', 434),
('臺南市', '龍崎區', 719),
('桃園市', '龍潭區', 325),
('桃園市', '龜山區', 333);

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_unpaid`
--

CREATE TABLE `prev_tax_unpaid` (
  `form_no` int(11) NOT NULL,
  `unpaid_no` int(11) NOT NULL,
  `unpaid` tinyint(1) NOT NULL DEFAULT 0 CHECK (`unpaid` >= 0),
  `type_id` int(11) NOT NULL CHECK (`type_id` >= 1),
  `unpaid_value` int(11) NOT NULL DEFAULT 0,
  `penality_value` int(11) NOT NULL DEFAULT 0,
  `penality_start_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prev_tax_unreturned`
--

CREATE TABLE `prev_tax_unreturned` (
  `form_no` int(11) NOT NULL,
  `prev_tax_no` int(11) NOT NULL,
  `prev_tax_rebating_year_diff` int(11) NOT NULL CHECK (`prev_tax_rebating_year_diff` > 0 and `prev_tax_rebating_year_diff` <= 3),
  `prev_tax_rebating_value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `priv_mapping`
--

CREATE TABLE `priv_mapping` (
  `priv_no` int(1) NOT NULL,
  `priv_name` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `priv_mapping`
--

INSERT INTO `priv_mapping` (`priv_no`, `priv_name`) VALUES
(1, 'guest'),
(2, 'general user'),
(3, 'administrator');

-- --------------------------------------------------------

--
-- Table structure for table `standard_deduction_mapping`
--

CREATE TABLE `standard_deduction_mapping` (
  `type_id` int(1) NOT NULL,
  `value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `standard_deduction_mapping`
--

INSERT INTO `standard_deduction_mapping` (`type_id`, `value`) VALUES
(1, 124000),
(2, 248000);

-- --------------------------------------------------------

--
-- Table structure for table `tax_rate_range`
--

CREATE TABLE `tax_rate_range` (
  `level_no` int(11) NOT NULL,
  `rate` float NOT NULL,
  `lower_bound` int(11) NOT NULL,
  `upper_bound` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tax_rate_range`
--

INSERT INTO `tax_rate_range` (`level_no`, `rate`, `lower_bound`, `upper_bound`) VALUES
(1, 0.05, 0, 590000),
(2, 0.12, 590000, 1330000),
(3, 0.2, 1330000, 2660000),
(4, 0.3, 2660000, 4980000),
(5, 0.4, 4980000, 100000000);

-- --------------------------------------------------------

--
-- Table structure for table `try_login`
--

CREATE TABLE `try_login` (
  `user_no` int(11) NOT NULL,
  `try_login_times` int(1) NOT NULL,
  `prev_try_login_time` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `prev_success_login_time` datetime NOT NULL,
  `can_login_id` tinyint(1) NOT NULL,
  `is_login` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `try_login`
--
DELIMITER $$
CREATE TRIGGER `lock_datetime_validation_trigger` BEFORE INSERT ON `try_login` FOR EACH ROW BEGIN
	DECLARE has_exception INT DEFAULT 0;
    
    SET @now_res_1 = CONVERT(NOW(),DATETIME);
    
    SET @datetimecmp_res_1 =
    	DATETIMECMP(NEW.`prev_try_login_time`,@now_res_1);
   	SET @datetimecmp_res_2 =
    	DATETIMECMP(NEW.`prev_success_login_time`,@now_res_1);
    
    IF  
   		@datetimecmp_res_1 = 1 OR 
        @datetimecmp_res_2 = 1
    THEN
    	SET @has_exception = 1;
    ELSE
        SET @has_exception = 0;
    END IF;
    
    IF 
    	@has_exception = 1
    THEN
    	SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'invalid date.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `reach_max_failed_login_trigger` AFTER UPDATE ON `try_login` FOR EACH ROW BEGIN
	SET @res_1 = `tax`.`REACH_MAX_FAILED_LOGIN`(NEW.`user_no`);
    IF 
    	@res_1 = 1
    THEN
    	CALL `tax`.`LOCK_LOGIN`(NEW.`user_no`);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `username` varchar(30) NOT NULL,
  `user_no` int(11) NOT NULL,
  `form_no` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `user`
--
DELIMITER $$
CREATE TRIGGER `valid_username_trigger` BEFORE INSERT ON `user` FOR EACH ROW BEGIN 
IF 
	/* check the input data are valid username. */
	VALIDUSERNAME(NEW.username) != 1
THEN
	/* not, so signal SQLERROR. */
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'One or more input data (includimg username) is considered to be invalid.'; 
	END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_type_mapping`
--

CREATE TABLE `user_type_mapping` (
  `user_no` int(11) NOT NULL,
  `priv_no` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_type_mapping`
--

INSERT INTO `user_type_mapping` (`user_no`, `priv_no`) VALUES
(3, 2),
(5, 2),
(9, 3);

--
-- Triggers `user_type_mapping`
--
DELIMITER $$
CREATE TRIGGER `check_priv_no_trigger` BEFORE INSERT ON `user_type_mapping` FOR EACH ROW BEGIN
	IF
    	NEW.`priv_no` NOT IN (1,2,3)
    THEN
    	SIGNAL SQLSTATE '45000'
        	SET MESSAGE_TEXT = 'ID is out of privilege number.';
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
  ADD PRIMARY KEY (`user_no`);

--
-- Indexes for table `city_mapping`
--
ALTER TABLE `city_mapping`
  ADD PRIMARY KEY (`letter`),
  ADD UNIQUE KEY `letter` (`letter`),
  ADD UNIQUE KEY `city` (`city`),
  ADD UNIQUE KEY `city_no` (`city_no`);

--
-- Indexes for table `city_unused_mapping`
--
ALTER TABLE `city_unused_mapping`
  ADD PRIMARY KEY (`letter`),
  ADD UNIQUE KEY `letter` (`letter`),
  ADD UNIQUE KEY `original_city` (`original_city`),
  ADD UNIQUE KEY `new_city` (`new_city`),
  ADD UNIQUE KEY `new_city_no` (`new_city_no`);

--
-- Indexes for table `earning_no`
--
ALTER TABLE `earning_no`
  ADD UNIQUE KEY `form_no` (`form_no`),
  ADD KEY `earning_type_id` (`type_id`);

--
-- Indexes for table `earning_type_mapping`
--
ALTER TABLE `earning_type_mapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `earning_type_no` (`id`),
  ADD UNIQUE KEY `earning_type_name` (`name`) USING HASH;

--
-- Indexes for table `failed_verification`
--
ALTER TABLE `failed_verification`
  ADD PRIMARY KEY (`user_no`),
  ADD UNIQUE KEY `failed_verification_time` (`failed_verification_time`);

--
-- Indexes for table `failed_verification_setting`
--
ALTER TABLE `failed_verification_setting`
  ADD UNIQUE KEY `max_failed_verification` (`max_failed_verification`),
  ADD UNIQUE KEY `number_of_verification` (`number_of_verification`),
  ADD UNIQUE KEY `failed_verification_step` (`failed_verification_step`);

--
-- Indexes for table `form`
--
ALTER TABLE `form`
  ADD PRIMARY KEY (`form_no`);

--
-- Indexes for table `form_info_mapping`
--
ALTER TABLE `form_info_mapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `operation_info_type_no` (`id`);

--
-- Indexes for table `gender_mapping`
--
ALTER TABLE `gender_mapping`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `home_address_no`
--
ALTER TABLE `home_address_no`
  ADD PRIMARY KEY (`post_code`),
  ADD UNIQUE KEY `home_address_no` (`home_address_no`),
  ADD UNIQUE KEY `country_no` (`country_no`),
  ADD UNIQUE KEY `post_code` (`post_code`);

--
-- Indexes for table `id_card`
--
ALTER TABLE `id_card`
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `home_address_no` (`home_address_no`),
  ADD UNIQUE KEY `birth_date` (`birth_date`),
  ADD UNIQUE KEY `registration_date` (`registration_date`);

--
-- Indexes for table `itemized_deduction`
--
ALTER TABLE `itemized_deduction`
  ADD UNIQUE KEY `user_no` (`form_no`),
  ADD KEY `itemized_deduction_id` (`id`);

--
-- Indexes for table `itemized_deduction_mapping`
--
ALTER TABLE `itemized_deduction_mapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`);

--
-- Indexes for table `lock_login_setting`
--
ALTER TABLE `lock_login_setting`
  ADD UNIQUE KEY `max_consecutive_failed_login` (`max_consecutive_failed_login`),
  ADD UNIQUE KEY `max_consecutive_failed_login_locking_time` (`max_consecutive_failed_login_locking_time`);

--
-- Indexes for table `log_asText`
--
ALTER TABLE `log_asText`
  ADD UNIQUE KEY `user_no` (`user_no`),
  ADD KEY `operation_type_id1` (`opeartion_type_id`),
  ADD KEY `operation_status_id1` (`operation_status_id`);

--
-- Indexes for table `log_mapping`
--
ALTER TABLE `log_mapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `type_id` (`id`);

--
-- Indexes for table `operation_mapping`
--
ALTER TABLE `operation_mapping`
  ADD UNIQUE KEY `logout_no` (`no`),
  ADD UNIQUE KEY `logout` (`status`);

--
-- Indexes for table `penality_id_mapping`
--
ALTER TABLE `penality_id_mapping`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `postal_code_mapping`
--
ALTER TABLE `postal_code_mapping`
  ADD UNIQUE KEY `area` (`area`),
  ADD UNIQUE KEY `postal_code` (`postal_code`);

--
-- Indexes for table `prev_tax_unpaid`
--
ALTER TABLE `prev_tax_unpaid`
  ADD PRIMARY KEY (`form_no`,`unpaid_no`),
  ADD KEY `penality_id` (`type_id`);

--
-- Indexes for table `prev_tax_unreturned`
--
ALTER TABLE `prev_tax_unreturned`
  ADD PRIMARY KEY (`form_no`,`prev_tax_no`),
  ADD KEY `prev_tax_no2` (`prev_tax_no`);

--
-- Indexes for table `priv_mapping`
--
ALTER TABLE `priv_mapping`
  ADD PRIMARY KEY (`priv_no`);

--
-- Indexes for table `standard_deduction_mapping`
--
ALTER TABLE `standard_deduction_mapping`
  ADD PRIMARY KEY (`type_id`),
  ADD UNIQUE KEY `type_id` (`type_id`);

--
-- Indexes for table `tax_rate_range`
--
ALTER TABLE `tax_rate_range`
  ADD PRIMARY KEY (`level_no`);

--
-- Indexes for table `try_login`
--
ALTER TABLE `try_login`
  ADD PRIMARY KEY (`user_no`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD UNIQUE KEY `name` (`username`),
  ADD UNIQUE KEY `form_no` (`form_no`),
  ADD KEY `user_no3` (`user_no`);

--
-- Indexes for table `user_type_mapping`
--
ALTER TABLE `user_type_mapping`
  ADD PRIMARY KEY (`user_no`),
  ADD UNIQUE KEY `no` (`user_no`),
  ADD KEY `priv_no` (`priv_no`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `earning_no`
--
ALTER TABLE `earning_no`
  ADD CONSTRAINT `earning_type_id` FOREIGN KEY (`type_id`) REFERENCES `earning_type_mapping` (`id`),
  ADD CONSTRAINT `form_no5` FOREIGN KEY (`form_no`) REFERENCES `form` (`form_no`);

--
-- Constraints for table `failed_verification`
--
ALTER TABLE `failed_verification`
  ADD CONSTRAINT `user_no2` FOREIGN KEY (`user_no`) REFERENCES `account_list` (`user_no`);

--
-- Constraints for table `home_address_no`
--
ALTER TABLE `home_address_no`
  ADD CONSTRAINT `post_code` FOREIGN KEY (`post_code`) REFERENCES `postal_code_mapping` (`postal_code`);

--
-- Constraints for table `id_card`
--
ALTER TABLE `id_card`
  ADD CONSTRAINT `home_address_no` FOREIGN KEY (`home_address_no`) REFERENCES `home_address_no` (`home_address_no`);

--
-- Constraints for table `itemized_deduction`
--
ALTER TABLE `itemized_deduction`
  ADD CONSTRAINT `form_no4` FOREIGN KEY (`form_no`) REFERENCES `form` (`form_no`),
  ADD CONSTRAINT `itemized_deduction_id` FOREIGN KEY (`id`) REFERENCES `itemized_deduction_mapping` (`id`);

--
-- Constraints for table `log_asText`
--
ALTER TABLE `log_asText`
  ADD CONSTRAINT `operation_status_id1` FOREIGN KEY (`operation_status_id`) REFERENCES `operation_mapping` (`no`),
  ADD CONSTRAINT `operation_type_id1` FOREIGN KEY (`opeartion_type_id`) REFERENCES `form_info_mapping` (`id`),
  ADD CONSTRAINT `user_no4` FOREIGN KEY (`user_no`) REFERENCES `account_list` (`user_no`);

--
-- Constraints for table `prev_tax_unpaid`
--
ALTER TABLE `prev_tax_unpaid`
  ADD CONSTRAINT `form_no2` FOREIGN KEY (`form_no`) REFERENCES `form` (`form_no`),
  ADD CONSTRAINT `penality_id` FOREIGN KEY (`type_id`) REFERENCES `penality_id_mapping` (`id`);

--
-- Constraints for table `prev_tax_unreturned`
--
ALTER TABLE `prev_tax_unreturned`
  ADD CONSTRAINT `form_no3` FOREIGN KEY (`form_no`) REFERENCES `form` (`form_no`),
  ADD CONSTRAINT `prev_tax_no2` FOREIGN KEY (`prev_tax_no`) REFERENCES `form` (`form_no`);

--
-- Constraints for table `try_login`
--
ALTER TABLE `try_login`
  ADD CONSTRAINT `user_no5` FOREIGN KEY (`user_no`) REFERENCES `account_list` (`user_no`);

--
-- Constraints for table `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `user_no3` FOREIGN KEY (`user_no`) REFERENCES `account_list` (`user_no`);

--
-- Constraints for table `user_type_mapping`
--
ALTER TABLE `user_type_mapping`
  ADD CONSTRAINT `priv_no` FOREIGN KEY (`priv_no`) REFERENCES `priv_mapping` (`priv_no`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
