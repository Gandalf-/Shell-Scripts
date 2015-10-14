#!/bin/bash

# This cleans up the junk that often shows up in files generated
# by the "script" command.

cat $1 | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | col -b > "$1".cleaned
mv "$1".cleaned $1
