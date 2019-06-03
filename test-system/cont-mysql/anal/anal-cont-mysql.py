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
	LOG_PATH = "/mnt/data/test/cont-mysql/oltp_write_only-1/systap-nvme1n2.log"
	arr0, arr1 = [],[]

	with open(LOG_PATH) as f:
		f.seek(0)
		for line in f:
			line=re.sub(' +',' ',line)
			line=line.split(" ")
#			print(line)

			if "logfile0" in line[7]:
				arr0.append(float(line[5]))
			
			if "logfile1" in line[7]:
				arr1.append(float(line[5]))

	print(np.min(arr0))
	print(np.mean(arr0))
	print(np.max(arr0))

	print(np.min(arr1))
	print(np.mean(arr1))
	print(np.max(arr1))

# Begin of program
if __name__ == "__main__":
	main()
