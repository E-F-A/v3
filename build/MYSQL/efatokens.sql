CREATE DATABASE /*32312 IF NOT EXISTS*/ efa;

USE efa;

--
-- Table structure for table `tokens`
--

CREATE TABLE tokens (
  token char(30) NOT NULL,
  datestamp date NOT NULL
) ENGINE=MyISAM;


