cdef extern from "types.h":
    ctypedef float FLOAT
    ctypedef FLOAT* IMAGE

    IMAGE new_image(int width, int height)
    void delete_image(IMAGE img)

cdef extern from "gaussian.h":
    void gaussian(int width, int height, IMAGE src, IMAGE dst, IMAGE tmp, FLOAT* mask, int mask_size)
