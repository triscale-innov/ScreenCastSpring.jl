push!(LOAD_PATH,joinpath(@__DIR__, ".."))
using Documenter, Spring

makedocs(
    modules = [Spring],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Laurent Plagne",
    sitename = "Spring.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com//Spring.jl.git",
)
