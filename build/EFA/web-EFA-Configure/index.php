<?php
require_once("libraries/password_compatibility_library.php");
require_once("config/db.php");
require_once("classes/Login.php");

// create a login object.
$login = new Login();
if ($login->isUserLoggedIn() == true) {
    header("Location: pages/index.php");
} else {
    include("login.php");
}
?>
