# settings about failed verification.
CREATE TABLE failed_verification_setting(
	max_failed_verification INT NOT NULL CHECK(max_failed_verification>=1 and max_failed_verification<=5),
	number_of_verification INT NOT NULL,
	failed_verification_step INT NOT NULL CHECK(failed_verification_step>=1 and failed_verification_step<=3)
);

INSERT INTO failed_verification_setting(`max_failed_verification`,`number_of_verification`,`failed_verification_step`) VALUES (2,-1,2);
