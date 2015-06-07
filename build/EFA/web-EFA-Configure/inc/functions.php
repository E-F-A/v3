<?php

/* E.F.A. Functions
 * 
 * 
 * 
 */


// Get settings from EFA-Config
$efa_config = preg_grep('/^EFASQLPWD/', file('/etc/EFA-Config'));

// Munin htaccess password for graphs
foreach($efa_config as $num => $line) {
  if ($line) {
    $MUNINPWD = chop(preg_replace('/^MUNINPWD:(.*)/','$1', $line));
  }
}