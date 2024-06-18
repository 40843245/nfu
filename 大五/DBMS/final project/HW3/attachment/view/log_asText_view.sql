### When a(n) user queries all operation info (which is stored in the field `log_text`) 
### given specific username. Syntax about view are as follows.
###
### NOTICE:
### 1. Since the contents of `log_text` field are too long, it can NOT display all contents 
### so that it replace the rest text as '...'.

## CREATE VIEW
# Command
CREATE VIEW log_as_text_view AS
SELECT DISTINCT(username), log_text FROM `log_asText` WHERE username = 'username1';

## Look at content of VIEW
# Command
SELECT * FROM `log_as_text_view`;

# Result
username	log_text	
username1	The username: username1 is a(n) administrator.
On...	
username1	The username: username1 is a(n) administrator.
On...	

## Look at table structure of VIEW
# Command
DESCRIBE `log_as_text_view`;

# Result
username	varchar(20)	NO		NULL		
log_text	text	NO		NULL		

