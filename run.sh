julia -e '
using Pkg;
Pkg.add(["Images", "FileIO", "ImageView", "Random"]);
Pkg.precompile()
'

julia data_augmentation.jl
