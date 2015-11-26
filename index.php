<html>
<head>
	<meta charset="utf-8" />
	<title>nagios_inventory formulaire</title>
<head>

<body>

<br>

<form action="nagios_inventory.php" method="post">
nagios_inventory --show : <input type="texte" name="show" size="55"> <input type="submit" name="submit" value="Envoyer">
</form>

<br>
<font face="Courier New">
Utilisation : th,ts,[freq,cmd,args,macros,plugin,url] | host,service,[freq,cmd,args,macros,plugin,url]

<br>
<br>
Exemple : 
<br>

th=ORACLE,ts,freq,cmd,args,macros
<br>
host=ORA,service=ORACLE,ts,freq,cmd,args

</font>

</body>
</html> 
