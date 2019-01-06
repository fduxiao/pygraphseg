#ifndef __GAUSS__
#define __GAUSS__

#include "types.h"

void gaussian(int width, int height, IMAGE src, IMAGE dst, IMAGE tmp, FLOAT* mask, int mask_size);

#endif