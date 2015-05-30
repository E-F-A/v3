<?php

/**
 * Configuration for: Database Connection
 *
 * For more information about constants please @see http://php.net/manual/en/function.define.php
 * If you want to know why we use "define" instead of "const" @see http://stackoverflow.com/q/2447791/1114320
 *
 * DB_HOST: database host, usually it's "127.0.0.1" or "localhost", some servers also need port info
 * DB_NAME: name of the database. please note: database and database table are not the same thing
 * DB_USER: user for your database. the user needs to have rights for SELECT, UPDATE, DELETE and INSERT.
 * DB_PASS: the password of the above user
 */
$efa_config = preg_grep('/^EFASQLPWD/', file('/etc/EFA-Config'));
foreach($efa_config as $num => $line) {
  if ($line) {
    $db_pass_tmp = chop(preg_replace('/^EFASQLPWD:(.*)/','$1', $line));
  }
}
define('DB_PASS', $db_pass_tmp);
define("DB_HOST", "127.0.0.1");
define("DB_NAME", "efa");
define("DB_USER", "efa");
