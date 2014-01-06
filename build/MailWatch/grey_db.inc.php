<?
function do_query($query)
{
        global $db_hostname, $db_user, $db_pass, $db_db, $db_type;

        /* Connecting, selecting database */
	if ($db_type == "mysql")
	{
		$link = mysql_connect($db_hostname, $db_user, $db_pass) or die("Could not connect to database");
		mysql_select_db($db_db) or die("Could not select database");

		$result = mysql_query($query) or die("Query failed");

		/* Closing connection */
		mysql_close($link);
	}
	else
	{
		$link = pg_connect("host=$db_hostname dbname=$db_db user=$db_user password=$db_pass") or die("Could not connect to database");

	        $result = pg_query($link, $query) or die("Query failed");

		/* Closing connection */
		pg_close($link);
	}

        return $result;
}

function fetch_row($result)
{
	global $db_type;

	if ($db_type == "mysql")
	{
		return mysql_fetch_array($result, MYSQL_ASSOC);
	}
	else
	{
		return pg_fetch_assoc($result);
	}
}
?>
