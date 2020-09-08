### A Pluto.jl notebook ###
# v0.11.12

using Markdown
using InteractiveUtils

# ╔═╡ 80b2135e-f1ed-11ea-17ee-656b8062026a
md"""
# A word about macros

Macros change the syntax of parts of a program.

While functions work on values, **macros take Julia code** which is represented as a datastrcuture in Julia itself and **rewrite it to a different piece of code**.

Here we take the example of a simple macro called `@elapsed`, which adds extra code around the input expression to measure how much time it took to run a piece of code.

First let's see it in action!
"""

# ╔═╡ f43139a2-f1ed-11ea-0cdf-678ffac4374a
@elapsed peakflops()

# ╔═╡ 67b3fb78-f1ee-11ea-2d0a-a92e81580917
md"""
**NOTE:** a macro is always called using the `@` prefix character, this is a visual cue that the following piece of code is not what is actually executed, but is transformed in some way.
"""

# ╔═╡ 5677f2d6-f1ee-11ea-3f9b-b59c8a8d07ff
md"""
You can look at the transformed expression by using `@macroexpand` which is itself a macro!!
"""

# ╔═╡ 4b2cbfc4-f1ee-11ea-17d6-a72fd22e6d89
@macroexpand @elapsed peakflops()

# ╔═╡ 9639e822-f1ee-11ea-19b6-5f377bb4b809
Base.remove_linenums!(@macroexpand @elapsed peakflops())

# ╔═╡ a5816132-f1ee-11ea-268b-05086212324b
md"""
How was `remove_linenums!` actually gets a Julia expression as an argument.

How can we create expressions in Julia?

"""

# ╔═╡ c5465fe0-f1ee-11ea-2f61-3172509f693d
1+2

# ╔═╡ c88dfe88-f1ee-11ea-0327-8b18a25c511c
:(1+2)

# ╔═╡ cbce40ee-f1ee-11ea-2e05-1d523acbf8b9
expr = :(x + 1)

# ╔═╡ e0685602-f1ee-11ea-2aa7-01b7705a2b6c
typeof(expr)

# ╔═╡ e46e6c96-f1ee-11ea-3e7f-4f613282ccb1
expr.head

# ╔═╡ e631bede-f1ee-11ea-0fab-7516ab535cf5
expr.args

# ╔═╡ eafc0a1e-f1ee-11ea-3851-217ba754f2ed
md"""
macros simply take expressions such as these and transform them in some way into something else.
"""

# ╔═╡ 0ff6e154-f1ef-11ea-2ee8-61eb98523642
md"""
## Conclusion


When you see something like `@foo` know that it's a **Syntactic transformation** and may add to the behavior of the language in some way!

Being able to represent Julia code within Julia is very useful, and hence you will see frequent use of macros and expression manipulation in Julia

"""

# ╔═╡ Cell order:
# ╟─80b2135e-f1ed-11ea-17ee-656b8062026a
# ╠═f43139a2-f1ed-11ea-0cdf-678ffac4374a
# ╟─67b3fb78-f1ee-11ea-2d0a-a92e81580917
# ╠═5677f2d6-f1ee-11ea-3f9b-b59c8a8d07ff
# ╠═4b2cbfc4-f1ee-11ea-17d6-a72fd22e6d89
# ╠═9639e822-f1ee-11ea-19b6-5f377bb4b809
# ╟─a5816132-f1ee-11ea-268b-05086212324b
# ╠═c5465fe0-f1ee-11ea-2f61-3172509f693d
# ╠═c88dfe88-f1ee-11ea-0327-8b18a25c511c
# ╠═cbce40ee-f1ee-11ea-2e05-1d523acbf8b9
# ╠═e0685602-f1ee-11ea-2aa7-01b7705a2b6c
# ╠═e46e6c96-f1ee-11ea-3e7f-4f613282ccb1
# ╠═e631bede-f1ee-11ea-0fab-7516ab535cf5
# ╟─eafc0a1e-f1ee-11ea-3851-217ba754f2ed
# ╟─0ff6e154-f1ef-11ea-2ee8-61eb98523642
