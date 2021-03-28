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

# ╔═╡ 3c1d206e-663d-11eb-06b8-19951cf1dce7
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
end

# ╔═╡ 4f9856cc-663d-11eb-0033-47ca2646c8aa
begin
	url = "https://www.gannett-cdn.com/-mm-/116eb12287558f9884b0e58dead79620a45394d9/c=0-0-3000-1692/local/-/media/USATODAY/USATODAY/2014/05/27//1401219246000-Axx-tiger-V2-22.jpg"
	download(url, "tiger.jpg")
	tiger = load("tiger.jpg")
end

# ╔═╡ 7ec7b884-663d-11eb-0b9f-51292219f935
tigerHead = tiger[50:600, 1600:2150]

# ╔═╡ 3cc217c6-663e-11eb-2f1f-ade72927110e
[
    tigerHead                      reverse(tigerHead, dims=2)
	reverse(tigerHead, dims=1)     reverse(reverse(tigerHead, dims=1), dims=2)
]

# ╔═╡ 87048b52-663e-11eb-1e6e-9f4b53833f63
begin
	green = RGB(0,1,0)
	newTiger = copy(tiger)
	for i in 50:600
		for j in 1600:2150
			newTiger[i, j] += green
		end
	end
	newTiger
end


# ╔═╡ f79dbf14-663e-11eb-05d3-176f95ca5477
begin
	newTiger2 = copy(tiger)
	newTiger2[50:600, 1600:2150] .-= RGB(1, 0 ,1)
	newTiger2
end

# ╔═╡ 66189548-665a-11eb-3574-ff01805a64a2
@bind blur_factor Slider(4:50, show_value=true)

# ╔═╡ 1e48e774-6691-11eb-1b97-1dac97f91c7b
function convolve(img, kernel)
    height = size(kernel, 1)
    width = size(kernel, 2)
    
    half_height = height ÷ 2
    half_width = width ÷ 2
    
    new_image = similar(img)
	
    @inbounds for i in 1:size(img, 1)
        for j in 1:size(img, 2)
			value = RGB(0,0,0)
			for k in -half_height:-half_height + height - 1
				for l in -half_width:-half_width + width - 1
					value += img[clamp(i - k, 1, size(img, 1)), clamp(j - l, 1, size(img, 2))] * kernel[k, l]
				end
			end
			new_image[i, j] = value
        end
    end
    
    return new_image
end

# ╔═╡ 98a2ea3a-6741-11eb-0636-11b20e6ae5f2


# ╔═╡ 6c68cd02-668f-11eb-305e-1923c6e54bec
kernelGausian = Kernel.gaussian((blur_factor, blur_factor))

# ╔═╡ 4c5ed802-669a-11eb-0b69-b373aaea32cb
tigerGauss1 = convolve(tigerHead, kernelGausian)

# ╔═╡ 2cc03ed4-6742-11eb-29af-4b798fed59e5


# ╔═╡ 0e2b0e66-671e-11eb-0c38-e5a66f1ac8bc


# ╔═╡ f64282d2-671d-11eb-37ae-e78a7a6c3dca


# ╔═╡ e71dd404-669c-11eb-3f7d-271e4086086d
tigerGauss2 = imfilter(tigerHead, Kernel.gaussian(blur_factor))

# ╔═╡ 5bc76cb8-6704-11eb-3eb7-c3b12d91baad
tigerGauss1 == tigerGauss2

# ╔═╡ 7b05e8ca-6704-11eb-1637-27f7fc055d98
isapprox(tigerGauss1, tigerGauss2)

# ╔═╡ 94378484-6704-11eb-0b00-05e098309749
mean(abs.(tigerGauss2 - tigerGauss1))

# ╔═╡ f59e6fac-669c-11eb-2e87-5749a436c093
tigerLaplas = imfilter(tigerHead, Kernel.Laplacian())

# ╔═╡ f8f435fe-668f-11eb-3b51-bfe2f7098d0f
grayTiger = Gray.(abs.(tigerGauss1))

# ╔═╡ e2498212-671d-11eb-35c1-a93d320f3958


# ╔═╡ c3097ff6-6704-11eb-2945-63cca9739eb1
function my_dft(signal)
	N = length(signal)
	zeta = -2 * π * im / N
	s = zeros(ComplexF64, size(signal, 1))
	for f in 1:N-1
		for n in 1:N-1
			s[f] += signal[n] * zeta^(f*n)
		end
	end
	
	return s
end

# ╔═╡ 11c5b204-6705-11eb-3186-114b3ad5929b
tigerSignal = vec(Float64.(grayTiger))[1:100]

# ╔═╡ 6982862e-6706-11eb-026c-77556ba5cfd7
tiger_dft = my_dft(tigerSignal)

# ╔═╡ cc79127c-671d-11eb-0d4e-dd2e653e32d5


# ╔═╡ 8d6c9fde-6706-11eb-3328-9ff21435f857
tiger_fft = fft(tigerSignal)

# ╔═╡ 363ecad2-6708-11eb-1667-e52e6aca57ca
tiger_dft == tiger_fft

# ╔═╡ 45ecaa20-6709-11eb-3e89-199c4bbbeea3
isapprox(tiger_dft, tiger_fft)

# ╔═╡ 504e2bf6-6709-11eb-12b0-83902554b5ea
mean(abs.(tiger_dft - tiger_fft))

# ╔═╡ 58605922-6709-11eb-1e11-257595456782
plot(abs.(tiger_dft), size = (1700, 1700))

# ╔═╡ b1201ef8-6709-11eb-3149-07024b41e66b
plot(abs.(tiger_fft), size = (1700, 1700))

# ╔═╡ ba2ef7d0-6709-11eb-14e4-cbd05ad38438


# ╔═╡ 2fa41448-6708-11eb-11d1-cd8fc7f7a32d


# ╔═╡ 232347ac-6708-11eb-0e0c-cf746a226427


# ╔═╡ 8890777e-6706-11eb-073c-0310d4590b54


# ╔═╡ 81ada104-6706-11eb-3cbe-c37b86039844


# ╔═╡ c4232e6e-6704-11eb-3bf6-51328c407920


# ╔═╡ c43a1f20-6704-11eb-13d6-fbf4efc0373f


# ╔═╡ c45327b8-6704-11eb-203a-d57cb7df466f


# ╔═╡ Cell order:
# ╠═3c1d206e-663d-11eb-06b8-19951cf1dce7
# ╠═4f9856cc-663d-11eb-0033-47ca2646c8aa
# ╠═7ec7b884-663d-11eb-0b9f-51292219f935
# ╠═3cc217c6-663e-11eb-2f1f-ade72927110e
# ╠═87048b52-663e-11eb-1e6e-9f4b53833f63
# ╠═f79dbf14-663e-11eb-05d3-176f95ca5477
# ╠═66189548-665a-11eb-3574-ff01805a64a2
# ╠═1e48e774-6691-11eb-1b97-1dac97f91c7b
# ╟─98a2ea3a-6741-11eb-0636-11b20e6ae5f2
# ╠═6c68cd02-668f-11eb-305e-1923c6e54bec
# ╠═4c5ed802-669a-11eb-0b69-b373aaea32cb
# ╟─2cc03ed4-6742-11eb-29af-4b798fed59e5
# ╟─0e2b0e66-671e-11eb-0c38-e5a66f1ac8bc
# ╟─f64282d2-671d-11eb-37ae-e78a7a6c3dca
# ╠═e71dd404-669c-11eb-3f7d-271e4086086d
# ╠═5bc76cb8-6704-11eb-3eb7-c3b12d91baad
# ╠═7b05e8ca-6704-11eb-1637-27f7fc055d98
# ╠═94378484-6704-11eb-0b00-05e098309749
# ╠═f59e6fac-669c-11eb-2e87-5749a436c093
# ╠═f8f435fe-668f-11eb-3b51-bfe2f7098d0f
# ╟─e2498212-671d-11eb-35c1-a93d320f3958
# ╠═c3097ff6-6704-11eb-2945-63cca9739eb1
# ╠═11c5b204-6705-11eb-3186-114b3ad5929b
# ╠═6982862e-6706-11eb-026c-77556ba5cfd7
# ╟─cc79127c-671d-11eb-0d4e-dd2e653e32d5
# ╠═8d6c9fde-6706-11eb-3328-9ff21435f857
# ╠═363ecad2-6708-11eb-1667-e52e6aca57ca
# ╠═45ecaa20-6709-11eb-3e89-199c4bbbeea3
# ╠═504e2bf6-6709-11eb-12b0-83902554b5ea
# ╠═58605922-6709-11eb-1e11-257595456782
# ╠═b1201ef8-6709-11eb-3149-07024b41e66b
# ╟─ba2ef7d0-6709-11eb-14e4-cbd05ad38438
# ╟─2fa41448-6708-11eb-11d1-cd8fc7f7a32d
# ╟─232347ac-6708-11eb-0e0c-cf746a226427
# ╟─8890777e-6706-11eb-073c-0310d4590b54
# ╟─81ada104-6706-11eb-3cbe-c37b86039844
# ╟─c4232e6e-6704-11eb-3bf6-51328c407920
# ╟─c43a1f20-6704-11eb-13d6-fbf4efc0373f
# ╟─c45327b8-6704-11eb-203a-d57cb7df466f
