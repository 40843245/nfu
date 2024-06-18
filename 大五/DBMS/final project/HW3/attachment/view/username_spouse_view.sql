### Display all users spouse status.
### Syntax about view are as follows.

## CREATE VIEW
# Command
CREATE VIEW username_spouse_view 
AS SELECT form.username, spouse_mapping.text FROM form INNER JOIN spouse_mapping ON form.spouse_no = spouse_mapping.id;

## Look at content of VIEW
# Command
SELECT * FROM username_spouse_view;

# Result
username	text	
username1	has spouse	
username2	has spouse	


## Look at table structure of VIEW
# Command
DESCRIBE username_spouse_view;

# Result
username	varchar(20)	NO		NULL		
text	varchar(10)	NO		NULL		
