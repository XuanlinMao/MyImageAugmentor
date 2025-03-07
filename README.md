# **ImageAugmentor: A Julia Package for Image Augmentation** (STAT244 2025 Spring)  

## **Overview**  
In this project, we have developed a Julia package for **image augmentation**, designed to enhance datasets and improve the performance of vision models such as CNNs.  

### **Supported Augmentations**  
This package includes the following augmentation operations:  

- **Geometric Transformations**  
  - `Padding`  
  - `Resize`  
  - `Rotate`  
  - `Flip`  
  - `Crop`  
  - `AffineTransform`  
    - Shear  
    - Translate  
    - Scale  

- **Color and Noise Adjustments**  
  - `ColorAdjust`  
    - Brightness  
    - Contrast  
  - `AddNoise`  

- **Region-Based Augmentations**  
  - `Erase`  
  - `GridDropout`  

## **Examples**  
We demonstrate the effect of each augmentation operation using **image_0** in the [ImageAugmentor/img_output](./ImageAugmentor/img_output) folder.  

## **How to Use**  
We provide an example using **10 images**, where each image is randomly augmented **4 times** and saved in the `img_aug` folder. You can reproduce this process with the following steps:  

```sh
git clone xxx
cd MyImageAugmentor
sh run.sh
```
