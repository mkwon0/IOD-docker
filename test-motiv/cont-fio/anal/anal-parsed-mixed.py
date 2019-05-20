import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as pd

NUM_DEV=4
ARR_READ_RATIO=[25, 50, 75]
ARR_DEV_SEL=["SS","RR"]
ARR_NUM_THREAD=[4, 16, 64, 256]

def cal_avg(TIME_DIR,NUM_THREAD,READ_RATIO,ANAL_TYPE,RW_TYPE):
	all_val=[]
	NUM_READ=int(NUM_THREAD*READ_RATIO/100)
	if RW_TYPE == "read":
		for CONT_ID in range(1,NUM_READ+1):
			anal_file=TIME_DIR+"ID"+str(CONT_ID)+"_"+str(ANAL_TYPE)+".1.log.parsed"
			cont_val=[]
			with open(anal_file) as f:
				f.seek(0)
				for line in f:
					line.split(",")
					cont_val.append(float(line.split(",")[1]))
			all_val.append(np.mean(cont_val))
	elif RW_TYPE == "write":
		for CONT_ID in range(NUM_READ+1,NUM_THREAD+1):
			anal_file=TIME_DIR+"ID"+str(CONT_ID)+"_"+str(ANAL_TYPE)+".1.log.parsed"
			cont_val=[]
			with open(anal_file) as f:
				f.seek(0)
				for line in f:
					line.split(",")
					cont_val.append(float(line.split(",")[1]))
			all_val.append(np.mean(cont_val))

	return np.mean(all_val)

def main():
	RESULT_DIR="/mnt/data/motiv/cont-fio/NS"+str(NUM_DEV)+"/"
	for DEV_SEL in ARR_DEV_SEL:
		read_avg_lat, read_avg_bw = {}, {}
		write_avg_lat, write_avg_bw = {}, {}
		for NUM_THREAD in ARR_NUM_THREAD:
			read_avg_lat[NUM_THREAD], read_avg_bw[NUM_THREAD] = {}, {}
			write_avg_lat[NUM_THREAD], write_avg_bw[NUM_THREAD] = {}, {}
			for READ_RATIO in ARR_READ_RATIO:
				INTERNAL_DIR=RESULT_DIR+"SRxSW-"+str(READ_RATIO)+"-"+str(DEV_SEL)+"-"+str(NUM_THREAD)+"/"
				TIME_DIR=INTERNAL_DIR+"timelog/"

				read_avg_bw[NUM_THREAD][READ_RATIO]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,READ_RATIO,"bw","read")
				read_avg_lat[NUM_THREAD][READ_RATIO]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,READ_RATIO,"lat","read")
				write_avg_bw[NUM_THREAD][READ_RATIO]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,READ_RATIO,"bw","write")
				write_avg_lat[NUM_THREAD][READ_RATIO]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,READ_RATIO,"lat","write")

		print(pd.DataFrame(read_avg_bw).T)
		print(pd.DataFrame(write_avg_bw).T)
		print(pd.DataFrame(read_avg_lat).T)
		print(pd.DataFrame(write_avg_lat).T)

# Begin of program
if __name__ == "__main__":
	main()
