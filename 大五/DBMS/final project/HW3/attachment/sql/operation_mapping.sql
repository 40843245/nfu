# get the status of operation, can bt SUCCESS, FAILURE,UNKNOWN
CREATE TABLE operation_mapping(
	no INT(1) NOT NULL PRIMARY KEY,
	status VARCHAR(10) NOT NULL UNIQUE
);

INSERT INTO operation_mapping(`no`,`status`) VALUES (1,'success');
INSERT INTO operation_mapping(`no`,`status`) VALUES (2,'fail');
INSERT INTO operation_mapping(`no`,`status`) VALUES (3,'unknown');