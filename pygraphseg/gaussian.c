#include "gaussian.h"

#define max(a, b) (a>b?a:b)
#define min(a, b) (a<b?a:b)

void convolve_even(int width, int height, IMAGE dst, IMAGE src, FLOAT* mask, int mask_size) {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            FLOAT sum = mask[0] * src[y*width+x];
            for (int i = 1; i < mask_size; i++) {
                sum += mask[i] *
                (src[y*width + max(x-i,0)]  +
                 src[y*width + min(x+i, width-1)]);
            }
            dst[y*width+x] = sum;
        }
    }
}

void gaussian(int width, int height, IMAGE src, IMAGE dst, IMAGE tmp, FLOAT* mask, int mask_size)
{
    convolve_even(width, height, tmp, src, mask, mask_size);
    convolve_even(width, height, dst, tmp, mask, mask_size);
}
