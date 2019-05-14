import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as pd

ARR_NUM_DEV=[1, 2, 4]
ARR_IO_TYPE=["read", "randread", "write", "randwrite"]
ARR_NUM_THREAD=[4, 16, 64, 256, 512]


def cal_avg(TIME_DIR,NUM_THREAD,ANAL_TYPE):
	all_val=[]
	for CONT_ID in range(1,NUM_THREAD+1):
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
	for IO_TYPE in ARR_IO_TYPE:
		avg_lat, avg_bw = {}, {}
		for NUM_DEV in ARR_NUM_DEV:
			avg_lat[NUM_DEV], avg_bw[NUM_DEV] = {}, {}
			RESULT_DIR="/mnt/data/motiv/cont-fio/NS"+str(NUM_DEV)+"/"
			for NUM_THREAD in ARR_NUM_THREAD:
				INTERNAL_DIR=RESULT_DIR+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/"
				TIME_DIR=INTERNAL_DIR+"timelog/"

				avg_bw[NUM_DEV][NUM_THREAD]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,"bw")
				avg_lat[NUM_DEV][NUM_THREAD]="%.2f" % cal_avg(TIME_DIR,NUM_THREAD,"lat")

		print(pd.DataFrame(avg_bw).T)
		print(pd.DataFrame(avg_lat).T)

# Begin of program
if __name__ == "__main__":
	main()
