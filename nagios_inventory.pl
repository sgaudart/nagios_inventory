#!/usr/bin/perl
#======================================================================
# Auteur : sgaudart@capensis.fr
# Date   : 20/10/2015
# But    : This script can read the config files (*.cfg) from Nagios or Centreon
#          and display the relation between the differents objects.
# INPUT : 
#          --show = th,ts,[freq,cmd,args,macros,plugin,url] | host,service,[freq,cmd,args,macros,plugin,url]
# OUTPUT :
#          ASCII report about the linked nagios objects
#
#======================================================================
#   Date       Version     Auteur     Commentaires
# 20/10/2015   1           SGA        initial version
# 22/10/2015   2           SGA        affichage tableau
# 22/10/2015   3           SGA        affichage bloc
# 23/10/2015   4           SGA        traitement des args command
# 26/10/2015   5           SGA        meilleur traitement nom command
# 27/10/2015   6           SGA        ajout option --show + affichage des MACROS
# 29/10/2015   7           SGA        ajout fonction ScanServiceTemplates
# 29/10/2015   8           SGA        bonne gestion du champ --show
# 02/11/2015   9           SGA        gestion du signe '=' pour le th
# 03/11/2015  10           SGA        gestion du signe '=' pour tous les champs
# 04/11/2015  11           SGA        prise en compte du champ 'plugin'
# 04/11/2015  12           SGA        prise en compte des ts non associes aux th
# 05/11/2015  13           SGA        prise en compte des host/services
# 09/11/2015  14           SGA        fix bug SERVICE_ID is not a macro
#======================================================================

use strict;
#use warnings;
use Getopt::Long;

my $show=""; # option --show
my @showtab;
our $csv="";

my $verbose;
my $help;

GetOptions (
"show=s" => \$show, # string
"csv=s" => \$csv, # string
"verbose" => \$verbose, # flag
"help" => \$help) # flag
or die("Error in command line arguments\n");

my $line;

my $centreon_conf="/etc/nagios/"; 

our %ts; # hash table for the service templates
our %ts_from_th; # hash table for the host templates => linked ts (ex: th{my_th}="ts1;ts2;ts3")
our $thname="";
our $tsname=""; # line counter

our %service; # hash table for the service
our $hostname;
our $service_name;

our %plugin_from_cmd; # hash table for the plugin => linked cmd

our $flag=1;

my $check_command=""; # command+args
my $command=""; # only the command
my $cursor=-1;
my $args="";
my $macro_name="";
my $macro_value="";
my $macros="";
my $freq=0;
my $url="";

my @tslist;
my $i=0; # reset

my %prefix  = ( "th"      => "    TH:",
				"ts"      => "    TS:",
				"host"    => "  HOST:",
				"service" => "   SVC:",
				"freq"    => "  FREQ:",
				"cmd"     => "   CMD:",
				"args"    => "  ARGS:",
				"macros"  => "MACROS:",
				"plugin"  => "PLUGIN:",
				"url"     => "   URL:"); 

###############################
# HELP
###############################

if (($help) || ($show eq ""))
{
	print"nagios_inventory.pl --show <th,ts,[freq,cmd,args,macros,plugin,url] | host,service,[freq,cmd,args,macros,plugin,url]>
                    [--csv <split chr>]
                    [--verbose]\n";
	exit;
}

###############################
# MAIN
###############################

ScanCheckcommands();
ScanServiceTemplates();


if ($csv eq "") { print "SHOW FIELDS : $show\n"; }
@showtab = split(',', $show);

if ($showtab[0] =~ /th/)
{
	print "DEBUG : PROCESSING TH\n" if $verbose;
	
	foreach $thname (keys(%ts_from_th))
	{
	   # on liste tous les TH
	   @tslist = split(";", $ts_from_th{$thname});
	   
	   foreach $tsname (@tslist)
	   {
			# on traite un couple TH+TS
			my $buffer=""; # init
			$flag=1; # init
			foreach my $field (@showtab)
			{
				$buffer=$buffer . CreateOutputFromTs($field);
			}
			
			if ($flag) # on affiche que si le filtre est bon
			{
				$i++; # counter
				$buffer="*************************** $i. row ***************************\n" . $buffer;
				print "$buffer\n";
			}
		}
	 }
}

if ($showtab[0] =~ /ts/)
{
	print "DEBUG : PROCESSING TS\n" if $verbose;
	
	# foreach $hostname (sort keys %event)
	foreach $tsname (sort keys %ts)
	{
		# on traite un couple TH+TS
		my $buffer=""; # init
		$flag=1; # init
		foreach my $field (@showtab)
		{
			$buffer=$buffer . CreateOutputFromTs($field);
		}
		
		if ($flag) # on affiche que si le filtre est bon
		{
			$i++; # counter
			$buffer="*************************** $i. row ***************************\n" . $buffer;
			print "$buffer\n";
		}
	}
}

if ($showtab[0] =~ /host|service/)
{
	print "DEBUG : PROCESSING HOST\n" if $verbose;
	
	ScanServices();
	foreach $hostname (sort keys %service)
	{
	   # on liste tous les HOSTS
	   foreach $service_name (sort keys %{ $service{$hostname} })
	   {
			# on traite un couple HOST+SERVICE
			my $buffer=""; # init
			$flag=1; # init
			foreach my $field (@showtab)
			{
				$buffer=$buffer . CreateOutputFromService($field);
			}
			
			if ($flag) # on affiche que si le filtre est bon
			{
				$i++; # counter
				$buffer="*************************** $i. row ***************************\n" . $buffer;
				print "$buffer\n";
			}
		}
	 }
}


#############  FONCTIONS  #################

###############################
# READING serviceTemplates.cfg
###############################

sub ScanServiceTemplates
{
	open (TSFD, "$centreon_conf/serviceTemplates.cfg") or die "Can't open $centreon_conf/serviceTemplates.cfg\n" ; # reading serviceTemplates.cfg
	while (<TSFD>)
	{
		$line=$_;
		chomp($line); # delete the carriage return
		
		if ($line =~ /^.*name(.*)$/)
		{
			$tsname = $1;
			$tsname =~ s/^\s+//; # space delete
		}
		
		if ($line =~ /^.*check_command(.*)$/)
		{
			$check_command = $1;
			$check_command =~ s/^\s+//; # space delete
			$cursor = index($check_command, '!');
			if ($cursor ne -1)
			{
				$command = substr($check_command,0,$cursor);
				$args = substr($check_command,$cursor+1,1000);
			}
			else
			{
				$command=$check_command;
				$args="";
			}
		}
		
		if ($line =~ /^.*normal_check_interval(.*)$/)
		{
			$freq = $1;
			$freq =~ s/^\s+//; # space delete
		}
		
		if ($line =~ /^.*notes_url(.*)$/)
		{
			$url = $1;
			$url =~ s/^\s+//; # space delete
		}
		
		# 	_SID				ADefinir
		if ($line  =~ /^\t_(.*)\t+(.*)$/)
		{
			$macro_name = $1;
			$macro_value = $2;
			$macro_name =~ s/[ \t]+$//; # tab delete
			$macros="$macro_name=$macro_value $macros";
		}
		
		if ($line =~ /^.*TEMPLATE-HOST-LINK(.*)$/)
		{
			$thname = $1;
			$thname =~ s/^\s+//; # space delete
			if (defined $ts_from_th{$thname})
			{
				$ts_from_th{$thname}="$ts_from_th{$thname};$tsname";
			}
			else
			{
				$ts_from_th{$thname}="$tsname";
			}
		}
		
		if ($line  eq "}")
		{
			# fin d'un bloc : traitement des infos du ts 
			$ts{$tsname}{ts}=$tsname;
			$ts{$tsname}{cmd}=$command;
			$ts{$tsname}{args}=$args;
			$ts{$tsname}{freq}=$freq;
			$ts{$tsname}{macros}=$macros;
			$ts{$tsname}{url}=$url;
			$ts{$tsname}{plugin}=$plugin_from_cmd{$command};
			
			#print "DEBUG : $tsname;$freq;$command;$macros\n" if $verbose;
			$macros=""; # init
		}

	}
	close TSFD;
}


sub ScanServices
{
	my $service_name;
	my $host_name;
	$command="";
	$args="";
	$freq="";
	$macros="";
	$url="";
	
	open (SVCFD, "$centreon_conf/services.cfg") or die "Can't open $centreon_conf/services.cfg\n" ; # reading serviceTemplates.cfg
	while (<SVCFD>)
	{
		# INIT
		
		$line=$_;
		chomp($line); # delete the carriage return
		
		if ($line =~ /^.*service_description(.*)$/)
		{
			$service_name = $1;
			$service_name =~ s/^\s+//; # space delete
		}
		
		if ($line =~ /^.*check_command(.*)$/)
		{
			$check_command = $1;
			$check_command =~ s/^\s+//; # space delete
			$cursor = index($check_command, '!');
			if ($cursor ne -1)
			{
				$command = substr($check_command,0,$cursor);
				$args = substr($check_command,$cursor+1,1000);
			}
			else
			{
				$command=$check_command;
				$args="";
			}
		}
		
		if ($line =~ /^.*host_name(.*)$/)
		{
			$host_name = $1;
			$host_name =~ s/^\s+//; # space delete
		}
		
		if ($line =~ /^.*normal_check_interval(.*)$/)
		{
			$freq = $1;
			$freq =~ s/^\s+//; # space delete
		}
		
		if ($line =~ /^.*notes_url(.*)$/)
		{
			$url = $1;
			$url =~ s/^\s+//; # space delete
		}
		
		# 	_SID				ADefinir
		if ($line  =~ /^\t_(.*)\t+(.*)$/)
		{
			if ($1 =~ /SERVICE_ID/) { next; }
			$macro_name = $1;
			$macro_value = $2;
			$macro_name =~ s/[ \t]+$//; # tab delete
			$macros="$macro_name=$macro_value $macros";
		}
		
		if ($line =~ /^.*use(.*)$/)
		{
			$tsname = $1;
			$tsname =~ s/^\s+//; # space delete
		}
		
		if ($line  eq "}")
		{
			# fin d'un bloc : traitement des infos du ts 
			$service{$host_name}{$service_name}{service}=$service_name;
			$service{$host_name}{$service_name}{ts}=$tsname;
			$service{$host_name}{$service_name}{cmd}=$command;
			$service{$host_name}{$service_name}{args}=$args;
			$service{$host_name}{$service_name}{freq}=$freq;
			$service{$host_name}{$service_name}{macros}=$macros;
			$service{$host_name}{$service_name}{url}=$url;
			$service{$host_name}{$service_name}{plugin}=$plugin_from_cmd{$command};
			
			# INIT
			$command="";
			$args="";
			$freq="";
			$macros="";
			$url="";
		}

	}
	close SVCFD;
}





sub ScanCheckcommands
{
	my $command_name;
	my $command_line;
	my $plugin;
	my @plugintab;
	open (CMDFD, "$centreon_conf/checkcommands.cfg") or die "Can't open $centreon_conf/checkcommands.cfg\n" ; # reading checkcommands.cfg
	while (<CMDFD>)
	{
		$line=$_;
		chomp($line); # delete the carriage return
		
		if ($line =~ /^.*command_name(.*)$/)
		{
			$command_name = $1;
			$command_name =~ s/^\s+//; # space delete
		}
		
		
		if ($line =~ /^.*command_line(.*)$/)
		{
			$command_line = $1;
			$command_line =~ s/^\s+//; # space delete
			@plugintab=split(' ',$command_line);
			$plugin=$plugintab[0];
		}
		
		if ($line  eq "}")
		{
			# fin d'un bloc : traitement des infos de la command
			$plugin_from_cmd{$command_name}=$plugin;
		}

	}
	close CMDFD;
}


# create the output by option
sub CreateOutputFromTs
{
	my $option = $_[0]; # 1 ARG : the option
	my $value="";
	my $output="";
	
	if ($option =~ /^th.*/)
	{
		$value=$thname;
		if ($option =~ /(^.*)=(.*)$/)
		{
			$option=$1;
			print "DEBUG : $value different de $2 ?\n" if $verbose;
			if ($value !~ /$2/) { $flag=0; }
		}
	}
	else
	{
		# cas TS,CMD,ARGS,MACROS
		if ($option =~ /(^.*)=(.*)$/)
		{
			$option=$1;
			$value=$ts{$tsname}{$1};
			if ($value !~ /$2/) { $flag=0; }
		}
		else
		{
			$value=$ts{$tsname}{$option};
		}
	}
	
	$output="$prefix{$option} $value\n";
	print "DEBUG: $output" if $verbose;
	return $output;
}


# create the output by option
sub CreateOutputFromService
{
	my $option = $_[0]; # 1 ARG : the option
	my $value="";
	my $output="";

	if ($option =~ /^host.*/)
	{
		$value=$hostname;
		if ($option =~ /(^.*)=(.*)$/)
		{
			$option=$1;
			print "DEBUG : $value different de $2 ?\n" if $verbose;
			if ($value !~ /$2/) { $flag=0; }
		}
	}
	else
	{
		# cas SERVICE,CMD,ARGS,MACROS
		if ($option =~ /(^.*)=(.*)$/)
		{
			$option=$1;
			if ($service{$hostname}{$service_name}{$1} eq "")
			{
				# la valeur est celle du ts et non celle du service
				$value=$ts{$service{$hostname}{$service_name}{ts}}{$1};
			}
			else
			{
				$value=$service{$hostname}{$service_name}{$1};
			}
			if ($value !~ /$2/) { $flag=0; }
		}
		else
		{
			if ($service{$hostname}{$service_name}{$option} eq "")
			{
				# la valeur est celle du ts et non celle du service
				$value=$ts{$service{$hostname}{$service_name}{ts}}{$option};
			}
			else
			{
				$value=$service{$hostname}{$service_name}{$option};
			}
		}
	}
	
	$output="$prefix{$option} $value\n";
	print "DEBUG: $output" if $verbose;
	return $output;
}
