import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_SWAP_TYPE=["public","private"]
ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[64, 128]
ARR_MEM_RATIO=[10, 20, 30]

def main():
	regexAvg = re.compile('avg:\s*(\d+\.\d+)') # ms unit
	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			for MEM_RATIO in ARR_MEM_RATIO:
				arr = []
				for CONT_ID in range(1, NUM_THREAD + 1): 
					LOG_PATH = "/mnt/data/motiv-old/cont-mysql/"+ \
								IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+"/sysbench"+str(CONT_ID)+".output"

					with open(LOG_PATH) as f:
						f.seek(0)
						for line in f:
							match = regexAvg.search(line)
							if match:	
								arr.append(float(match.group(1)))

				print(IO_TYPE+"-"+str(NUM_THREAD)+"-"+str(MEM_RATIO),end="\n")
#				print("motiv "+str(np.mean(arr))+" "+str(np.std(arr)))
				for i in range(NUM_THREAD):
					print(arr[i],end=" ")

# Begin of program
if __name__ == "__main__":
	main()
