cimport cpygraphseg
from math import exp, sqrt
from libc.stdlib cimport malloc, free


ctypedef struct represent:
    int rank
    int p
    int size


cdef class Universe:
    cdef represent* elements
    cdef int elem_size
    cdef int num
    cdef int origin_size

    def __cinit__(self, size=0):
        self.elem_size = size
        self.num = size
        self.elements = NULL
        self.origin_size = 0
        if size:
            self.init(size)

    def __dealloc__(self):
        if self.elements:
            free(self.elements)
            self.elements = NULL

    # noinspection PyAttributeOutsideInit
    cpdef init(self, int size):
        self.origin_size = size
        if self.elements is not NULL:
            if size != self.elem_size:
                free(self.elements)
                self.elements = NULL
        self.elem_size = size
        if self.elements is NULL:
            self.elements = <represent*>malloc(sizeof(represent)*size)
        for i in range(size):
            self.elements[i].rank = 0
            self.elements[i].size = 1
            self.elements[i].p = i
        self.num = size

    cpdef int num_sets(self):
        return self.num

    cpdef int size(self, int x):
        return self.elements[x].size

    cpdef int find(self, int x):
        cdef int y = x;
        while y != self.elements[y].p:
            y = self.elements[y].p
        self.elements[x].p = y
        return y

    cpdef void join(self, int x, int y):
        if self.elements[x].rank > self.elements[y].rank:
            self.elements[y].p = x
            self.elements[x].size += self.elements[y].size
        else:
            self.elements[x].p = y
            self.elements[y].size += self.elements[x].size
            if self.elements[x].rank == self.elements[y].rank:
                self.elements[y].rank += 1
        self.num -= 1

    def __len__(self):
        return self.origin_size

    def __getitem__(self, item):
        if item >= self.origin_size or item < 0:
            raise IndexError("list index out of range")
        return self.elements[item].p


cdef class Gaussian:
    cdef cpygraphseg.IMAGE tmp
    cdef cpygraphseg.IMAGE img
    cdef cpygraphseg.FLOAT* mask
    cdef int width
    cdef int height
    cdef int mask_size

    def __cinit__(self, width: int, height: int, sigma: int, gaussian_width=4.0):
        self.width = width
        self.height = height
        sigma = max(sigma, 0.01)
        self.mask_size = int(sigma * gaussian_width) + 1
        self.mask = cpygraphseg.new_image(self.mask_size, 1)
        if self.mask is NULL:
            raise MemoryError()
        for i in range(self.mask_size):
            percent = i/sigma
            self.mask[i] = exp(-0.5*percent*percent)
        # normalization
        cdef cpygraphseg.FLOAT s = 0.
        for i in range(self.mask_size):
            s += abs(self.mask[i])

        s = 2 * s + abs(self.mask[0])
        for i in range(self.mask_size):
            self.mask[i] /= s

        self.tmp = cpygraphseg.new_image(width, height)
        if self.tmp is NULL:
            raise MemoryError()
        self.img = cpygraphseg.new_image(width, height)
        if self.img is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self.mask is not NULL:
            cpygraphseg.delete_image(self.mask)

        if self.tmp is not NULL:
            cpygraphseg.delete_image(self.tmp)

        if self.img is not NULL:
            cpygraphseg.delete_image(self.img)

    cpdef do(self, array):
        cpygraphseg.gaussian(self.width, self.height, self.img, self.img, self.tmp, self.mask, self.mask_size)

    def __getitem__(self, item):
        return self.img[item]

    def __setitem__(self, key, value):
        self.img[key] = value


cdef cpygraphseg.FLOAT square(cpygraphseg.FLOAT x):
        return x * x


def calculate_edges(Gaussian r, Gaussian g, Gaussian b):
    edges = list()
    height, width = r.height, r.width

    def diff(x1, y1, x2, y2):
        return sqrt(
            square(r[x1+y1*width] - r[x2+y2*width]) +
            square(g[x1+y1*width] - g[x2+y2*width]) +
            square(b[x1+y1*width] - b[x2+y2*width])
        )
    def xy2pos(a, b):
        return b * width + a

    for y in range(height):
        for x in range(width):
            """
                . . . . . .
                . . . 4 . .
                     /
                . . *-1 . .
                    |\
                . . 2 3 . .
                . . . . . .
             """
            if x + 1 < width:
                edges.append((
                    xy2pos(x, y),
                    xy2pos(x+1, y),
                    diff(x, y, x+1, y),
                ))

            if y + 1 < height:
                edges.append((
                    xy2pos(x, y),
                    xy2pos(x, y+1),
                    diff(x, y, x, y+1),
                ))

            if x + 1 < width and y + 1 < height:
                edges.append((
                    xy2pos(x, y),
                    xy2pos(x+1, y+1),
                    diff(x, y, x+1, y+1),
                ))

            if x + 1 < width and y > 0:
                edges.append((
                    xy2pos(x, y),
                    xy2pos(x+1, y-1),
                    diff(x, y, x+1, y-1),
                ))
    return edges


# a normal python class
class Segment:

    def __init__(self, sigma=0.8, c=300, min_size=1):
        self.width = -1
        self.height = -1
        self.gaussian_r = None
        self.gaussian_g = None
        self.gaussian_b = None
        self.universe = Universe()
        self.threshold = None
        self.sigma = sigma
        self.num = 0
        self.c = c
        self.min_size=1

    def init(self, image):
        height = len(image)
        width = len(image[0])
        if height != self.height or width != self.height:
            self.height = height
            self.width = width
            self.gaussian_r = Gaussian(width, height, self.sigma)
            self.gaussian_g = Gaussian(width, height, self.sigma)
            self.gaussian_b = Gaussian(width, height, self.sigma)
            self.threshold = [0.] * (width * height)
        for y in range(height):
            for x in range(width):
                self.gaussian_r[x+y*width] = image[y][x][0]
                self.gaussian_g[x+y*width] = image[y][x][1]
                self.gaussian_b[x+y*width] = image[y][x][2]

    def do(self, image, mix_color=False, smooth=True):
        self.init(image)

        if smooth:
            self.gaussian_r.do(image)
            self.gaussian_g.do(image)
            self.gaussian_b.do(image)

        edges = calculate_edges(self.gaussian_r, self.gaussian_g, self.gaussian_b)
        n_vertex = self.width * self.height

        edges.sort(key=lambda x: x[2])
        self.universe.init(n_vertex)

        for i in range(n_vertex):
            self.threshold[i] = self.c

        for e in edges:
            a = self.universe.find(e[0])
            b = self.universe.find(e[1])
            if a != b:
                if e[2] <= self.threshold[a] and e[2] <= self.threshold[b]:
                    self.universe.join(a, b)
                    a = self.universe.find(a)
                    self.threshold[a] = e[2] + self.c/self.universe.size(a)

        # post process small components
        for e in edges:
            a = self.universe.find(e[0])
            b = self.universe.find(e[1])
            if a != b and (self.universe.size(a) < self.min_size or self.universe.size(b) < self.min_size):
                self.universe.join(a, b)

        num = self.universe.num_sets()
        self.num = num
        p_num = [num]
        rel = dict()
        def get_n(represent):
            def give_next():
                p_num[0] -= 1
                n = p_num[0]  # pop the value
                rel[represent] = lambda : n
                return n
            return rel.get(represent, give_next)()
        if not mix_color:
            result = list()
            for y in range(self.height):
                line = []
                for x in range(self.width):
                    line.append(
                        get_n(self.universe.find(x+y*self.width))
                    )
                result.append(line)
            return result
        # mix color
        color_r = [0.] * num
        color_g = [0.] * num
        color_b = [0.] * num
        for y in range(self.height):
            for x in range(self.width):
                component = self.universe.find(x+y*self.width)
                size = self.universe.size(component)
                color_r[get_n(component)] += image[y][x][0] / size
                color_g[get_n(component)] += image[y][x][1] / size
                color_b[get_n(component)] += image[y][x][2] / size
        result = [[[0, 0, 0] for x in range(self.width)] for y in range(self.height)]
        for y in range(self.height):
            for x in range(self.width):
                component = self.universe.find(x+y*self.width)
                result[y][x][0] = color_r[get_n(component)]
                result[y][x][1] = color_g[get_n(component)]
                result[y][x][2] = color_b[get_n(component)]
        return result
