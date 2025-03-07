using Test
using Images
include("../src/ImageAugmentor.jl")
using .ImageAugmentor, Images, FileIO, ImageView, Random

img_dir = "MyImageAugmentor/ImageAugmentor/img"
img_out_dir = "MyImageAugmentor/ImageAugmentor/img_output"
Random.seed!(123)

# save the original image
img_ori = load(joinpath(img_dir, "image_0.png"))
save(joinpath(img_out_dir, "test_ori.png"), img_ori)

# test linear resize
ops = [
    Resize(100, 100, :linear)
]

save(joinpath(img_out_dir, "test_resize_linear.png"), augment(img_ori, ops))

# test nearest resize
ops = [
    Resize(100, 100, :nearest)
]
save(joinpath(img_out_dir, "test_resize_nearest.png"), augment(img_ori, ops))

# test padding
ops = [
    Padding(10, 0, 20, 0, 0.5)
]
save(joinpath(img_out_dir, "test_padding.png"), augment(img_ori, ops))

# test padding
ops = [
    Rotate(30, 0.5)
]
save(joinpath(img_out_dir, "test_rotate.png"), augment(img_ori, ops))

# test flip
ops = [
    Flip(:horizontal)
]
save(joinpath(img_out_dir, "test_flip.png"), augment(img_ori, ops))

# test crop
ops = [
    Crop(:padding, (0.8,0.6), 0.5)
]
save(joinpath(img_out_dir, "test_crop_padding.png"), augment(img_ori, ops))
ops = [
    Crop(:resize, (0.8,0.6), 0.5)
]
save(joinpath(img_out_dir, "test_crop_resize.png"), augment(img_ori, ops))

# test affine transform
ops = [
    AffineTransform(:shear, (0.2,0.1), 0.5)
]
save(joinpath(img_out_dir, "test_affine_shear.png"), augment(img_ori, ops))
ops = [
    AffineTransform(:translate, (10,-5), 0.5)
]
save(joinpath(img_out_dir, "test_affine_translate.png"), augment(img_ori, ops))
ops = [
    AffineTransform(:scale, (1.5,1), 0.5)
]
save(joinpath(img_out_dir, "test_affine_scale.png"), augment(img_ori, ops))

# test color adjustment
ops = [
    ColorAdjust(:contrast, 0.2)
]
save(joinpath(img_out_dir, "test_color_contrast.png"), augment(img_ori, ops))
ops = [
    ColorAdjust(:brightness, 2)
]
save(joinpath(img_out_dir, "test_color_brightness.png"), augment(img_ori, ops))

# test add noise
ops = [
    AddNoise(20)
]
save(joinpath(img_out_dir, "test_addnoise.png"), augment(img_ori, ops))

# test erase
ops = [
    Erase((0.2,0.2), 5, 0.)
]
save(joinpath(img_out_dir, "test_erase.png"), augment(img_ori, ops))

# test grid dropout
ops = [
    GridDropout(8, 0.3, 0.)
]
save(joinpath(img_out_dir, "test_grid_dropout.png"), augment(img_ori, ops))


# test mixed methods
ops = [
    ColorAdjust(:contrast, 0.2),
    ColorAdjust(:brightness, 2),
    Flip(:horizontal),
    Rotate(30, 0.5),
    GridDropout(8, 0.3, 0.),
    AddNoise(20),
    Crop(:resize, (0.9,0.9), 0.5),
    Resize(100, 100, :linear)
]
save(joinpath(img_out_dir, "test_mix.png"), augment(img_ori, ops))


