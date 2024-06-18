CREATE TABLE user_type_mapping(
	username VARCHAR(20) NOT NULL UNIQUE,
	priv_no INT(1) NOT NULL,
	FOREIGN KEY (username) REFERENCES account_list(username) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (priv_no) REFERENCES priv_mapping(priv_no) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO user_type_mapping(`username`,`priv_no`) VALUES ('username1',0);
INSERT INTO user_type_mapping(`username`,`priv_no`) VALUES ('username2',0);
INSERT INTO user_type_mapping(`username`,`priv_no`) VALUES ('username3',1);