#!/bin/bash

# If a program is in a non-executable partition, then this can be used to move it
# to /tmp, where it can be run normally (this is true on chromebooks at least)
#
# Takes two arguments
# ./run.sh filename [execution-command]
#
# execution-command examples are java, racket, perl, etc

NAME=$(basename $1)

cp "$1" /tmp

if [[ "$2" == "" ]]; then
  /tmp/$NAME
else
  "$2" /tmp/$NAME
fi

rm /tmp/$NAME
