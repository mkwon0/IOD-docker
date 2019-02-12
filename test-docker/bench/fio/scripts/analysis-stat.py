import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import scipy.stats as stats
import numpy as np

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')

def convertBWUnit(unit):
  if unit == 'G':
    return 1000.
  elif unit == 'M':
    return 1.
  elif unit == 'k':
    return 0.001
  else:
    print('Unknown unit ' + unit)

def convertLatencyUnit(unit):
  if unit == 'm':
    return 1000.
  elif unit == 'u':
    return 1.
  elif unit == 'n':
    return 0.001
  else:
    print('Unknown unit ' + unit)

def main(args):
  global analType
  analType = args[2]
  try:
    with open(args[1]) as f:
      config = {}

      # Parse contents
      regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
      regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

      IO = 0
      f.seek(0)
      for line in f:
        match = regexBW.search(line)
        if match:
          bw = float(match.group(1)) * convertBWUnit(match.group(2))
         
        match = regexLatency.search(line)
        if match:
          lat = float(match.group(2)) * convertLatencyUnit(match.group(1))

    print(str(bw)+" "+str(lat))
    #print(bw, "Bandwidth(MB/s)")
    #print(lat, "Latency(us)")

  except IOError:
    print('No such file exists')

# Begin of program
if len(sys.argv) == 3:
  main(sys.argv)
else:
  print('Usage: parse.py [file to parse] [parsing type]')
