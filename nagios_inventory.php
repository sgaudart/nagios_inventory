<html>
 <head>
  <title>nagios_inventory traitement</title>
 </head>
 <body>

 <font face="Courier New" size="2">
 <?php

$option=$_POST['show'];
 
$prefix="./nagios_inventory.pl --show ";
$cmd=$prefix . $option;

exec($cmd, $out);
foreach ($out as $key => $valeur )
echo $valeur."<br>";

?>



?>
</font>

 </body>
</html>
