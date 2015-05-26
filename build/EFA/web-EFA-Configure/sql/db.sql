CREATE TABLE `efa`.`users` (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(30) NOT NULL,
    `password` CHAR(128) NOT NULL,
    `email` VARCHAR(50) NOT NULL,
    `salt` CHAR(128) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE `efa`.`login_attempts` (
    `user_id` INT(11) NOT NULL,
    `time` VARCHAR(30) NOT NULL
) ENGINE=InnoDB
