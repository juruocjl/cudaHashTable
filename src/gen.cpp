#include <bits/stdc++.h>
#define ull unsigned long long
using namespace std;
mt19937 rng;
int M = 2e6;
void gen_key(unsigned long long seed = 0) { // for insert key
	mt19937 rng(seed);
	FILE *fp = fopen("/root/cudaHashTable/data/zak/input1.keys", "wb");
	for (int t = 0; t < M; ++t) {
		ull val = rng();
		val &= (1ull << 26) - 1;
		for (int i = 0; i < 10; i += 1) {
			val *= 2023;
			val ^= val << 4;
			val ^= val >> 9;
		}
		fwrite(&val, sizeof(ull), 1, fp);
	}
	fclose(fp);
}
void gen_key2(unsigned long long seed = 0) { // for find key
	mt19937 rng(seed);
	FILE *fp = fopen("/root/cudaHashTable/data/zak/input2.keys", "wb");
	for (int t = 0; t < M; ++t) {
		ull val = rng();
		val &= (1ull << 26) - 1;
		for (int i = 0; i < 10; i += 1) {
			val *= 2023;
			val ^= val << 4;
			val ^= val >> 9;
		}
		fwrite(&val, sizeof(ull), 1, fp);
	}
	fclose(fp);
}
void gen_vals() { // for insert val
	FILE *fp = fopen("/root/cudaHashTable/data/zak/input1.vals", "wb");
	for (int t = 0; t < M * 8; ++t) {
		float val = pow(sqrt(rng()) * rng(), 1. / 3);
		fwrite(&val, sizeof(float), 1, fp);
	}
	fclose(fp);
}
int main(int argc, char **argv) {
	if (argc == 2)
		M = atoi(argv[1]);
	gen_key();
	gen_vals();
	gen_key2(114514);
	return 0;
}