import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

ARR_NUM_DEV=[1, 2, 4]
ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[4, 16, 64, 256]

def main():
	regexBW = re.compile('Throughput\s*\(R/W\):\s*(\d*,*\d*)[K,M,G]iB/s\s*/\s*(\d*,*\d*)[K,M,G]iB/s')
	for IO_TYPE in ARR_IO_TYPE:
		for NUM_DEV in ARR_NUM_DEV:
			read_bw = {}
			write_bw = {}
			for NUM_THREAD in ARR_NUM_THREAD:
				read_bw[NUM_THREAD] = {}
				write_bw[NUM_THREAD] = {}

				for DEV_ID in range(1,NUM_DEV+1):
					LOG_PATH = "/mnt/data/motiv/cont-mysql/NS"+str(NUM_DEV)+"/"+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/blktrace-nvme1n"+str(DEV_ID)+".log"
					with open(LOG_PATH) as f:
						f.seek(0)
						for line in f:
							match = regexBW.search(line)
							if match:
								read_bw[NUM_THREAD][DEV_ID]=float(match.group(1).replace(",",""))
								write_bw[NUM_THREAD][DEV_ID]=float(match.group(2).replace(",",""))
			print(IO_TYPE+" "+str(NUM_DEV)+" read bandwidth")
			print(p.DataFrame(read_bw).T)
			print(IO_TYPE+" "+str(NUM_DEV)+" write bandwidth")
			print(p.DataFrame(write_bw).T)

# Begin of program
if __name__ == "__main__":
	main()
