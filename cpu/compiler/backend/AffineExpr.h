#ifndef BIR_AFFINEEXPR_H
#define BIR_AFFINEEXPR_H

#include <vector>
#include <string>
#include <iostream>
#include <sstream>
#include <unordered_map>

#include "bir/LoopAxis.h"

namespace bir {
using loopmap = std::unordered_map<bir::LoopAxis*, int>;
class AffineExpr {
 public:
  int c = 0;
  std::vector<LoopAxis*> vars;
  loopmap terms;  // loop - tripcount of one iteration of the loop 
  
  std::string toSymbolString() {
    std::stringstream ss;    
    for (auto term : terms) {
      ss << term.first->getName() << "*" << term.second << "+";  
    }
    ss << c;
    return ss.str();
  }

  int eval_lb() {
    loopmap local;  
    for (auto loop : vars) {
      local[loop] = loop->getLb();  
    }
    return eval(local);  
  }

  int eval_ub() {
    loopmap local;  
    for (auto loop : vars) {
      local[loop] = loop->getUb();  
    }
    return eval(local);
  }

  int getIteration() {
    int iter = 1;
    for (auto *var : vars) {
      iter *= var->getTripcount();
    }
    return iter;
  }

  std::string toString() {
    std::stringstream ss;    
    int lb = eval_lb();
    int ub = eval_ub();
    ss << "[" << lb << "," << ub;
    int stride = 1;
    if (vars.size() > 0)
      stride = vars[0]->getStride();
    if (stride != 1) ss << "," << stride;
    ss << ")";
    return ss.str();
  }
  
  AffineExpr() {}

  void updateTerms(std::vector<LoopAxis*>& t) {
    for (int i = 0; i < t.size() - 1; i++) {
      terms[t[i]] = t[i + 1]->getTripcount();  
    }
    terms[t.back()] = 1;
  }

  template <typename... Args>
  AffineExpr(Args... loops) {
    vars = {loops...};
    updateTerms(vars);
  }

  void addTerm(LoopAxis* axis) {terms[axis] = axis->getTripcount();}
  
  int eval(loopmap &localmap) {  // compute current loop index
    int final_c = c;
    for (auto &term : terms) {
      if (localmap.find(term.first) != localmap.end()) {
        final_c += term.second * localmap[term.first];  
      }  
    }
    return final_c;
  }

  AffineExpr *add(AffineExpr* e) {
    AffineExpr *t = new AffineExpr();
    t->updateTerms(vars);
    t->updateTerms(e->vars);
    t->c = c + e->c;
    return t;    
  }
};

}
#endif
