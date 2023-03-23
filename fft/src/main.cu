#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <cufft.h>
#include <math.h>
#include "image.h"


__global__ void grayscale_kernel(int* d_input_image, int* d_output_image, int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x < width && y < height) {
        int idx = y * width + x;
        int r = d_input_image[3 * idx + 0];
        int g = d_input_image[3 * idx + 1];
        int b = d_input_image[3 * idx + 2];
        int color = 0.299f * r + 0.587f * g + 0.114f * b;
        d_output_image[3 * idx + 0] = color;
        d_output_image[3 * idx + 1] = color;
        d_output_image[3 * idx + 2] = color;
    }
}

__global__ void split_channels_kernel(Pixel* d_input_pixels, int width, int height, double* output_data_r, double* output_data_g, double* output_data_b) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int idy = blockIdx.y * blockDim.y + threadIdx.y;
    if (idx < width && idy < height) {
        int offset = idy * width + idx;
        output_data_r[offset] = d_input_pixels[offset].r;
        output_data_g[offset] = d_input_pixels[offset].g;
        output_data_b[offset] = d_input_pixels[offset].b;
    }
}

__global__ void merge_channels_kernel(Pixel* d_input_pixels, int width, int height, cufftDoubleComplex* d_input_data_r, cufftDoubleComplex* d_input_data_g, cufftDoubleComplex* d_input_data_b) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x < width && y < height) {
        int index = y * width + x;
        int i = 0;
        if(y < height && x * height <= width * y) {
            i = (y - 1) * width * y / (2 * height) + x;
        } else {
            int dy = height - y - 1;
            int dx = width - x - 1;
            i = (dy - 1) * width * dy / (2 * height) + dx;
        }
        d_input_pixels[index].r = (int) (std::sqrt(d_input_data_r[i].x * d_input_data_r[i].x + d_input_data_r[i].y * d_input_data_r[i].y) * 255 / (width * height));
        d_input_pixels[index].g = (int) (std::sqrt(d_input_data_g[i].x * d_input_data_g[i].x + d_input_data_g[i].y * d_input_data_g[i].y) * 255 / (width * height));
        d_input_pixels[index].b = (int) (std::sqrt(d_input_data_b[i].x * d_input_data_b[i].x + d_input_data_b[i].y * d_input_data_b[i].y) * 255 / (width * height));
    }
}


template<typename KernelT>
__host__ void run_kernel_on_image(Image& img, KernelT k){
    
    int* d_input_image;
    int* d_output_image;
    size_t image_size_bytes = img.width * img.height * 3 * sizeof(int);

    cudaMalloc(&d_input_image, image_size_bytes);
    cudaMalloc(&d_output_image, image_size_bytes);

    cudaMemcpy(d_input_image, img.pixels, image_size_bytes, cudaMemcpyHostToDevice);

    int block_size = 32;
    dim3 dim_grid((img.width + block_size - 1) / block_size, (img.height + block_size - 1) / block_size);
    dim3 dim_block(block_size, block_size);

    k<<<dim_grid, dim_block>>>(d_input_image, d_output_image, img.width, img.height);

    
    cudaMemcpy(img.pixels, d_output_image, image_size_bytes, cudaMemcpyDeviceToHost);

    cudaFree(d_input_image);
    cudaFree(d_output_image);
}

__host__ void run_fft_on_imge(Image& img){
    const int width = img.width;
    const int height = img.height;

    double* d_input_data_r;
    double* d_input_data_g;
    double* d_input_data_b;
    cudaMalloc((void**)&d_input_data_r, sizeof(double) * width * height);
    cudaMalloc((void**)&d_input_data_g, sizeof(double) * width * height);
    cudaMalloc((void**)&d_input_data_b, sizeof(double) * width * height);

    cufftDoubleComplex* d_output_data_r;
    cufftDoubleComplex* d_output_data_g;
    cufftDoubleComplex* d_output_data_b;
    cudaMalloc((void**)&d_output_data_r, sizeof(cufftDoubleComplex) * width * (height / 2 + 1));
    cudaMalloc((void**)&d_output_data_g, sizeof(cufftDoubleComplex) * width * (height / 2 + 1));
    cudaMalloc((void**)&d_output_data_b, sizeof(cufftDoubleComplex) * width * (height / 2 + 1));

    Pixel *d_input_pixels;
    cudaMalloc((void**)&d_input_pixels, sizeof(Pixel) * width * height);

    cudaMemcpy(d_input_pixels, img.pixels, sizeof(Pixel) * width * height, cudaMemcpyHostToDevice);
    
    dim3 blockSize(32, 32);
    dim3 gridSize((width + blockSize.x - 1) / blockSize.x, (height + blockSize.y - 1) / blockSize.y);
   
    split_channels_kernel<<<gridSize, blockSize>>>(d_input_pixels, width, height, d_input_data_r, d_input_data_g, d_input_data_b);

    cufftHandle plan_r, plan_g, plan_b;
    cufftPlan2d(&plan_r, width, height, CUFFT_D2Z);
    cufftPlan2d(&plan_g, width, height, CUFFT_D2Z);
    cufftPlan2d(&plan_b, width, height, CUFFT_D2Z);

    cufftExecD2Z(plan_r, d_input_data_r, (cufftDoubleComplex*)d_output_data_r);
    cufftExecD2Z(plan_g, d_input_data_g, (cufftDoubleComplex*)d_output_data_g);
    cufftExecD2Z(plan_b, d_input_data_b, (cufftDoubleComplex*)d_output_data_b);

    merge_channels_kernel<<<gridSize, blockSize>>>(d_input_pixels, width, height, d_output_data_r, d_output_data_g, d_output_data_b);

    cudaMemcpy(img.pixels, d_input_pixels, sizeof(Pixel) * width * height, cudaMemcpyDeviceToHost);

    cudaFree(d_input_data_r);
    cudaFree(d_input_data_g);
    cudaFree(d_input_data_b);
    cudaFree(d_output_data_r);
    cudaFree(d_output_data_g);
    cudaFree(d_output_data_b);
    cudaFree(d_input_pixels);
    cufftDestroy(plan_r);
    cufftDestroy(plan_g);
    cufftDestroy(plan_b);
}


int main(int argc, char **argv) {
    // Load input image data
    Image img(argv[1]);
    // int width = img.width;
    // int height = img.height;
    // run_kernel_on_image(img, grayscale_kernel);
    run_fft_on_imge(img);
    // run_kernel_on_image(img, grayscale_kernel);

    // img.WriteImage(std::string(argv[2])+"_gray");


    // double* h_input_data = (double*)malloc(sizeof(double) * width * height); // Load input image data
    // for(int i = 0; i < width*height; i++){
    //     h_input_data[i] = img.pixels[i].r ;
    // }

    // // Execute 2D FFT
    // fft2d(h_input_data, width, height, h_input_data);

    // for(int i = 0; i < width * height; i++){
    //     img.pixels[i] = {(int)h_input_data[i],(int)h_input_data[i],(int)h_input_data[i]};
    // }

    img.WriteImage(argv[2]);
    // Free memory
    // free(h_input_data);

    return 0;
}
