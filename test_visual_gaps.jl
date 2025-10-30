using Pkg
Pkg.activate(".")

using EntroPlots
using Plots

println("\n" * "="^60)
println("VISUAL GAP TEST - Creating plots with various gap sizes")
println("="^60 * "\n")

# Create test PFMs (simple 4x9 matrices)
function create_test_pfm()
    pfm = zeros(Float64, 4, 9)
    for i in 1:9
        pfm[:, i] = [0.25, 0.25, 0.25, 0.25]
        pfm[mod(i, 4) + 1, i] = 0.7
        pfm[:, i] ./= sum(pfm[:, i])
    end
    return pfm
end

pfm1 = create_test_pfm()
pfm2 = create_test_pfm()

println("Test 1: Gap of 1 position")
println("-" * "="^59)
p1 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 11],  # Gap of 1: positions 10-11 (1-9, gap, 11-19)
    20,
    uniform_color=false
)
savefig(p1, "visual_gap_1pos.png")
println("✓ Saved: visual_gap_1pos.png")

println("\nTest 2: Gap of 2 positions")
println("-" * "="^59)
p2 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 12],  # Gap of 2: positions 10-12 (1-9, gap, 12-20)
    21,
    uniform_color=false
)
savefig(p2, "visual_gap_2pos.png")
println("✓ Saved: visual_gap_2pos.png")

println("\nTest 3: Gap of 3 positions")
println("-" * "="^59)
p3 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 13],  # Gap of 3: positions 10-13 (1-9, gap, 13-21)
    22,
    uniform_color=false
)
savefig(p3, "visual_gap_3pos.png")
println("✓ Saved: visual_gap_3pos.png")

println("\nTest 4: Original issue - gap of 2 with long initial gap")
println("-" * "="^59)
p4 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [39, 50],  # Original problematic case (1-38, 39-47, gap 48-49, 50-58)
    60,
    uniform_color=false
)
savefig(p4, "visual_gap_original.png")
println("✓ Saved: visual_gap_original.png")

println("\nTest 5: Multiple small gaps")
println("-" * "="^59)
pfm3 = create_test_pfm()
p5 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2, pfm3], 
    [1, 11, 21],  # Two gaps of 1 position each (1-9, gap, 11-19, gap, 21-29)
    30,
    uniform_color=false
)
savefig(p5, "visual_gap_multiple.png")
println("✓ Saved: visual_gap_multiple.png")

println("\n" * "="^60)
println("VISUAL TEST COMPLETE")
println("="^60)
println("\nPlease check the following PNG files:")
println("  • visual_gap_1pos.png      - 1 position gap")
println("  • visual_gap_2pos.png      - 2 position gap")
println("  • visual_gap_3pos.png      - 3 position gap")
println("  • visual_gap_original.png  - Original issue case")
println("  • visual_gap_multiple.png  - Multiple small gaps")
println("\nAll gap rectangles should be clearly visible.")
println("="^60 * "\n")
