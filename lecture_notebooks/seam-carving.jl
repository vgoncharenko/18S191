### A Pluto.jl notebook ###
# v0.11.12

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ e196fa66-eef5-11ea-2afe-c9fcb6c48937
begin
	# Poor man's Project.toml
	using Pkg

	Pkg.add(["Images",
			"ImageMagick",
			"PlutoUI",
			"Plots",
			"PaddedViews",
			"ImageFiltering"])
end

# ╔═╡ 18388072-efef-11ea-00d2-f74d34786e24
using ImageFiltering

# ╔═╡ fe19ad0a-ef04-11ea-1e5f-1bfcbbb51302
using PlutoUI

# ╔═╡ 0316b94c-eef6-11ea-19bc-dbc959901bb5
using Images
using ImageMagick
using Statistics
using LinearAlgebra
using Plots
using PaddedViews
using ImageFiltering

# ╔═╡ cb335074-eef7-11ea-24e8-c39a325166a1
md"""
# Seam Carving

1. We use convolution with Sobel filters for "edge detection".
2. We use that to write an algorithm that removes "uninteresting"
   bits of an image in order to shrink it.
"""

# ╔═╡ 65ec23be-efef-11ea-077c-b7cb0ec91b74


# ╔═╡ d2ae6dd2-eef9-11ea-02df-255ec3b46a36
# img = load(download("https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg/480px-Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg"))
img = load(download("https://imgur.com/RbrCJLX.png"))
#img = load(download("https://web.mit.edu/facilities/photos/construction/Projects/stata/1_large.jpg", tempname()))

# ╔═╡ 0b6010a8-eef6-11ea-3ad6-c1f10e30a413
# brightness of a color is the sum of the r,g,b values (stored as float32's)
brightness(c::AbstractRGB) = mean((c.r, c.g, c.b))

# ╔═╡ fc1c43cc-eef6-11ea-0fc4-a90ac4336964
Gray.(brightness.(img) ./ maximum(brightness.(img)))

# ╔═╡ 2afc2e3c-eef7-11ea-3dd4-797539cbf4da
# brightness of an image bordered with zeros
function pad(X::Array, elem=zero(eltype(X)))
	h, w = size(X)
	PaddedView(elem, X, (0:h+1, 0:w+1))
end

# ╔═╡ 82c0d0c8-efec-11ea-1bb9-83134ecb877e
md"""
# Edge detection


Here we convolve the brightness with the Sobel filter to compute a measure of "gradient" along the `x` and `y` directions.
"""

# ╔═╡ 089e1fd4-efed-11ea-12dc-09f9e912d4ab
function clamp_at_boundary(M, i, j)
	return M[
		clamp(i, 1, size(M, 1)),
		clamp(j, 1, size(M, 2)),	
	]
end

# ╔═╡ fcf46120-efec-11ea-06b9-45f470899cb2
function convolve(M, kernel, M_index_func=clamp_at_boundary)
    height = size(kernel, 1)
    width = size(kernel, 2)
    
    half_height = height ÷ 2
    half_width = width ÷ 2
    
    new_image = similar(M)
	
    # (i, j) loop over the original image
    @inbounds for i in 1:size(M, 1)
        for j in 1:size(M, 2)
            # (k, l) loop over the neighbouring pixels
			new_image[i, j] = sum([
				kernel[k, l] * M_index_func(M, i - k, j - l)
				for k in -half_height:-half_height + height - 1
				for l in -half_width:-half_width + width - 1
			])
        end
    end
    
    return new_image
end

# ╔═╡ dec62538-efee-11ea-1e03-0b801e61e91c
function show_colored_kernel(kernel)
	to_rgb(x) = RGB(max(-x, 0), max(x, 0), 0)
	to_rgb.(kernel) / maximum(abs.(kernel))
end


# ╔═╡ 69fbcbb0-eef7-11ea-3adf-576546a2420c
# the 3x3 stencil for energy
# take a 3x3 sub-matrix and compute the energy.
function gradient(b)
    x_energy = b[1,1] + 2b[2,1] + b[3,1] - b[1,3] - 2b[2,3] - b[3,3]
    y_energy = b[1,1] + 2b[1,2] + b[1,3] - b[3,1] - 2b[3,2] - b[3,3]
    [x_energy y_energy]
end


# ╔═╡ d6e46ac4-efa7-11ea-3311-c99448c2ad13
function energy_stencil(b)
	norm(gradient(b))
end

# ╔═╡ fb32e0ea-eef8-11ea-2ad2-0d2f1f48a82f
function apply_stencil(stencil, X)
	m, n = size(X)
	[stencil(X[i-1:i+1, j-1:j+1]) for i = 1:m-2, j=1:n-2]
end

# ╔═╡ a3e459b0-efa5-11ea-35b4-494093ef34e4
let
	m, n = (10,10)
	Gray.(pad([i+j for i=1:m,j=1:n] ./ (m+n)))
end

# ╔═╡ a14c98c2-efad-11ea-3543-9f92301bf72e
pad(img)[0,0]

# ╔═╡ cf10d358-efae-11ea-0f5b-198d0d26fbb2


# ╔═╡ 495de0a0-efa6-11ea-3665-7d12c97fb3cb
let
	m, n = (20,20)
	grid = [i+j for i=1:m,j=1:n] ./ (m+n)
	gradients = apply_stencil(gradient, pad(grid))

	ycoords = (1:m) .* ones(n)'
	xcoords = ones(m) .* (1:n)'

	∇x = map(first, gradients)
	∇y = map(last, gradients)
	
	quiver(xcoords, ycoords, quiver=vec.((∇x,∇y) .* 2), ratio=1)
end

# ╔═╡ d71dbf8e-efab-11ea-1f67-5b975a33fbe1
#=

	
	ycoords = (1:m) .* ones(n)'
	xcoords = ones(m) .* (1:n)'
	
	∇x = map(first, gradients)
	∇y = map(last, gradients)
	
	quiver(xcoords, ycoords, quiver=vec.((∇x,∇y) .* 2), ratio=1)
=#

# ╔═╡ 4d62f328-eef9-11ea-25b1-dba6c2fc6274
energy(X) = apply_stencil(energy_stencil, X)

# ╔═╡ 9b569f8a-eefe-11ea-3bc3-59bc1c60be30
e = energy(pad(brightness.(img)))

# ╔═╡ 8f80499a-eef9-11ea-1eb4-7d3083555a70
Gray.(1 .- e./ maximum(e))

# ╔═╡ 172c7612-efee-11ea-077a-5d5c6e2505a4
function shrink_image(image, ratio=5)
	(height, width) = size(image)
	new_height = height ÷ ratio - 1
	new_width = width ÷ ratio - 1
	list = [
		mean(image[
			ratio * i:ratio * (i + 1),
			ratio * j:ratio * (j + 1),
		])
		for j in 1:new_width
		for i in 1:new_height
	]
	reshape(list, new_height, new_width)
end

# ╔═╡ 19e6a72e-efee-11ea-0511-5b5b2eac7f60


# ╔═╡ 025e2c94-eefb-11ea-12cb-f56f34886334
md"""
# Seam with least energy

Now our task is to find a seam that goes from top most row to the bottom most row. At every step in going down, the path is allowed to go south west, south or south east. We want to find a seam with the minimum possible sum of energies.

We start by writing a `least_energy` function which given a matrix of energies, returns
a matrix of minimum possible energy starting from that pixel going up to a pixel in the bottom most row.
"""

# ╔═╡ acc1ee8c-eef9-11ea-01ac-9b9e9c4167b3
#            e[x,y] 
#          ↙   ↓   ↘       <--pick the next path which gives the least overall energy
#  e[x-1,y+1] e[x,y+1]  e[x+1,y+1]     
#
# Basic Comp:   e[x,y] += min( e[x-1,y+1],e[x,y],e[x+1,y])
#               dirs records which one from (-1==SW,0==S,1==SE)

function least_energy(E)
	least_E = zeros(size(E))
	dirs = zeros(Int, size(E))
	least_E[end, :] .= E[end, :] # the minimum energy on the last row is the energy
	                             # itself
	padded_least_E = pad(least_E, Inf)
	m, n = size(E)
	# Go from the last row up, finding the minimum energy
	for i in m-1:-1:1
		for j in 1:n
			e, dir = findmin(padded_least_E[i+1, j-1:j+1])
			least_E[i,j] += e
			dirs[i, j] = (-1, 0, 1)[dir]
		end
	end
	least_E, dirs
end

# ╔═╡ ce433b6a-efad-11ea-1572-2fcb4fe45c84


# ╔═╡ 84d3afe4-eefe-11ea-1e31-bf3b2af4aecd
least_e, dirs = least_energy(e)

# ╔═╡ b507480a-ef01-11ea-21c4-63d19fac19ab
getindex.(([" ", "↙", "↓", "↘"],), dirs.+3)

# ╔═╡ 7d8b20a2-ef03-11ea-1c9e-fdf49a397619
md"## Remove seams"

# ╔═╡ f690b06a-ef31-11ea-003b-4f2b2f82a9c3
md"""
Compressing an image horizontally involves a number of seams of lowest energy successively.
"""

# ╔═╡ 977b6b98-ef03-11ea-0176-551fc29729ab
function get_seam_at(dirs, j)
	m = size(dirs, 1)
	js = fill(0, m)
	js[1] = j
	for i=2:m
		js[i] = js[i-1] + dirs[i-1, js[i-1]]
	end
	tuple.(1:m, js)
end

# ╔═╡ 9abbb158-ef03-11ea-39df-a3e8aa792c50
get_seam_at(dirs, 2)

# ╔═╡ cf9a9124-ef04-11ea-14a4-abf930edc7cc
@bind start_column Slider(1:size(img, 2))

# ╔═╡ 772a4d68-ef04-11ea-366a-f7ae9e1634f6
path = get_seam_at(dirs, start_column)

# ╔═╡ 14f72976-ef05-11ea-2ad5-9f0914f9cf58
function mark_path(img, path)
	img′ = copy(img)
	for i in path
		img′[i...] = RGB(1,0,0)
	end
	img′
end

# ╔═╡ 552fb92e-ef05-11ea-0a79-dd7a6760089a
mark_path(img, path)

# ╔═╡ 4f23bc54-ef0f-11ea-06a9-35ca3ece421e
function rm_path(img, path)
	img′ = img[:, 1:end-1] # one less column
	for (i, j) in path
		img′[i, 1:j-1] .= img[i, 1:j-1]
		img′[i, j:end] .= img[i, j+1:end]
	end
	img′
end

# ╔═╡ 0892c568-ef2e-11ea-35af-0d4857ee01fc
rm_path(img, get_seam_at(dirs, 42))

# ╔═╡ 4de89bf6-ef2e-11ea-36be-eb5b11db1270
(size(img), size(rm_path(img, get_seam_at(dirs, 42))))

# ╔═╡ b401f398-ef0f-11ea-38fe-012b7bc8a4fa
function shrink_n(img, n)
	imgs = []

	e = energy(pad(brightness.(img)))
	for i=1:n
		least_E, dirs = least_energy(e)
		_, min_j = findmin(@view least_E[1, :])
		seam = get_seam_at(dirs, min_j)
		img = rm_path(img, seam)
		e = rm_path(e, seam)
		push!(imgs, img)
	end
	imgs
end

# ╔═╡ 2eb459d4-ef36-11ea-1f74-b53ffec7a1ed
carved = shrink_n(img, 300); # returns a vector of n successively smaller images

# ╔═╡ 7038abe4-ef36-11ea-11a5-75e57ab51032
@bind n Slider(1:length(carved))

# ╔═╡ 2d6c6820-ef2d-11ea-1704-49bb5188cfcc
md"shrunk by $n:"

# ╔═╡ fa6a2152-ef0f-11ea-0e67-0d1a6599e779
[img carved[n]]

# ╔═╡ 15d1e5dc-ef2f-11ea-093a-417108bcd495
[size(img) size(carved[n])]

# ╔═╡ Cell order:
# ╠═e196fa66-eef5-11ea-2afe-c9fcb6c48937
# ╠═0316b94c-eef6-11ea-19bc-dbc959901bb5
# ╠═cb335074-eef7-11ea-24e8-c39a325166a1
# ╠═65ec23be-efef-11ea-077c-b7cb0ec91b74
# ╠═d2ae6dd2-eef9-11ea-02df-255ec3b46a36
# ╠═0b6010a8-eef6-11ea-3ad6-c1f10e30a413
# ╠═fc1c43cc-eef6-11ea-0fc4-a90ac4336964
# ╟─2afc2e3c-eef7-11ea-3dd4-797539cbf4da
# ╟─82c0d0c8-efec-11ea-1bb9-83134ecb877e
# ╟─089e1fd4-efed-11ea-12dc-09f9e912d4ab
# ╟─fcf46120-efec-11ea-06b9-45f470899cb2
# ╟─dec62538-efee-11ea-1e03-0b801e61e91c
# ╠═18388072-efef-11ea-00d2-f74d34786e24
# ╠═69fbcbb0-eef7-11ea-3adf-576546a2420c
# ╠═d6e46ac4-efa7-11ea-3311-c99448c2ad13
# ╠═fb32e0ea-eef8-11ea-2ad2-0d2f1f48a82f
# ╠═a3e459b0-efa5-11ea-35b4-494093ef34e4
# ╠═a14c98c2-efad-11ea-3543-9f92301bf72e
# ╠═cf10d358-efae-11ea-0f5b-198d0d26fbb2
# ╠═495de0a0-efa6-11ea-3665-7d12c97fb3cb
# ╠═d71dbf8e-efab-11ea-1f67-5b975a33fbe1
# ╠═4d62f328-eef9-11ea-25b1-dba6c2fc6274
# ╠═9b569f8a-eefe-11ea-3bc3-59bc1c60be30
# ╠═8f80499a-eef9-11ea-1eb4-7d3083555a70
# ╟─172c7612-efee-11ea-077a-5d5c6e2505a4
# ╠═19e6a72e-efee-11ea-0511-5b5b2eac7f60
# ╟─025e2c94-eefb-11ea-12cb-f56f34886334
# ╠═acc1ee8c-eef9-11ea-01ac-9b9e9c4167b3
# ╠═ce433b6a-efad-11ea-1572-2fcb4fe45c84
# ╠═84d3afe4-eefe-11ea-1e31-bf3b2af4aecd
# ╠═b507480a-ef01-11ea-21c4-63d19fac19ab
# ╟─7d8b20a2-ef03-11ea-1c9e-fdf49a397619
# ╠═f690b06a-ef31-11ea-003b-4f2b2f82a9c3
# ╠═fe19ad0a-ef04-11ea-1e5f-1bfcbbb51302
# ╠═977b6b98-ef03-11ea-0176-551fc29729ab
# ╠═9abbb158-ef03-11ea-39df-a3e8aa792c50
# ╠═cf9a9124-ef04-11ea-14a4-abf930edc7cc
# ╠═772a4d68-ef04-11ea-366a-f7ae9e1634f6
# ╠═14f72976-ef05-11ea-2ad5-9f0914f9cf58
# ╠═552fb92e-ef05-11ea-0a79-dd7a6760089a
# ╠═4f23bc54-ef0f-11ea-06a9-35ca3ece421e
# ╠═0892c568-ef2e-11ea-35af-0d4857ee01fc
# ╠═4de89bf6-ef2e-11ea-36be-eb5b11db1270
# ╠═b401f398-ef0f-11ea-38fe-012b7bc8a4fa
# ╠═2eb459d4-ef36-11ea-1f74-b53ffec7a1ed
# ╠═7038abe4-ef36-11ea-11a5-75e57ab51032
# ╟─2d6c6820-ef2d-11ea-1704-49bb5188cfcc
# ╠═fa6a2152-ef0f-11ea-0e67-0d1a6599e779
# ╠═15d1e5dc-ef2f-11ea-093a-417108bcd495
