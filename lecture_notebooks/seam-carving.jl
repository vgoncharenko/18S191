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
			"ImageFiltering"])
end

# ╔═╡ 0316b94c-eef6-11ea-19bc-dbc959901bb5
begin
	using Images
	using ImageMagick
	using Statistics
	using LinearAlgebra
	using Plots
	using ImageFiltering
end

# ╔═╡ fe19ad0a-ef04-11ea-1e5f-1bfcbbb51302
using PlutoUI

# ╔═╡ cb335074-eef7-11ea-24e8-c39a325166a1
md"""
# Seam Carving

1. We use convolution with Sobel filters for "edge detection".
2. We use that to write an algorithm that removes "uninteresting"
   bits of an image in order to shrink it.
"""

# ╔═╡ d2ae6dd2-eef9-11ea-02df-255ec3b46a36
# img = load(download("https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg/480px-Grant_Wood_-_American_Gothic_-_Google_Art_Project.jpg"))
# img = load(download("https://imgur.com/RbrCJLX.png"))
img = load(download("https://cdn.shortpixel.ai/spai/w_1086+q_lossy+ret_img+to_webp/https://wisetoast.com/wp-content/uploads/2015/10/The-Persistence-of-Memory-salvador-deli-painting.jpg"))
#img = load(download("https://web.mit.edu/facilities/photos/construction/Projects/stata/1_large.jpg", tempname()))

# ╔═╡ 0b6010a8-eef6-11ea-3ad6-c1f10e30a413
# arbitrarily choose the brightness of a pixel as mean of rgb
brightness(c::AbstractRGB) = mean((c.r, c.g, c.b))

# ╔═╡ fc1c43cc-eef6-11ea-0fc4-a90ac4336964
Gray.(brightness.(img) ./ maximum(brightness.(img)))

# ╔═╡ 82c0d0c8-efec-11ea-1bb9-83134ecb877e
md"""
# Edge detection filter

(Spoiler alert!) Here, we use the Sobel edge detection filter we created in Homework 1.

(Notes: remove kron,)

```math
\begin{align}

G_x &= \left(\begin{bmatrix}
1 \\
2 \\
1 \\
\end{bmatrix} \otimes [1~0~-1]
\right) * A = \begin{bmatrix}
1 & 0 & -1 \\
2 & 0 & -2 \\
1 & 0 & -1 \\
\end{bmatrix}*A\\
G_y &= \left(
\begin{bmatrix}
1 \\
0 \\
-1 \\
\end{bmatrix} \otimes [1~2~1]
\right) * A = \begin{bmatrix}
1 & 2 & 1 \\
0 & 0 & 0 \\
-1 & -2 & -1 \\
\end{bmatrix}*A
\end{align}
```
Here $A$ is the array corresponding to your image.
We can think of these as derivatives in the $x$ and $y$ directions.

Then we combine them by finding the magnitude of the **gradient** (in the sense of multivariate calculus) by defining

$$G_\text{total} = \sqrt{G_x^2 + G_y^2}.$$
"""

# ╔═╡ da726954-eff0-11ea-21d4-a7f4ae4a6b09
Sy, Sx = Kernel.sobel()

# ╔═╡ abf6944e-f066-11ea-18e2-0b92606dab85
(collect(Int.(8 .* Sy)), collect(Int.(8 .* Sx)))

# ╔═╡ 5ebf6ebe-f069-11ea-0256-1b04242afb27
[img[300:end, 1:300] img[300:end, 1:300]]

# ╔═╡ ac8d6902-f069-11ea-0f1d-9b0fa706d769
md"""
- green shows positive values
- red shows negative values

Horizontal gradient <-> Vertical gradient
"""

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

# ╔═╡ 6f7bd064-eff4-11ea-0260-f71aa7f4f0e5
function edgeness(img)
	Sy, Sx = Kernel.sobel()
	b = brightness.(img)

	∇y = convolve(b, Sy)
	∇x = convolve(b, Sx)

	sqrt.(∇x.^2 + ∇y.^2)
end

# ╔═╡ dec62538-efee-11ea-1e03-0b801e61e91c
	function show_colored_kernel(kernel)
		to_rgb(x) = RGB(max(-x, 0), max(x, 0), 0)
		to_rgb.(kernel) / maximum(abs.(kernel))
	end

# ╔═╡ da39c824-eff0-11ea-375b-1b6c6e186182
show_colored_kernel.((Sy, Sx))

# ╔═╡ 44192a40-eff2-11ea-0ec7-05cdadb0c29a
begin
	∇y = convolve(brightness.(img), Sy)
	∇x = convolve(brightness.(img), Sx)

	show_colored_kernel([∇x ∇y]) # do hbox
end

# ╔═╡ d0eba4f8-f069-11ea-17f3-171b793239d2
let
	# zoom in on the whale thing
	show_colored_kernel([∇x[300:end,  1:300] ∇y[300:end, 1:300]])
end

# ╔═╡ d6a268c0-eff4-11ea-2c9e-bfef19c7f540
vcat(img, show_colored_kernel(edgeness(img))) # it's all green because norm makes it positive.

# ╔═╡ f8283a0e-eff4-11ea-23d3-9f1ced1bafb4
md"""

## Seam carving idea

The idea of seam carving is to find a path from the top of the image to the bottom of the image where the path minimizes the edgness.

In other words, this path **minimizes the number of edges it crosses**
"""

# ╔═╡ 025e2c94-eefb-11ea-12cb-f56f34886334
md"""

At every step in going down, the path is allowed to go south west, south or south east. We want to find a seam with the minimum possible sum of energies.

We start by writing a `least_edgy` function which given a matrix of energies, returns
a matrix of minimum possible energy starting from that pixel going up to a pixel in the bottom most row.
"""

# ╔═╡ acc1ee8c-eef9-11ea-01ac-9b9e9c4167b3
#            e[x,y] 
#          ↙   ↓   ↘       <--pick the next path which gives the least overall energy
#  e[x-1,y+1] e[x,y+1]  e[x+1,y+1]     
#
# Basic Comp:   e[x,y] += min( e[x-1,y+1],e[x,y],e[x+1,y])
#               dirs records which one from (-1==SW,0==S,1==SE)

function least_edgy(E)
	least_E = zeros(size(E))
	dirs = zeros(Int, size(E))
	least_E[end, :] .= E[end, :] # the minimum energy on the last row is the energy
	                             # itself

	m, n = size(E)
	# Go from the last row up, finding the minimum energy
	for i in m-1:-1:1
		for j in 1:n
			j1, j2 = max(1, j-1), min(j+1, n)
			e, dir = findmin(least_E[i+1, j1:j2])
			least_E[i,j] += e
			least_E[i,j] += E[i,j]
			dirs[i, j] = (-1,0,1)[dir + (j==1)]
		end
	end
	least_E, dirs
end

# ╔═╡ 8b204a2a-eff6-11ea-25b0-13f230037ee1
# The bright areas are screaming "AVOID ME!!!"
least_e, dirs = least_edgy(edgeness(img))

# ╔═╡ 84d3afe4-eefe-11ea-1e31-bf3b2af4aecd
show_colored_kernel(least_e)

# ╔═╡ b507480a-ef01-11ea-21c4-63d19fac19ab
# direction the path should take at every pixel.
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

# ╔═╡ 14f72976-ef05-11ea-2ad5-9f0914f9cf58
function mark_path(img, path)
	img′ = copy(img)
	for i in path
		img′[i...] = RGB(1,0,0)
	end
	img′
end

# ╔═╡ cf9a9124-ef04-11ea-14a4-abf930edc7cc
@bind start_column Slider(1:size(img, 2))

# ╔═╡ 772a4d68-ef04-11ea-366a-f7ae9e1634f6
path = get_seam_at(dirs, start_column)

# ╔═╡ 552fb92e-ef05-11ea-0a79-dd7a6760089a
[mark_path(img, path) mark_path(show_colored_kernel(least_e), path)]

# ╔═╡ 081a98cc-f06e-11ea-3664-7ba51d4fd153
f(x) = Gray(1-x) # colors[round(Int, clamp((x+1) * 45, 1, 90))]

# ╔═╡ 237647e8-f06d-11ea-3c7e-2da57e08bebc
e = edgeness(img);

# ╔═╡ dfd03c4e-f06c-11ea-1e2a-89233a675138
let
	[mark_path(img, path) mark_path(map(f, e ./ maximum(e)), path)]
end

# ╔═╡ ca4a87e8-eff8-11ea-3d57-01dfa34ff723
let
	# least energy path of them all:
	_, k = findmin(least_e[1, :])
	path = get_seam_at(dirs, k)
	[mark_path(img, path) mark_path(show_colored_kernel(least_e), path)]
end

# ╔═╡ 4f23bc54-ef0f-11ea-06a9-35ca3ece421e
function rm_path(img, path)
	img′ = img[:, 1:end-1] # one less column
	for (i, j) in path
		img′[i, 1:j-1] .= img[i, 1:j-1]
		img′[i, j:end] .= img[i, j+1:end]
	end
	img′
end

# ╔═╡ b401f398-ef0f-11ea-38fe-012b7bc8a4fa
function shrink_n(img, n)
	imgs = []

	e = edgeness(img)
	for i=1:n
		least_E, dirs = least_edgy(e)
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
# ╟─cb335074-eef7-11ea-24e8-c39a325166a1
# ╠═d2ae6dd2-eef9-11ea-02df-255ec3b46a36
# ╠═0b6010a8-eef6-11ea-3ad6-c1f10e30a413
# ╠═fc1c43cc-eef6-11ea-0fc4-a90ac4336964
# ╠═82c0d0c8-efec-11ea-1bb9-83134ecb877e
# ╠═da726954-eff0-11ea-21d4-a7f4ae4a6b09
# ╠═da39c824-eff0-11ea-375b-1b6c6e186182
# ╠═abf6944e-f066-11ea-18e2-0b92606dab85
# ╠═44192a40-eff2-11ea-0ec7-05cdadb0c29a
# ╠═5ebf6ebe-f069-11ea-0256-1b04242afb27
# ╟─ac8d6902-f069-11ea-0f1d-9b0fa706d769
# ╠═d0eba4f8-f069-11ea-17f3-171b793239d2
# ╠═6f7bd064-eff4-11ea-0260-f71aa7f4f0e5
# ╠═d6a268c0-eff4-11ea-2c9e-bfef19c7f540
# ╟─172c7612-efee-11ea-077a-5d5c6e2505a4
# ╟─089e1fd4-efed-11ea-12dc-09f9e912d4ab
# ╟─fcf46120-efec-11ea-06b9-45f470899cb2
# ╟─dec62538-efee-11ea-1e03-0b801e61e91c
# ╟─f8283a0e-eff4-11ea-23d3-9f1ced1bafb4
# ╠═025e2c94-eefb-11ea-12cb-f56f34886334
# ╠═acc1ee8c-eef9-11ea-01ac-9b9e9c4167b3
# ╠═8b204a2a-eff6-11ea-25b0-13f230037ee1
# ╠═84d3afe4-eefe-11ea-1e31-bf3b2af4aecd
# ╠═b507480a-ef01-11ea-21c4-63d19fac19ab
# ╟─7d8b20a2-ef03-11ea-1c9e-fdf49a397619
# ╠═f690b06a-ef31-11ea-003b-4f2b2f82a9c3
# ╠═fe19ad0a-ef04-11ea-1e5f-1bfcbbb51302
# ╠═977b6b98-ef03-11ea-0176-551fc29729ab
# ╠═9abbb158-ef03-11ea-39df-a3e8aa792c50
# ╠═772a4d68-ef04-11ea-366a-f7ae9e1634f6
# ╠═14f72976-ef05-11ea-2ad5-9f0914f9cf58
# ╠═cf9a9124-ef04-11ea-14a4-abf930edc7cc
# ╠═552fb92e-ef05-11ea-0a79-dd7a6760089a
# ╠═081a98cc-f06e-11ea-3664-7ba51d4fd153
# ╠═237647e8-f06d-11ea-3c7e-2da57e08bebc
# ╠═dfd03c4e-f06c-11ea-1e2a-89233a675138
# ╠═ca4a87e8-eff8-11ea-3d57-01dfa34ff723
# ╠═4f23bc54-ef0f-11ea-06a9-35ca3ece421e
# ╠═b401f398-ef0f-11ea-38fe-012b7bc8a4fa
# ╠═2eb459d4-ef36-11ea-1f74-b53ffec7a1ed
# ╠═7038abe4-ef36-11ea-11a5-75e57ab51032
# ╟─2d6c6820-ef2d-11ea-1704-49bb5188cfcc
# ╠═fa6a2152-ef0f-11ea-0e67-0d1a6599e779
# ╠═15d1e5dc-ef2f-11ea-093a-417108bcd495
