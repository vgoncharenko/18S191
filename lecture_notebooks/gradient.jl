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

# ╔═╡ 15a4ba3e-f0d1-11ea-2ef1-5ff1dee8795f
using Pkg

# ╔═╡ 21e744b8-f0d1-11ea-2e09-7ffbcdf43c37
begin
	Pkg.add("Gadfly")
	Pkg.add("Compose")
	Pkg.add("Statistics")
	Pkg.add("Hyperscript")
	Pkg.add("Colors")
	Pkg.add("Images")
	Pkg.add("ImageMagick")
	Pkg.add("ImageFiltering")
	
	using Gadfly
	using Images
	using Compose
	using Hyperscript
	using Colors
	using Statistics
	using PlutoUI
	using ImageMagick
	using ImageFiltering
end

# ╔═╡ 1ab1c808-f0d1-11ea-03a7-e9854427d45f
Pkg.activate(mktempdir())

# ╔═╡ 10f850fc-f0d1-11ea-2a58-2326a9ea1e2a
set_default_plot_size(12cm, 12cm)

# ╔═╡ 891673aa-f0d3-11ea-1950-61fdf15f2479
function clamp_at_boundary(M, i, j)
	return M[
		clamp(i, 1, size(M, 1)),
		clamp(j, 1, size(M, 2)),	
	]
end

# ╔═╡ 7b4d5270-f0d3-11ea-0b48-79005f20602c
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

# ╔═╡ 6fd3b7a4-f0d3-11ea-1f26-fb9740cd16e0
function disc(n, r1=0.8, r2=0.8)
	white = RGB{Float64}(1,1,1)
	blue = RGB{Float64}(colorant"#4EC0E3")
	convolve([(i-n/2)^2 + (j-n/2)^2 <= (n/2-5)^2 ? white : blue for i=1:n, j=1:n],
		Kernel.gaussian((1,1)))
end

# ╔═╡ fe3559e0-f13b-11ea-06c8-a314e44c20d6
brightness(c) = mean((c.r, c.g, c.b))

# ╔═╡ 03282aae-f1e1-11ea-3c49-c39613467a58
md"# How Sobel finds the edges"

# ╔═╡ 0ccf76e4-f0d9-11ea-07c9-0159e3d4d733
@bind img_select Radio(["disc", "mario"], default="disc")

# ╔═╡ 236dab08-f13d-11ea-1922-a3b82cfc7f51
img = Dict("disc" => disc(25),
	       "mario" => load(download("http://files.softicons.com/download/game-icons/super-mario-icons-by-sandro-pereira/png/32/Retro%20Mario.png")))[img_select]

# ╔═╡ 03434682-f13b-11ea-2b6e-11ad781e9a51
md"""Show $G_x$ $(@bind Gx CheckBox())

Show $G_y$ $(@bind Gy CheckBox())

Show magnitude $\sqrt{G_x^2 + G_y^2}$ $(@bind norm CheckBox())"""

# ╔═╡ 268f0122-f1c6-11ea-10ee-9b234a9594cc
function pencil(X)
	f(x) = RGB(1-x,1-x,1-x)
	map(f, X ./ maximum(X))
end

# ╔═╡ 9d9cccb2-f118-11ea-1638-c76682e636b2
function arrowhead(θ)
	eq_triangle = [(0, 1/sqrt(3)),
		           (-1/3, -2/(2 * sqrt(3))),
		           (1/3, -2/(2 * sqrt(3)))]

	compose(context(units=UnitBox(-1,-1,2,2), rotation=Rotation(θ, 0, 0)),
				polygon(eq_triangle))
end

# ╔═╡ b7ea8a28-f0d7-11ea-3e98-7b19a1f58304
function quiver(points, vecs)
	xmin = minimum(first.(points))
	ymin = minimum(last.(points))
	xmax = maximum(first.(points))
	ymax = maximum(last.(points))
	hs = map(x->hypot(x...), vecs)
	hs = hs / maximum(hs)
	
	strokecolor(h) = RGBA(1, 0.3,0.1, h)

	vector(p, v, h) = all(iszero, v) ? context() :
		(context(),
		    (context((p.+v.*6 .- .2)..., .4,.4),
				arrowhead(atan(v[2], v[1]) - pi/2)),
		stroke(strokecolor(h)),
		fill(strokecolor(h)),
		line([p, p.+v.*8]))

	compose(context(units=UnitBox(xmin,ymin,xmax,ymax)),
         vector.(points, vecs, hs)...)
end

# ╔═╡ c821b906-f0d8-11ea-2df0-8f2d06964aa2
function sobel_quiver(img, ∇x, ∇y)
    quiver([(j-1,i-1) for i=1:size(img,1), j=1:size(img,2)],
           [(∇x[i,j], ∇y[i,j]) for i=1:size(img,1), j=1:size(img,2)])
end

# ╔═╡ 6da3fdfe-f0dd-11ea-2407-7b85217b35cc
# render an Image using squares in Compose
function compimg(img)
	xmax, ymax = size(img)
	xmin, ymin = 0, 0
	arr = [(j-1, i-1) for i=1:ymax, j=1:xmax]

	compose(context(units=UnitBox(xmin, ymin, xmax, ymax)),
		fill(vec(img)),
		rectangle(
			first.(arr),
			last.(arr),
			fill(1.0, length(arr)),
			fill(1.0, length(arr))))
end

# ╔═╡ f22aa34e-f0df-11ea-3053-3dcdc070ec2f
let
	Sy,Sx = Kernel.sobel()
	∇x, ∇y = zeros(size(img)), zeros(size(img))

	if Gx
		∇x = convolve(brightness.(img), Sx)
	end
	if Gy
		∇y = convolve(brightness.(img), Sy)
	end
	
	img′ = img
	if (Gx || Gy) && norm
		img′ = pencil(hypot.(∇x, ∇y))
	end

	compose(context(),
		sobel_quiver(img, ∇x, ∇y),
		compimg(img′))
end

# ╔═╡ Cell order:
# ╠═15a4ba3e-f0d1-11ea-2ef1-5ff1dee8795f
# ╠═1ab1c808-f0d1-11ea-03a7-e9854427d45f
# ╠═21e744b8-f0d1-11ea-2e09-7ffbcdf43c37
# ╠═10f850fc-f0d1-11ea-2a58-2326a9ea1e2a
# ╟─7b4d5270-f0d3-11ea-0b48-79005f20602c
# ╟─891673aa-f0d3-11ea-1950-61fdf15f2479
# ╟─6fd3b7a4-f0d3-11ea-1f26-fb9740cd16e0
# ╠═fe3559e0-f13b-11ea-06c8-a314e44c20d6
# ╟─03282aae-f1e1-11ea-3c49-c39613467a58
# ╟─0ccf76e4-f0d9-11ea-07c9-0159e3d4d733
# ╟─236dab08-f13d-11ea-1922-a3b82cfc7f51
# ╟─03434682-f13b-11ea-2b6e-11ad781e9a51
# ╠═f22aa34e-f0df-11ea-3053-3dcdc070ec2f
# ╠═268f0122-f1c6-11ea-10ee-9b234a9594cc
# ╠═b7ea8a28-f0d7-11ea-3e98-7b19a1f58304
# ╠═9d9cccb2-f118-11ea-1638-c76682e636b2
# ╠═c821b906-f0d8-11ea-2df0-8f2d06964aa2
# ╠═6da3fdfe-f0dd-11ea-2407-7b85217b35cc
