# noinspection PyPackageRequirements
from skimage.data import astronaut
# noinspection PyPackageRequirements
from PIL import Image
# noinspection PyPackageRequirements
import numpy as np
import pygraphseg

ast = astronaut().copy()

# noinspection PyUnresolvedReferences
seg = pygraphseg.Segment(0.8)

image = seg.do(ast, mix_color=True)
image = np.asarray(image, dtype=np.uint8)
image = Image.fromarray(image)
image.show()
