#include "dinner123.h"
template <typename K, typename V, const int DIM>
class CPUHashTable {
  public:
	/*
	 * 查找keys在表中是否存在，若存在则返回对应的value
	 * @param n: keys的数量
	 * @param keys: 要查的keys
	 * @param values: 要返回的values
	 * @param exists: 返回keys对应位置的在表中是否存在
	 */
	std :: unordered_map<K, int> MP[1024];
	uint64_t T[2000007];
	int tot, cnt;
	void find(size_t n, const K *keys, uint64_t *values, bool *exists) {
		for (int i = 0; i < n; ++i) {
			if (MP[keys[i] & 1023].count(keys[i])) {
				int id = MP[keys[i] & 1023][keys[i]];
				values[i] = T[id];
				exists[i] = 1;
			} else {
				exists[i] = 0;
			}
		}
	}

	void insert(size_t n, const K *keys, V *values) {
		for (int i = 0; i < n; ++i) {
			int id = 0;
			if (!MP[keys[i] & 1023].count(keys[i]))
				id = MP[keys[i] & 1023][keys[i]] = ++tot;
			else
				id = MP[keys[i] & 1023][keys[i]];
			T[id] = (uint64_t)&values[i * DIM];
		}
	}
	CPUHashTable(){}
	~CPUHashTable(){}
};
