CREATE TABLE form(
	form_no INT(6) NOT NULL UNIQUE PRIMARY KEY CHECK(form_no > 0 ),
	username VARCHAR(20) NOT NULL UNIQUE,
	id_card VARCHAR(10) NOT NULL UNIQUE,
	spouse_no INT(1) NOT NULL,
	gross_consolidated_income INT NOT NULL,
	exemptions INT NOT NULL,
	deductions INT NOT NULL,
	FOREIGN KEY (username) REFERENCES account_list(username) ON UPDATE CASCADE ON DELETE CASCADE
);

INSERT INTO form(`form_no`,`username`,`id_card`,`spouse_no`,`gross_consolidated_income`,`exemptions`,`deductions`) VALUES (1,'username1','N126537175',2,1,0,0);
INSERT INTO form(`form_no`,`username`,`id_card`,`spouse_no`,`gross_consolidated_income`,`exemptions`,`deductions`) VALUES (2,'username2','A169825673',2,1,0,0);