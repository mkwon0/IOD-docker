import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_NUM_DEV=[1, 2, 4]
ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[4, 16, 64, 256]

def main():
	for IO_TYPE in ARR_IO_TYPE:
		for NUM_DEV in ARR_NUM_DEV:
			read_ratio = {}
			for NUM_THREAD in ARR_NUM_THREAD:
				read_ratio[NUM_THREAD] = {}
				for DEV_ID in range(1,NUM_DEV+1):
					BLKPARSE_PATH = "/mnt/data/motiv/cont-mysql/NS"+str(NUM_DEV)+"/"+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/blktrace-nvme1n"+str(DEV_ID)+".log"
					write_cnt, read_cnt = 0,0
					with open(BLKPARSE_PATH) as f:
						f.seek(0)
						for line in f:
							line1=line.replace(" ","").split(",")
							if "CPU" in line1[0]:
								break
							if line1[3] == 'D':
								if "R" in line1[4]:
									read_cnt+=1
								elif "W" in line1[4]:
									write_cnt+=1
					read_ratio[NUM_THREAD][DEV_ID]=float(read_cnt)/(float(read_cnt)+float(write_cnt))

			print(IO_TYPE+" "+str(NUM_DEV))
			print(p.DataFrame(read_ratio).T)					

# Begin of program
if __name__ == "__main__":
	main()
