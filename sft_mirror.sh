#!/bin/sh

SERVICE="lftp"
if pgrep -x "$SERVICE" >/dev/null
then
    logger "$SERVICE is already running"
else
    LastUploadFilePath="./LastUploadFileInfo.txt"

    for SourceFilePath in "./files"/*.json
    do
        [ -f "$SourceFilePath" ] || continue

        rm -f $LastUploadFilePath

        logger "upload start $SourceFilePath"

        SourceFileSize=$(ls -al $SourceFilePath | awk '{print $5}')
        logger "SourceFileSize is $SourceFileSize"

        SourceFileName=$(basename $SourceFilePath)

        SFTPCMD="lftp -d sftp://dbs_env_vib_test:1234@s-6795fc9179ba4bb29.server.transfer.ap-northeast-2.amazonaws.com \
        -e 'set sftp:connect-program \"ssh -i id_rsa\";\
        set net:timeout 10;set net:max-retries 1;set net:reconnect-interval-multiplier 1;set net:reconnect-interval-base 1;\
        set xfer:log-file /honglim/sftp-xfer.log;\
        set log:file /honglim/sftp-proto.log;\
        put -c ${SourceFilePath};\
        ls | grep ${SourceFileName} | xargs > ${LastUploadFilePath}
        bye'"

        eval "$SFTPCMD"
        result=$?

        if [ $result -eq 0 ]; then
            if [ -f "$LastUploadFilePath" ]; then
                UploadedFileSize=$(cat $LastUploadFilePath | awk '{print $5}')
                logger "UploadedFileSize  is $UploadedFileSize"                  
                if [ "$UploadedFileSize" = "$SourceFileSize" ]; then             
                    logger "upload success & delete file :${SourceFilePath}"     
                    rm -rf $SourceFilePath                                       
                else                                                             
                    logger "UploadedFileSize  error"                             
                fi 
            else
                logger "Create fail $LastUploadFilePath" 
            fi
        else
            logger "upload fail :${SourceFilePath}"
        fi
    done
fi
