### A Pluto.jl notebook ###
# v0.12.20

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

# ╔═╡ f6352dcc-a24a-11eb-1cc6-6da9f12dcd39
begin
	using Markdown
	using InteractiveUtils
	using Images
	using ImageMagick
	using PlutoUI
	using ImageFiltering
	using DSP
	using Plots
	using Statistics
	using FFTW
	
	f = Plots.font("DejaVu Sans", 24);
end

# ╔═╡ 0f195886-a24b-11eb-33a3-2b8c93dc2a4e
begin
	url_bitonic1 = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/09fig16.gif"
	download(url_bitonic1, "bitonic1.gif")
	image_bitonic1 = load("bitonic1.gif")
end

# ╔═╡ 414b401c-a24b-11eb-2dd1-85a934f1c363
begin
	url_bitonic2 = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/09fig17.gif"
	download(url_bitonic2, "bitonic2.gif")
	image_bitonic2 = load("bitonic2.gif")
end

# ╔═╡ 5c7e5090-a24b-11eb-0968-fbec37ab3e98
begin
	url_bitonic3 = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/09fig13.gif"
	download(url_bitonic3, "bitonic3.gif")
	image_bitonic3 = load("bitonic3.gif")
end

# ╔═╡ c4c19ab8-a77d-11eb-0617-9b55b13b8140
begin
	url_compare_split = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/09fig07.gif"
	download(url_compare_split, "url_compare_split.gif")
	image_compare_split = load("url_compare_split.gif")
end

# ╔═╡ 5a4a7b7a-b824-11eb-1fbb-f5e32cb52329
begin
	url_qsort = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/09fig52.gif"
	download(url_qsort, "url_qsort.gif")
	image_qsort = load("url_qsort.gif")
end

# ╔═╡ 6fd6d2ca-a24b-11eb-3b91-9573e0877d49
@bind N Slider(21:40, show_value=true)

# ╔═╡ 8183f52c-a24b-11eb-04d2-b5886c4ec096
begin
	q=2;
	w_list = zeros(Float64, N);
	p_GPU=1024;
	p=11;
	
	w_list[1] = 1024;
	for i in 2:N
		w_list[i] = w_list[i-1]*q;
	end
	
	fastest_Ts = [7.7372e-05, 9.1744e-05, 0.000202863, 0.000428801, 0.000919273, 0.00192596, 0.00408615, 0.00860469, 0.0174678, 0.0321075, 0.0679416, 0.139414, 0.298718, 0.622546, 1.31219, 2.7119, 5.59791, 11.5875, 23.5888, 48.664, 100.321];
	
	bitonic_Tp = [0.00150849, 0.00135855, 0.00191785, 0.00263433, 0.00482597, 0.00930071, 0.0189586, 0.030105, 0.0669785, 0.138423, 0.306094, 0.661332, 1.44338, 3.04583, 6.91205, 16.4814, 39.9194, 99.8946, 197.205, 428.598, 833.838];
	
	bubble_Tp = [0.00509197, 0.00457341, 0.00499876, 0.00482387, 0.00573194, 0.00644977, 0.00702309, 0.00787602, 0.0122018, 0.0198506, 0.0371858, 0.0791028, 0.16417, 0.333523, 0.633281, 1.32708, 2.81722, 5.9766, 13.0339, 28.9605, 62.2295];
	
	qsort_Tp = [0.000396608, 0.000148541, 0.000248666, 0.000476002, 0.00100338, 0.0021487, 0.0044513, 0.00911093, 0.018919, 0.0394939, 0.077471, 0.1458, 0.307258, 0.640094, 0.885405, 1.55876, 3.16629, 6.63017, 9.80368, 17.6679, 25.5611];
	
	bitonic_speedup = zeros(Float64, N);
	bubble_speedup = zeros(Float64, N);
	qsort_speedup = zeros(Float64, N);
	
	bitonic_efficiency = zeros(Float64, N);
	bubble_efficiency = zeros(Float64, N);
	qsort_efficiency = zeros(Float64, N);


	for i in 1:N
		bitonic_speedup[i] = fastest_Ts[i] / bitonic_Tp[i];
		bubble_speedup[i] = fastest_Ts[i] / bubble_Tp[i];
		qsort_speedup[i] = fastest_Ts[i] / qsort_Tp[i];
		
		bitonic_efficiency[i] = bitonic_speedup[i] / p;
		bubble_efficiency[i] = bubble_speedup[i] / p;
		qsort_efficiency[i] = qsort_speedup[i] / p;

	end
end

# ╔═╡ ac669bea-ad53-11eb-279e-65189cfefed5
begin
	plot(w_list, fastest_Ts, label="fastest_Ts", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f);
	plot!(w_list, bitonic_Tp, label="bitonic_Tp", lw = 3);
	plot!(w_list, bubble_Tp, label="bubble_Tp", lw = 3);
	plot!(w_list, qsort_Tp, label="qsort_Tp", lw = 3);
end

# ╔═╡ ab82e0a8-ad53-11eb-19d7-6739c69f81c5
begin
	plot(w_list, bitonic_speedup, label="bitonic_speedup", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f);
	plot!(w_list, bubble_speedup, label="bubble_speedup", lw = 3);
	plot!(w_list, qsort_speedup, label="qsort_speedup", lw = 3);
end

# ╔═╡ da06bb70-ad53-11eb-0a0d-6f22a39ebf70
begin
	plot(w_list, bitonic_efficiency, label="bitonic_efficiency", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f);
	plot!(w_list, bubble_efficiency, label="bubble_efficiency", lw = 3);
	plot!(w_list, qsort_efficiency, label="qsort_efficiency", lw = 3);
end

# ╔═╡ Cell order:
# ╠═f6352dcc-a24a-11eb-1cc6-6da9f12dcd39
# ╠═0f195886-a24b-11eb-33a3-2b8c93dc2a4e
# ╠═414b401c-a24b-11eb-2dd1-85a934f1c363
# ╠═5c7e5090-a24b-11eb-0968-fbec37ab3e98
# ╠═c4c19ab8-a77d-11eb-0617-9b55b13b8140
# ╠═5a4a7b7a-b824-11eb-1fbb-f5e32cb52329
# ╠═6fd6d2ca-a24b-11eb-3b91-9573e0877d49
# ╠═8183f52c-a24b-11eb-04d2-b5886c4ec096
# ╠═ac669bea-ad53-11eb-279e-65189cfefed5
# ╠═ab82e0a8-ad53-11eb-19d7-6739c69f81c5
# ╠═da06bb70-ad53-11eb-0a0d-6f22a39ebf70
