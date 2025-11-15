#include "bir/MemoryLocation.h"

using namespace bir;

std::string bir::MemoryType2String(MemoryType ty) {
  std::string name;
  switch (ty) {
    case MemoryType::DRAM: name = "DRAM"; break;
    case MemoryType::FB: name = "FB"; break;
    case MemoryType::WB: name = "WB"; break;
    case MemoryType::BB: name = "BB"; break;
    case MemoryType::PSUM: name = "PSUM"; break;
    default: name = "?"; break;
  }
  return name;
}