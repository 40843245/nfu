# get the message that will be written into log file by id.
CREATE TABLE log_mapping(
	id INT(0) NOT NULL PRIMARY KEY,
	name VARCHAR(50) NOT NULL UNIQUE,
	priv_no INT(1) NOT NULL,
	FOREIGN KEY(priv_no) REFERENCES priv_mapping(priv_no)
);

INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (1,'simulate tax',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (2,'export simulation tax',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (3,'fill form',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (4,'import form for fill',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (5,'export filled form',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (6,'add a new form',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (7,'query my form',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (8,'calculate tax',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (9,'import tax',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (10,'export tax',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (11,'login',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (12,'logout',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (13,'verify for login',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (14,'verify email',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (15,'query my info',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (16,'export my info',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (17,'change passowrd',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (18,'report bugs',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (19,"query one or some user's info",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (20,"change one or some user's info",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (21,"disable one or some user's account",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (22,"export user's account",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (23,"deactivate one or some user's account",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (24,"get all report bugs",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (25,"change changelog of the development og this system",1);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (27,'query my account info',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (28,'import my account info',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (29,'export my account info',0);
INSERT INTO log_mapping(`id`,`name`,`priv_no`) VALUES (30,"activate one or some user's account",1);
