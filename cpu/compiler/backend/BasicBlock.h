#ifndef BIR_BASICBLOCK_H
#define BIR_BASICBLOCK_H

#include <unordered_map>
#include "bir/NodeContainer.h"
#include "bir/Instruction.h"
#include "nlohmann/json.hpp"

namespace bir {

class Function;
class Instruction;
class MemoryLocation;

class BasicBlock : public NodeContainer<BasicBlock, Instruction>,
  public NodeWithParent<BasicBlock, Function> {
 public:
  using instruction_iterator = NodeContainer<BasicBlock, Instruction>::iterator;
  
  BasicBlock(const std::string &Name, Function *Parent);

  inline boost::iterator_range<instruction_iterator> instructions() {
    return elements();
  }

  template < typename Type, typename... Args>
  Type &insertInstructionBefore(Instruction &where, const std::string Name, Args... ConstructorArgs) {
    Type &instruction = NodeContainer<BasicBlock, Instruction>::insertElement<Type>(
        where.getIterator(), Name, ConstructorArgs...);
    return instruction;
  }

  template < typename Type, typename... Args>
  Type &addInstruction(const std::string Name, Args... ConstructorArgs) {
    Type &instruction = NodeContainer<BasicBlock, Instruction>::insertElement<Type>(
        end(), Name, ConstructorArgs...
    );
    return instruction;
  }

  void removeInstruction(Instruction &);
  Instruction *getInstructionByName(const std::string &Name);

  void dump(std::ostream &os);

  std::vector<Instruction*> complex_instructions;
  void addComplexInstruction(Instruction* I) {complex_instructions.push_back(I);}
};

}  // namespace bir

#endif  // BIR_BASICBLOCK_H
