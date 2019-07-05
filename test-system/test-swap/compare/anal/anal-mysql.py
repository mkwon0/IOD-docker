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
ARR_IO_TYPE=["oltp_write_only", "oltp_read_only"]
ARR_NUM_THREAD=[64,128]
ARR_MEM_RATIO=[20,30]

#ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
#ARR_NUM_THREAD=[4, 16, 64, 256]

def main():
#	regexAvg = re.compile('avg:\s*(\d+\.\d+)') # ms unit
	regexAvg = re.compile('total time:\s*(\d+\.\d+)') # ms unit
#	regexAvg = re.compile('95th percentile:\s*(\d+\.\d+)') # ms unit
	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			for MEM_RATIO in ARR_MEM_RATIO:
				gap0, gap1, gap2, gap3, gap = [],[],[],[],[]
				for CONT_ID in range(1, NUM_THREAD + 1):
					tmp = (CONT_ID-1)%4
					for SWAP_TYPE in ARR_SWAP_TYPE:
						LOG_PATH = "/mnt/data/swap-"+SWAP_TYPE+"/cont-mysql/"+ \
									IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+"/sysbench"+str(CONT_ID)+".output"

						if os.path.isfile(LOG_PATH):
							with open(LOG_PATH) as f:
								f.seek(0)
								for line in f:
									match = regexAvg.search(line)
									if match:	
										if SWAP_TYPE == "public":
											val_public=float(match.group(1))
										else:
											val_private=float(match.group(1))

					gap.append(val_public-val_private)
					if tmp == 0:
						gap0.append(val_public-val_private)
					elif tmp == 1:
						gap1.append(val_public-val_private)
					elif tmp == 2:
						gap2.append(val_public-val_private)
					else:
						gap3.append(val_public-val_private)
					
				if len(gap) != NUM_THREAD:
					print(IO_TYPE+" "+str(NUM_THREAD)+" "+str(MEM_RATIO)+" wrong value!!!!!!!!!!!!!!!!!")

#				print(IO_TYPE+" "+str(NUM_THREAD)+" "+str(MEM_RATIO)+" NS0 NS1 NS2 NS3 TOT")
				print(IO_TYPE+" "+str(NUM_THREAD)+" "+str(MEM_RATIO)+" "+str(np.mean(gap0))+" "+str(np.mean(gap1))+" "+str(np.mean(gap2))+" "+str(np.mean(gap3))+" "+str(np.mean(gap)))
					

# Begin of program
if __name__ == "__main__":
	main()
