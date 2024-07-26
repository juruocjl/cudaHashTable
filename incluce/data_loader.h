#ifndef DATA_LOADER_H
#define DATA_LOADER_H

#include <stdio.h>
#include <string.h>

template<T>
class Loader{
  private:
  
  FILE *fp;
  size_t T_sz,tot_sz,buf_size;
  char *buf,*p1,*p2;

  public:
  Loader(string file, int buffer_size = 1 << 18) {
    fp = fread(file.c_str());
    FILE *tmp=fopen(file.c_str(), "rb");
    fseek(tmp, 0, SEEK_END);
    tot_sz = ftell(tmp);
    fclose(tmp);
    T_sz = sizeof(T);
    buf_size = buffer_size * T_sz;
    buf = p1 = p2 = (*char) malloc();
  }
  ~Loader() {
    free(buf);
  }
  size_t len() {
    return tot_sz / T_sz;
  }
  T get() {
    if (p1 == p2) {
      p2 = (p1 = buf) + fread(buf, 1, buf_size, fp);
    }
    T res = *((*T)p1);
    p1 += T_sz;
  }
};
#ENDIF