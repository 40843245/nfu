# map type_id to form.spouse_no, getting the standard deduction for reduction of tax according to the value of form.spouse_no.
CREATE TABLE standard_deduction_mapping(
	type_id INT(1) NOT NULL PRIMARY KEY,
	value INT NOT NULL
);

INSERT INTO standard_deduction_mapping(`type_id`,`value`) VALUES (1,124000);
INSERT INTO standard_deduction_mapping(`type_id`,`value`) VALUES (2,248000);