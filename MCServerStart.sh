#!/bin/bash

# This is an example of a monitor that will restart a process if it dies for any reason.
# The 15 second wait is recommended in the case that the process can't be started again

echo "Starting"
until bash -c "sudo java -Xmx1024M -Xms1024M -jar minecraft_server.1.8.4.jar nogui >&2"; do
  echo "Server crashed with exit code $?. Restarting in 15 seconds" >&2
  sleep 15
done
