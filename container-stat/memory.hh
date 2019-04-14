#pragma once

#ifndef __STAT_MEMORY__
#define __STAT_MEMORY__

#include <fstream>

#include "stat.hh"

class MemoryStat : public StatObject {
 private:
  std::ifstream proc;
  std::string pid;

  uint64_t VmPeak; //  Peak virtual memory size
  uint64_t VmRSS; // Resident set size
  uint64_t RssAnon; // Size of resident anonymous memory
  uint64_t RssFile;  // Size of resident file mappings
  uint64_t RssShmem; // Size of resident shared memory
  uint64_t VmSwap;  // Swapped-out virtual memory size by anonymous private pages; shmem swap usage is not included

  void loadValues();

 public:
  MemoryStat(std::string);
  ~MemoryStat(); 

  void getStatList(std::vector<std::string> &) override;
  void getStatValues(std::vector<double> &) override;
  void resetStatValues() override;
};

#endif
