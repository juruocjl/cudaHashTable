#include "dinner123.h"
const int MultiProcessorCount = 80;
#define mix(h) ({					\
			(h) ^= (h) >> 23;		\
			(h) *= 0x2127599bf4325c37ULL;	\
			(h) ^= (h) >> 47; })


uint64_t fasthash64(uint64_t v) {
	const uint64_t m = 0x880355f21e6d1965ULL;
	uint64_t h = 1919810;
	h ^= mix(v);
	h *= m;
	return mix(h);
}

__device__ uint64_t fasthash64_d(uint64_t v) {
	const uint64_t m = 0x880355f21e6d1965ULL;
	uint64_t h = 114514;
	h ^= mix(v);
	h *= m;
	return mix(h);
}

const size_t TABLESIZE = 1 << 30;
const size_t stride = 64 * 4;

__global__ void insert_kernel(uint64_t *hashtable_keys, uint64_t *hashtable_vals,const uint64_t *keys, uint64_t start, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = keys[i];
    size_t slot = fasthash64_d(key) & (TABLESIZE - 1);
    while(1) {
      uint64_t prev = atomicCAS((unsigned long long int*)&hashtable_keys[slot], 0, (unsigned long long int)key);
      if (prev == 0 || prev == key){
        atomicMax((unsigned long long *)&hashtable_vals[slot], (unsigned long long)(start + i * stride));
        break;
      }
      slot = (slot + 1) & (TABLESIZE - 1);
    }
  }
}

__global__ void find_kernel(const uint64_t *hashtable_keys, const uint64_t *hashtable_vals, const uint64_t *keys, uint64_t *vals, bool *ok, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = keys[i];
    size_t slot = fasthash64_d(key) & (TABLESIZE - 1);
    while(1) {
      if (hashtable_keys[slot] == 0 || hashtable_keys[slot] == key) {
        vals[i] = hashtable_vals[slot];
        ok[i] = !!vals[i];
        break;
      }
      slot = (slot + 1) & (TABLESIZE - 1);
    }
  }
}

template <typename K, typename V, const int DIM>
class HashTable {
  private:
  uint64_t *keys_d ,* vals_d;
  public:
  void find(size_t n, const K* keys, uint64_t* values, bool* exists){
    find_kernel<<<MultiProcessorCount, 1024>>>(keys_d, vals_d, keys, values, exists, n);
  }
  void insert(size_t n, const K* keys, const uint64_t values){
    insert_kernel<<<MultiProcessorCount, 1024>>>(keys_d, vals_d, keys, values, n);
  }
  HashTable(){
    CHECK(cudaMalloc(&keys_d, TABLESIZE * sizeof(uint64_t)));
    CHECK(cudaMalloc(&vals_d, TABLESIZE * sizeof(uint64_t)));
  }
  ~HashTable(){
    
  }
};