#include "dinner123.h"
#include "hash_table.h"
const char *Akeys = "/root/cudaHashTable/data/akdream1/A/part0.keys";
const char *Avals = "/root/cudaHashTable/data/akdream1/A/part0.vals";
const char *Bkeys = "/root/cudaHashTable/data/akdream1/A/part0.keys";
const char *Bvals = "/root/cudaHashTable/data/akdream1/A/part0.vals";
signed main(){
  init();
  {
    CTimer t;
    Loader<uint64_t> keys(Akeys, &t, 1 << 12);
    Loader<data> vals(Avals, &t, 1 << 12);
    t.start();
    insert(keys, vals);
    t.stop();
    printf("insert use:%fs\n", t.elapsed() / 1000);
    printf("insert qps:%f\n", keys.count() / (t.elapsed() / 1000));
  }
  {
    CTimer t;
    Loader<uint64_t> keys(Bkeys, &t, 1 << 12);
    Checker<data> vals(Bvals, &t, 1 << 12);
    t.start();
    find(keys, vals);
    t.stop();
    printf("find use:%fs\n", t.elapsed() / 1000);
    printf("find qps:%f\n", keys.count() / (t.elapsed() / 1000));
    printf("acc:%lf%\n", vals.acc() * 100);
  }
  clear();
}