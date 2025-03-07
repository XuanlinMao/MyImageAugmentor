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

## **Data Source**  
The dataset used in this project is **CIFAR-10** ([link](https://www.cs.toronto.edu/~kriz/cifar.html)).  
We loaded and preprocessed the dataset in `dataloader.ipynb` and saved 50 sample images in PNG format inside the [img](./img) folder for augmentation experiments.  

## **Examples**  
We demonstrate the effect of each augmentation operation using `image_0` in the [ImageAugmentor/img_output](./ImageAugmentor/img_output) folder.  

## **How to Use**  

Here is an example for the package:

```julia
using ImageAugmentor
ops = [
    ColorAdjust(:contrast, 0.2),
    Flip(:horizontal),
    Rotate(30, 0.5),
    GridDropout(8, 0.3, 0.),
    AddNoise(20),
    Crop(:resize, (0.9,0.9), 0.5),
    Resize(100, 100, :linear)
]
augment(img, ops)
```

For more complex usage involving randomness and parallelization, we provide an example using 10 images in [data_augentation.jl](./data_augentation.jl), where we will generate 4 augmented images for each image, and the new images will be saved in the `img_aug` folder. You can reproduce this process with the following steps:  

```sh
git clone https://github.com/XuanlinMao/MyImageAugmentor.git
cd MyImageAugmentor
sh run.sh
```

