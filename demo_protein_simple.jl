# Simple Protein Logo with Gap and Reference Coloring
using Pkg; Pkg.activate(".")
using EntroPlots, Plots

# Create two protein PFMs (20 amino acids × 10 positions each)
pfm1 = rand(20, 10); pfm1 ./= sum(pfm1, dims=1)
pfm2 = rand(20, 10); pfm2 ./= sum(pfm2, dims=1)

# Make some positions conserved for visibility
pfm1[[15, 7, 11], [2, 5, 8]] .= 0.7  # R, H, M at positions 2, 5, 8
pfm2[[1, 10, 19], [3, 6, 9]] .= 0.7  # A, L, W at positions 3, 6, 9

# Normalize
for i in 1:10
    pfm1[:, i] ./= sum(pfm1[:, i])
    pfm2[:, i] ./= sum(pfm2[:, i])
end

# Create reference matrices (mark which amino acids to highlight)
ref1 = falses(20, 10)
ref1[15, 2] = true  # R at position 2
ref1[7, 5] = true   # H at position 5

ref2 = falses(20, 10)
ref2[1, 3] = true   # A at position 3
ref2[10, 6] = true  # L at position 6

# Plot: Domain 1 (pos 1-10), Gap (pos 11-12), Domain 2 (pos 13-22)
p = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [1, 13],
    25;
    protein = true,
    uniform_color = false,
    reference_pfms = [ref1, ref2]
)

savefig(p, "protein_simple.png")
println("✓ Saved: protein_simple.png")
println("  Blue = matches reference, Red = differs from reference")
println("  Gap at positions 11-12 shown as strike-through")
