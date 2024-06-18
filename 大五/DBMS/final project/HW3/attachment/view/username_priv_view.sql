### Display all usernames privileges.
### Syntax about view are as follows.

## CREATE VIEW
# Command
CREATE VIEW username_priv_view AS 
SELECT user_type_mapping.username, priv_mapping.priv_name FROM user_type_mapping INNER JOIN priv_mapping ON user_type_mapping.priv_no = priv_mapping.priv_no;

## Look at content of VIEW
# Command
SELECT * FROM `username_priv_view`;

# Result
username	priv_name	
username1	general user	
username2	general user	
username3	administrator	

## Look at table structure of VIEW
# Command
DESCRIBE username_priv_view;

# Result
username	varchar(20)	NO		NULL		
priv_name	varchar(20)	NO		NULL		
	
