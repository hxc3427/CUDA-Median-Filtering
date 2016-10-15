//
//  CPU.cpp
//  hpalab5
//
//  Created by Harshdeep Singh Chawla on 10/11/16.
//  Copyright © 2016 Harshdeep Singh Chawla. All rights reserved.
//

#include "Bitmap.h"
#include "MedianFilter.h"
#include <stdio.h>


void MedianFilterCPU( Bitmap* image, Bitmap* outputImage ){
    //creating filter
 unsigned  char filter[9];
   //getting the pixel
   for(int w=0;w<image->Width();w++){
      for(int h=0;h<image->Height();h++){   
            if(h==0 || w==0 || h==image->Height()-1 || w==image->Width()-1){

			outputImage->SetPixel(w,h, 0);
			}		
            else{
                 filter[0]=image->GetPixel(w-1,h-1);
				 filter[1]=image->GetPixel(w,h-1);
				 filter[2]=image->GetPixel(w+1,h-1);
			     filter[3]=image->GetPixel(w-1,h);
			     filter[4]=image->GetPixel(w,h);
			     filter[5]=image->GetPixel(w+1,h);
			     filter[6]=image->GetPixel(w-1,h+1);
			     filter[7]=image->GetPixel(w,h+1);
			     filter[8]=image->GetPixel(w+1,h+1);
				 ///Sorting pixels
				// std::cout <<filter[0]<<filter[1]<<filter[2]<<filter[3]<<filter[4]<<filter[5]<<filter[6]<<filter[7]<<filter[8];
            for(int k=0;k<9;k++){
                for(int l=k+1;l<9;l++){
                    if(filter[k]>filter[l]){
                       unsigned char swap;
                        swap = filter[k];
                        filter[k]=filter[l];
                        filter[l]=swap;
                    }
                }
            }
		//	std::cout <<filter[0]<<filter[1]<<filter[2]<<filter[3]<<filter[4]<<filter[5]<<filter[6]<<filter[7]<<filter[8];
    ///setting the pixel
          outputImage->SetPixel(w, h, filter[4]);
                }
			
}
   }
}
