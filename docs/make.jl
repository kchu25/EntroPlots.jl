using EntroPlots
using Documenter

DocMeta.setdocmeta!(EntroPlots, :DocTestSetup, :(using EntroPlots); recursive = true)

makedocs(;
    modules = [EntroPlots],
    authors = "Shane Kuei-Hsien Chu (skchu@wustl.edu)",
    sitename = "EntroPlots.jl",
    format = Documenter.HTML(;
        canonical = "https://kchu25.github.io/EntroPlots.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = ["Home" => "index.md"],
)

deploydocs(; repo = "github.com/kchu25/EntroPlots.jl", devbranch = "main")
