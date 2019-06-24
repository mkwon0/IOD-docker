import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

ARR_SWAP_TYPE=["public","private"]
ARR_IO_TYPE=["simple"]
ARR_NUM_THREAD=[16]

def main():
	regexAvg = re.compile('id:\stest-\d*-\d*,\sreceiving\srate\savg:\s(\d+)')
	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			arr0, arr1 = [],[]	
			for SWAP_TYPE in ARR_SWAP_TYPE:
				for CONT_ID in range(1, NUM_THREAD + 1): 
					LOG_PATH = "/mnt/data/swap-"+SWAP_TYPE+"/cont-rabbitmq/"+ \
								IO_TYPE+"-"+str(NUM_THREAD)+"/output"+str(CONT_ID)+".txt"

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
			print("public "+str(np.mean(arr0))+" "+str(np.std(arr0)))
			print("private "+str(np.mean(arr1))+" "+str(np.std(arr1)))

# Begin of program
if __name__ == "__main__":
	main()
