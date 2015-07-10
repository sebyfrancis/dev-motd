#!/bin/sh
find /tmp/s3fscache/  -mtime +2 -exec rm {} \;
