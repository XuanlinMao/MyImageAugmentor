include("ImageAugmentor/src/ImageAugmentor.jl")

using .ImageAugmentor, Images, FileIO, ImageView, Random, Base.Threads

# define the operations that may be randomly used
ops = [
    ColorAdjust(:contrast, 0.1),
    ColorAdjust(:brightness, 1.1),
    Flip(:horizontal),
    Flip(:vertical),
    Rotate(10, 0.5),
    GridDropout(8, 0.1, 0.),
    AddNoise(20),
    Crop(:resize, (0.9, 0.9), 0.5),
    Erase((0.2,0.2), 2, 0.),
    AffineTransform(:shear, (0.2,0.1), 0.5),
]

# directory of original images
img_dir = "img/"
# directory of augmented images
img_out_dir = "img_aug/"

mkpath(img_out_dir)

Random.seed!(123)

image_files = readdir(img_dir, join=true)[1:10]

function augment_image(img_path, out_dir, ops, num_aug=4)
    img_ori = load(img_path)
    file_name = splitext(basename(img_path))[1] # filename
    save(joinpath(out_dir, "$(file_name).png"), img_ori) # save the original file
    for i in 1:num_aug
        selected_ops = vcat(rand(ops[1:end], num_aug), Resize(100, 100, :linear))
        augmented_img = augment(img_ori, selected_ops)
        out_path = joinpath(out_dir, "$(file_name)_aug_$i.png")
        save(out_path, augmented_img)
    end
end

@threads for img_path in image_files
    file_name = splitext(basename(img_path))[1] # filename
    if startswith(file_name, "image")
        augment_image(img_path, img_out_dir, ops)
    end
end