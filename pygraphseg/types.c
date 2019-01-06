#include <stdlib.h>
#include "types.h"

FLOAT* new_image(int width, int height)
{
    return (FLOAT*)malloc(sizeof(FLOAT) * width * height);
}

void delete_image(FLOAT* ptr)
{
    free(ptr);
}
