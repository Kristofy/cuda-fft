# Project
This application runs 2d fft on the input image, and produces an output image of said fft.
git
This project uses the ppm(P3) file format because it does not require any compression or uncompression, 
The magick portable linux tool is capable of converting from png to ppm and vice versa

# Make
If make is installed and the dependencies are met, then following capabilities are awailable:

- make build
    - builds the application, note that if you change a header file, then the application must be clean built
- make clean
    - clears any temporary files, and the executable
- make run
    - builds the application if it's not build, and then runs it

# Dependency
    Cuda must be installed
    The make file is for linux based systems, but if you compile by hand then it should be cross compatible with other os-es
    The project uses nvcc, and cufft libraries