#!/usr/bin/env julia
# Regenerate all demo images for README
using Pkg; Pkg.activate(".")
using EntroPlots
using Plots
using Random

println("Regenerating demo images...")

# ===== demo.png: Basic Logo =====
pfm = [0.02  1.0  0.98  0.0   0.0   0.0   0.98  0.0   0.18  1.0
       0.98  0.0  0.02  0.19  0.0   0.96  0.01  0.89  0.03  0.0
       0.0   0.0  0.0   0.77  0.01  0.0   0.0   0.0   0.56  0.0
       0.0   0.0  0.0   0.04  0.99  0.04  0.01  0.11  0.23  0.0]

save_logoplot(pfm, "demo/demo.png"; dpi=22)
println("✓ demo/demo.png")

# ===== no_margin.png: Minimal styling =====
p = logoplot(pfm; _margin_=0Plots.mm, tight=true, yaxis=false, xaxis=false, dpi=22)
savefig(p, "demo/no_margin.png")
println("✓ demo/no_margin.png")

# ===== demo4.png: Highlighted regions =====
background = [0.25, 0.25, 0.25, 0.25]
highlighted_regions = [4:8]
p = logoplot_with_highlight(pfm, background, highlighted_regions; dpi=26)
savefig(p, "demo/demo4.png")
println("✓ demo/demo4.png")

# ===== demo4_tight.png: Highlighted regions with tight layout =====
p = logoplot_with_highlight(pfm, background, [4:8]; _margin_=0Plots.mm, tight=true, dpi=26)
savefig(p, "demo/demo4_tight.png")
println("✓ demo/demo4_tight.png")

# ===== logo_protein.png: Protein logo =====
Random.seed!(42)
matrix = rand(20, 25)
pfm_protein = matrix ./ sum(matrix, dims=1)
reduce_entropy!(pfm_protein)

p = logoplot(pfm_protein; protein=true, dpi=160)
savefig(p, "demo/logo_protein.png")
println("✓ demo/logo_protein.png")

# ===== logo_protein_highlight.png: Protein logo with highlighting =====
p = logoplot_with_highlight(pfm_protein, [2:5, 8:12, 21:25]; protein=true, dpi=160)
savefig(p, "demo/logo_protein_highlight.png")
println("✓ demo/logo_protein_highlight.png")

println("\nAll demo images regenerated!")
