#ifndef BIR_MODULE_H
#define BIR_MODULE_H

#include <map>
#include <boost/range/iterator_range.hpp>
#include "bir/Function.h"
#include "bir/NodeContainer.h"
#include "Arch.h"

namespace bir {

class Module : public NodeContainer<Module, Function> {
 public:
  Arch* arch;

  Module() {
    arch = new Arch();
  }
  Module(Module &&other);
  Module &operator=(Module &&other);
  void dump() const;
  Function &addFunction(const std::string &Name);
  void removeFunction(Function &Func);
  Function *getFunctionByName(const std::string &Name);
  Arch* getArchModel() {return arch;}
  void load(const std::string &inputFileName);
  void loadJson(std::ifstream &inputStream);
};  

}  // namespace bir

#endif  // BIR_MODULE_H