#!/bin/sh

DAYS=7

find /var/log/kafka/ -name \*.log -mtime +${DAYS} -exec rm {} \;               2>/dev/null
