<?php
require_once("libraries/password_compatibility_library.php");
require_once("config/db.php");
require_once("classes/Login.php");

// create a login object.
$login = new Login();

if ($login->isUserLoggedIn() == true) {
    header("Location: pages/index.php");
} else {
    // the user is not logged in. you can do whatever you want here.
    // for demonstration purposes, we simply show the "you are not logged in" view.
    include("login.php");
}

?>