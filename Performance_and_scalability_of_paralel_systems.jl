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

# ╔═╡ 8665ad12-8541-11eb-1eb0-4f9d384df11c
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
	
	f = Plots.font("DejaVu Sans", 24)
end

# ╔═╡ 8215c470-8548-11eb-2093-b3c3b4e56846
# 5.5 (Scaled speedup) Scaled speedup is defined as the speedup obtained when the problem size is increased linearly with the number of processing elements; that is, if W is chosen as a base problem size for a single processing element, then
# Scaled speedup = pW / Tp(pW, p)
# For the problem of adding n numbers on p processing elements (Example 5.1), plot the speedup curves, assuming that the base problem for p = 1 is that of adding 256 numbers. Use p = 1, 4, 16, 64, and 256. Assume that it takes 10 time units to communicate a number between two processing elements, and that it takes one unit of time to add two numbers. Now plot the standard speedup curve for the base problem size and compare it with the scaled speedup curve.



# 5.6 Plot a third speedup curve for Problem 5.5, in which the problem size is scaled up according to the isoefficiency function, which is Θ(p log p). Use the same expression for TP .



# 5.7 Plot the efficiency curves for the problem of adding n numbers on p processing elements corresponding to the standard speedup curve (Problem 5.5), the scaled speedup curve (Problem 5.5), and the speedup curve when the problem size is increased according to the isoefficiency function (Problem 5.6).



# 5.8 A drawback of increasing the number of processing elements without increasing the total workload is that the speedup does not increase linearly with the number of processing elements, and the efficiency drops monotonically. Based on your experience with Problems 5.5 and 5.7, discuss whether or not scaled speedup increases linearly with the number of processing elements in general. What can you say about the isoefficiency function of a parallel system whose scaled speedup curve matches the speedup curve determined by increasing the problem size according to the isoefficiency function?

begin
	url = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/05fig14.gif"
	download(url, "Example_5_1.gif")
	example = load("Example_5_1.gif")
end



# ╔═╡ 390278d8-8549-11eb-38bf-07d2643c0df8


# ╔═╡ bd3eac94-8541-11eb-32cd-33ff677dc01b
@bind N Slider(4:25, show_value=true)

# ╔═╡ 8ea6c20e-8541-11eb-39cb-c74b21c3d256
begin
	W1=256;
	q=4;
	p_list=zeros(Int64, N);
	p_list[1] = 1;
	for i in 2:N
		p_list[i] = p_list[i-1]*q;
	end
	w_list = copy(p_list);
	w_list .*= W1;
	w_list_isoefficiency = copy(w_list);
	for i in 1:N
		w_list_isoefficiency[i] *= log(2, p_list[i]);
	end
	
	Tp = zeros(Float64, N);
	Tp_base = zeros(Float64, N);
	Tp_isoefficiency = zeros(Float64, N);
	
	speedup = zeros(Float64, N);
	speedup_base = zeros(Float64, N);
	speedup_isoefficiency = zeros(Float64, N);
	
	efficiency = zeros(Float64, N);
	efficiency_base = zeros(Float64, N);
	efficiency_isoefficiency = zeros(Float64, N);
	for i in 1:N
		Tp[i] = (w_list[i]/p_list[i]) + 11 * log(2, p_list[i]);
		Tp_base[i] = (w_list[i]/p_list[i]) + 2 * log(2, p_list[i]);
		Tp_isoefficiency[i] = (w_list_isoefficiency[i]/p_list[i]) + 11 * log(2, p_list[i]);
		
		speedup[i] = w_list[i] / Tp[i];
		speedup_base[i] = w_list[i] / Tp_base[i];
		speedup_isoefficiency[i] = w_list_isoefficiency[i] / Tp_isoefficiency[i];
		
		efficiency[i] = speedup[i] /  p_list[i];
		efficiency_base[i] = speedup_base[i] /  p_list[i];
		efficiency_isoefficiency[i] = speedup_isoefficiency[i] /  p_list[i];
	end
end

# ╔═╡ 0ec38a7a-8548-11eb-3ad9-513df471c2f4
p_list

# ╔═╡ 11aa3036-8548-11eb-1434-2fe3ec454cf1
w_list

# ╔═╡ 5433a6b2-85a7-11eb-23b2-bf6c5f23baa8
w_list_isoefficiency

# ╔═╡ 61d8e914-8677-11eb-213d-7376ed3f1f30
Tp

# ╔═╡ 62a132de-8677-11eb-26c4-bd2de46295ce
Tp_base

# ╔═╡ 65d0205a-8677-11eb-3b87-45ff103a9e44
Tp_isoefficiency

# ╔═╡ 059a6a68-8548-11eb-2bf1-c37b366920c0
speedup

# ╔═╡ 4f513fb8-854a-11eb-3b9e-43b31fe397f6
speedup_base

# ╔═╡ bdde38d0-85a6-11eb-1d7b-2bdbc32850a1
speedup_isoefficiency

# ╔═╡ 6cf1d59c-85a8-11eb-0bd5-7b24054b6a43
efficiency

# ╔═╡ 70add870-85a8-11eb-1d12-d34e8a2eaa05
efficiency_base

# ╔═╡ 751f925e-85a8-11eb-3829-ef24e4657fb3
efficiency_isoefficiency

# ╔═╡ e0c9684e-8540-11eb-3f0b-2b26fa6a3ebb
begin
	plot(w_list, speedup, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list, speedup_base); #red
	plot!(w_list_isoefficiency, speedup_isoefficiency); #green
	#plot!(p_list, speedup);
end

# ╔═╡ 5574d5d0-854a-11eb-1962-0f728841ba73
begin
	plot(w_list, efficiency, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list, efficiency_base); #red
	plot!(w_list_isoefficiency, efficiency_isoefficiency); #green
end

# ╔═╡ 46798c6a-854a-11eb-3aa8-91ed72958943
# 5.9 (Time-constrained scaling) Using the expression for TP from Problem 5.5 for p = 1, 4, 16, 64, 256, 1024, and 4096, what is the largest problem that can be solved if the total execution time is not to exceed 512 time units? In general, is it possible to solve an arbitrarily large problem in a fixed amount of time, provided that an unlimited number of processing elements is available? Why?


# My answer:
# yes and no. 
#
# As long as we would increase W together with p and also taking into account  To(W,p)=O(W/2) to keep next retio true:
#
#            Tp = (W + To(W,p))/ p, where Tp=O(512)
#
# For the systems where Ts is't 0, we have to substitute p with C(W) as asymptotical upper bound for such paralell system to be aralelled:
#
#            Tp = (W + To(W,C(W)))/ C(W), where Tp=O(512)
#
# Only paralell systems with no overhead could have no obstacles to have alwayse the aswer 'yes' because for them paralell time formula will look like this:
#
#            Tp = W / p
#

# ╔═╡ 2c15db9c-8600-11eb-04b6-a136879ec94b
begin
	plot(w_list, Tp, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list, Tp_base); #orange
	plot!(w_list_isoefficiency, Tp_isoefficiency); #green
end

# ╔═╡ 3f1cb858-8602-11eb-39fb-fda0e0a00dd2
Tp

# ╔═╡ ab4f3fe6-8602-11eb-1ff2-c15897b3e69b
Tp_base

# ╔═╡ ace4c088-8602-11eb-33f8-fd975ac94414
Tp_isoefficiency

# ╔═╡ b0b755a4-8602-11eb-2d56-632242c58935
# 5.10 (Prefix sums) Consider the problem of computing the prefix sums (Example 5.1) of n numbers on n processing elements. What is the parallel runtime, speedup, and efficiency of this algorithm? Assume that adding two numbers takes one unit of time and that communicating one number between two processing elements takes 10 units of time. Is the algorithm cost-optimal?

# My answer:
# Alghorithm is not cost optimal by the cost-optimality property:
#    pTp = O(W)
#    11nLog(p) > n


# 5.11 Design a cost-optimal version of the prefix sums algorithm (Problem 5.10) for computing all prefix-sums of n numbers on p processing elements where p < n. Assuming that adding two numbers takes one unit of time and that communicating one number between two processing elements takes 10 units of time, derive expressions for TP , S, E , cost, and the isoefficiency function.

# My answer:
# Make local sum on p processors in n/p unit of time first, then performe Log(p) message sendings and add between p processors: 
# Tp = n/p + 11Log(p)
			
begin
	url2 = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/04fig21.gif"
	download(url2, "Example_3_8.gif")
	example2 = load("Example_3_8.gif")
end

# ╔═╡ b637e702-8673-11eb-06b2-c5c972f5cfcf
@bind N5_10 Slider(4:25, show_value=true)

# ╔═╡ e84aa6ea-8672-11eb-2837-ef734dc7cede
begin
	q5_10=8;
	p_list5_10=zeros(Int64, N5_10);
	p_list5_10[1] = 1;
	for i in 2:N5_10
		p_list5_10[i] = p_list5_10[i-1]*q;
	end
	w_list5_10 = copy(p_list5_10);
	w_list_isoefficient5_10 = copy(w_list5_10);
	w_list_cost_optimal_isoefficient5_10 = copy(w_list5_10);
	for i in 2:N5_10
		# K=4, means E=0.8
		w_list_isoefficient5_10[i] = 4*(11*w_list_isoefficient5_10[i-1]*log(2, p_list5_10[i])-w_list_isoefficient5_10[i-1]);
	end
	for i in 1:N5_10
		# K=4, means E=0.8
		w_list_cost_optimal_isoefficient5_10[i] *= 4*11*log(2, p_list5_10[i]);
	end
	Tp5_10 = zeros(Float64, N5_10);
	Tp_isoefficient5_10 = zeros(Float64, N5_10);
	Tp_cost_optimal_isoefficient5_10 = zeros(Float64, N5_10);
	
	speedup5_10 = zeros(Float64, N5_10);
	speedup_isoefficient5_10 = zeros(Float64, N5_10);
	speedup_cost_optimal_isoefficient5_10 = zeros(Float64, N5_10);
	
	efficiency5_10 = zeros(Float64, N5_10);
	efficiency_isoefficient5_10 = zeros(Float64, N5_10);
	efficiency_cost_optimal_isoefficient5_10 = zeros(Float64, N5_10);
	for i in 1:N5_10
		Tp5_10[i] = 11*(w_list5_10[i]/p_list5_10[i]) * log(2, p_list5_10[i]);
		Tp_isoefficient5_10[i] = 11*(w_list_isoefficient5_10[i]/p_list5_10[i]) * log(2, p_list5_10[i]);
		Tp_cost_optimal_isoefficient5_10[i] = w_list_cost_optimal_isoefficient5_10[i]/p_list5_10[i] + 11*log(2, p_list5_10[i]);
		
		speedup5_10[i] = w_list5_10[i] / Tp5_10[i];
		speedup_isoefficient5_10[i] = w_list_isoefficient5_10[i] / Tp_isoefficient5_10[i];
		speedup_cost_optimal_isoefficient5_10[i] = w_list_cost_optimal_isoefficient5_10[i] / Tp_cost_optimal_isoefficient5_10[i];
		
		efficiency5_10[i] = speedup5_10[i] /  p_list5_10[i];
		efficiency_isoefficient5_10[i] = speedup_isoefficient5_10[i] /  p_list5_10[i];
		efficiency_cost_optimal_isoefficient5_10[i] = speedup_cost_optimal_isoefficient5_10[i] /  p_list5_10[i];
	end
end

# ╔═╡ 8c74cd2c-8673-11eb-1e97-f32e50e81d25
p_list5_10

# ╔═╡ 95855d28-8673-11eb-396b-3189d9826f17
w_list5_10

# ╔═╡ b939ab4a-8676-11eb-34c7-c997f541610b
w_list_isoefficient5_10

# ╔═╡ 7caa61c4-8743-11eb-24d5-c76b5386101d
w_list_cost_optimal_isoefficient5_10

# ╔═╡ ef31d876-8676-11eb-3c28-036c2746e7a5
Tp5_10

# ╔═╡ f074c7a2-8676-11eb-25fd-75622cace8b7
Tp_isoefficient5_10

# ╔═╡ 8652e3d6-8743-11eb-2096-7b19b9946d61
Tp_cost_optimal_isoefficient5_10

# ╔═╡ 98364b9a-8673-11eb-33c3-2180dfd219c5
speedup5_10

# ╔═╡ ca248d1c-8676-11eb-2f4f-67574d09e8fd
speedup_isoefficient5_10

# ╔═╡ 8e1ed6c4-8743-11eb-1faf-8d7f69de95e7
speedup_cost_optimal_isoefficient5_10

# ╔═╡ 9b117d8a-8673-11eb-022c-9f4a02829909
efficiency5_10

# ╔═╡ dd3020d8-8676-11eb-0ebd-41e1995d9efc
efficiency_isoefficient5_10

# ╔═╡ 93cf3096-8743-11eb-3769-f1c2031e7c84
efficiency_cost_optimal_isoefficient5_10

# ╔═╡ a1cf769a-8673-11eb-39a4-09a20b5d0a87
begin
	plot(w_list5_10, Tp5_10, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_isoefficient5_10, Tp_isoefficient5_10); #orange
	plot!(w_list_cost_optimal_isoefficient5_10, Tp_cost_optimal_isoefficient5_10) #green
end

# ╔═╡ 1c779ddc-8674-11eb-2c4a-399043d0a1af
begin
	plot(w_list5_10, speedup5_10, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_isoefficient5_10, speedup_isoefficient5_10); #orange
	plot!(w_list_cost_optimal_isoefficient5_10, speedup_cost_optimal_isoefficient5_10); #green
end

# ╔═╡ 2a50627a-8674-11eb-32e2-ebdf469ffe13
begin
	plot(w_list5_10, efficiency5_10, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_isoefficient5_10, efficiency_isoefficient5_10); #orange
	plot!(w_list_cost_optimal_isoefficient5_10, efficiency_cost_optimal_isoefficient5_10); #green
end

# ╔═╡ f080cf4c-8749-11eb-35b2-49ccabc5a104
# 4.15 Describe an algorithm for finding the maximum of n numbers on an sqrt(n) x sqrt(n) mesh of processors. Is the algorithm cost-optimal?

# 4.16 Redesign the algorithm for finding the maximum of n numbers o a mesh (problem 4.15) to work on fewer than n processors. Assume that:
# tcmp = 1 unit of time
# tcomm = 10 unit of time between directly connected processors
# What is the smallest n (in terms of p) such that the maximum of n numberrs can be computed cost-optimaly on a p-processors mesh. What is the isoefficiency func of this paralell system?

begin
	example3 = load("File_000.jpeg")
end

# ╔═╡ 7cbb6ba6-874b-11eb-10ec-ab7c1c8d981a
@bind N5_15 Slider(4:25, show_value=true)

# ╔═╡ f2b27868-874b-11eb-3c12-b10fb929f9d1
begin
	q5_15=8;
	p_list5_15=zeros(Int64, N5_10);
	p_list5_15[1] = 1;
	for i in 2:N5_15
		p_list5_15[i] = p_list5_15[i-1]*q;
	end
	w_list5_15 = copy(p_list5_15);
	w_list_cost_optimal_isoefficient5_15 = copy(w_list5_15);
	for i in 1:N5_15
		# K=4, means E=0.8
		w_list_cost_optimal_isoefficient5_15[i] *= 4*(11*sqrt(p_list5_15[i]));
	end
	Tp5_15 = zeros(Float64, N5_15);
	Tp_cost_optimal_isoefficient5_15 = zeros(Float64, N5_15);
	
	speedup5_15 = zeros(Float64, N5_15);
	speedup_cost_optimal_isoefficient5_15 = zeros(Float64, N5_15);
	
	efficiency5_15 = zeros(Float64, N5_15);
	efficiency_cost_optimal_isoefficient5_15 = zeros(Float64, N5_15);
	for i in 1:N5_15
		Tp5_15[i] = w_list5_15[i]/p_list5_15[i] + 11*sqrt(p_list5_15[i]);
		Tp_cost_optimal_isoefficient5_15[i] = w_list_cost_optimal_isoefficient5_15[i]/p_list5_15[i] + 11*sqrt(p_list5_15[i]);
		
		speedup5_15[i] = w_list5_15[i] / Tp5_15[i];
		speedup_cost_optimal_isoefficient5_15[i] = w_list_cost_optimal_isoefficient5_15[i] / Tp_cost_optimal_isoefficient5_15[i];
		
		efficiency5_15[i] = speedup5_15[i] /  p_list5_15[i];
		efficiency_cost_optimal_isoefficient5_15[i] = speedup_cost_optimal_isoefficient5_15[i] /  p_list5_15[i];
	end
end

# ╔═╡ 4fdb0b46-874d-11eb-3f78-656829848a62
begin
	plot(w_list5_15, Tp5_15, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_cost_optimal_isoefficient5_15, Tp_cost_optimal_isoefficient5_15) #orange
end

# ╔═╡ f06fe47a-874b-11eb-0594-ab44408e6bc5
begin
	plot(w_list5_15, speedup5_15, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_cost_optimal_isoefficient5_15, speedup_cost_optimal_isoefficient5_15); #orange
end

# ╔═╡ 7ccb102e-874d-11eb-15bd-6be04b917bd4
begin
	plot(w_list5_15, efficiency5_15, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
	plot!(w_list_cost_optimal_isoefficient5_15, efficiency_cost_optimal_isoefficient5_15); #orange
end

# ╔═╡ 5b644c40-8785-11eb-07fa-f14a44d923a2
# 5.14 [GK93a] Consider two parallel systems with the same overhead function, but with different degrees of concurrency. Let the overhead function of both parallel systems be W 1/3 p3/2 + 0.1W 2/3 p. Plot the TP versus p curve for W = 106, and 1 ≤ p ≤ 2048. If the degree of concurrency is W1/3 for the first algorithm and W2/3 for the second algorithm, compute the values of Dependency graphs for Problem 5.3. for both parallel systems. Also compute the cost and efficiency for both the parallel systems at the point on the TP versus p curve where their respective minimum runtimes are achieved.

# ╔═╡ 7efb699a-8785-11eb-3eb2-9b923cf4a54f
@bind N5_20 Slider(4:25, show_value=true)

# ╔═╡ 6c7ea0f2-8785-11eb-27f8-754081ebc398
begin
	q5_20=8;
	p_list5_20=zeros(Int64, N5_20);
	p_list5_20[1] = 1;
	for i in 2:N5_20
		p_list5_20[i] = p_list5_20[i-1]*q;
	end
	w_list5_20 = 1000000;
	To_20 = zeros(Float64, N5_20);
	Tp5_20 = zeros(Float64, N5_20);

	for i in 1:N5_20
		To_20[i] = w_list5_20^(1/3) * p_list5_20[i]^(3/2) + 0.1 * w_list5_20^(2/3) * p_list5_20[i]
		Tp5_20[i] = (w_list5_20 - To_20[i]) / p_list5_20[i];
	end
end

# ╔═╡ 455a641a-8786-11eb-30b2-4334214e522a
begin
	plot(Tp5_20, p_list5_20, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f); #blue
end

# ╔═╡ Cell order:
# ╠═8665ad12-8541-11eb-1eb0-4f9d384df11c
# ╠═8215c470-8548-11eb-2093-b3c3b4e56846
# ╠═390278d8-8549-11eb-38bf-07d2643c0df8
# ╠═bd3eac94-8541-11eb-32cd-33ff677dc01b
# ╠═8ea6c20e-8541-11eb-39cb-c74b21c3d256
# ╠═0ec38a7a-8548-11eb-3ad9-513df471c2f4
# ╠═11aa3036-8548-11eb-1434-2fe3ec454cf1
# ╠═5433a6b2-85a7-11eb-23b2-bf6c5f23baa8
# ╠═61d8e914-8677-11eb-213d-7376ed3f1f30
# ╠═62a132de-8677-11eb-26c4-bd2de46295ce
# ╠═65d0205a-8677-11eb-3b87-45ff103a9e44
# ╠═059a6a68-8548-11eb-2bf1-c37b366920c0
# ╠═4f513fb8-854a-11eb-3b9e-43b31fe397f6
# ╠═bdde38d0-85a6-11eb-1d7b-2bdbc32850a1
# ╠═6cf1d59c-85a8-11eb-0bd5-7b24054b6a43
# ╠═70add870-85a8-11eb-1d12-d34e8a2eaa05
# ╠═751f925e-85a8-11eb-3829-ef24e4657fb3
# ╠═e0c9684e-8540-11eb-3f0b-2b26fa6a3ebb
# ╠═5574d5d0-854a-11eb-1962-0f728841ba73
# ╠═46798c6a-854a-11eb-3aa8-91ed72958943
# ╠═2c15db9c-8600-11eb-04b6-a136879ec94b
# ╠═3f1cb858-8602-11eb-39fb-fda0e0a00dd2
# ╠═ab4f3fe6-8602-11eb-1ff2-c15897b3e69b
# ╠═ace4c088-8602-11eb-33f8-fd975ac94414
# ╠═b0b755a4-8602-11eb-2d56-632242c58935
# ╠═b637e702-8673-11eb-06b2-c5c972f5cfcf
# ╠═e84aa6ea-8672-11eb-2837-ef734dc7cede
# ╠═8c74cd2c-8673-11eb-1e97-f32e50e81d25
# ╠═95855d28-8673-11eb-396b-3189d9826f17
# ╠═b939ab4a-8676-11eb-34c7-c997f541610b
# ╠═7caa61c4-8743-11eb-24d5-c76b5386101d
# ╠═ef31d876-8676-11eb-3c28-036c2746e7a5
# ╠═f074c7a2-8676-11eb-25fd-75622cace8b7
# ╠═8652e3d6-8743-11eb-2096-7b19b9946d61
# ╠═98364b9a-8673-11eb-33c3-2180dfd219c5
# ╠═ca248d1c-8676-11eb-2f4f-67574d09e8fd
# ╠═8e1ed6c4-8743-11eb-1faf-8d7f69de95e7
# ╠═9b117d8a-8673-11eb-022c-9f4a02829909
# ╠═dd3020d8-8676-11eb-0ebd-41e1995d9efc
# ╠═93cf3096-8743-11eb-3769-f1c2031e7c84
# ╠═a1cf769a-8673-11eb-39a4-09a20b5d0a87
# ╠═1c779ddc-8674-11eb-2c4a-399043d0a1af
# ╠═2a50627a-8674-11eb-32e2-ebdf469ffe13
# ╠═f080cf4c-8749-11eb-35b2-49ccabc5a104
# ╠═7cbb6ba6-874b-11eb-10ec-ab7c1c8d981a
# ╠═f2b27868-874b-11eb-3c12-b10fb929f9d1
# ╠═4fdb0b46-874d-11eb-3f78-656829848a62
# ╠═f06fe47a-874b-11eb-0594-ab44408e6bc5
# ╠═7ccb102e-874d-11eb-15bd-6be04b917bd4
# ╠═5b644c40-8785-11eb-07fa-f14a44d923a2
# ╠═7efb699a-8785-11eb-3eb2-9b923cf4a54f
# ╠═6c7ea0f2-8785-11eb-27f8-754081ebc398
# ╠═455a641a-8786-11eb-30b2-4334214e522a
