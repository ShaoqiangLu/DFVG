#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <iomanip>
#include <ctime>
#include <fstream>
#include <sstream>
#include <llvm/Support/CommandLine.h>

#include "bir/Module.h"
#include "bir/BasicBlock.h"
#include "pass/ChannelEnhance.h"
#include "pass/LowerComplex.h"
#include "pass/Allocator.h"
#include "pass/Scheduler.h"
#include "pass/Codegen.h"
#include "pass/DRAMLayoutGen.h"

using namespace llvm;

cl::opt<std::string> inputFileName("i",
                                   cl::desc("input file name"),
                                   cl::Optional);

cl::opt<bool> codegenNonIsa("codegen-non-isa",
                            cl::desc("export lincode json for simulation"),
                            cl::Optional);


std::string getCurrentTime() {
  std::stringstream ss;
  auto t = std::time(nullptr);
  auto tm = *std::localtime(&t);
  ss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
  return ss.str();
}

bool run_passes(std::vector<std::string> &pass_names,
                std::vector<std::unique_ptr<bir::Module>> &modules) {
  bir::Module &module = *modules[0];
  int pass_idx = 0;
  for (auto name : pass_names) {
    std::cout << getCurrentTime() << " Start " << name << " Pass\n";
    if (name == "channel_enhance") {
      ChannelEnhance().run(module);
    } else if (name == "lower_complex") {
      LowerComplex().run(module);
    } else if (name == "allocation") {
      Allocator().run(module);  
    } else if (name == "scheduling") {
      Scheduler().run(module);
    } else if (name == "codegen") {
      Codegen *cg = new Codegen();
      if (codegenNonIsa)
        cg->setExportJson(true);
      cg->run(module);
    } else if (name == "dram_layout_gen") {
      DRAMLayoutGen().run(module);
    } else {
      std::cout << "Invalid pass name : " << name << "\n";
      exit(1);
    }
    std::cout << getCurrentTime() << " Finish " << name << " Pass\n";
    if (name == "channel_enhance" || name == "dram_layout_gen")
      continue;
    std::stringstream ss;
    ss << std::setw(3) << std::setfill('0') << pass_idx;
    for (auto &f : module) {
      for (auto &bb : f) {
        std::ofstream out("output/" + bb.getName() + "_pass_" + ss.str() + "_after_" + name + ".txt", std::ios::out);
        bb.dump(out);
        out.close();
      }
    }
    pass_idx++;
  }
  return true;
}

int main(int argc, char*argv[]){
  // CLI
  cl::ResetAllOptionOccurrences();
  cl::ParseCommandLineOptions(argc, argv);
  
  // Initialize
  std::vector<std::unique_ptr<bir::Module>> modules;
  modules.emplace_back(std::make_unique<bir::Module>());
  modules.back()->load(inputFileName);

  // Passes
  std::vector<std::string> pass_names;
  pass_names.emplace_back("channel_enhance");
  pass_names.emplace_back("lower_complex");
  pass_names.emplace_back("allocation");
  pass_names.emplace_back("scheduling");
  pass_names.emplace_back("dram_layout_gen");
  pass_names.emplace_back("codegen");
  bool success = run_passes(pass_names, modules);
  return 0;  
}