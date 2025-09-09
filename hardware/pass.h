#ifndef PASS_PASS_H
#define PASS_PASS_H

#include <vector>
#include <llvm/Support/Casting.h>
#include "bir/Module.h"

namespace bir {
  class Module;  
}

class Pass {
 public:
  Pass() = default;
  virtual ~Pass() = default;

  virtual int run(bir::Module &module) = 0;
  virtual int run(std::vector<std::unique_ptr<bir::Module>> &modules);
  std::string getName() const {return name;}
  void setName(const std::string &Name) {name = Name;}

  std::string name;   
};

#endif
