import os

file1="../ftrace-rw-corun2-sort.txt"
file2="../ftrace-rw-corun3-sort.txt"
file3="../ftrace-rw-corun4-sort.txt"
output="common.txt"


with open(file1) as file1o:
  for file1_line in file1o:
    split1 = file1_line.split(' ')
    split1 = [x for x in split1 if x!='']
    print split1[0]

    command = "grep %s %s %s %s >> %s" % (split1[0], file1, file2, file3, output)
    os.system(command)
