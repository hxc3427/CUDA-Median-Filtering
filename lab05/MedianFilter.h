//
//  MedianFilter.h
//  hpalab5
//
//  Created by Harshdeep Singh Chawla on 10/11/16.
//  Copyright © 2016 Harshdeep Singh Chawla. All rights reserved.
//

#ifndef MedianFilter_h
#define MedianFilter_h
#include "Bitmap.h"

//Define the size of the window that will be used for filtering.
#ifndef WNIDOW_SIZE
#define WINDOW_SIZE (3)
#endif

//CPU Median Filtering
void MedianFilterCPU( Bitmap* image, Bitmap* outputImage );

//GPU Median Filtering
bool MedianFilterGPU( Bitmap* image, Bitmap* outputImage, bool sharedMemoryUse );


#endif /* MedianFilter_h */
