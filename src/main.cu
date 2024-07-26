#include "dinner123.h"
#include "data_loader.h"
#include "data_writer.h"
#include "hash_table.h"
const char *Akeys = "/root/cudaHashTable/data/sample/A/part_0.keys";
const char *Avals = "/root/cudaHashTable/data/sample/A/part_0.vals";
const char *Bkeys = "/root/cudaHashTable/data/sample/A/part_0.keys";
const char *Bvals = "/root/cudaHashTable/data/sample/A/part_0.vals";
signed main(){
    {
        cudaTimer t;
        Loader<uint64_t> keys(Akeys);
        Loader<float> vals(Avals);
        insert(keys, vals);
        printf("insert qps:%lf\n", keys.count() / (t.elapsed() / 1000));
    }
    {
        cudaTimer t;
        Loader<uint64_t> keys(Bkeys);
        Checker<float> vals(Ovals);
        find(keys, vals);
        printf("find qps:%lf\n", keys.count() / (t.elapsed() / 1000));
    }
    {
        Loader<float> B(Bvals);
        Loader<float> O(Ovals);
        size_t tot = 0, ok = 0;
        for (int i = 0; i < B.count(); i += dim) {
            bool flag = 1;
            for (int j = 0; j < dim; j++) {
                if (B.get() != O.get()) {
                    flag = 0;
                    break;
                }
            }
            tot++;
            if (flag) {
                ok++;
            }
        }
        printf("acc:%lf\n", 1. * ok / tot);
    }
}