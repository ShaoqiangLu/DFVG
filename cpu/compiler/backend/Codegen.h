#ifndef PASS_CODEGEN_H
#define PASS_CODEGEN_H

#include <vector>
#include <unordered_map>

#include "pass/pass.h"
#include "bir/BasicBlock.h"
#include "pass/LegacyMC.h"

using namespace bir;

class Codegen : public Pass {
 public:
  Codegen() {}
  virtual ~Codegen() {}
  virtual int run(bir::Module &module) override;

  std::string filename = "linecode.json";
  void setOutputJsonFile(std::string name) {this->filename = name;}
  bool export_json = false;
  void setExportJson(bool enable) {this->export_json = enable;}
  void generate_fsim_inst(Module &module);
};

#endif
