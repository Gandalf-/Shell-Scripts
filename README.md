# Shell-Scripts
Example shell scripts

### AlpineBrain.sh
Checks for network availability, if it can connect it will
- Tell server (Google Drive) it's external and internal ip addresses
- If the roundtrip time to server isn't too high, start the VPN
- Provide server a reverse tunnel for sshfs
This provides a flexible, self repairing monitor for network status and connectivity

### apache-list-ips.sh
This searches through the access logs for Apache, and returns
the top 10 unique IP addresses found

### cleanscript.sh
This cleans up the junk that often shows up in files generated
by the "script" command.

### connectivity.sh
This prints whether the current machine has internet connectivity, and DNS

### decimate.sh
This deletes every other file in a directory with the .zip extension.
Asks for permission first, unless you provide another character after
the command. eg. "./decimate.sh yes"

### MCServerStart.sh
This is an example of a monitor that will restart a process if it dies for any reason.
The 15 second wait is recommended in the case that the process can't be started again

### run.sh
If a program is in a non-executable partition, then this can be used to move it
to /tmp, where it can be run normally

### ViewRam.sh
This will search memory for strings
