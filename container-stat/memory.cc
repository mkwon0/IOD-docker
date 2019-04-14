#include "memory.hh"

#include <iostream>

MemoryStat::MemoryStat(std::string pid) {
  pid=pid;
  proc.open("/proc/"+pid+"status");
}

MemoryStat::~MemoryStat() {
  if (proc.is_open()) {
    proc.close();
  }
}

void MemoryStat::loadValues() {
  int counter = 0;

  proc.seekg(0);

  if (!proc.fail()) {
    std::string word;

    while (!proc.eof()) {
      proc >> word;

      if (word == "VmPeak:") {
        counter++;

        proc >> VmPeak;
        proc >> word;  // kB
      }
      else if (word == "VmRSS:") {
        counter++;

        proc >> VmRSS;
        proc >> word;  // kB
      }
      else if (word == "RSSAnon:") {
        counter++;

        proc >> RssAnon;
        proc >> word;  // kB
      }
      else if (word == "RSSFile:") {
        counter++;

        proc >> RssFile;
        proc >> word;  // kB
      }
      else if (word == "RSSShmem:") {
        counter++;

        proc >> RssShmem;
        proc >> word;  // kB
      }
      else if (word == "VmSwap:") {
        counter++;

        proc >> VmSwap;
        proc >> word;  // kB
      }

      if (counter >= 6) {
        break;
      }
    }
  }
  else {
    proc.close();
    proc.open("/proc/"+pid+"status");
  }
}

void MemoryStat::getStatList(std::vector<std::string> &list) {
  list.push_back("Peak virtual memory (MB)");
  list.push_back("RSS (MB)");
  list.push_back("Resident anonymous(MB)");
  list.push_back("Resident file mappings (MB)");
  list.push_back("Resideng shared (MB)");
  list.push_back("Swapped-out (MB)");
}

void MemoryStat::getStatValues(std::vector<double> &values) {
  loadValues();

  values.push_back(VmPeak / 1000.);
  values.push_back(VmRSS / 1000.);
  values.push_back(RssAnon / 1000.);
  values.push_back(RssFile / 1000.);
  values.push_back(RssShmem / 1000.);
  values.push_back(VmSwap / 1000.);
}

void MemoryStat::resetStatValues() {
  // Do Nothing
}
