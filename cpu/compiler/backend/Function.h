#ifndef BIR_FUNCTION_H
#define BIR_FUNCTION_H

#include <map>
#include "bir/NodeContainer.h"
#include "bir/BasicBlock.h"

namespace bir {

class Module;

class Function : public NodeContainer<Function, BasicBlock>,
  public NodeWithParent<Function, Module> {
 public:
  Function(const std::string &Name, Module *Parent);

  using NodeContainer<Function, BasicBlock>::size;
  using NodeContainer<Function, BasicBlock>::empty;
  using NodeContainer<Function, BasicBlock>::begin;
  using NodeContainer<Function, BasicBlock>::end;
  using NodeContainer<Function, BasicBlock>::getElementByName;

  BasicBlock & addBasicBlock(const std::string &Name);
  void removeBasicBlock(BasicBlock &Block);
  BasicBlock *getBasicBlockByName(const std::string &Name);
  void dump() const;
  std::vector<MemoryLocation*> mem_locs;
  void addMemoryLocation(MemoryLocation* m) {mem_locs.push_back(m);}
  std::vector<MemoryLocation*> MemoryLocations() {return mem_locs;}
};

}  // namespace bir

#endif  // BIR_FUNCTION_H