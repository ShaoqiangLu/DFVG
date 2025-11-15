#ifndef BIR_LOOPAXIS_H
#define BIR_LOOPAXIS_H

#include <sstream>
#include <cmath>

namespace bir {

class LoopInst;

class LoopAxis {
 public:
  int lb = 0;
  int ub;
  int stride = 1;
  int tripcount = -1;
  int last_ub = -1;
  std::string name;
  LoopInst *loopinst;
  bool isParallel = false;
  bool isOnChip = false;

  LoopAxis(std::string Name) {this->name = Name;}
  LoopAxis(std::string Name, int lb, int ub, int stride = 1) {
    this->name = Name;
    this->lb = lb;
    this->ub = ub;
    this->stride = stride;
  }
  ~LoopAxis(){}
  void SetName(std::string Name) {this->name = Name;}
  const std::string &getName() const {return name;}
  void setLb(int lb) {this->lb = lb;}
  int getLb() const {return lb;}
  void setUb(int ub) {this->ub = ub;}
  int getUb() const {return ub;}
  void setStride(int stride) {this->stride = stride;}
  int getStride() const {return stride;}
  int getTripcount() {
    if (tripcount == -1) {
      tripcount = (ub - lb) / stride;
    }  
    return tripcount;
  }
  std::string toString(int level = 0) {
    std::stringstream ss;
    for (int i = 0; i < level; i++) 
      ss << "  ";
    ss << "for ";
    ss << name << " : [" << lb << "," << ub << ")";  
    if (isParallel)
      ss << "  // parallel";
    if (isOnChip)
      ss << " // onchip";
    return ss.str();
  } 
  void setLoopInst(LoopInst *loopinst) {this->loopinst = loopinst;}
  LoopInst *getLoopInst() const {return loopinst;}

  std::pair<LoopAxis*, LoopAxis*> tile(int tile_size) {
    getTripcount();
    int tile_cnt = ceil((float)tripcount / tile_size);
    int residue = tripcount % tile_size;
    this->ub = tile_cnt;
    getTripcount();
    auto axis = new LoopAxis(this->name + "_1");
    this->name += "_0";
    axis->ub = tile_size;
    if (residue != 0) 
      axis->last_ub = residue;
    return {this, axis};
  }

};

}

#endif
