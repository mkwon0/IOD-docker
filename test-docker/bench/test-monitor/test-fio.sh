#/bin/bash
source variablegen

### Job File Generation
if [ "$GEN_JOB_FILE_WORK" = 1 ]
then
    echo "********** FIO JOB_FILE GENERATION **********"
    rm -rf $JOB_PATH/*

    ### For raw device test
    BFS=raw
    for JOB_TYPE in "${ARR_JOB[@]}"
    do
        ORIG_JOB=$ORIG_JOB_PATH/$JOB_TYPE.fio
        for NUM_CONC in "${ARR_CONC[@]}"
        do
            FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$NUM_CONC/$NS/$TARGET/$JOB_TYPE
            mkdir -p $FIOSRC_PATH
            for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))  
            do
                JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                JOB_FILE=$JOB_PATH/$JOB_NAME.fio
                PART_DIR=${DEV_NAME}-${BFS}

                if [ -f "$JOB_FILE" ]
                then
                    rm -f $JOB_FILE
                fi

                sed '/filename/c\directory=/mnt/'$PART_DIR'' $ORIG_JOB > $JOB_FILE
                sed -i '/write_bw_log/c\write_bw_log='$FIOSRC_PATH'/logfile'$CONC_ID'' $JOB_FILE
                sed -i '/write_lat_log/c\write_lat_log='$FIOSRC_PATH'/logfile'$CONC_ID'' $JOB_FILE

            done
        done
    done

    ### For filesystem test
    for (( FS_IDX=1; FS_IDX < ${#ARR_FS[@]}; ++FS_IDX ))
    do
        part=$((FS_IDX+1))
        BFS=${ARR_FS[FS_IDX]}
        PART_DIR=${DEV_NAME}-${BFS}

        for JOB_TYPE in "${ARR_JOB[@]}"
        do
            ORIG_JOB=$ORIG_JOB_PATH/$JOB_TYPE.fio
            for NUM_CONC in "${ARR_CONC[@]}"
            do
                FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$NUM_CONC/$NS/$TARGET/$JOB_TYPE
                mkdir -p $FIOSRC_PATH
                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_BUF_NAME=${BFS}-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE=$JOB_PATH/${JOB_NAME}.fio
                    JOB_FILE_BUF=$JOB_PATH/${JOB_BUF_NAME}.fio

                    if [ -f "$JOB_FILE" ]
                    then
                        rm -f $JOB_FILE
                    fi

                    if [ -f "$JOB_FILE_BUF" ]
                    then
                        rm -f $JOB_FILE_BUF
                    fi

                    sed '/filename/c\filename=/mnt/'$PART_DIR'/text'$CONC_ID'' $ORIG_JOB > $JOB_FILE
                    sed -i '/write_bw_log/c\write_bw_log='$FIOSRC_PATH'/logfile'$CONC_ID'' $JOB_FILE
                    sed -i '/write_lat_log/c\write_lat_log='$FIOSRC_PATH'/logfile'$CONC_ID'' $JOB_FILE

                    sed '/filename/c\filename=/mnt/'$PART_DIR'/text'$CONC_ID'' $ORIG_JOB > $JOB_FILE_BUF
                    sed -i '/direct/c\direct=0' $JOB_FILE_BUF
                    sed -i '/write_bw_log/c\write_bw_log='$FIOSRC_PATH'/logfile'$CONC_ID'-buf' $JOB_FILE_BUF
                    sed -i '/write_lat_log/c\write_lat_log='$FIOSRC_PATH'/logfile'$CONC_ID'-buf' $JOB_FILE_BUF
                done
            done
        done
    done
fi

### Fio execution
if [ "$RUN_BIND" = 1 ]
then
    echo "********** FIO JOB EXECUTION **********"
    for (( FS_IDX=1; FS_IDX < ${#ARR_FS[@]}; ++FS_IDX ))
    do
        part=$((FS_IDX+1))
        BFS=${ARR_FS[FS_IDX]}
        PART_DIR=${DEV_NAME}-${BFS}
        PART_PATH=/mnt/${PART_DIR}

        for JOB_TYPE in "${ARR_JOB[@]}"
        do
            for NUM_CONC in "${ARR_CONC[@]}"
            do
                FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$NUM_CONC/$NS/$TARGET/$JOB_TYPE

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE=$JOB_PATH/${JOB_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}

                    docker run --name $JOB_NAME \
                               --mount type=bind,source=$PART_PATH,target=$PART_PATH \
                               --mount source=$SRC_VOL,target=$SRC_PATH \
                               -e JOBFILES=$JOB_FILE \
                               $IMAGE > $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_NAME
                    docker container rm $JOB_NAME
                done

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE_BUF=$JOB_PATH/${JOB_BUF_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}-buf

                    docker run --name $JOB_BUF_NAME \
                               --mount type=bind,source=$PART_PATH,target=$PART_PATH \
                               --mount source=$SRC_VOL,target=$SRC_PATH \
                               -e JOBFILES=$JOB_FILE_BUF \
                               $IMAGE > $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_BUF_NAME
                    docker container rm $JOB_BUF_NAME
                done
            done
        done
    done
fi

### Fio execution
if [ "$RUN_VOLUME" = 1 ]
then
    echo "********** FIO JOB EXECUTION **********"
    for (( FS_IDX=1; FS_IDX < ${#ARR_FS[@]}; ++FS_IDX ))
    do
        part=$((FS_IDX+1))
        BFS=${ARR_FS[FS_IDX]}
        PART_DIR=${DEV_NAME}-${BFS}
        PART_PATH=/mnt/${PART_DIR}

        for JOB_TYPE in "${ARR_JOB[@]}"
        do
            for NUM_CONC in "${ARR_CONC[@]}"
            do
                FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$NUM_CONC/$NS/$TARGET/$JOB_TYPE

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE=$JOB_PATH/${JOB_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}

                    docker run --name $JOB_NAME \
                               --mount source=$BFS,target=$PART_PATH \
                               --mount source=$SRC_VOL,target=$SRC_PATH \
                               -e JOBFILES=$JOB_FILE \
                               $IMAGE $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_NAME
                    docker container rm $JOB_NAME
                done

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE_BUF=$JOB_PATH/${JOB_BUF_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}-buf

                    docker run --name $JOB_BUF_NAME \
                               --mount source=$BFS,target=$PART_PATH \
                               --mount source=$SRC_VOL,target=$SRC_PATH \
                               -e JOBFILES=$JOB_FILE_BUF \
                               $IMAGE > $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_BUF_NAME
                    docker container rm $JOB_BUF_NAME
                done
            done
        done
    done
fi


### Fio execution
if [ "$RUN_CONTAINER" = 1 ]
then
    echo "********** FIO JOB EXECUTION **********"
    for (( FS_IDX=1; FS_IDX < ${#ARR_FS[@]}; ++FS_IDX ))
    do
        part=$((FS_IDX+1))
        BFS=${ARR_FS[FS_IDX]}
        PART_DIR=${DEV_NAME}-${BFS}
        PART_PATH=/mnt/${PART_DIR}

        for JOB_TYPE in "${ARR_JOB[@]}"
        do
            for NUM_CONC in "${ARR_CONC[@]}"
            do
                FIOSRC_PATH=$SRC_PATH/$DEV/$BFS/$WORK/$STORAGE/conc$NUM_CONC/$NS/$TARGET/$JOB_TYPE
                VOLCONT=volume-container

                docker run -d --name $VOLCONT \
                           --mount source=$BFS,target=$PART_PATH \
                           --mount source=$SRC_VOL,target=$SRC_PATH \
                           ubuntu

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE=$JOB_PATH/${JOB_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}

                    docker run --name $JOB_NAME \
                               --volumes-from=$VOLCONT \
                               -e JOBFILES=$JOB_FILE \
                               $IMAGE > $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_NAME=$BFS-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_NAME
                    docker container rm $JOB_NAME
                done

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    JOB_FILE_BUF=$JOB_PATH/${JOB_BUF_NAME}.fio
                    FIO_LOG=$FIOSRC_PATH/fiolog${CONC_ID}-buf

                    docker run --name $JOB_BUF_NAME \
                               --volumes-from=$VOLCONT \
                               -e JOBFILES=$JOB_FILE_BUF \
                               $IMAGE > $FIO_LOG &
                done
                wait

                for (( CONC_ID=1; CONC_ID <= $NUM_CONC; ++CONC_ID ))
                do
                    JOB_BUF_NAME=$BFS-buf-conc$NUM_CONC-$JOB_TYPE$CONC_ID
                    docker container stop $JOB_BUF_NAME
                    docker container rm $JOB_BUF_NAME
                done
                docker container stop $VOLCONT
            done
        done
    done
fi
