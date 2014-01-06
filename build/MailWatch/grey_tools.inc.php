<?
function mdate($in)
{
	return substr($in, 0, 4)."-".substr($in, 4, 2)."-".substr($in, 6, 2)." ".substr($in, 8, 2).":".substr($in, 10, 2).":".substr($in, 12, 2);
}

function enchttp($in)
{
       $encoded = bin2hex("$in");
       $encoded = chunk_split($encoded, 2, '%');
       $encoded = '%' . substr($encoded, 0, strlen($encoded) - 1);

       return $encoded;   
}
?>
