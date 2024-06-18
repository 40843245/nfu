CREATE TABLE log_asText(
	username VARCHAR(20) NOT NULL,
	log_time DATETIME NOT NULL,
	log_text TEXT NOT NULL,
	FOREIGN KEY (username) REFERENCES account_list(username) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO log_asText(`username`,`log_time`,`log_text`) VALUES ('username1','2024/6/16 6:53:52','The username: username1 is a(n) administrator.
One does the operations: verify for login at 2024/6/16 6:53:52 with status success');
INSERT INTO log_asText(`username`,`log_time`,`log_text`) VALUES ('username1','2024/6/16 6:54:5','The username: username1 is a(n) administrator.
One does the operations: export filled form  at 2024/6/16 6:54:5 with status fail');
