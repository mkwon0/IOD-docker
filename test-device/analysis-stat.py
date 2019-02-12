import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import scipy.stats as stats
import pandas as pd 
from statsmodels.formula.api import ols
from statsmodels.stats.anova import anova_lm
import matplotlib.pyplot as plt
import numpy as np

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')

def detectHeader(line, config):
  config = {"mindev": 0, "maxdev": 0, "minns": 0, "maxns": 0}
  config['mindev'] = int(0)
  config['maxdev'] = int(0)
  config['minns'] = int(1)
  config['maxns'] = int(4)

  return [True, config]

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

def printData(data, analtype, title):
  pType = len(data)

  if analType == "stat":
    for p in range(0, pType):
      sys.stdout.write('{0:.2f}'.format(data[p]))
      sys.stdout.write('\t')
    sys.stdout.write('\n')
 
def main(args):
  global analType
  analType = args[2]
  title = args[3] 
  try:
    with open(args[1]) as f:
      config = {}
      
      # parse header
      for line in f:
        ret = detectHeader(line, config)
        config = ret[1]
        if not ret[0]:
          break

      config['devcount'] = int(config['maxdev'] - config['mindev'] + 1)
      config['nscount'] = int(config['maxns'] - config['minns'] + 1)
      config['typecount'] = 4
 
      # Allocate data
      bw = []
      lat = []

      # Parse contents
      regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
      regexLatency = re.compile(' lat \(([mun])sec\):.*max=([ \d.]+)')

      IO = 0
      f.seek(0)
      for line in f:
        match = regexBW.search(line)
        if match:
          bw.append(float(match.group(1)) * convertBWUnit(match.group(2)))
         
        match = regexLatency.search(line)
        if match:
          lat.append(float(match.group(2)) * convertLatencyUnit(match.group(1)))

    printData(bw, "Bandwidth(MB/s)", title)
    printData(lat, "Latency(us)", title)

  except IOError:
    print('No such file exists')

# Begin of program
if len(sys.argv) == 4:
  main(sys.argv)
else:
  print('Usage: parse.py [file to parse] [parsing type]')
