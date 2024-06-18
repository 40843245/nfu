# map priv_no to user_type_mapping.priv_no, getting the privilege name of username.
CREATE TABLE priv_mapping(
	priv_no INT(1) NOT NULL PRIMARY KEY,
	priv_name VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO priv_mapping(`priv_no`,`priv_name`) VALUES (0,'general user');
INSERT INTO priv_mapping(`priv_no`,`priv_name`) VALUES (1,'administrator');