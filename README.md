# nagios_inventory
CENTREON REQUIRED : show easily the objects of Centreon and the relation between us.

## Requirement

  - Perl

## Options

```erb
nagios_inventory.pl --show <th,ts,[freq,cmd,args,macros,plugin,url] | host,service,[freq,cmd,args,macros,plugin,url]>
                    [--csv <split chr>]
                    [--verbose]
th = Host Template
ts = Service Template
option --csv is not implemented
```

## Examples 

```erb
./nagios_inventory.pl --show th,ts,cmd,args
SHOW FIELDS : th,ts,cmd,args
*************************** 1. row ***************************
    TH: TH_OPT_UNIX_AIX
    TS: TS_OPT_UNIX_AIX_PROCESS_ntp_STATUS
   CMD: check_nrpe_unix_process_if-started_STATUS
  ARGS: 1:2!1:2!ntp

*************************** 2. row ***************************
    TH: TH_SYS_LINUX_CENTOS_5.9
    TS: TS_SYS_LINUX_CENTOS-5.9_FILESYSTEM_/tmp_USAGE
   CMD: check_NRPE_Linux_MountFS_Usage
  ARGS: /tmp!90!95
  
...etc
```

```erb
./nagios_inventory.pl --show th=ORACLE,ts,cmd,args
SHOW FIELDS : th=ORACLE,ts,cmd,args
*************************** 1. row ***************************
    TH: TH_MID_ORACLE_LISTENER
    TS: TS_MID_ORACLE_LISTENER_STATE_tnsping_STATUS
   CMD: check_oracle_tnsping
  ARGS:

*************************** 2. row ***************************
    TH: TH_MID_ORACLE_LISTENER
    TS: TS_MID_ORACLE_UNIX_PROCESS_connected_VALUE
   CMD: check_NRPE_Linux_Proc_status
  ARGS: 0:1000 0:1000 LOCAL=YES

*************************** 3. row ***************************
    TH: TH_MID_ORACLE_LISTENER
    TS: TS_MID_ORACLE_UNIX_PROCESS_local_VALUE
   CMD: check_NRPE_Linux_Proc_status
  ARGS: 0:1000 0:2000 LOCAL=NO

...etc
```

