<?php

session_start();

echo "Current PHP Session Variables<br/>";
$myusername = $_SESSION['myusername'];
$fullname = $_SESSION['fullname'];
$user_type = $_SESSION['user_type'];

if (isset($_SERVER['PHP_AUTH_USER']))
   echo "PHP_AUTH_USER is set<br/>";

echo "myusername = $myusername<br/>";

if (isset($_SERVER['PHP_AUTH_PW']))
   echo "PHP_AUTH_PW is set<br/>";

echo "fullname = $fullname<br/>";
echo "user_type = $user_type<br/>";

?>

