import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_SWAP_TYPE=["single","multiple"]
ARR_IO_TYPE=["oltp_write_only"]
#ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[64]
ARR_MEM_RATIO=[10]

def main():
#	regexTot = re.compile('total\stime:\s*(\d+\.\d+)s') # sec unit
	regexTot = re.compile('avg:\s*(\d+\.\d+)') # sec unit
	regexReadAhead = re.compile('swapin_readahead\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexReadCache = re.compile('read_swap_cache_async\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexSwapWrite = re.compile('swap_writepage\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexLookup = re.compile('lookup_swap_cache\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexFree = re.compile('swap_free\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexMark = re.compile('mark_page_accessed\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexRmap = re.compile('page_add_anon_rmap\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexDelete = re.compile('delete_from_swap_cache\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexUnmap = re.compile('try_to_unmap\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')
	regexAdd = re.compile('add_to_swap\s*(\d*\.*\d*)\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus\s*(\d*\.*\d*)\sus')

	for IO_TYPE in ARR_IO_TYPE:	
		for NUM_THREAD in ARR_NUM_THREAD:
			for MEM_RATIO in ARR_MEM_RATIO:
				for SWAP_TYPE in ARR_SWAP_TYPE:
					
					mysql_total = []
					swapwrite_count, swapwrite_total, swapwrite_avg = [],[],[]
					readahead_count, readahead_total, readahead_avg = [],[],[]
					readcache_count, readcache_total, readcache_avg = [],[],[]
					lookup_count, lookup_total, lookup_avg = [],[],[]
					free_count, free_total, free_avg = [],[],[]
					mark_count, mark_total, mark_avg = [],[],[]
					rmap_count, rmap_total, rmap_avg = [],[],[]
					delete_count, delete_total, delete_avg = [],[],[]
					unmap_count, unmap_total, unmap_avg = [],[],[]
					add_count, add_total, add_avg = [],[],[]

					for CONT_ID in range(1, NUM_THREAD + 1): 
						LOG_PATH = "/mnt/data/motiv/cont-mysql/"+SWAP_TYPE+"/"+ \
									IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+ \
									"/sysbench"+str(CONT_ID)+".output"

						with open(LOG_PATH) as f:
							f.seek(0)
							for line in f:
								match = regexTot.search(line)
								if match:	
									mysql_total.append(float(match.group(1)))

						FTRACE_PATH = "/mnt/data/motiv/cont-mysql/"+SWAP_TYPE+"/"+ \
									IO_TYPE+"-"+str(NUM_THREAD)+"-ratio"+str(MEM_RATIO)+ \
									"/trace.output"
						
						with open(FTRACE_PATH) as f:
							f.seek(0)
							for line in f:
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
								match = regexReadAhead.search(line)
								if match:
									readahead_count.append(float(match.group(1)))
									readahead_total.append(float(match.group(2)))				
									readahead_avg.append(float(match.group(3)))
								match = regexReadCache.search(line)
								if match:
									readcache_count.append(float(match.group(1)))
									readcache_total.append(float(match.group(2)))				
									readcache_avg.append(float(match.group(3)))
								match = regexLookup.search(line)
								if match:
									lookup_count.append(float(match.group(1)))
									lookup_total.append(float(match.group(2)))				
									lookup_avg.append(float(match.group(3)))
								match = regexFree.search(line)
								if match:
									free_count.append(float(match.group(1)))
									free_total.append(float(match.group(2)))				
									free_avg.append(float(match.group(3)))
								match = regexMark.search(line)
								if match:
									mark_count.append(float(match.group(1)))
									mark_total.append(float(match.group(2)))				
									mark_avg.append(float(match.group(3)))
								match = regexRmap.search(line)
								if match:
									rmap_count.append(float(match.group(1)))
									rmap_total.append(float(match.group(2)))				
									rmap_avg.append(float(match.group(3)))

					print(IO_TYPE+"-"+str(NUM_THREAD)+"-"+str(SWAP_TYPE)+"-"+str(MEM_RATIO))
					print(str(np.mean(mysql_total)))
					print(str(np.sum(add_count))+" "+str(np.sum(add_total))+" "+str(np.mean(add_avg)))
					print(str(np.sum(unmap_count))+" "+str(np.sum(unmap_total))+" "+str(np.mean(unmap_avg)))
					print(str(np.sum(swapwrite_count))+" "+str(np.sum(swapwrite_total))+" "+str(np.mean(swapwrite_avg)))
					print(str(np.sum(delete_count))+" "+str(np.sum(delete_total))+" "+str(np.mean(delete_avg)))
					print(str(np.sum(lookup_count))+" "+str(np.sum(lookup_total))+" "+str(np.mean(lookup_avg)))
					print(str(np.sum(readahead_count))+" "+str(np.sum(readahead_total))+" "+str(np.mean(readahead_avg)))
					print(str(np.sum(readcache_count))+" "+str(np.sum(readcache_total))+" "+str(np.mean(readcache_avg)))
					print(str(np.sum(mark_count))+" "+str(np.sum(mark_total))+" "+str(np.mean(mark_avg)))
					print(str(np.sum(free_count))+" "+str(np.sum(free_total))+" "+str(np.mean(free_avg)))
					print(str(np.sum(rmap_count))+" "+str(np.sum(rmap_total))+" "+str(np.mean(rmap_avg)))

# Begin of program
if __name__ == "__main__":
	main()
