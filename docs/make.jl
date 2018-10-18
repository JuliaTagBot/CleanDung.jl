using Documenter, CleanDung

makedocs(
    modules = [CleanDung],
    format = :html,
    sitename = "CleanDung.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/yakir12/CleanDung.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
