module ImageAugmentor

using Random, Images
export augment, 
    #    padding, resize, rotate, flip, crop, affine_transform, color_adjust, add_noise, occlude_region,
       Padding, Resize, Rotate, Flip, Crop, AffineTransform, ColorAdjust, AddNoise, Erase, GridDropout


# Define the abstract class. It is used to realize the sequence of augmentation
abstract type Augmentation end

struct Padding <: Augmentation
    # number of pixels to pad in different directions
    top::Int 
    bottom::Int
    left::Int
    right::Int
    # value to fill
    value::Real 
end

function padding(img::AbstractArray, p::Padding)
    """
    Pad the image in four directions and fill with the value provided
    """
    # value must be in [0,1] or else the result cannot be converted to RBG
    @assert (p.value >=0) && (p.value <=1) "value to pad must be in range [0,1]"
    h, w, c = size(img)
    
    new_h = h + p.top + p.bottom
    new_w = w + p.left + p.right
    
    res = fill(p.value, new_h, new_w, c)
    res[(p.top+1):(p.top+h), (p.left+1):(p.left+w), :] = img
    return res
end

struct Resize <: Augmentation
    height::Int
    width::Int
    method::Symbol  # :nearest, :linear
end


function resize(img::AbstractArray, r::Resize)
    """
    Resize the image to the specified size
    """
    if r.method == :nearest
        _resize_nearest(img, r.height, r.width)
    elseif r.method == :linear
        _resize_linear(img, r.height, r.width)
    else
        error("Unsupported method: $(r.method). Only nearest and linear resize are supported")
    end
end


function _resize_nearest(img::AbstractArray, new_h::Int, new_w::Int)
    """
    Resize the image through nearest interpolation
    """
    h, w, c = size(img)
    resized = similar(img, new_h, new_w, c)
    for ci in 1:c
        for hi in 1:new_h
            for wi in 1:new_w
                h_ori = clamp(Int(ceil(hi * h / new_h)), 1, h) # nearest h
                w_ori = clamp(Int(ceil(wi * w / new_w)), 1, w) # nearest w
                resized[hi,wi,ci] = img[h_ori, w_ori, ci] # interpolation
            end
        end
    end
    return resized
end


function _resize_linear(img::AbstractArray, new_h::Int, new_w::Int)
    """
    Resize the image through bilinear interpolation
    """
    h, w, c = size(img)
    res = similar(img, new_h, new_w, c)
    for ci in 1:c
        for hi in 1:new_h
            for wi in 1:new_w
                h_ori = (hi - 1) * (h - 1) / (new_h - 1) + 1
                w_ori = (wi - 1) * (w - 1) / (new_w - 1) + 1
                h1 = clamp(Int(floor(h_ori)), 1, h-1)
                w1 = clamp(Int(floor(w_ori)), 1, w-1)
                h2 = clamp(h1 + 1, 1, h)
                w2 = clamp(w1 + 1, 1, w)

                w_h = h_ori - h1 # weight of height
                w_w = w_ori - w1 # weight of width

                top = (1 - w_w) * img[h1, w1, ci] + w_w * img[h1, w2, ci]
                bottom = (1 - w_w) * img[h2, w1, ci] + w_w * img[h2, w2, ci]
                res[hi, wi, ci] = (1 - w_h) * top + w_h * bottom
            end
        end
    end
    res
end


struct Rotate <: Augmentation
    angle::Real
    value::Number # value to fill in blank after rotation
end

function rotate(img::AbstractArray, r::Rotate)
    """
    Rotate counterclockwise around the center.
    r.angle: angle in degree (ex. 0, 90, 180...)
    r.value: value to pad after rotation
    """
    @assert (r.value >=0) && (r.value <=1) "value to pad must be in range [0,1]"
    theta = deg2rad(r.angle)
    h, w, c = size(img)
    
    # calculate the new height and width
    new_h = Int(ceil(h * abs(cos(theta)) + w * abs(sin(theta))))
    new_w = Int(ceil(h * abs(sin(theta)) + w * abs(cos(theta))))
    
    # rotate around the center
    center = [clamp(h/2, 1, h), clamp(w/2, 1, w)]
    new_center = [clamp(new_h/2, 1, new_h), clamp(new_w/2, 1, new_w)]
    
    res = fill(r.value, new_h, new_w, c)
    for ci in 1:c
        for hi in 1:new_h
            for wi in 1:new_w
                # https://en.wikipedia.org/wiki/Rotation_matrix
                w_ori = (wi - new_center[2]) * cos(theta) - (hi - new_center[1]) * sin(theta) + center[2]
                h_ori = (wi - new_center[2]) * sin(theta) + (hi - new_center[1]) * cos(theta) + center[1]
                w_floor = clamp(Int(floor(w_ori)), 1, w)
                h_floor = clamp(Int(floor(h_ori)), 1, h)
                
                # if it is out of index, continue
                if (1 <= w_ori) && (w_ori <= w) && (1 <= h_ori) && (h_ori <= h)
                    w_floor = Int(floor(w_ori))
                    h_floor = Int(floor(h_ori))
                    res[hi, wi, ci] = img[h_floor, w_floor, ci]
                end
            end
        end
    end

    return res
end


struct Flip <: Augmentation
    direction::Symbol
end

function flip(img::AbstractArray, f::Flip)
    """
    Flip the image in horizontal or vertical direction
    """
    h, w, c = size(img)
    res = copy(img)

    if f.direction == :horizontal
        for j in 1:w
            res[:, w - j + 1, :] = img[:, j, :]
        end
    elseif f.direction == :vertical
        for i in 1:h
            res[h - i + 1, :, :] = img[i, :, :]
        end
    else
        error("Unsupported direction: $(f.direction). Flip direction must be :horizontal or :vertical!")
    end

    return res
end



struct Crop <: Augmentation
    mode::Symbol # :padding, :resize
    ratio::Tuple{Float64,Float64}
    value::Real
end


function crop(img::AbstractArray, cr::Crop)
    """
    Crop the image according to the given ratio.
    """
    @assert (0 < cr.ratio[1] <= 1) && (0 < cr.ratio[2] <= 1) "Ratio must be in the range of (0,1]"
    @assert (0<= cr.value <= 1) "Value must be in the range of [0,1]"
    
    h, w, c = size(img)
    new_h = floor(Int, h * cr.ratio[1])
    new_w = floor(Int, w * cr.ratio[2])
    
    y, x = (rand(1:(h - new_h + 1)), rand(1:(w - new_w + 1)))
    
    res = img[y:(y + new_h - 1), x:(x + new_w - 1), :]
    
    # resize the new img
    if cr.mode == :resize
        return resize(res, Resize(h, w, :linear))
    # pad the new img
    elseif cr.mode == :padding
        top = div(h - new_h, 2)
        bottom = h - new_h - top
        left = div(w - new_w, 2)
        right = w - new_w - left
        return padding(res, Padding(top, bottom, left, right, cr.value))
    else
        error("Unsupported mode: $(cr.mode)")
    end
end



struct AffineTransform <: Augmentation
    method::Symbol #:shear, :translate, :scale
    params::Tuple{Real, Real}
    value::Real
end

function affine_transform(img::AbstractArray, a::AffineTransform)
    """
    Affine transformation of the image.
    The params depens on the method.
    See https://en.wikipedia.org/wiki/Affine_transformation for reference
    Shear Matrix: [1 params[1] 0; params[2] 1 0; 0 0 1]
    Translate Matrix: [1 0 params[1]; 0 1 params[2]; 0 0 1]
    Scale Matrix: [params[1] 0 0; 0 params[2] 0; 0 0 1]
    """
    h, w, c = size(img)
    if a.method == :shear
        cx, cy = a.params
        A = [1 cx 0; cy 1 0; 0 0 1]
    elseif a.method == :translate
        tx, ty = a.params
        A = [1 0 tx; 0 1 ty; 0 0 1]
    elseif a.method == :scale
        cx, cy = a.params
        A = [cx 0 0; 0 cy 0; 0 0 1]
    else
        error("Unsupported affine transform method $(a.method).")
    end
    
    res = fill(a.value, h, w, c)
    for ci in 1:c
        for hi in 1:h
            for wi in 1:w
                coords = A * [wi; hi; 1]
                new_x = round(Int, coords[1])
                new_y = round(Int, coords[2])
                
                if (1 <= new_x <= w) && (1 <= new_y <= h)
                    res[hi, wi, ci] = img[new_y, new_x, ci]
                end
            end
        end
    end
    return res
end



struct ColorAdjust <: Augmentation
    type::Symbol # :brightness, :contrast
    factor::Float64 
end


function color_adjust(img::AbstractArray, ca::ColorAdjust)
    """
    Adjust the color style of the image.
    factor >= 0 when type = :brightness
    factor in [0, 1] when type = :contrast
    """
    res = copy(img)
    
    if ca.type == :brightness
        @assert ca.factor >= 0 "Factor >= 0 when type = :brightness"
        res .*= ca.factor
    elseif ca.type == :contrast
        @assert 0 <= ca.factor <= 1 "Factor in [0, 1] when type = :contrast"
        # https://www.dfstudios.co.uk/articles/programming/image-programming-algorithms/image-processing-algorithms-part-5-contrast-adjustment/
        factor = (259.0 * (ca.factor * 255.0 + 255.0)) / (255.0 * (259.0 - ca.factor * 255.0))
        res[:,:,1] = factor .* (img[:,:,1] .- 0.5) .+ 0.5
        res[:,:,2] = factor .* (img[:,:,2] .- 0.5) .+ 0.5
        res[:,:,3] = factor .* (img[:,:,3] .- 0.5) .+ 0.5

    else
        error("Unsupported color adjustment type  $(ca.type)")
    end
    
    clamp!(res, 0, 1) # make sure the result can be converted to RGB 
    return res
end



struct AddNoise <: Augmentation
    std::Real
end

function add_noise(img::AbstractArray, a::AddNoise)
    """
    Add gaussian noise to the image.
    AddNoise.std is in the scale of (0, 255). We recommend setting it between 10-30.
    """
    res = copy(img)
    noise = randn(size(img)) .* (a.std / 255.0)
    res .+= noise
    clamp!(res, 0, 1)
    return res
end



struct Erase <: Augmentation
    scale::Tuple{Real, Real}
    num_regions::Int
    value::Real
end

function erase(img::AbstractArray, o::Erase)
    @assert (0 < o.scale[1] < 1) && (0 < o.scale[2] < 1) "Erase.scale must be in (0,1)!"
    @assert (0 <= o.value <= 1) "GridDropout.value must be between 0 and 1"
    h, w, c = size(img)
    res = copy(img)
    
    for _ in 1:o.num_regions
        # size of area to erase
        eh = floor(Int, h * o.scale[1]) 
        ew = floor(Int, w * o.scale[2])
        # left top coordinate
        y = rand(1:(h - eh + 1))
        x = rand(1:(w - ew + 1))
        res[y:(y+eh-1), x:(x+ew-1), :] .= o.value
    end

    return res
end

struct GridDropout <: Augmentation
    grid_num::Int
    p::Real
    value::Real
end

function grid_dropout(img::AbstractArray, o::GridDropout)
    @assert (0 <= o.p <= 1) "GridDropout.p must be between 0 and 1"
    @assert (0 <= o.value <= 1) "GridDropout.value must be between 0 and 1"
    h, w, c = size(img)
    res = copy(img)

    grid_h = div(h, o.grid_num)
    grid_w = div(w, o.grid_num)

    for i in 0:o.grid_num-1
        for j in 0:o.grid_num-1
            if rand() < o.p
                i_start = i * grid_h + 1
                j_start = j * grid_w + 1
                i_end = min(i_start + grid_h - 1, h)
                j_end = min(j_start + grid_w - 1, w)
                res[i_start:i_end, j_start:j_end, :] .= o.value
            end
        end
    end

    return res
end



function augment(img, operations::Vector{<:Augmentation})
    result = copy(img) # avoid inplace modification
    result = Float32.(channelview(result))
    @assert ndims(result) == 3 "Dims of the image must be (H,W,C)!"
    result = permutedims(result, (2, 3, 1))
    for op in operations
        result = _apply_augmentation(result, op)
    end
    # convert back to the RGB format
    result = colorview(RGB, permutedims(result, (3, 1, 2)))
    return result
end

function _apply_augmentation(img, op::Augmentation)
    if op isa Padding
        return padding(img, op)
    elseif op isa Resize
        return resize(img, op)
    elseif op isa Rotate
        return rotate(img, op)
    elseif op isa Flip
        return flip(img, op)
    elseif op isa Crop
        return crop(img, op)
    elseif op isa AffineTransform
        return affine_transform(img, op)
    elseif op isa ColorAdjust
        return color_adjust(img, op)
    elseif op isa AddNoise
        return add_noise(img, op)
    elseif op isa Erase
        return erase(img, op)
    elseif op isa GridDropout
        return grid_dropout(img, op)
    else
        error("Unsupported augmentation type!")
    end
end


end # module
