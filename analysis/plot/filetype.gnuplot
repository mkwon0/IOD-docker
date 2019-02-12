#!/usr/local/bin/gnuplot -p
set macros
set loadpath '~/.gnuplot/config'
set fontpath '/usr/share/fonts/msttcore'
#load 'x1y2.cfg'

### Variables
FILE_PATH="/mnt/resource/xfs-volume/fio-CONTs-NS1/"
ARR_JOB_TYPE="randread read randwrite write"
#ARR_PERF_TYPE="bw lat"
#ARR_FILE_TYPE="same diff"
Y1COLOR="#000000"
Y2COLOR="#5060D0"
#PLOT_TYPE="single"
QD="32-old"
revisedQD="32"
BS="4K"

#ARR_JOB_TYPE="randread"
ARR_PERF_TYPE="bw lat"
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
if (PLOT_TYPE eq "single"){
    set style line 1 lt 1 lc rgb "#A00000" lw 4 pt 7 ps 3
    set style line 2 lt 1 lc rgb "#00A000" lw 4 pt 11 ps 3

    do for [job_id=1:words(ARR_JOB_TYPE)] {
        do for [perf_id=1:words(ARR_PERF_TYPE)]{
            TITLE=sprintf("fio-CONTs-NS1 (%s)",word(ARR_JOB_TYPE,job_id))
            FILE_SAME=sprintf("%s%s-sameAPP-sameFile-QD%s-%s.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),QD,word(ARR_PERF_TYPE,perf_id))
            FILE_DIFF=sprintf("%s%s-sameAPP-diffFile-QD%s-%s.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),QD,word(ARR_PERF_TYPE,perf_id))
            FILE_PNG=sprintf("/mnt/resource/xfs-volume/images/%s-sameAPP-%s.png",\
                            word(ARR_JOB_TYPE,job_id),word(ARR_PERF_TYPE,perf_id))

            if (perf_id == 1) {
                set key right top; set ylabel "Per-container bandwidth (MB/s)"
            } else {
                set key left top; set ylabel "Per-container latency (us)"
            }

            print FILE_SAME
            print FILE_DIFF

            set term png enhanced size 900,600 font 'arial,24'
            set output FILE_PNG
            set title TITLE
            plot FILE_SAME @plot ls 1 t 'Same file', FILE_DIFF @plot ls 3 t 'Diff file'

            print FILE_PNG
            @X11
            set output
            replot
        }
    }
} else {
    set style line 1 lt 1 lc rgb "#A00000" lw 1 pt 7 ps 2
    set style line 2 lt 1 lc rgb "#00A000" lw 1 pt 11 ps 2

    do for [perf_id=1:words(ARR_PERF_TYPE)]{
        if (perf_id == 1) {
            set key right top; set ylabel "Per-container bandwidth (MB/s)"
        } else {
            set key left top; set ylabel "Per-container latency (us)"
        }

        TITLE=sprintf("fio-CONTs-NS1-QD%s-BS%s",revisedQD,BS)
        FILE_PNG=sprintf("/mnt/resource/xfs-volume/images/sameAPP-%s.png",word(ARR_PERF_TYPE,perf_id))

        set term png enhanced size 900,600 font 'arial,12'
        set output FILE_PNG
        set multiplot layout 2,2 title TITLE

        do for [job_id=1:words(ARR_JOB_TYPE)]{
            TITLE1=sprintf("%s",word(ARR_JOB_TYPE,job_id))
            FILE_SAME=sprintf("%s%s-sameAPP-sameFile-QD%s-%s.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),QD,word(ARR_PERF_TYPE,perf_id))
            FILE_DIFF=sprintf("%s%s-sameAPP-diffFile-QD%s-%s.dat",FILE_PATH,word(ARR_JOB_TYPE,job_id),QD,word(ARR_PERF_TYPE,perf_id))
            set title word(ARR_JOB_TYPE,job_id)
            plot FILE_SAME @plot ls 1 t 'Same file', FILE_DIFF @plot ls 3 t 'Diff file'
        }
        unset multiplot

        print FILE_PNG
   } 
}
