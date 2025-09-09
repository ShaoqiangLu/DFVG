#include "./vmem.h"
#include <glog/logging.h>

void VirtualMemory::FromFile(void* dst, size_t bytes, std::string filename, std::string info) {
  // open the file:
  std::ifstream file(filename.c_str(), std::ios::binary);
  // get its size:
  file.seekg(0, std::ios::end);
  size_t fileSize = file.tellg();
  file.seekg(0, std::ios::beg);
  // CHECK(fileSize == bytes) << info << " Get:" << fileSize << " v.s. Target:" << bytes;
  // read the data:
  file.read(reinterpret_cast<char*>(dst), fileSize);
  file.close();
}

void VirtualMemory::Init() {
  base = Alloc((ins_addr_ini - fm_addr_ini) *64);
  fm = GetAddr(fm_addr_ini);
  wgt = GetAddr(wgt_addr_ini);
  bias = GetAddr(bias_addr_ini);
  /* Example
  FromFile(fm, 416*416*64, "tinyyolo/ifm.bin");
  FromFile(wgt, 246336*64, "tinyyolo/weights.bin");
  FromFile(bias, 51648, "tinyyolo/bias.bin");
  */
  FromFile(fm, IFM_BYTES, IFM_FILE_PATH, "FM");
  FromFile(wgt, WGT_BYTES, WGT_FILE_PATH, "WEIGHT");
  FromFile(bias, BIAS_BYTES, BIAS_FILE_PATH, "BIAS");
}

void* VirtualMemory::Alloc(addr_t size) {
  addr_t npages = (size + kPageSize - 1) / kPageSize;
  addr_t start = ptable_.size();
  std::unique_ptr<Page> p(new Page(start, npages));
  ptable_.resize(start + npages, p.get());
  void* data = p->data;
  pmap_[data] = std::move(p);
  return data;
}

void* VirtualMemory::GetAddr(addr_t phy_addr) {
  addr_t addr_v = phy_addr - fm_addr_ini;
  addr_t loc = addr_v >> kPageBits;
  CHECK_LT(loc, ptable_.size()) << "phy_addr = " << loc << "> ptable_.size() = "
                                << ptable_.size();
  Page* p = ptable_[loc];
  CHECK(p != nullptr);
  size_t offset = (loc - p->ptable_begin) << kPageBits;
  offset += addr_v & (kPageSize - 1);
  return reinterpret_cast<char*>(p->data) + offset * 64;
}

void* VirtualMemory::GetBaseAddr() {
  return fm;
}

void VirtualMemory::Write(addr_t phy_addr, void* data, size_t size) {
  void* dst = GetAddr(phy_addr);
  std::memcpy(dst, data, size);
}
