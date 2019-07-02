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
ARR_IO_TYPE=["oltp_write_only"]
#ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[16]
ARR_MEM_RATIO=[10]

def main():
	regexTot = re.compile('total\stime:\s*(\d+\.\d+)s') # sec unit
	regexDoSwap = re.compile('do_swap_page\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexSwapWrite = re.compile('swap_writepage\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexDelete = re.compile('delete_from_swap_cache\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexUnmap = re.compile('try_to_unmap\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexAdd = re.compile('add_to_swap\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')

	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			for MEM_RATIO in ARR_MEM_RATIO:
				for SWAP_TYPE in ARR_SWAP_TYPE:
					
					mysql_total = []
					doswap_count, doswap_total, doswap_avg = [],[],[]
					swapwrite_count, swapwrite_total, swapwrite_avg = [],[],[]
					delete_count, delete_total, delete_avg = [],[],[]
					unmap_count, unmap_total, unmap_avg = [],[],[]
					add_count, add_total, add_avg = [],[],[]

					for CONT_ID in range(1, NUM_THREAD + 1): 
						LOG_PATH = "/mnt/data/swap-"+SWAP_TYPE+"/cont-mysql/"+ \
									IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+ \
									"/sysbench"+str(CONT_ID)+".output"

						with open(LOG_PATH) as f:
							f.seek(0)
							for line in f:
								match = regexTot.search(line)
								if match:	
									mysql_total.append(float(match.group(1)))

						FTRACE_PATH = "/mnt/data/swap-"+SWAP_TYPE+"/cont-mysql/"+ \
									IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+ \
									"/trace.output"
						
						with open(FTRACE_PATH) as f:
							f.seek(0)
							for line in f:
								match = regexDoSwap.search(line)
								if match:
									doswap_count.append(float(match.group(1)))
									doswap_total.append(float(match.group(2)))				
									doswap_avg.append(float(match.group(3)))
								match = regexSwapWrite.search(line)
								if match:
									swapwrite_count.append(float(match.group(1)))
									swapwrite_total.append(float(match.group(2)))				
									swapwrite_avg.append(float(match.group(3)))
								match = regexDelete.search(line)
								if match:
									delete_count.append(float(match.group(1)))
									delete_total.append(float(match.group(2)))				
									delete_avg.append(float(match.group(3)))
								match = regexUnmap.search(line)
								if match:
									unmap_count.append(float(match.group(1)))
									unmap_total.append(float(match.group(2)))				
									unmap_avg.append(float(match.group(3)))
								match = regexAdd.search(line)
								if match:
									add_count.append(float(match.group(1)))
									add_total.append(float(match.group(2)))				
									add_avg.append(float(match.group(3)))

					print(IO_TYPE+"-"+str(NUM_THREAD)+"-"+str(SWAP_TYPE)+"-"+str(MEM_RATIO))
					print(str(np.sum(mysql_total)))
					print(str(np.sum(doswap_count))+" "+str(np.sum(doswap_total))+" "+str(np.mean(doswap_avg)))
					print(str(np.sum(swapwrite_count))+" "+str(np.sum(swapwrite_total))+" "+str(np.mean(swapwrite_avg)))
					print(str(np.sum(delete_count))+" "+str(np.sum(delete_total))+" "+str(np.mean(delete_avg)))
					print(str(np.sum(unmap_count))+" "+str(np.sum(unmap_total))+" "+str(np.mean(unmap_avg)))
					print(str(np.sum(add_count))+" "+str(np.sum(add_total))+" "+str(np.mean(add_avg)))

# Begin of program
if __name__ == "__main__":
	main()
