#/bin/bash
source variablegen

### FS Initialization
if [ "$INIT_FS" = 1 ]
then
    echo "**********  FS Initialization  **********"
    wipefs -a -f ${DEV}p1
    mkfs.ext4 ${DEV}p1
    mkfs.xfs ${DEV}p2
    mkfs.ext4 ${DEV}p3
    mkfs.vfat ${DEV}p4
fi

### CONFIG Checker
if [ "$CHECK_CONF" = 1 ]
then
    echo "**********  FS Checker  **********"
    for (( idx=0; idx <${#ARR_FS[@]}; ++idx))
    do
        part=$((idx+1))
        echo "$idx" "${ARR_FS[idx]}"
        if [[ -z $(fsck -N /dev/${DEV_NAME}p${part} | grep ${ARR_FS[idx]}) ]]
        then
            echo "****Backing FileSystem of ${DEV_NAME}p${part} is not ${ARR_FS[idx]}. ABOURTED!!!!****"
            exit 1
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

    PART_PATH=${IO_PATH}-raw
    if [[ -z $(df -h | grep -w $PART_PATH) ]]
    then
        mkdir -p $PART_PATH
        mount -o rw ${IO_DEV}p1 $PART_PATH
    fi

    for (( idx=1; idx <${#ARR_FS[@]}; ++idx))
    do
        part=$((idx+1))
        PART_DEV=${IO_DEV}p${part}
        PART_PATH=${IO_PATH}-${ARR_FS[idx]}

        if [[ -z $(df -h | grep -w $PART_PATH) ]]
        then
            mkdir -p $PART_PATH
            mount $PART_DEV $PART_PATH
        fi
    done

    echo "********** IO Volume Existence Checker **********"
    if [ "$STORAGE" = "volume" ] || [ "$STORAGE" = "container" ]
    then
        for (( idx=1; idx <${#ARR_FS[@]}; ++idx))
        do
            part=$((idx+1))
            PART_DEV=${IO_DEV}p${part}
            BFS=${ARR_FS[idx]}
            PART_PATH=${IO_PATH}-${BFS}

            if [[ -z $(docker volume ls | grep -w $BFS) ]]
            then
                docker volume create -d local-persist -o mountpoint=$PART_PATH --name=$BFS 
            else
                echo "****IO Volume (named $BFS) Exists****"
            fi
        done
    fi
fi

### Fio jobfile generation
if [ "$GEN_FIOJOB" = 1 ]
then
    echo "********** FIO JOB_FILE GENERATION **********"
    for (( idx=1; idx <${#ARR_FS[@]}; ++idx))
    do
        part=$((idx+1))
        PART_DEV=${DEV_NAME}p${part}
        BFS=${ARR_FS[idx]}
        PART_DIR=${DEV_NAME}-${BFS}
        ORIG_JOB=$ORIG_JOB_PATH/$JOB_TYPE.fio

        for CONC_NUM in "${ARR_CONC[@]}"
        do
            FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$CONC_NUM/$NS/$TARGET/$JOB_TYPE
            JOB_NAME=$BFS-$JOB_TYPE$CONC_NUM
            JOB_FILE=$JOB_PATH/$JOB_NAME.fio
            mkdir -p $FIOSRC_PATH $JOB_PATH

            if [ -f "$JOB_FILE" ]
            then
                rm -f $JOB_FILE
            fi
           
            sed '/filename/c\filename=/mnt/'$PART_DIR'/text'$CONC_NUM'' $ORIG_JOB > $JOB_FILE
        done
    done
fi

### File Generation
if [ "$GEN_FILE" = 1 ]
then
    echo "********** WORKLOAD DATAFILE GENERATION **********"
    for (( idx=1; idx <${#ARR_FS[@]}; ++idx))
    do
        part=$((idx+1))
        PART_DEV=${DEV_NAME}p${part}
        BFS=${ARR_FS[idx]}
        PART_DIR=${DEV_NAME}-${BFS}
        PART_PATH=/mnt/${PART_DIR}

        for CONC_NUM in "${ARR_CONC[@]}"
        do
            JOB_NAME=$BFS-$JOB_TYPE$CONC_NUM
            JOB_FILE=$JOB_PATH/$JOB_NAME.fio
            CONT_NAME=$BFS-$JOB_TYPE$CONC_NUM

            if [ "$STORAGE" = "bind" ]
            then
                docker run --name $CONT_NAME \
                           --mount type=bind,source=$PART_PATH,target=$PART_PATH \
                           --mount source=$SRC_VOL,target=$SRC_PATH \
                           $IMAGE $JOB_FILE
            elif [ "$STORAGE" = "volume" ] || [ "$STORAGE" = "container" ]
            then
                docker run --name $CONT_NAME \
                           --mount source=$BFS,target=$PART_PATH \
                           --mount source=$SRC_VOL,target=$SRC_PATH \
                           $IMAGE $JOB_FILE
            fi
        done

        for CONC_NUM in "${ARR_CONC[@]}"
        do
            CONT_NAME=$BFS-$JOB_TYPE$CONC_NUM
            docker wait $CONT_NAME
            docker container stop $CONT_NAME
            docker container rm $CONT_NAME
        done
    done
fi
