#ifndef __TYPES__
#define __TYPES__

typedef float FLOAT;
typedef FLOAT* IMAGE;

IMAGE new_image(int width, int height);
void delete_image(IMAGE);

#endif
