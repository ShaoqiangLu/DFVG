#include "pass/pass.h"

int Pass::run(std::vector<std::unique_ptr<bir::Module>> &modules) {
  for (std::unique_ptr<bir::Module> &module : modules) {
    int status = run(*module);
    if (status != 0) {
      return status;
    }
   }
}