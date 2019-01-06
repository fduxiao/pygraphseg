try:
    from Cython.Build import cythonize
except ImportError:
    print("Please install cython! See http://cython.org.")
    cythonize = None
    exit(-1)

from setuptools import setup, Extension
import os
import pathlib

# root path of the package
here = pathlib.Path(os.path.abspath(os.path.dirname(__file__)))


with open(here/'README.md', encoding="utf-8") as fh:
    long_description = fh.read()

pygraphseg = Extension('pygraphseg', sources=[
    str(here/'pygraphseg'/'types.c'),
    str(here/'pygraphseg'/'gaussian.c'),
    str(here/'pygraphseg'/'pygraphseg.pyx'),
])

setup(
    name="pygraphseg",
    version="0.0.1",
    author="fduxiao",
    description="An implementation of http://cs.brown.edu/~pff/papers/seg-ijcv.pdf in C",
    long_description=long_description,
    url="https://github.com/fduxiao/pygraphseg",
    # packages=find_packages(exclude=["tests", "docs"]),
    classifiers=[
        "Development Status :: 1 - Planning",
        "Programming Language :: Python :: 3",
        "Topic :: Multimedia :: Graphics",
        "License :: OSI Approved :: GNU Lesser General Public License v3 or later (LGPLv3+)",
        "Operating System :: OS Independent",
    ],
    ext_modules=cythonize(pygraphseg),
    install_requires=['cython'],
)
