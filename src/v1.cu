//std::map
#include "dinner123.h"
#include "hash_table.h"
#include <bits/stdc++.h>
#include <map>
size_t size(){
  return 0;
}
size_t capacity(){
  return 0;
}
std :: map<uint64_t, data> qwq;
void init() {

}
void insert(Loader<uint64_t> &keys, Loader<data> &vals){
  for (int i = 0; i < keys.count(); i++) 
    qwq[keys.get()] = vals.get();
}
void find(Loader<uint64_t> &keys, Checker<data> &vals){
  for (int i = 0; i < keys.count(); i++) {
    vals.put(qwq[keys.get()]);
  }
}
void clear() {

}