#!/usr/local/bin/gnuplot -p
set macros
set loadpath '~/.gnuplot/config'
set fontpath '/usr/share/fonts/msttcore'
#load 'x1y2.cfg'

### Variables
FILE_PATH="/mnt/resource/xfs-volume/fio-CONTs-NS1/"
#ARR_JOB_TYPE="randread read randwrite write"
ARR_JOB_TYPE="read randwrite write"
#ARR_FILE_TYPE="same diff"
#ARR_PERF_TYPE="bw lat"
Y1COLOR="#000000"
Y2COLOR="#5060D0"
QD="4"

#ARR_JOB_TYPE="randread"
ARR_FILE_TYPE="diff"
ARR_PERF_TYPE="bw lat"

PLOT_TYPE="multiple"

### MACROS
plot="u 2:xticlabels(1)"
plote="u 1:2:3" 
#plot="u 0:2 w lp"
PS="set term postscript enhanced size 900,600 font 'arial,24'"
PNG="set term png enhanced size 900,600"
X11="set term x11 enhanced size 900,600 font'arial,24' persist"
LW="lw 4"
PS="ps 3"

### Configuration
set style line 80 lt 4 lc rgb "#808081"
set style line 81 lt 0 lc rgb "#808080" lw 0.5
set style line 1 lt 1 lc rgb "#A00000" @LW pt 7 @PS
set style line 2 lt 1 lc rgb "#00A000" @LW pt 11 @PS
set style line 3 lt 1 lc rgb "#5060D0" @LW pt 9 @PS
set style line 4 lt 1 lc rgb "#0000A0" @LW pt 8 @PS
set style line 5 lt 1 lc rgb "#D0D000" @LW pt 13 @PS
set style line 6 lt 1 lc rgb "#00D0D0" @LW pt 12 @PS
set style line 7 lt 1 lc rgb "#B200B2" @LW pt 5 @PS

set grid back ls 81
unset key
set ytics nomirror
set xlabel "Number of Container" textcolor rgb Y1COLOR
set ylabel "Bandwidth (MB/s)" textcolor rgb Y1COLOR
set y2label "Latency (us)" textcolor rgb Y2COLOR
set y2tics textcolor rgb Y2COLOR

### Custom Configuration
if (PLOT_TYPE eq "single"){
    do for [job_id=1:words(ARR_JOB_TYPE)] {
        do for [file_id=1:words(ARR_FILE_TYPE)]{
            TITLE=sprintf("fio-CONTs-NS1-sameAPP(%s)-%sFile",word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE,file_id))
            FILE_BW=sprintf("%s%s-sameAPP-%sFile-QD%s-bw.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE,file_id),QD)
            FILE_LAT=sprintf("%s%s-sameAPP-%sFile-QD%s-lat.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE,file_id),QD)
            FILE_PNG=sprintf("/mnt/resource/xfs-volume/images/%s-sameAPP-%sFile-QD%s.png",\
                            word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE,file_id),QD)

            @PNG
            set output FILE_PNG
            set title TITLE
            plot FILE_BW @plot ls 1, FILE_LAT @plot ls 3 axis x1y2

            print FILE_PNG
#        @X11
#        set output
#        replot
        }
    }
} else {
    reset
    Y1COLOR="#000000"
    Y2COLOR="#5060D0"
    unset key
    set style line 1 lt 1 lc rgb "#A00000" lw 1 pt 7 ps 2
    set style line 3 lt 1 lc rgb "#5060D0" lw 1 pt 11 ps 2
    set xlabel "Number of Container" textcolor rgb Y1COLOR
    set ytics nomirror
    set y2tics textcolor rgb Y2COLOR
    TITLE=sprintf("fio-CONTs-NS1-sameAPP-QD%s",QD)
    FILE_PNG=sprintf("/mnt/resource/xfs-volume/images/sameAPP-QD%s.png",QD)
    set term png enhanced size 900,600 font 'arial,12'
    set output FILE_PNG
    set multiplot layout 2,2 title TITLE
    do for [job_id=1:words(ARR_JOB_TYPE)]{
        do for [file_id=1:words(ARR_FILE_TYPE)]{
            TITLE1=sprintf("%s",word(ARR_JOB_TYPE,job_id))
            FILE_BW=sprintf("%s%s-sameAPP-%sFile-QD%s-bw.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE, file_id),QD)
            FILE_LAT=sprintf("%s%s-sameAPP-%sFile-QD%s-lat.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_FILE_TYPE,file_id),QD)

            set title TITLE1
            set ylabel "Bandwidth (MB/s)" textcolor rgb Y1COLOR
            set y2label "Latency (us)" textcolor rgb Y2COLOR
            plot FILE_BW u 2:xticlabels(1) w lp ls 1 t 'bandwidth', \
                FILE_LAT u 2:xticlabels(1) w lp ls 3 t 'latency'
#            plot FILE_BW u 1:2:3 w errorlines ls 1 t 'Bandwidth', \
#                FILE_LAT u 1:2:3 w errorlines ls 3 t 'Latency'

#            set ylabel "Bandwidth (MB/s)" textcolor rgb Y1COLOR
#            plot FILE_BW u 0:2:3 w errorlines ls 1 t 'Bandwidth'

#            set ylabel "Latency (us)" textcolor rgb Y2COLOR
#            plot FILE_LAT u 1:2:3 w errorlines ls 3 t 'Latency'

        }
    }
    unset multiplot
    print FILE_PNG
}
