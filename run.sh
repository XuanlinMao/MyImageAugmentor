echo "Installing packages of Julia"

julia -e '
using Pkg;
Pkg.add(["Images", "FileIO", "ImageView", "Random"]);
Pkg.precompile()
'

echo "Done"

echo "Start data augmentation"
julia data_augmentation.jl
echo "Done"