#!/bin/bash

# This deletes every other file in a directory with the .zip extension.
# Asks for permission first, unless you provide another character after
# the command. eg. "./decimate.sh yes"

delete=no
dry=no
files=""

if test "$1" = ""
  then
    echo "Dry run"
    dry=yes
fi

for file in *.zip 
  do
    if [ $delete = yes ]
      then
        echo $file
        files="$files $file"
        
        if [ $dry = no ]
          then
            rm -f $file
        fi

        delete=no
    else
      delete=yes
    fi
done

if [[ $dry = yes ]]
  then
    echo "Total disk size freed:"
    du -s $files | awk '{print $1;}' | paste -sd+ | bc | awk '{$1/=1024; printf "%.2f MB\n", $1}'
fi
