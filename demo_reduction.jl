# Demo: Reference Reduction - Filter out columns matching reference
using Pkg; Pkg.activate(".")
using EntroPlots, Plots

println("\n" * "="^70)
println("REFERENCE REDUCTION DEMO")
println("="^70 * "\n")

# Create a PFM where some columns exactly match reference
pfm = [0.98 0.1  0.7  0.02 0.6  0.1  0.95 0.1  0.5;   # A
       0.01 0.85 0.1  0.96 0.1  0.7  0.02 0.1  0.2;   # C
       0.01 0.02 0.15 0.01 0.2  0.15 0.02 0.75 0.2;   # G
       0.00 0.03 0.05 0.01 0.1  0.05 0.01 0.05 0.1]   # T

# Normalize
for i in 1:size(pfm, 2)
    pfm[:, i] ./= sum(pfm[:, i])
end

# Reference: each column has exactly one entry = 1 (one-hot encoding)
# Positions 1, 2, 4, 7 should match exactly
ref = BitMatrix([1 0 0 1 0 0 1 0 0;   # A at pos 1, 4, 7
                 0 1 0 0 0 0 0 0 0;   # C at pos 2
                 0 0 1 0 0 1 0 1 0;   # G at pos 3, 6, 8
                 0 0 0 0 1 0 0 0 1])  # T at pos 5, 9

println("PFM has 9 columns")
println("Reference sequence: A C G A T G A G T")
println("  (each column has exactly one entry = 1)")
println("Columns 1, 2, 4, 7 in PFM closely match reference")
println()

# Plot WITHOUT reduction
println("1. Without reduction (reduction=false):")
p1 = EntroPlots.logoplot_with_rect_gaps(
    [pfm],
    [1],
    9;
    reference_pfms = [ref],
    reduction = false
)
savefig(p1, "reduction_off.png")
println("   ✓ Saved: reduction_off.png")
println("   Shows all 9 columns")
println()

# Plot WITH reduction
println("2. With reduction (reduction=true):")
p2 = EntroPlots.logoplot_with_rect_gaps(
    [pfm],
    [1],
    9;
    reference_pfms = [ref],
    reduction = true,
    reduction_tolerance = 0.05  # Allow small deviations
)
savefig(p2, "reduction_on.png")
println("   ✓ Saved: reduction_on.png")
println("   Only shows columns that differ from reference")
println("   Columns matching reference are filtered out")
println()

# Multi-PFM example with reduction
println("3. Two PFMs with reduction:")

pfm1 = [0.95 0.1  0.7;   # A
        0.02 0.85 0.1;   # C
        0.02 0.02 0.15;  # G
        0.01 0.03 0.05]  # T

pfm2 = [0.1  0.92 0.6;   # A
        0.7  0.03 0.2;   # C
        0.15 0.02 0.1;   # G
        0.05 0.03 0.1]   # T

# Normalize
for i in 1:size(pfm1, 2)
    pfm1[:, i] ./= sum(pfm1[:, i])
    pfm2[:, i] ./= sum(pfm2[:, i])
end

ref1 = BitMatrix([1 0 0;   # A at pos 1 (matches)
                  0 1 0;   # C at pos 2 (matches)
                  0 0 1;   # G at pos 3
                  0 0 0])  # T

ref2 = BitMatrix([0 1 0;   # A at pos 2 (matches)
                  1 0 0;   # C at pos 1
                  0 0 1;   # G at pos 3
                  0 0 0])  # T

p3 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [10, 20],
    25;
    reference_pfms = [ref1, ref2],
    reduction = true,
    reduction_tolerance = 0.1
)
savefig(p3, "reduction_multi.png")
println("   ✓ Saved: reduction_multi.png")
println("   PFM1: columns 1,2 match reference → filtered out, only col 3 shown")
println("   PFM2: column 2 matches reference → filtered out, cols 1,3 shown")
println("   Result: Multiple fragments with gaps between them")
println()

println("="^70)
println("DEMO COMPLETE")
println("="^70)
println("\nGenerated files:")
println("  - reduction_off.png  : All columns shown (reduction=false)")
println("  - reduction_on.png   : Only non-matching columns (reduction=true)")
println("  - reduction_multi.png: Multi-PFM with fragmentation")
println("\nThe reduction feature:")
println("  • Removes columns that exactly match reference")
println("  • Fragments PFMs into multiple regions")
println("  • Useful for highlighting only variable/non-conserved positions")
println("="^70 * "\n")
