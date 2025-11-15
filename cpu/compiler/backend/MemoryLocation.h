#ifndef BIR_MEMORYLOCATION_H
#define BIR_MEMORYLOCATION_H

#include <algorithm>

#include "bir/AffineExpr.h"
#include "bir/LoopAxis.h"

namespace bir {

class Instruction;

enum class MemoryType {
  DRAM,
  FB,
  WB,
  PSUM,
  BB
};

std::string MemoryType2String(MemoryType ty);

class MemoryLocation {
 public:
  std::string name;
  MemoryType type;
  // symbolic
  std::vector<int> tensorShape;
  std::vector<AffineExpr*> ap;

  // physical
  int offset = 0;
  int step = 0;  
  int step_size = 0; // step size every stride
  int stride = 0;
  int bank_id = 0;  

  std::vector<Instruction*> readers;
  std::vector<Instruction*> writers;

  MemoryLocation(const std::string &Name, MemoryType Type) {
    this->name = Name;
    this->type = Type;  
  }

  bool equal(MemoryLocation& m) {
    bool eq = true;
    eq &= (type == m.type);
    for (int i = 0; i < tensorShape.size(); i++)
      eq &= (tensorShape[i] == m.tensorShape[i]);
    for (int i = 0; i < ap.size(); i++) {
      eq &= (ap[i]->eval_lb() == m.ap[i]->eval_lb());
      eq &= (ap[i]->eval_ub() == m.ap[i]->eval_ub());
    }  
    return eq;
  }

  void setName(const std::string &Name) {this->name = Name;}
  std::string getName() {return name;}

  void setType(MemoryType Type) {this->type = Type;}
  MemoryType getType() {return type;}
  
  template <typename... Args>
  void setTensorshape(Args... shape) {
    this->tensorShape = {shape...};   
  }

  std::vector<int> getTensorshape() {
    return tensorShape;  
  }
  
  template <typename... Args>
  void setAccessPattern(Args... affine_exprs) {
    this->ap.clear();
    std::vector<AffineExpr*> t = {affine_exprs...};
    for (auto expr : t) {
      this->ap.push_back(expr);
    }
  }

  AffineExpr *getAccessPattern(int idx) {
    return ap[idx];
  }

  std::vector<std::pair<int, int>> getAccessPatternRange() {
    std::vector<std::pair<int, int>> p;
    for (auto e : ap) {
      p.push_back({e->eval_lb(), e->eval_ub()});  
    } 
    return p;  
  }

  void setAP(int idx, AffineExpr* expr) {
    ap[idx] = expr;  
  }

  MemoryLocation* clone() {
    MemoryLocation* m = new MemoryLocation(name, type);
    m->setTensorshape(tensorShape);
    m->setAccessPattern(ap);
    m->offset = offset;
    m->step = step;  
    m->step_size = step_size; // step size every stride
    m->stride = stride;
    m->bank_id = bank_id;  
    return m;   
  }

  std::string toString() {
    std::stringstream ss;
    ss << name << "@" << MemoryType2String(type);
    for (auto i = 0; i < ap.size(); i++) {
      ss << ap[i]->toString();
      if (i != ap.size() - 1) 
        ss << "x";  
    }
    if (step > 0) {
      ss << "-<#" << bank_id << " : " << offset << "+:" << step_size << " x " << step << " s" << stride << ">";  
    }
    return ss.str(); 
  }

  std::string tensorShape2String() {
    std::stringstream ss;
    for (auto i = 0; i < tensorShape.size(); i++) {
      ss << tensorShape[i];
      if (i != tensorShape.size() - 1)
        ss << "x";
    }
    return ss.str();
  }
  
  void addReader(Instruction *I) {
    auto it = std::find(readers.begin(), readers.end(), I);
    if (it == readers.end())
      readers.push_back(I);  
  }
  void removeReader(Instruction *I) {
    readers.erase(std::find(readers.begin(), readers.end(), I));  
  }
  void addWriter(Instruction *I) {
    auto it = std::find(writers.begin(), writers.end(), I);
    if (it == writers.end())
      writers.push_back(I);  
  }
  void removeWriter(Instruction *I) {
    writers.erase(std::find(writers.begin(), writers.end(), I));  
  }

  void setOffset(int offset) {this->offset = offset;}
  int getOffset() {return this->offset;}
  void setStep(int step) {this->step = step;}
  int getStep() {return this->step;}
  void setStepSize(int step_size) {this->step_size = step_size;}
  int getStepSize() {return this->step_size;}
  void setStride(int stride) {this->stride = stride;}
  int getStride() {return this->stride;}


  bool intersect(MemoryLocation* b) {
    std::vector<std::pair<int, int>> poly_a;
    for (auto e : ap) {
      poly_a.push_back({e->eval_lb(), e->eval_ub()});  
    }
    std::vector<std::pair<int, int>> poly_b;
    for (auto e : b->ap) {
      poly_b.push_back({e->eval_lb(), e->eval_ub()});  
    }
    if (poly_a.size() != poly_b.size()) 
      return false;
    bool sect = false;
    for (int i = 0; i < poly_a.size(); i++) {
      int lb_a = poly_a[i].first;
      int ub_a = poly_a[i].second;  
      int lb_b = poly_b[i].first;
      int ub_b = poly_b[i].second;
      sect |= (lb_a < ub_b || lb_b < ub_a);
    }
    return sect;
  }

  void setBankId(int id) {bank_id = id;}
  int getBankId() {return bank_id;}
};

}
#endif
