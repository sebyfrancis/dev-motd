#!/bin/bash
#
# Originally written 2014.12.09 by Khalid J Hosein, Platform28
#
# Script to migrate recordings to S3
# Checks that the file isn't in use first.
# 

MINUTES=60
TARGET_DIR="s3://p28-main-storage/Platform28/temp-for-recordings/`/bin/date +%Y/%m/%d`/"
REC_DIR="/media/ephemeral0/recordings"
WAV_FILES=()

echo ""
echo "About to upload WAV files in $REC_DIR up to S3 folder:"
echo "    $TARGET_DIR"
echo "Then delete if MD5 sums line up."
echo "Starting in 5 seconds..."
sleep 5

cd $REC_DIR

# Remove *wav_sent files as they are just copies that were already successfully
# uploaded properly by the Recording Uploader
rm *.wav_sent

while IFS= read -d $'\0' -r file ; do
    WAV_FILES=("${WAV_FILES[@]}" "$file")
done < <(find $REC_DIR -name \*.wav\* -mmin +$MINUTES -print0)

# echo "${WAV_FILES[@]}"   # DEBUG

for wav_file in "${WAV_FILES[@]}"
do
    # lsof returns non-zero return value for file not in use
    lsof "$wav_file" 2>&1 > /dev/null
    if test $? -ne 0 ; then
        echo ""
        echo "$wav_file isn't open. Copying to S3..."
        s3cmd -p put $wav_file $TARGET_DIR
        # s3cmd -n put $wav_file $TARGET_DIR # DEBUG - dry-run

        ## Now attempt to delete if the MD5 sums check out:

        wav_file_remote=${wav_file##*/}
        md5sum_remote=`s3cmd info  "$TARGET_DIR$wav_file_remote" | grep MD5 | awk '{print $3}'`
        md5sum_local=`md5sum $wav_file | awk '{print $1}'`
        if [[ "$md5sum_remote" == "$md5sum_local" ]]; then
          echo "$wav_file_remote MD5 sum checks out. Deleting..."
          rm $wav_file
        fi
    fi
done
