//
//  main.cpp
//  hpalab5
//
//  Created by Harshdeep Singh Chawla on 10/10/16.
//  Copyright © 2016 Harshdeep Singh Chawla. All rights reserved.
//

#include "Bitmap.h"
#include "MedianFilter.h"
#include <ctime>
#include <cuda.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <iostream>

const int itrs=10;

int main() {
    // insert code here...
    
    Bitmap *inputimage= new Bitmap(),*CPUo_pimage= new Bitmap(),*GPUo_pimage= new Bitmap();
	//loading image
    inputimage->Load("milkyway.bmp");
	CPUo_pimage->Load("milkyway.bmp");
	CPUo_pimage->Save("l2.bmp");
	GPUo_pimage->Load("milkyway.bmp");
	GPUo_pimage->Save("l3.bmp");
	
	//getting height and width of the image
	int w= inputimage->Width();
	int h = inputimage->Height();
	 std::cout << "Width is "<< w <<"  Height is "<<h<<std::endl;

	 /////////////CPU///////////////////
    float start = clock();
	for(int i=0;i<itrs;i++)
    MedianFilterCPU( inputimage, CPUo_pimage);
	CPUo_pimage->Save("CPU.bmp");
    float end = clock();
    float tcpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC;
    std::cout << "Average Time per CPU Iteration is: " << tcpu << " ms" << std::endl << std::endl;


//////Waking call for gpu//////

	MedianFilterGPU( inputimage,GPUo_pimage,false );

/////////////GPU without shared memory/////////////
	float start1 = clock();
	for(int j=0;j<itrs;j++)
    MedianFilterGPU( inputimage,GPUo_pimage,false );
	CPUo_pimage->Save("GPU.bmp");
    float end1 = clock();
    float tgpu = (float)(end1 - start1) * 1000 / (float)CLOCKS_PER_SEC;
    std::cout << "Average Time per GPU Iteration with global Memory is: " << tgpu << " ms" << std::endl;
	std::cout << "Speedup : " << tcpu/tgpu<< std::endl;


	int difference1 =0;
    Bitmap *cpu1= new Bitmap(),*gpu= new Bitmap();
    cpu1->Load("CPU.bmp");
	cpu1->Save("CPUcheck1.bmp");
	gpu->Load("GPU.bmp");
	gpu->Save("GPUcheck.bmp");
	for(int height=1; height<cpu1->Height()-1; height++){
		for(int width=1; width<cpu1->Width()-1; width++){
				if(cpu1->GetPixel(width, height) != gpu->GetPixel(width, height))
				difference1++;   // increment the differences.
	}
	}
std::cout << "differnce in pixel: " <<difference1 << std::endl << std::endl ;

	/////////////GPU with shared memory/////////////
	
	float start2 = clock();
	for(int j=0;j<itrs;j++)
    MedianFilterGPU( inputimage,GPUo_pimage,true );
	CPUo_pimage->Save("GPU_SHARED.bmp");
    float end2 = clock();
    float tgpu1 = (float)(end2 - start2) * 1000 / (float)CLOCKS_PER_SEC;
    std::cout << "Average Time per GPU Iteration with Shared memory is: " << tgpu1 << " ms" << std::endl;
	std::cout << "Speedup : " << tcpu/tgpu1<< std::endl;
	//////cpu.bmp-gpushared.bmp///////////////

	int difference =0;
    Bitmap *cpu= new Bitmap(),*gpu_shared= new Bitmap();
    cpu->Load("CPU.bmp");
	cpu->Save("CPUcheck.bmp");
	gpu_shared->Load("GPU_SHARED.bmp");
	gpu_shared->Save("GPU_SHAREDcheck.bmp");
	for(int height=1; height<cpu->Height()-1; height++){
		for(int width=1; width<cpu->Width()-1; width++){
				if(cpu->GetPixel(width, height) != gpu_shared->GetPixel(width, height))
				difference++;   // increment the differences.
	}
	}
std::cout << "differnce in pixel: " <<difference << std::endl << std::endl ;
std::cout << "Result is for Iterations: " <<itrs << std::endl << std::endl ;

	_sleep(10000000);
    return 0;
}
