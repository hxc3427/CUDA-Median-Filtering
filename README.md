# CUDA-Median-Filtering

Median filtering is a commonly used noise reduction algorithm that can remove substantial salt-and- pepper kind of noise 
without losing the fidelity of edges like other blurring operations. In this lab, you will be implementing a 3x3 median 
filtering program on the GPU using shared memory. This program will clean up a corrupted grayscale bitmap. 
Three images are provided for testing. One of them is a relatively small image of Lena, one is a medium sized image of RIT, 
and the last is a large image of the Milky Way galaxy.
The algorithm should load in the image (using the provided Bitmap class) and perform median filtering first with the CPU, 
with the GPU implementation using global memory, and finally an implementation using shared memory, comparing the results 
and performance using the timing techniques covered previously. Also make sure to check for errors after important operations
such as memory allocation and the kernel launch.
