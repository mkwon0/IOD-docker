ARR_JOB_TYPE="randread read randwrite write"
ARR_APP_TYPE="same diff"
ARR_FILE_TYPE="same diff"
ARR_PERF_TYPE="bw lat"
ARR_READ_RATIO="10 20 30 40 50 60 70 80 90"

do for [app_id=1:words(ARR_APP_TYPE)]{
    if ( word(ARR_APP_TYPE,app_id) == "same" ) {
        do for [job_id=1:words(ARR_JOB_TYPE)]{
            print word(ARR_JOB_TYPE,job_id)
        }
    } else {
        do for [read_ratio_id=1:words(ARR_READ_RATIO)]{
            print word(ARR_READ_RATIO,read_ratio_id)
        }
    }
}
