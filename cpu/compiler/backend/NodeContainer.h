#ifndef BIR_CONTAINER_H
#define BIR_CONTAINER_H

#include <cassert>
#include <cstdint>
#include <map>
#include <vector>
#include <atomic>
#include <llvm/ADT/ilist.h>
#include <boost/range/iterator_range.hpp>

namespace bir {

template <typename, typename> class NodeContainer;

template <typename C, typename P>
class NodeWithParent : public llvm::ilist_node_with_parent<C, P> {
 public:
  P *Parent;
  std::string Name;
  unsigned Id;
  static std::atomic<unsigned> IdCounter;

  using llvm::ilist_node_with_parent<C, P>::getIterator;

  friend class NodeContainer<P, C>;

  NodeWithParent (const std::string &Name, P *Parent) : Parent(Parent), Name(Name), Id(IdCounter++) {}

  void setParent(P *Parent) {this->Parent = Parent;}
  const std::string &getName() const {return Name;}
  P *getParent() {return Parent;}

  void moveBefore(NodeWithParent<C, P> &MovePos) {
    NodeContainer<P, C> *MoveParent = MovePos.getParent();
    MoveParent->splice(MovePos.getIterator(), *getParent(), getIterator());
  }

  void moveAfter(NodeWithParent<C, P> &MovePos) {
    NodeContainer<P, C> *MoveParent = MovePos.getParent();
    MoveParent->splice(++MovePos.getIterator(), *getParent(), getIterator());
  }
};

template <typename C, typename T>
class NodeContainer {
 public:
  using ListType = typename llvm::ilist<T>;
  using iterator = typename ListType::iterator;

  ListType Elements;
  std::map<std::string, T*> SymbolTable;

  template <typename Type, typename... Args>
  Type &insertElement(iterator where, const std::string &Name, Args... ConstructorArgs) {
    Type *element = new Type(Name, static_cast<C*>(this), std::forward<Args>(ConstructorArgs)...);                          
    Elements.insert(where, element);
    SymbolTable.insert({Name, element});
    return *element;                             
  }

  NodeContainer & operator=(NodeContainer &&other) {
    Elements.clear();
    std::swap(Elements, other.Elements);
    SymbolTable.clear();
    std::swap(SymbolTable, other.SymbolTable);
    return *this;
  }
          
  iterator begin() {return Elements.begin();}
  iterator end() {return Elements.end();}
  size_t size() const {return Elements.size();}
  bool empty() const {return Elements.empty();}

  boost::iterator_range<iterator> elements() {
    return boost::iterator_range<iterator>(Elements.begin(), Elements.end()); 
  }

  T *getElementByName(std::string Name) {
    auto it = SymbolTable.find(Name);
    if (it == SymbolTable.end()) 
      return nullptr;
    else 
      it->second;
  }

  void splice(iterator where, NodeContainer<C, T> &other, iterator pos) {
    Elements.splice(where, other.Elements, pos);
    if (this != &other) {
      T &NodeWithParent = *pos;
      other.SymbolTable.erase(NodeWithParent.getName());
      SymbolTable.insert({NodeWithParent.getName(), &NodeWithParent});
      NodeWithParent.setParent(static_cast<C*>(this));  
    }  
  }

  void removeElement(NodeWithParent<T, C> & object) {
    SymbolTable.erase(object.getName());
    Elements.erase(object.getIterator());
  }
};

}  // namespace bir

#endif
