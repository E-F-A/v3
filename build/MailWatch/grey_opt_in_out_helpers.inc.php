<?
	if ($_GET["direction"] == "out")
	{
		$title = "White";
		$table = "optout_";
	}
	else
	{
		$title = "Grey";
		$table = "optin_";
	}
	if ($_GET["what"] == "domain")
	{
		$title .= " Domains";
		$table .= "domain";
		$field = "domain";
		$heading = "Add a domain";
	}
	else
	{
		$title .= " Addresses";
		$table .= "email";
		$field = "email";
		$heading = "Add an address";
	}
?>
