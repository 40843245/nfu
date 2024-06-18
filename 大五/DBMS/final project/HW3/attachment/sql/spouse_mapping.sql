# map spouse_mapping to form.spouse_no, getting the spouse status.
CREATE TABLE spouse_mapping(
	id INT(1) NOT NULL PRIMARY KEY,
	status VARCHAR(5) NOT NULL UNIQUE,
	text VARCHAR(10) NOT NULL UNIQUE
);

INSERT INTO spouse_mapping(`id`,`status`,`text`) VALUES (1,'no','no spouse');
INSERT INTO spouse_mapping(`id`,`status`,`text`) VALUES (2,'yes','has spouse');

