#!/usr/local/bin/gnuplot -p
set macros
set loadpath '~/.gnuplot/config'
set fontpath '/usr/share/fonts/msttcore'

### Variables
FILE_PATH="/mnt/resource/xfs-volume/fio-CONTs-NS1/"
#ARR_JOB_TYPE="randread read randwrite write"
ARR_JOB_TYPE="read randwrite write"
Y1COLOR="#000000"
Y2COLOR="#5060D0"
BS="4K"

ARR_PERF_TYPE="bw lat"
ARR_QD="1 4 32"
PLOT_TYPE="multiple"

### MACROS
plot="u 2:xticlabels(1) w lp"
X11="set term x11 enhanced size 900,600 font 'arial,24' persist"

### Configuration
set style line 80 lt 4 lc rgb "#808081"
set style line 81 lt 0 lc rgb "#808080" lw 1 
set border ls 80
set grid back ls 81
set ytics nomirror
set xlabel "Number of Container" textcolor rgb Y1COLOR

### Custom Configuration
set style line 1 lt 1 lc rgb "#A00000" lw 1 pt 7 ps 2
set style line 2 lt 1 lc rgb "#00A000" lw 1 pt 11 ps 2

do for [perf_id=1:words(ARR_PERF_TYPE)]{
    if (perf_id == 1) {
        set key right top; set ylabel "Per-container bandwidth (MB/s)"
    } else {
        set key left top; set ylabel "Per-container latency (us)"
    }

    TITLE=sprintf("fio-CONTs-NS1-BS%s",BS)
    FILE_PNG=sprintf("/mnt/resource/xfs-volume/images/sameAPP-%s.png",word(ARR_PERF_TYPE,perf_id))

    set term png enhanced size 900,600 font 'arial,12'
    set output FILE_PNG
    set multiplot layout 2,2 title TITLE

    do for [job_id=1:words(ARR_JOB_TYPE)]{
        TITLE1=sprintf("%s",word(ARR_JOB_TYPE,job_id))
        set title TITLE1
        plot for [qd_id=1:words(ARR_QD)] sprintf("%s%s-sameAPP-diffFile-QD%s-%s.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_QD,qd_id),word(ARR_PERF_TYPE,perf_id)) @plot ls qd_id t "QD".word(ARR_QD,qd_id) 
    }
    unset multiplot

    print FILE_PNG
} 
