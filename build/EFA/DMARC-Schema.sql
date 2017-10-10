CREATE TABLE `domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(191) NOT NULL,
  `firstseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5448 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ipaddr` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `addr` varchar(64) NOT NULL,
  `firstseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `addr` (`addr`)
) ENGINE=InnoDB AUTO_INCREMENT=6923 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `jobid` varchar(128) NOT NULL,
  `reporter` int(10) unsigned NOT NULL,
  `policy` tinyint(3) unsigned NOT NULL,
  `disp` tinyint(3) unsigned NOT NULL,
  `ip` int(10) unsigned NOT NULL,
  `env_domain` int(10) unsigned NOT NULL,
  `from_domain` int(10) unsigned NOT NULL,
  `policy_domain` int(10) unsigned NOT NULL,
  `spf` tinyint(3) unsigned NOT NULL,
  `align_dkim` tinyint(3) unsigned NOT NULL,
  `align_spf` tinyint(3) unsigned NOT NULL,
  `sigcount` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reporter` (`reporter`,`date`,`jobid`),
  KEY `date` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=27128 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 

CREATE TABLE `reporters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(191) NOT NULL,
  `firstseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` int(11) NOT NULL,
  `repuri` varchar(255) NOT NULL,
  `adkim` tinyint(4) NOT NULL,
  `aspf` tinyint(4) NOT NULL,
  `policy` tinyint(4) NOT NULL,
  `spolicy` tinyint(4) NOT NULL,
  `pct` tinyint(4) NOT NULL,
  `locked` tinyint(4) NOT NULL,
  `firstseen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastsent` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain` (`domain`),
  KEY `lastsent` (`lastsent`)
) ENGINE=InnoDB AUTO_INCREMENT=4230 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `signatures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` int(11) NOT NULL,
  `domain` int(11) NOT NULL,
  `pass` tinyint(4) NOT NULL,
  `error` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `message` (`message`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;