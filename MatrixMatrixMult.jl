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

# ╔═╡ 8e06c8d2-97e6-11eb-0caa-2590b7f9cf78
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

# ╔═╡ 923b5656-9be8-11eb-038b-77922b0bb8b0
begin
	url_mvm_cannon = "https://learning.oreilly.com/library/view/introduction-to-parallel/0201648652/graphics/08fig31.gif"
	download(url_mvm_cannon, "Matrix_vector_mult_cannon.gif")
	example_mvm_cannon = load("Matrix_vector_mult_cannon.gif")
end

# ╔═╡ b1f39a2c-97e6-11eb-1f6c-9985398c9d64
@bind N_mvm Slider(7:20, show_value=true)

# ╔═╡ bb300fe4-97e6-11eb-28ca-ddddeac35d36
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
	
	Ts_CPU_real = [0.000154591, 0.00108197, 0.00907174, 0.0921075, 0.678858, 8.65941, 191.597];
	
	Tp_mvm = zeros(Float64, N_mvm);
Tp_GPU_real = [0.000153, 0.000195, 0.000269, 0.000379, 0.000595, 0.000844, 0.001682]; #0.004270, 0.013795, 0.031573, 0.058411

	Tp_CPU8_real_horizontal = [0.000265272, 0.000416492, 0.00254158, 0.0207416, 0.168377, 1.87159, 33.3575];
	Tp_CPU16_real_horizontal = [0.000461501, 0.000334829, 0.0013896, 0.0118515, 0.11511, 1.12063, 29.998];
	Tp_CPU32_real_horizontal = [0.000863918, 0.000736312, 0.00194987, 0.0153029, 0.128273, 1.48833, 31.8674];
	
	Tp_CPU8_real_horizontal_loop_unrolled = [0.000273414, 0.000323488, 0.00158323, 0.0145369, 0.12785, 1.27026, 19.2649];
	Tp_CPU16_real_horizontal_loop_unrolled = [0.000393414, 0.000324356, 0.00107238, 0.00892886, 0.094354, 0.994733, 21.846];
	Tp_CPU32_real_horizontal_loop_unrolled = [0.00101759, 0.00063289, 0.00110239, 0.00899222, 0.0857203, 0.934058, 23.9149];
	
	Tp_CPU8_real_true_horizontal = [0.000232919, 0.000322771, 0.00117743, 0.00853431, 0.0640172, 0.50095, 4.24992];
	Tp_CPU16_real_true_horizontal = [0.000522845, 0.000325476, 0.00151731, 0.0085312, 0.0601183, 0.532288, 4.51218];
	Tp_CPU32_real_true_horizontal = [0.000755834, 0.000753304, 0.00192776, 0.0121123, 0.0692833, 0.595705, 4.58969];
	
	Tp_CPU8_real_true_horizontal_loop_unrolled = [0.000363677, 0.000355482, 0.00134084, 0.00892531, 0.058307, 0.504619, 3.66266];
	Tp_CPU16_real_true_horizontal_loop_unrolled = [0.000462175, 0.000415105, 0.0010607, 0.0066444, 0.0479493, 0.426288, 3.64998];
	Tp_CPU32_real_true_horizontal_loop_unrolled = [0.000928411, 0.000878871, 0.00100197, 0.00635319, 0.0482158, 0.422595, 3.69898];
	
	Tp_CPU8_real_true_horizontal_loop_unrolled_vector = [0.000231437, 0.000424302, 0.00291311, 0.0225639, 0.194088, 1.45416, 13.0486];
	
	Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled = [0.00132642, 0.00135877, 0.00267276, 0.0135687, 0.0831978, 0.512099, 5.65377];
	
	Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var = [0.00118258, 0.000554188, 0.00146481, 0.00833184, 0.063368, 0.512647, 5.01905];
	
	speedup_mvm = zeros(Float64, N_mvm);
	speedup_GPU_real = zeros(Float64, N_mvm);
	speedup_CPU8_real_horizontal = zeros(Float64, N_mvm);
	speedup_CPU16_real_horizontal = zeros(Float64, N_mvm);
	speedup_CPU32_real_horizontal = zeros(Float64, N_mvm);
	speedup_CPU8_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU16_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU32_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU8_real_true_horizontal = zeros(Float64, N_mvm);
	speedup_CPU16_real_true_horizontal = zeros(Float64, N_mvm);
	speedup_CPU32_real_true_horizontal = zeros(Float64, N_mvm);
	speedup_CPU8_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU16_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU32_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU8_real_true_horizontal_loop_unrolled_vector = zeros(Float64, N_mvm);
	speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled = zeros(Float64, N_mvm);
	speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var = zeros(Float64, N_mvm);
	
	efficiency_mvm = zeros(Float64, N_mvm);
	efficiency_GPU_real = zeros(Float64, N_mvm);
	efficiency_CPU8_real_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU16_real_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU32_real_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU8_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU16_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU32_real_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU8_real_true_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU16_real_true_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU32_real_true_horizontal = zeros(Float64, N_mvm);
	efficiency_CPU8_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU16_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU32_real_true_horizontal_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU8_real_true_horizontal_loop_unrolled_vector = zeros(Float64, N_mvm);
	efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled = zeros(Float64, N_mvm);
	efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var = zeros(Float64, N_mvm);

	for i in 1:N_mvm
		speedup_GPU_real[i] = Ts_CPU_real[i] / Tp_GPU_real[i];
		speedup_CPU8_real_horizontal[i] = Ts_CPU_real[i] / Tp_CPU8_real_horizontal[i];
		speedup_CPU16_real_horizontal[i] = Ts_CPU_real[i] / Tp_CPU16_real_horizontal[i];
		speedup_CPU32_real_horizontal[i] = Ts_CPU_real[i] / Tp_CPU32_real_horizontal[i];
		speedup_CPU8_real_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU8_real_horizontal_loop_unrolled[i];
		speedup_CPU16_real_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU16_real_horizontal_loop_unrolled[i];
		speedup_CPU32_real_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU32_real_horizontal_loop_unrolled[i];
		speedup_CPU8_real_true_horizontal[i] = Ts_CPU_real[i] / Tp_CPU8_real_true_horizontal[i];
		speedup_CPU16_real_true_horizontal[i] = Ts_CPU_real[i] / Tp_CPU16_real_true_horizontal[i];
		speedup_CPU32_real_true_horizontal[i] = Ts_CPU_real[i] / Tp_CPU32_real_true_horizontal[i];
		speedup_CPU8_real_true_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU8_real_true_horizontal_loop_unrolled[i];
		speedup_CPU16_real_true_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU16_real_true_horizontal_loop_unrolled[i];
		speedup_CPU32_real_true_horizontal_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU32_real_true_horizontal_loop_unrolled[i];
		speedup_CPU8_real_true_horizontal_loop_unrolled_vector[i] = Ts_CPU_real[i] / Tp_CPU8_real_true_horizontal_loop_unrolled_vector[i];
		speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled[i] = Ts_CPU_real[i] / Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled[i];
	speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var[i] = Ts_CPU_real[i] / Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var[i];
		
		efficiency_GPU_real[i] = speedup_GPU_real[i] / p_GPU_mvm;
		efficiency_CPU8_real_horizontal[i] = speedup_CPU8_real_horizontal[i] / p_CPU8_mvm;
		efficiency_CPU16_real_horizontal[i] = speedup_CPU16_real_horizontal[i] / p_CPU16_mvm;
		efficiency_CPU32_real_horizontal[i] = speedup_CPU32_real_horizontal[i] / p_CPU32_mvm;
		efficiency_CPU8_real_horizontal_loop_unrolled[i] = speedup_CPU8_real_horizontal_loop_unrolled[i] / p_CPU8_mvm;
		efficiency_CPU16_real_horizontal_loop_unrolled[i] = speedup_CPU16_real_horizontal_loop_unrolled[i] / p_CPU16_mvm;
		efficiency_CPU32_real_horizontal_loop_unrolled[i] = speedup_CPU32_real_horizontal_loop_unrolled[i] / p_CPU32_mvm;
		efficiency_CPU8_real_true_horizontal[i] = speedup_CPU8_real_true_horizontal[i] / p_CPU8_mvm;
		efficiency_CPU16_real_true_horizontal[i] = speedup_CPU16_real_true_horizontal[i] / p_CPU16_mvm;
		efficiency_CPU32_real_true_horizontal[i] = speedup_CPU32_real_true_horizontal[i] / p_CPU32_mvm;
		efficiency_CPU8_real_true_horizontal_loop_unrolled[i] = speedup_CPU8_real_true_horizontal_loop_unrolled[i] / p_CPU8_mvm;
		efficiency_CPU16_real_true_horizontal_loop_unrolled[i] = speedup_CPU16_real_true_horizontal_loop_unrolled[i] / p_CPU16_mvm;
		efficiency_CPU32_real_true_horizontal_loop_unrolled[i] = speedup_CPU32_real_true_horizontal_loop_unrolled[i] / p_CPU32_mvm;
		efficiency_CPU8_real_true_horizontal_loop_unrolled_vector[i] = speedup_CPU8_real_true_horizontal_loop_unrolled_vector[i] / p_CPU8_mvm;
		efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled[i] = speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled[i] / p_CPU16_mvm;
efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var[i] = speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var[i] / p_CPU16_mvm;
	end
end

# ╔═╡ cd53ff96-97e6-11eb-1963-7b516445f8ca
begin
	plot(w_list_mvm, Tp_CPU8_real_true_horizontal, label="Tp_CPU8_real_true_horizontal", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f);
	plot!(w_list_mvm, Tp_CPU16_real_true_horizontal, label="Tp_CPU16_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, Tp_CPU32_real_true_horizontal, label="Tp_CPU32_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, Tp_CPU8_real_true_horizontal_loop_unrolled, label="Tp_CPU8_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU16_real_true_horizontal_loop_unrolled, label="Tp_CPU16_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU32_real_true_horizontal_loop_unrolled, label="Tp_CPU32_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU8_real_true_horizontal_loop_unrolled_vector, label="Tp_CPU8_real_true_horizontal_loop_unrolled_vector", lw = 3);
	plot!(w_list_mvm, Tp_CPU8_real_horizontal, label="Tp_CPU8_real_horizontal", lw = 3);
	plot!(w_list_mvm, Tp_CPU16_real_horizontal, label="Tp_CPU16_real_horizontal", lw = 3);
	plot!(w_list_mvm, Tp_CPU32_real_horizontal, label="Tp_CPU32_real_horizontal", lw = 3);
	plot!(w_list_mvm, Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled, label="Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var, label="Tp_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var", lw = 3);
	plot!(w_list_mvm, Tp_CPU8_real_horizontal_loop_unrolled, label="Tp_CPU8_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU16_real_horizontal_loop_unrolled, label="Tp_CPU16_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Tp_CPU32_real_horizontal_loop_unrolled, label="Tp_CPU32_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, Ts_CPU_real, lw = 3, label="Ts_CPU_real_horizontal");
	plot!(w_list_mvm, Tp_GPU_real, label="Tp_GPU_real", lw = 3);
end

# ╔═╡ d7b1d2b0-97e6-11eb-0500-21a2e68d2336
begin
	plot(w_list_mvm, speedup_CPU8_real_true_horizontal, label="speedup_CPU8_real_true_horizontal", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f, );
	plot!(w_list_mvm, speedup_CPU16_real_true_horizontal, label="speedup_CPU16_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, speedup_CPU32_real_true_horizontal, label="speedup_CPU32_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, speedup_CPU8_real_true_horizontal_loop_unrolled, label="speedup_CPU8_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, speedup_CPU16_real_true_horizontal_loop_unrolled, label="speedup_CPU16_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, speedup_CPU32_real_true_horizontal_loop_unrolled, label="speedup_CPU32_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, speedup_CPU8_real_true_horizontal_loop_unrolled_vector, label="speedup_CPU8_real_true_horizontal_loop_unrolled_vector", lw = 3);
	plot!(w_list_mvm, speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled, label="speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled", lw = 3);
	plot!(w_list_mvm, speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var, label="speedup_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var", lw = 3);
	plot!(w_list_mvm, speedup_CPU8_real_horizontal, label="speedup_CPU8_real_horizontal", lw = 3);
	plot!(w_list_mvm, speedup_CPU16_real_horizontal, label="speedup_CPU16_real_horizontal", lw = 3);
	plot!(w_list_mvm, speedup_CPU32_real_horizontal, label="speedup_CPU32_real_horizontal", lw = 3);
	plot!(w_list_mvm, speedup_CPU8_real_horizontal_loop_unrolled, label="speedup_CPU8_real_horizontal_loop_unrolled", lw = 3);
	 plot!(w_list_mvm, speedup_CPU16_real_horizontal_loop_unrolled, label="speedup_CPU16_real_horizontal_loop_unrolled", lw = 3);
	 plot!(w_list_mvm, speedup_CPU32_real_horizontal_loop_unrolled, label="speedup_CPU32_real_horizontal_loop_unrolled", lw = 3);
	 plot!(w_list_mvm, speedup_GPU_real, label="speedup_GPU_real", lw = 3);
end

# ╔═╡ df430cb0-97e6-11eb-3447-aba75d8e5925
begin
	plot(w_list_mvm, efficiency_CPU8_real_true_horizontal,  label="efficiency_CPU8_real_true_horizontal", lw = 3, size = (2700, 2700), xtickfont=f, ytickfont=f, legendfont=f, guidefont=f, titlefont=f);
	plot!(w_list_mvm, efficiency_CPU16_real_true_horizontal, label="efficiency_CPU16_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, efficiency_CPU32_real_true_horizontal, label="efficiency_CPU32_real_true_horizontal", lw = 3);
	plot!(w_list_mvm, efficiency_CPU8_real_true_horizontal_loop_unrolled, label="efficiency_CPU8_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU16_real_true_horizontal_loop_unrolled, label="efficiency_CPU16_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU32_real_true_horizontal_loop_unrolled, label="efficiency_CPU32_real_true_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU8_real_true_horizontal_loop_unrolled_vector, label="efficiency_CPU8_real_true_horizontal_loop_unrolled_vector", lw = 3);
	plot!(w_list_mvm, efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled, label="efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var, label="efficiency_CPU16_real_true_horizontal_checkerboard_cannon_loop_unrolled_cond_var", lw = 3);
	plot!(w_list_mvm, efficiency_CPU8_real_horizontal, label="efficiency_CPU8_real_horizontal", lw = 3);
	plot!(w_list_mvm, efficiency_CPU16_real_horizontal, label="efficiency_CPU16_real_horizontal", lw = 3);
	plot!(w_list_mvm, efficiency_CPU32_real_horizontal, label="efficiency_CPU32_real_horizontal", lw = 3);
	plot!(w_list_mvm, efficiency_CPU8_real_horizontal_loop_unrolled, label="efficiency_CPU8_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU16_real_horizontal_loop_unrolled, label="efficiency_CPU16_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_CPU32_real_horizontal_loop_unrolled, label="efficiency_CPU32_real_horizontal_loop_unrolled", lw = 3);
	plot!(w_list_mvm, efficiency_GPU_real, label="efficiency_GPU_real", lw = 3);
end

# ╔═╡ Cell order:
# ╠═8e06c8d2-97e6-11eb-0caa-2590b7f9cf78
# ╠═923b5656-9be8-11eb-038b-77922b0bb8b0
# ╠═b1f39a2c-97e6-11eb-1f6c-9985398c9d64
# ╠═bb300fe4-97e6-11eb-28ca-ddddeac35d36
# ╠═cd53ff96-97e6-11eb-1963-7b516445f8ca
# ╠═d7b1d2b0-97e6-11eb-0500-21a2e68d2336
# ╠═df430cb0-97e6-11eb-3447-aba75d8e5925
