# settings about lock when user fails to login up to limit.
CREATE TABLE lock_login_setting(
	max_consecutive_failed_login INT NOT NULL CHECK(max_consecutive_failed_login>=1 and max_consecutive_failed_login<=5),
	max_consecutive_failed_login_locking_time INT NOT NULL
);

INSERT INTO lock_login_setting(`max_consecutive_failed_login`,`max_consecutive_failed_login_locking_time`) VALUES (5,20);
