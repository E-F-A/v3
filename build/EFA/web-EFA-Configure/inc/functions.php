<?php

/* E.F.A. Functions
 * 
 *
 *
 */


function test_input($data) {
  $data = trim($data);
  $data = stripslashes($data);
  $data = htmlspecialchars($data);
  return $data;
}