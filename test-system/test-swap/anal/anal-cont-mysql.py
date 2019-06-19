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
ARR_IO_TYPE=["oltp_read_only"]
ARR_NUM_THREAD=[64]

#ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
#ARR_NUM_THREAD=[4, 16, 64, 256]

def main():
	regexAvg = re.compile('avg:\s*(\d+\.\d+)') # ms unit
	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			arr0, arr1 = [],[]	
			for SWAP_TYPE in ARR_SWAP_TYPE:
				for CONT_ID in range(1, NUM_THREAD + 1): 
					LOG_PATH = "/mnt/data/swap-"+SWAP_TYPE+"/cont-mysql/"+ \
								IO_TYPE+"-"+str(NUM_THREAD)+"/sysbench"+str(CONT_ID)+".output"

					with open(LOG_PATH) as f:
						f.seek(0)
						for line in f:
							match = regexAvg.search(line)
							if match:	
								if SWAP_TYPE == "public":
									arr0.append(float(match.group(1)))
								else:
									arr1.append(float(match.group(1)))

			print(IO_TYPE+"-"+str(NUM_THREAD))
			print("public "+str(np.mean(arr0)))
			print("private "+str(np.mean(arr1)))

# Begin of program
if __name__ == "__main__":
	main()
