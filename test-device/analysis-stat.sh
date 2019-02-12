#!/bin/bash

python analysis-stat.py results-interf/resultD2V2-read.txt stat read
python analysis-stat.py results-interf/resultD2V3-read.txt stat read
python analysis-stat.py results-interf/resultD2V4-read.txt stat read
python analysis-stat.py results-interf/resultD2V2-randread.txt stat randread
python analysis-stat.py results-interf/resultD2V3-randread.txt stat randread
python analysis-stat.py results-interf/resultD2V4-randread.txt stat randread
python analysis-stat.py results-interf/resultD2V2-write.txt stat write
python analysis-stat.py results-interf/resultD2V3-write.txt stat write
python analysis-stat.py results-interf/resultD2V4-write.txt stat write
python analysis-stat.py results-interf/resultD2V2-randwrite.txt stat randwrite
python analysis-stat.py results-interf/resultD2V3-randwrite.txt stat randwrite
python analysis-stat.py results-interf/resultD2V4-randwrite.txt stat randwrite
