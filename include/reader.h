#ifndef SPARK_READER_H
#define SPARK_READER_H
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <cuda_runtime.h>
#include "dinner123.h"
template <typename T>
class file_loader {
  public:
	file_loader(const char *name) {
		FILE *IN = fopen(name, "rb");
		fseek(IN, 0, SEEK_END);
		file_size = ftell(IN);
		rewind(IN);
		CHECK(cudaHostAlloc(&buf, file_size, cudaHostAllocMapped));
		//buf = (T*) malloc(file_size);
		fread(buf, 1, file_size, IN);
		fclose(IN);
	}
	size_t count() { return file_size / sizeof(T); }
	T *data() { return buf; }

  private:
	T *buf;
	size_t file_size;
};
class data_loader {
  private:
	file_loader<uint64_t> keys_file;
	file_loader<float> vals_file;
	int key_size, val_size;

  public:
	data_loader(const char *name) : keys_file((std::string(name) + ".keys").c_str()), vals_file((std::string(name) + ".vals").c_str()) {
		key_size = keys_file.count();
		val_size = vals_file.count();
	}
	int size() { return key_size; }
	int dim() { return val_size / key_size; }
	uint64_t *keys() { return keys_file.data(); }
	float *vals() { return vals_file.data(); }
};
#endif