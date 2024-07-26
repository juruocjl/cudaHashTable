#ifndef DATA_LOADER_H
#define DATA_LOADER_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cassert>
template<class T>
class Loader{
  private:
  
  FILE *fp;
  size_t T_sz,tot_sz,buf_size;
  T *buf,*p1,*p2;

  public:
  Loader(const char *file, int buffer_size = 1 << 18) {
    fp = fopen(file, "rb");
    if (fp == NULL){
      printf("No such file");
      exit(1);
    }
    FILE *tmp=fopen(file, "rb");
    fseek(tmp, 0, SEEK_END);
    tot_sz = ftell(tmp);
    fclose(tmp);
    T_sz = sizeof(T);
    buf_size = buffer_size * T_sz;
    buf = p1 = p2 = (T*) malloc(buf_size);
  }
  ~Loader(void) {
    free(buf);
    fclose(fp);
  }
  size_t count() {
    return tot_sz / T_sz;
  }
  T get() {
    if (p1 == p2) {
      p2 = (p1 = buf) + fread(buf, 1, buf_size, fp) / T_sz;
    }
    T res = *p1;
    p1 ++;
    return res;
  }
};
#endif