#!/bin/bash

# This searches through the access logs for Apache, and returns
# the top 10 unique IP addresses found

sudo tail -10000 /var/log/apache2/access.log | awk '{print }' | sort | uniq -c | sort -n | tail
