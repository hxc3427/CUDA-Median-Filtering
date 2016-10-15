//
//  GPU.cpp
//  hpalab5
//
//  Created by Harshdeep Singh Chawla on 10/11/16.
//  Copyright © 2016 Harshdeep Singh Chawla. All rights reserved.
//


#include <cuda.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>
#include "MedianFilter.h"
#include "Bitmap.h"

///Kernelk function
__global__ void MFKernel(unsigned char *inputImage, unsigned char *outputImage, int Width, int Height)
{
	// indexing for thread.
	int idy = blockIdx.y * blockDim.y + threadIdx.y;
	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	//filter mask
	unsigned char filter[9];

	/////checking boundry conditions
	if((idy==0) || (idx==0) || (idy==Height-1) || (idx==Width-1))
				outputImage[idy*Width+idx] = 0;
	else {
		for (int x = 0; x < WINDOW_SIZE; x++) { 
			for (int y = 0; y < WINDOW_SIZE; y++){
				filter[x*WINDOW_SIZE+y] = inputImage[(idy+x-1)*Width+(idx+y-1)];   // setup the filterign window.
			}
		}
		////Sorting in filter
		for (int i = 0; i < 9; i++) {
			for (int j = i + 1; j < 9; j++) {
				if (filter[i] > filter[j]) { 
					//Swap the variables.
					unsigned char tmp = filter[i];
					filter[i] = filter[j];
					filter[j] = tmp;
				}
			}
		}
		outputImage[idy*Width+idx] = filter[4];   //Set output variables.
	}
}

__global__ void MFSharedKernel(unsigned char *inputImage, unsigned char *outputImage, int Width, int Height)
{
	//Set the row and col value for each thread.
	int idy = blockIdx.y * blockDim.y + threadIdx.y;
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
    const int TILE_SIZE = 16;
	__shared__ unsigned char sharedmem[(TILE_SIZE+2)]  [(TILE_SIZE+2)];  //initialize shared memory

	//Initialize with zero
	if(threadIdx.x == 0)
		sharedmem[threadIdx.x][threadIdx.y+1] = 0;
	else if(threadIdx.x == TILE_SIZE-1)
		sharedmem[threadIdx.x + 2][threadIdx.y+1]=0;
	if (threadIdx.y == 0){
		sharedmem[threadIdx.x+1][threadIdx.y] = 0;
		if(threadIdx.x == 0)
			sharedmem[threadIdx.x][threadIdx.y] = 0;
		else if(threadIdx.x == TILE_SIZE-1)
			sharedmem[threadIdx.x+2][threadIdx.y] = 0;
	}
	else if (threadIdx.y == TILE_SIZE-1){
		sharedmem[threadIdx.x+1][threadIdx.y+2] = 0;
		if(threadIdx.x == TILE_SIZE-1)
			sharedmem[threadIdx.x+2][threadIdx.y+2] = 0;
		else if(threadIdx.x == 0)
			sharedmem[threadIdx.x][threadIdx.y+2] = 0;
	}

	//Setup pixel values
	sharedmem[threadIdx.x+1][threadIdx.y+1] = inputImage[idy*Width+idx];
	//Check for boundry conditions.
	if(threadIdx.x == 0 && (idx>0))
		sharedmem[threadIdx.x][threadIdx.y+1] = inputImage[idy*Width+(idx-1)];
	else if(threadIdx.x == TILE_SIZE-1 && (idx<Width-1))

		sharedmem[threadIdx.x + 2][threadIdx.y+1]= inputImage[idy*Width+(idx+1)];
	if (threadIdx.y == 0 && (idy>0)){
		sharedmem[threadIdx.x+1][threadIdx.y] =inputImage[(idy-1)*Width+idx];

		if(threadIdx.x == 0)
			sharedmem[threadIdx.x][threadIdx.y] = inputImage[(idy-1)*Width+(idx-1)];
		else if(threadIdx.x == TILE_SIZE-1 )
			sharedmem[threadIdx.x+2][threadIdx.y] = inputImage[(idy-1)*Width+(idx+1)];
	}
	else if (threadIdx.y == 0 && (idy<Height-1)){
		sharedmem[threadIdx.x+1][threadIdx.y+2] = inputImage[(idy+1)*Width + idx];
		if(threadIdx.x == TILE_SIZE-1)
			sharedmem[threadIdx.x+2][threadIdx.y+2] =inputImage[(idy+1)*Width+(idx+1)];
		else if(threadIdx.x == 0)
			sharedmem[threadIdx.x][threadIdx.y+2] = inputImage[(idy+1)*Width+(idx-1)];
	}

//	cudaThreadSynchronize();   //Wait for all threads to be done.

	//Setup the filter.
	unsigned char filterVector[9] = {sharedmem[threadIdx.x][threadIdx.y], sharedmem[threadIdx.x+1][threadIdx.y], sharedmem[threadIdx.x+2][threadIdx.y],
                   sharedmem[threadIdx.x][threadIdx.y+1], sharedmem[threadIdx.x+1][threadIdx.y+1], sharedmem[threadIdx.x+2][threadIdx.y+1],
                   sharedmem[threadIdx.x] [threadIdx.y+2], sharedmem[threadIdx.x+1][threadIdx.y+2], sharedmem[threadIdx.x+2][threadIdx.y+2]};

	
	{
		for (int i = 0; i < 9; i++) {
        for (int j = i + 1; j < 9; j++) {
            if (filterVector[i] > filterVector[j]) { 
				//Swap Values.
                char tmp = filterVector[i];
                filterVector[i] = filterVector[j];
                filterVector[j] = tmp;
            }
        }
    }
	outputImage[idy*Width+idx] = filterVector[4];   //Set the output image values.
	}
}



///GPU Function
bool MedianFilterGPU( Bitmap* image, Bitmap* outputImage, bool sharedMemoryUse ){

	//Cuda error and image values.
	cudaError_t status;
	int w = image->Width();
	int h = image->Height();

	int bytes =  w * h * sizeof(unsigned char);
	//initialize images.
	unsigned char *inputimage_d;
	cudaMalloc((void**) &inputimage_d, bytes);
	cudaMemcpy(inputimage_d, image->image, bytes, cudaMemcpyHostToDevice);
	
	unsigned char *outputImage_d;
	cudaMalloc((void**) &outputImage_d, bytes);
	//take block and grids.
	int TILE_SIZE=16;
	dim3 dimBlock(TILE_SIZE, TILE_SIZE);
	dim3 dimGrid((int)ceil((float)image->Width() / (float)TILE_SIZE),
				(int)ceil((float)image->Height() / (float)TILE_SIZE));

	//Check condition for shared memorey
	if (sharedMemoryUse== false){
	//kernel call
		MFKernel<<<dimGrid, dimBlock>>>(inputimage_d, outputImage_d, w, h);
		cudaThreadSynchronize();
	}
	else{
		MFSharedKernel<<<dimGrid, dimBlock>>>(inputimage_d, outputImage_d, w, h);
		cudaThreadSynchronize();
	}
	
	// save output image to host.
	cudaMemcpy(outputImage->image, outputImage_d, bytes, cudaMemcpyDeviceToHost);
	status = cudaGetLastError();              
	if (status != cudaSuccess) {                     
		std::cout << "Kernel failed for cudaMemcpy cudaMemcpyDeviceToHost: " << cudaGetErrorString(status) << 
		std::endl;
		cudaFree(inputimage_d);
		cudaFree(outputImage_d);
		return false;
	}
	//Free the memory
	cudaFree(inputimage_d);
	cudaFree(outputImage_d);
	return true;
}