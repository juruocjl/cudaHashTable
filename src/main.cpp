#include "dinner123.h"
#include "data_loader.h"

signed main(){
    Loader keys("/cudaHashTable/data/part_0.keys");
    printf("%lld", keys.len());
}