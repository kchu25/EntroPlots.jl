using Pkg; Pkg.activate(".")
using EntroPlots

# Create simple nucleotide PFMs (4 rows: A, C, G, T)
pfm1 = [0.7 0.1 0.1 0.1 0.6 0.2 0.1 0.1 0.5;
        0.1 0.7 0.1 0.6 0.1 0.1 0.7 0.1 0.2;
        0.1 0.1 0.7 0.1 0.2 0.6 0.1 0.7 0.2;
        0.1 0.1 0.1 0.2 0.1 0.1 0.1 0.1 0.1]

pfm2 = [0.1 0.6 0.1 0.1 0.7 0.1 0.1 0.6 0.5;
        0.7 0.1 0.1 0.6 0.1 0.1 0.7 0.1 0.2;
        0.1 0.2 0.7 0.1 0.1 0.6 0.1 0.2 0.2;
        0.1 0.1 0.1 0.2 0.1 0.2 0.1 0.1 0.1]

# Reference sequences (what should be at each position)
ref1 = BitMatrix([1 0 0 0 1 0 0 0 1;  # A at pos 1, 5, 9
                  0 1 0 1 0 0 1 0 0;  # C at pos 2, 4, 7
                  0 0 1 0 0 1 0 1 0;  # G at pos 3, 6, 8
                  0 0 0 0 0 0 0 0 0]) # T (none)

ref2 = BitMatrix([0 1 0 0 1 0 0 1 1;  # A
                  1 0 0 1 0 0 1 0 0;  # C
                  0 0 1 0 0 1 0 0 0;  # G
                  0 0 0 0 0 0 0 0 0]) # T

# Plot: Motif at positions 10-18, gap, Motif at positions 21-29
p = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [10, 21],           # Starting positions
    30;                 # Total sequence length
    reference_pfms = [ref1, ref2],  # Blue=match, Red=mismatch
    xrotation = 25      # Rotate x-axis labels
)

using Plots
savefig(p, "simple_demo.png")
println("✓ Saved: simple_demo.png")
println("  Blue letters = match reference")
println("  Red letters = differ from reference")
println("  Gap (strike-through) = positions 19-20")
