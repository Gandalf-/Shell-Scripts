#!/bin/bash

# This will search memory for strings
sudo dd if=/dev/mem | cat | strings | more
