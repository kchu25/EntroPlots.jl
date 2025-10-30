# Activate the local package environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Revise 
using Plots
using EntroPlots

println("="^60)
println("DEBUGGING GAP GENERATION")
println("="^60)

# Simple test case: 2 PFMs with a 2-position gap
pfm1 = ones(4, 9) ./ 4
pfm2 = ones(4, 9) ./ 4
pfms = [pfm1, pfm2]

# PFM1: positions 39-47, PFM2: positions 50-58
# Gap: positions 48-49 (2 positions)
starting_indices = [39, 50]
total_len = 60

println("\nInput:")
println("  Starting indices: $starting_indices")
println("  PFM lengths: $(size.(pfms, 2))")
println("  Total length: $total_len")
println()

# Step 1: Check get_display_increments
println("Step 1: get_display_increments")
incs = EntroPlots.get_display_increments(starting_indices, pfms, total_len)
println("  Raw increments: $incs")
println("  inc[1] (before PFM1): $(incs[1]) positions")
println("  inc[2] (gap between PFMs): $(incs[2]) positions")  # Should be 2
println("  inc[3] (after PFM2): $(incs[3]) positions")
println()

# Step 2: Check inc_round_up transformation
println("Step 2: inc_round_up transformation")
incs_transformed = EntroPlots.inc_round_up.(incs)
println("  Transformed increments: $incs_transformed")
println("  Transformed gap: $(incs_transformed[2])")  # Should be >= 1
println()

# Step 3: Check get_offset_from_start
println("Step 3: get_offset_from_start")
offsets, total_adjusted = EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)
println("  Offsets: $offsets")
println("  Total adjusted: $total_adjusted")
println()

# Step 4: Check get_spacers (this is where rectangles are generated)
println("Step 4: get_spacers")
d_starts, d_cols = EntroPlots.get_spacers(pfms, starting_indices, total_len)
println("  d_starts: $d_starts")
println("  d_cols: $d_cols")
println("  Number of gaps to draw: $(length(d_cols[1]))")
println()

if length(d_cols[1]) == 0
    println("❌ ERROR: No gaps generated! This is the problem.")
    println("   The gap is being filtered out somewhere.")
else
    println("✓ Gaps generated successfully")
    for i in 1:length(d_cols[1])
        println("   Gap $i: starts at $(d_starts[i]), width $(d_cols[1][i])")
    end
end
println()

# Step 5: Try plotting
println("Step 5: Attempting to plot")
try
    p = EntroPlots.logoplot_with_rect_gaps(pfms, starting_indices, total_len)
    savefig(p, "debug_gap_test.png")
    println("✓ Plot saved as debug_gap_test.png")
    println("  Check if gap rectangle is visible")
catch e
    println("❌ Error during plotting: $e")
end

println()
println("="^60)
