#include <iostream>
#include <cstdint>
#include <cstring>
#include <type_traits>
#include <vector>
#include <unordered_map>
#include <memory>
#include <fstream>
#include <string>

#include "./config.h"

#ifndef FSIM_VMEM_H_
#define FSIM_VMEM_H_

/*
 * reference : paged virtual memory for vta
 *   https://github.com/apache/incubator-tvm-vta/blob/master/src/vmem/virtual_memory.h
 *
 * Paged DRAM
 */

typedef uint64_t addr_t;
class VirtualMemory {
 public:
  static constexpr addr_t kPageBits = 17;
  static constexpr addr_t kPageSize = (1 << kPageBits);
  struct Page {
    using Dtype = typename std::aligned_storage<kPageSize, 512>::type;
    size_t ptable_begin;
    size_t npages;
    Dtype* data {nullptr};
    Page(size_t ptable_begin, size_t npages) :
        ptable_begin(ptable_begin), npages(npages) {
      data = new Dtype[npages];
    }
    ~Page() {
      delete [] data;
    }
  };
  // Page table
  std::vector<Page*> ptable_;
  // virtual memory address - page pointer
  std::unordered_map<void*, std::unique_ptr<Page>> pmap_;


  void Init();
  void FromFile(void* dts, size_t bytes, std::string filename, std::string info);
  void* Alloc(size_t size);
  // Read
  void* GetAddr(addr_t phy_addr);
  void* GetBaseAddr();
  // Write
  void Write(addr_t phy_addr, void* data, size_t size);
  
  // DRAM sections
  addr_t fm_addr_ini {FM_ADDR_INI};
  addr_t wgt_addr_ini {WGT_ADDR_INI};
  addr_t bias_addr_ini {BIAS_ADDR_INI};
  addr_t ins_addr_ini {INS_ADDR_INI};
  
  // Base addresses
  void* base;
  void* fm;
  void* wgt;
  void* bias;
};

#endif  // FSIM_VMEM_H_
