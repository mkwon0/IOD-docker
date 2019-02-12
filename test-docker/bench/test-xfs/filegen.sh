#/bin/bash
source variablegen

### FS Initialization
if [ "$INIT_FS" = 1 ]
then
    echo "**********  FS Initialization  **********"
    wipefs -a -f ${DEV}
    for (( i=1; i <5; ++i ))
    do
        wipefs -a -f /dev/${DEV}n$i
        mkfs.xfs -f /dev/${DEV}n$i
        fsck -N /dev/${DEV}n$i
    done
fi

### CONFIG Checker
if [ "$CHECK_CONF" = 1 ]
then
    echo "**********  FS Checker  **********"
    for (( i=1; i <5; ++i ))
    do
        if [[ -z $(fsck -N /dev/${DEV}n$i | grep xfs) ]]
        then
            echo "****Backing FileSystem of /dev/${DEV}n$i is not xfs. ABOURTED!!!!****"
        fi
    done

    echo "**********  Resource Volume Mount Checker **********"
    if [[ -z $(df -h | grep -w $SRC_PATH) ]]
    then
        mkdir -p $SRC_PATH
        mount $SRC_DEV $SRC_PATH
    fi

    echo "********** Resource Volume Existence Checker **********"
    if [[ -z $(docker volume ls | grep -w $SRC_VOL) ]]
    then
        docker volume create -d local-persist -o mountpoint=$SRC_PATH --name=$SRC_VOL
    else
        echo "****Resource Volume (named $SRC_VOL) Exists****"
    fi

    echo "********** IO Volume Mount Checker **********"

    for (( i=1; i <5; ++i ))
    do
        NS_PATH=/mnt/${DEV}n$i
        if [[ -z $(df -h | grep -w $NS_PATH) ]]
        then
            mkdir -p $NS_PATH
            mount /dev/${DEV}n$i $NS_PATH
        fi
    done
fi

### Fio jobfile generation
if [ "$GEN_FILE" = 1 ]
then
    echo "********** FIO JOB_FILE GENERATION **********"
    for (( NS_ID=3; NS_ID <4; ++NS_ID ))
    do
        for (( CONC_NUM=22; CONC_NUM<=400; ++CONC_NUM))
        do
            MOUNT_PATH=/mnt/${DEV}n${NS_ID}
            JOB_NAME=xfs-fill-NS_ID${NS_ID}-CONC_NUM${CONC_NUM}
            JOB_FILE=$JOB_PATH/$JOB_NAME.fio
            CONT_NAME=$JOB_NAME
            mkdir -p $JOB_PATH
            if [ -f "$JOB_FILE" ]
            then
                rm -f $JOB_FILE
            fi
            sed '/filename/c\filename=/mnt/'${DEV}'n'$NS_ID'/text'$CONC_NUM'' $FILL_JOB > $JOB_FILE

            docker run -d --rm --name $CONT_NAME \
                       --mount type=bind,source=${MOUNT_PATH},target=${MOUNT_PATH} \
                       --mount source=$SRC_VOL,target=$SRC_PATH \
                       $IMAGE $JOB_FILE
        done
        wait
    done
fi
