#!/bin/bash
#
# Originally written 2015.04.23 by Khalid J Hosein, Platform28
#
# Script to migrate TRADE Kernel logs to S3
# Checks that the file isn't in use first.
# 

MINUTES=60
TARGET_DIR="s3://p28-trade-kernel-logs/`hostname -s`/logs/"
TRADE_LOGS_DIR="/home/tradekernel/TRADE/logs/"
TRADE_LOG_FILES=()

echo ""
echo "About to upload TRADE log files in $TRADE_LOGS_DIR up to S3 folder:"
echo "    $TARGET_DIR"
# echo "Then delete if MD5 sums line up."
echo "Starting in 5 seconds..."
sleep 5

cd $TRADE_LOGS_DIR

while IFS= read -d $'\0' -r file ; do
    TRADE_LOG_FILES=("${TRADE_LOG_FILES[@]}" "$file")
done < <(find $TRADE_LOGS_DIR -name EXSKernel-\*.log\*.bz2 -mmin +$MINUTES -print0)

# echo "${TRADE_LOG_FILES[@]}"   # DEBUG

for trade_log_file in "${TRADE_LOG_FILES[@]}"
do
    # lsof returns non-zero return value for file not in use
    lsof "$trade_log_file" 2>&1 > /dev/null
    if test $? -ne 0 ; then
        echo ""
        echo "$trade_log_file isn't open. Copying to S3..."
        s3cmd -p --rr put $trade_log_file $TARGET_DIR
        # s3cmd -n put $trade_log_file $TARGET_DIR # DEBUG - dry-run

        ## Now attempt to delete if the MD5 sums check out:
        # trade_log_file_remote=${trade_log_file##*/}
        # md5sum_remote=`s3cmd info  "$TARGET_DIR$trade_log_file_remote" | grep MD5 | awk '{print $3}'`
        # md5sum_local=`md5sum $trade_log_file | awk '{print $1}'`
        # if [[ "$md5sum_remote" == "$md5sum_local" ]]; then
        #   echo "$trade_log_file_remote MD5 sum checks out. Deleting..."
        #   rm $trade_log_file
        # fi
    fi
done
