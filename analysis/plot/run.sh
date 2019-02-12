#!/bin/bash
GNUPLOT_FILE=$1
#GNUPLOT_FILE=filetype.gnuplot
##GNUPLOT_FILE=perf.gnuplot
FONT_PATH="/usr/share/fonts/msttcore/"

source ~/.bashrc
gnuplot $GNUPLOT_FILE &> tmp.txt
eog $(head -n 1 tmp.txt)
rm -f tmp.txt
