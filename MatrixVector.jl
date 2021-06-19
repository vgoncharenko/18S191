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

# ╔═╡ a8f395ca-89b4-11eb-2794-35b8c7f9614d
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

# ╔═╡ d3d5bbac-8ffd-11eb-0036-f720d75de63d
#Info:
# CPU:
#	1) https://drive.google.com/file/d/1yJnA0DMCurglTWt1Ndoi3VhU0qLtFnpB/view?usp=sharing
#	2) https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/ch08.html
	

# Examples:
# GPU: https://github.com/vgoncharenko/2d/tree/master/metal-samples/MatrixVectorMult
# CPU: https://github.com/vgoncharenko/algorithms/blob/master/graphic/MatrixVectorMult.cpp

# ╔═╡ 3dcb8242-89b6-11eb-0ac0-53812d8838df
begin
	url_mvm = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/08fig10.gif"
	download(url_mvm, "Matrix_vector_mult.gif")
	example_mvm = load("Matrix_vector_mult.gif")
end

# ╔═╡ fdc28106-89b4-11eb-210b-798df79f6049
@bind N_mvm Slider(11:20, show_value=true)

# ╔═╡ 18e55c7e-89b5-11eb-0944-63fc3551ec56
begin
	q_mvm=2;
	Ts_mvm=1;
	Tw_mvm=1;
	w_list_mvm = zeros(Float64, N_mvm);
	p_GPU_mvm=1024;
	p_CPU8_mvm=8;
	p_CPU16_mvm=16;
	p_CPU32_mvm=32;
	
	w_list_mvm[1] = 1024;
	for i in 2:N_mvm
		w_list_mvm[i] = w_list_mvm[i-1]*q_mvm;
	end
	
	Ts_CPU_real = [3.809e-6, 9.1e-6, 3.4614e-5, 0.000136064, 0.000582283, 0.002276375, 0.008850202, 0.036460935, 0.139286468, 0.576185534, 2.423606761];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	
	Tp_mvm = zeros(Float64, N_mvm);
	Tp_GPU_real_2steps = [0.000109, 0.000187, 0.000179, 0.000310, 0.000406, 0.000879, 0.001212, 0.002001, 0.004325, 0.005948, 0.017153];
	Tp_GPU_real_OneStep = [0.000079, 0.000170, 0.000139, 0.000241, 0.000241, 0.000659, 0.000446, 0.000925, 0.000863, 0.001515, 0.003031];

	Tp_CPU8_real = [0.000293152, 0.000188624, 0.000164073, 0.000205863, 0.000448019, 0.00131523, 0.00423999, 0.0180002, 0.0476746, 0.249551, 6.23891];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	Tp_CPU16_real = [0.000335457, 0.000252915, 0.000281748, 0.000245044, 0.000459353, 0.00130977, 0.00414545, 0.0128069, 0.05105, 0.225218, 1.64807];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	Tp_CPU32_real = [0.000768577, 0.000703513, 0.000633718, 0.000670372, 0.00071964, 0.00130375, 0.00346425, 0.0131895, 0.041867, 0.155067, 1.95651];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	
	Tp_CPU8_real_loop_unrolled = [0.000240674, 0.000138532, 0.000142338, 0.00022269, 0.000409169, 0.00129388, 0.00321101, 0.0093671, 0.0346442, 0.113349, 1.22145];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	Tp_CPU16_real_loop_unrolled = [0.000394569, 0.000290968, 0.000308606, 0.000297296, 0.00047905, 0.00137733, 0.00519842, 0.0182241, 0.052886, 0.10293, 0.663978];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	Tp_CPU32_real_loop_unrolled = [0.000923686, 0.00079691, 0.000876126, 0.00084179, 0.000686909, 0.00115958, 0.00269761, 0.00864347, 0.0298196, 0.106457, 1.26769];#, 0, 0, 0, 0, 0 ,0, 0, 0 ,0];
	
	speedup_mvm = zeros(Float64, N_mvm);
	speedup_GPU_real_2steps = zeros(Float64, N_mvm);
	speedup_GPU_real_OneStep = zeros(Float64, N_mvm);
	speedup_CPU8_real = zeros(Float64, N_mvm);
	speedup_CPU16_real = zeros(Float64, N_mvm);
	speedup_CPU32_real = zeros(Float64, N_mvm);
	speedup_CPU8_real_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU16_real_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU32_real_loop_unrolled = zeros(Float64, N_mvm);
	
	efficiency_mvm = zeros(Float64, N_mvm);
	efficiency_GPU_real_2steps = zeros(Float64, N_mvm);
	efficiency_GPU_real_OneStep = zeros(Float64, N_mvm);
	efficiency_CPU8_real = zeros(Float64, N_mvm);
	efficiency_CPU16_real = zeros(Float64, N_mvm);
	efficiency_CPU32_real = zeros(Float64, N_mvm);
	efficiency_CPU8_real_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU16_real_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU32_real_loop_unrolled = zeros(Float64, N_mvm);

	for i in 1:N_mvm
		Tp_mvm[i] = 2 * w_list_mvm[i]/p_GPU_mvm * 1.e-9;
		
		speedup_mvm[i] = w_list_mvm[i] * 1.e-9 / Tp_mvm[i];
		speedup_GPU_real_2steps[i] = Ts_CPU_real[i] / Tp_GPU_real_2steps[i];
		speedup_GPU_real_OneStep[i] = Ts_CPU_real[i] / Tp_GPU_real_OneStep[i];
		speedup_CPU8_real[i] = Ts_CPU_real[i] / Tp_CPU8_real[i];
		speedup_CPU16_real[i] = Ts_CPU_real[i] / Tp_CPU16_real[i];
		speedup_CPU32_real[i] = Ts_CPU_real[i] / Tp_CPU32_real[i];
		speedup_CPU8_real_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU8_real_loop_unrolled[i];
		speedup_CPU16_real_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU16_real_loop_unrolled[i];
		speedup_CPU32_real_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU32_real_loop_unrolled[i];
		
		efficiency_mvm[i] = speedup_mvm[i] / p_GPU_mvm;
		efficiency_GPU_real_2steps[i] = speedup_GPU_real_2steps[i] / p_GPU_mvm;
		efficiency_GPU_real_OneStep[i] = speedup_GPU_real_OneStep[i] / p_GPU_mvm;
		efficiency_CPU8_real[i] = speedup_CPU8_real[i] / p_CPU8_mvm;
		efficiency_CPU16_real[i] = speedup_CPU16_real[i] / p_CPU16_mvm;
		efficiency_CPU32_real[i] = speedup_CPU32_real[i] / p_CPU32_mvm;
		efficiency_CPU8_real_loop_unrolled[i] = speedup_CPU8_real_loop_unrolled[i] / p_CPU8_mvm;
		efficiency_CPU16_real_loop_unrolled[i] = speedup_CPU16_real_loop_unrolled[i] / p_CPU16_mvm;
		efficiency_CPU32_real_loop_unrolled[i] = speedup_CPU32_real_loop_unrolled[i] / p_CPU32_mvm;
	end
end

# ╔═╡ 572564e2-8d8a-11eb-3012-6b39088dec5d
w_list_mvm

# ╔═╡ 1415938e-89b6-11eb-3c88-0ddd27a0c8bd
begin
	plot(w_list_mvm, Tp_GPU_real_2steps, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f, label="Tp_GPU_real_2steps");
	plot!(w_list_mvm, Tp_GPU_real_OneStep, label="Tp_GPU_real_OneStep");
	plot!(w_list_mvm, Ts_CPU_real, label="Ts_CPU_real");
	plot!(w_list_mvm, Tp_CPU8_real, label="Tp_CPU8_real");
	plot!(w_list_mvm, Tp_CPU16_real, label="Tp_CPU16_real");
	plot!(w_list_mvm, Tp_CPU32_real, label="Tp_CPU32_real");
	plot!(w_list_mvm, Tp_CPU8_real_loop_unrolled, label="Tp_CPU8_real_loop_unrolled");
	plot!(w_list_mvm, Tp_CPU16_real_loop_unrolled, label="Tp_CPU16_real_loop_unrolled");
	plot!(w_list_mvm, Tp_CPU32_real_loop_unrolled, label="Tp_CPU32_real_loop_unrolled");
end

# ╔═╡ 0b44f5e2-89b6-11eb-3056-038f60d880e1
begin
	plot(w_list_mvm, speedup_CPU8_real, label="speedup_CPU8_real", size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f,);
	plot!(w_list_mvm, speedup_CPU16_real, label="speedup_CPU16_real");
	plot!(w_list_mvm, speedup_CPU32_real, label="speedup_CPU32_real");
	plot!(w_list_mvm, speedup_CPU8_real_loop_unrolled, label="speedup_CPU8_real_loop_unrolled");
	plot!(w_list_mvm, speedup_CPU16_real_loop_unrolled, label="speedup_CPU16_real_loop_unrolled");
	plot!(w_list_mvm, speedup_CPU32_real_loop_unrolled, label="speedup_CPU32_real_loop_unrolled");
	plot!(w_list_mvm, speedup_GPU_real_2steps, label="speedup_GPU_real_2steps");
    plot!(w_list_mvm, speedup_GPU_real_OneStep, label="speedup_GPU_real_OneStep");
end

# ╔═╡ f5be813e-89b5-11eb-089a-bb42d62a4c45
begin
	plot(w_list_mvm, efficiency_GPU_real_2steps, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f, label="efficiency_GPU_real_2steps");
	plot!(w_list_mvm, efficiency_GPU_real_OneStep, label="efficiency_GPU_real_OneStep");
	plot!(w_list_mvm, efficiency_CPU8_real, label="efficiency_CPU8_real");
	plot!(w_list_mvm, efficiency_CPU16_real, label="efficiency_CPU16_real");
	plot!(w_list_mvm, efficiency_CPU32_real, label="efficiency_CPU32_real");
	plot!(w_list_mvm, efficiency_CPU8_real_loop_unrolled, label="efficiency_CPU8_real_loop_unrolled");
	plot!(w_list_mvm, efficiency_CPU16_real_loop_unrolled, label="efficiency_CPU16_real_loop_unrolled");
	plot!(w_list_mvm, efficiency_CPU32_real_loop_unrolled, label="efficiency_CPU32_real_loop_unrolled");
end

# ╔═╡ Cell order:
# ╠═d3d5bbac-8ffd-11eb-0036-f720d75de63d
# ╠═a8f395ca-89b4-11eb-2794-35b8c7f9614d
# ╠═3dcb8242-89b6-11eb-0ac0-53812d8838df
# ╠═fdc28106-89b4-11eb-210b-798df79f6049
# ╠═18e55c7e-89b5-11eb-0944-63fc3551ec56
# ╠═572564e2-8d8a-11eb-3012-6b39088dec5d
# ╠═1415938e-89b6-11eb-3c88-0ddd27a0c8bd
# ╠═0b44f5e2-89b6-11eb-3056-038f60d880e1
# ╠═f5be813e-89b5-11eb-089a-bb42d62a4c45
