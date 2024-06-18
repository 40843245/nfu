CREATE TABLE account_list(
	accountname VARCHAR(20) NOT NULL UNIQUE,
	username VARCHAR(20) NOT NULL PRIMARY KEY,
	email_name VARCHAR(30) NOT NULL UNIQUE,
	password_name VARCHAR(20) NOT NULL UNIQUE,
	active BOOLEAN NOT NULL DEFAULT 1
);

INSERT INTO account_list(`accountname`,`username`,`email_name`,`password_name`,`active`) VALUES ('accountname1','username1','jayw711kb1@gmail.com','password1',1);
INSERT INTO account_list(`accountname`,`username`,`email_name`,`password_name`,`active`) VALUES ('accountname2','username2','jayw711kb2@gmail.com','password2',1);
INSERT INTO account_list(`accountname`,`username`,`email_name`,`password_name`,`active`) VALUES ('accountname3','username3','jayw711kb3@gmail.com','password3',1);
