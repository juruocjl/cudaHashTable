#include "dinner123.h"
#include "data_loader.h"
#include "data_writer.h"
#include "hash_table.h"
#include <map>
size_t size(){
  return 0;
}
size_t capacity(){
  return 0;
}
struct data{
  float a[dim];
  data(){}
  data(Loader<float> &vals){
    for (int i=0; i < dim; i++) {
      a[i] = vals.get();
    }
  }
};
std :: map<uint64_t, data> qwq;
void insert(Loader<uint64_t> &keys, Loader<float> &vals){
  for (int i = 0; i < keys.count(); i++) 
    qwq[keys.get()] = data(vals);
}
void find(Loader<uint64_t> &keys, Checker<float> &vals){
  for (int i = 0; i < keys.count(); i++) {
    data res = qwq[keys.get()];
    for (int j = 0; j < dim; j++) {
      vals.put(res.a[j]);
    }
  }
}