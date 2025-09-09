#include "pass/Codegen.h"

using namespace bir;

void run_legacy_mc(Module &module) {
  Arch *A = module.getArchModel();
  /*for (auto &f : module) {
    for (auto &bb : f) {
      auto mc = new LegacyMC();
      mc->init();
      std::cout << "[BB] " << bb.getName() << "\n";
      mc->run(bb, A);//exit(1);
    }   
  }*/
  auto mc = new LegacyMC();
  mc->init();
  for (auto &f : module) {
    for (auto &bb : f) {
      std::cout << "[BB] " << bb.getName() << "\n";
      mc->run(bb, A);//exit(1);
      mc->instMatch();
      mc->dump_txt("output/isa_txt_" + bb.getName() + ".txt");
      mc->dump_bin_txt("output/isa_bin_txt_" + bb.getName() + ".txt");
    }   
  }
}

void Codegen::generate_fsim_inst(Module &module) {
  auto mc = new LegacyMC();
  Arch *A = module.getArchModel();
  mc->init();
  std::ofstream outj(this->filename);
  for (auto &f : module) {
    for (auto &bb : f) {
      std::cout << "[BB] " << bb.getName() << " export json line code\n";
      mc->sync_map.clear();
      mc->reg_trace.clear();
      mc->next_engine_inst.clear();
      mc->findLastMatmult(bb);
      mc->emitLayerGlobalRegTrace(bb, A);
      mc->setSyncId(bb);
      mc->setSync();
      mc->instMatch();
      mc->exportSimJson(bb, outj);
    }   
  }
  outj.close();
}

int Codegen::run(Module &module) {
  if (export_json)
    generate_fsim_inst(module);
  else 
    run_legacy_mc(module);
  return 0;  
}