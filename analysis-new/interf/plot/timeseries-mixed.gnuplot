#!/usr/bin/gnuplot -p
set macros
set loadpath '~/.gnuplot/color4'
set fontpath '/usr/share/fonts/msttcore'

## MACROS
FONT="arial,22"

## Frame info
set term png enhanced size 900,600 font FONT 
set style line 81 lt 0 lc rgb '#808080' lw 1
set grid back ls 81

## Target specific variables
ARR_JOB_TYPE="rw randrw"
ARR_TARGET_TYPE="bw lat"
ARR_TYPE="read write"
ARR_RATIO="10 20 30 40 50 60 70 80 90"

## User defined plot info
XLABEL="Timeline (ms)"
#YLABEL="Bandwidth (MB/s)"
INPUT_PATH="/mnt/data/resource/Interf-noCache"
OUTPUT_PATH="/mnt/data/resource/Interf-noCache"

## Page info
Y1COLOR="#000000"
Y2COLOR="#5060D0"
set ytics nomirror
set xlabel XLABEL textcolor rgb Y1COLOR
#set ylabel YLABEL textcolor rgb Y1COLOR

set key out horiz center top

## Plot graph
do for [job_id=1:words(ARR_JOB_TYPE)] {
	do for [target_id=1:words(ARR_TARGET_TYPE)]{
		do for [ratio_id=1:words(ARR_RATIO)]{
			do for [type_id=1:words(ARR_TYPE)]{
				FILE_PNG=sprintf("%s/figs-mixed/timeseries-%s-RATIO%s-%s-QD1-BS4k-%s.png",OUTPUT_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_RATIO,ratio_id),word(ARR_TYPE,type_id),word(ARR_TARGET_TYPE,target_id))
				TITLE=sprintf("figs-mixed/timeseries-%s-RATIO%s-%s-QD1-BS4k-%s",word(ARR_JOB_TYPE,job_id),word(ARR_RATIO,ratio_id),word(ARR_TYPE,type_id),word(ARR_TARGET_TYPE,target_id))
				INPUT=sprintf("%s/%s-QD1-BS4k/READ_RATIO%s/timeseries%s-%s.dat",INPUT_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_RATIO,ratio_id),word(ARR_TARGET_TYPE,target_id),word(ARR_TYPE,type_id))
				if (target_id == 1) {
					YLABEL="Bandwidth (MB/s)"
				} else {
					YLABEL="Latency (us)"
				}
	
				set output FILE_PNG
				set title TITLE
				set ylabel YLABEL textcolor rgb Y1COLOR
				plot for [col=2:5] INPUT u 1:col w lp ls (col-1) t "NS".(col-1)
				print FILE_PNG
			}
		}
	}
}
