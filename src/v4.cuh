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

const size_t BUFSIZE = 1 << 20;
const size_t TABLESIZE = 1000000007;

typedef std :: pair<uint64_t, uint64_t> pr;
__global__ void insert_kernel(pr *hashtable, uint64_t *buf,uint64_t start, uint64_t stride, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i];
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      uint64_t prev = atomicCAS((unsigned long long int*)&hashtable[slot].first, 0, (unsigned long long int)key);
      if (prev == 0 || prev == key){
        atomicMax((unsigned long long *)&hashtable[slot].second, (unsigned long long)(start + i * stride));
        break;
      }
      slot = (slot + 1) % TABLESIZE;
    }
  }
}

__global__ void find_kernel(const pr *hashtable, uint64_t *buf, bool *ok, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i];
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      if (hashtable[slot].first == 0 || hashtable[slot].first == key) {
        buf[i] = hashtable[slot].second;
        ok[i] = !!buf[i];
        break;
      }
      slot = (slot + 1) % TABLESIZE;
    }
  }
}

template <typename K, typename V, const int DIM>
class HashTable {
  private:
  pr *table_d;
  uint64_t *buf_d;
  bool *ok_d;
  public:
  void find(size_t n, const K* keys, uint64_t* values, bool* exists){
    for (size_t i = 0; i < n; i += BUFSIZE) {
      CHECK(cudaMemcpy(buf_d, keys + i, sizeof(K) * std :: min(BUFSIZE, n - i), cudaMemcpyHostToDevice));
      find_kernel<<<MultiProcessorCount, 1024>>>(table_d, buf_d, ok_d, std :: min(BUFSIZE, n - i));
      CHECK(cudaMemcpy(values + i, buf_d, sizeof(K) * std :: min(BUFSIZE, n - i), cudaMemcpyDeviceToHost));
      CHECK(cudaMemcpy(exists + i, ok_d, sizeof(K) * std :: min(BUFSIZE, n - i), cudaMemcpyDeviceToHost));
    }
  }
  void insert(size_t n, const K* keys, const V* values){
    for (size_t i = 0; i < n; i += BUFSIZE) {
      CHECK(cudaMemcpy(buf_d, keys + i, sizeof(K) * std :: min(BUFSIZE, n - i), cudaMemcpyHostToDevice));
      insert_kernel<<<MultiProcessorCount, 1024>>>(table_d, buf_d, (uint64_t)(&values[i * DIM]), sizeof(V) * DIM, min(BUFSIZE, n - i));
    }
  }
  HashTable(){
    CHECK(cudaMalloc(&table_d, sizeof(pr) * TABLESIZE));
    CHECK(cudaMalloc(&buf_d, sizeof(pr) * BUFSIZE));
    CHECK(cudaMalloc(&ok_d, sizeof(pr) * BUFSIZE));
  }
  ~HashTable(){
    CHECK(cudaFree(table_d));
    CHECK(cudaFree(buf_d));
    CHECK(cudaFree(ok_d));
  }
};