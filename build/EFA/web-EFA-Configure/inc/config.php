<?php
/**
 * These are the database login details
 */
define('DB_USER', 'efa');
define('DB_HOST', 'localhost');
define('DB_NAME', 'efa');
$efa_config = preg_grep('/^EFASQLPWD/', file('/etc/EFA-Config'));
foreach($efa_config as $num => $line) {
  if ($line) {
    $db_pass_tmp = chop(preg_replace('/^EFASQLPWD:(.*)/','$1', $line));
  }
}
define('DB_PASS', $db_pass_tmp);
?>
