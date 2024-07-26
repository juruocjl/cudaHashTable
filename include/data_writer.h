#ifndef DATA_LOADER_H
#define DATA_LOADER_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cassert>
template<class T>
class Writer{
  private:
  
  FILE *fp;
  T *buf, *p1, *p2;

  public:
  Writer(const char *file, int buffer_size = 1 << 18) {
    fp = fopen(file, "wb");
    buf_size = buffer_size * sizeof(T);
    buf = p1 = p2 = (T*) malloc(buf_size);
    p2 += buf_size;
  }
  void reflush(){
    fwrite(buf, sizeof(T), p1 - buf, p1);
  }
  ~Writer(void) {
    reflush();
    fclose(fp);
  }
  void put(T x) {
    if (p1 == p2) {
        reflush();
    }
    *p1 = x;
    p1++;
  }
};
#endif