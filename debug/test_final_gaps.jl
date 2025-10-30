using Pkg
Pkg.activate(".")

using EntroPlots
using Plots

println("\n" * "="^70)
println("FINAL COMPREHENSIVE GAP TEST")
println("="^70 * "\n")
println("Testing that gaps are:")
println("  ✓ Visible for all sizes (especially 1-3 nucleotides)")
println("  ✓ Not overlapping with adjacent logos")
println("  ✓ Properly scaled\n")

# Create test PFMs
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
pfm3 = create_test_pfm()

println("Test 1: Gap of 1 nucleotide (most challenging)")
println("-" * "="^69)
p1 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 11],
    20,
    uniform_color=false
)
savefig(p1, "final_test_gap_1nt.png")
println("✓ Saved: final_test_gap_1nt.png")
println("  Gap should be visible and NOT touching the right logo\n")

println("Test 2: Gap of 2 nucleotides")
println("-" * "="^69)
p2 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 12],
    21,
    uniform_color=false
)
savefig(p2, "final_test_gap_2nt.png")
println("✓ Saved: final_test_gap_2nt.png")
println("  Gap should be visible and NOT touching the right logo\n")

println("Test 3: Gap of 3 nucleotides")
println("-" * "="^69)
p3 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 13],
    22,
    uniform_color=false
)
savefig(p3, "final_test_gap_3nt.png")
println("✓ Saved: final_test_gap_3nt.png")
println("  Gap should be visible with slight clearance\n")

println("Test 4: Original problematic case (2nt gap with large offset)")
println("-" * "="^69)
p4 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [39, 50],
    60,
    uniform_color=false
)
savefig(p4, "final_test_original_case.png")
println("✓ Saved: final_test_original_case.png")
println("  Gap should be clearly visible\n")

println("Test 5: Multiple small gaps")
println("-" * "="^69)
p5 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2, pfm3], 
    [1, 11, 21],
    30,
    uniform_color=false
)
savefig(p5, "final_test_multiple_gaps.png")
println("✓ Saved: final_test_multiple_gaps.png")
println("  Both gaps should be visible without overlap\n")

println("Test 6: Larger gap for comparison")
println("-" * "="^69)
p6 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2], 
    [1, 20],
    29,
    uniform_color=false
)
savefig(p6, "final_test_large_gap.png")
println("✓ Saved: final_test_large_gap.png")
println("  Larger gap should be clearly visible with minimal trimming\n")

println("="^70)
println("ALL TESTS COMPLETE")
println("="^70)
println("\nGenerated files:")
println("  • final_test_gap_1nt.png        - 1 nucleotide gap (60% width)")
println("  • final_test_gap_2nt.png        - 2 nucleotide gap (60% width)")
println("  • final_test_gap_3nt.png        - 3 nucleotide gap (75% width)")
println("  • final_test_original_case.png  - Original issue (2nt gap)")
println("  • final_test_multiple_gaps.png  - Two 1nt gaps")
println("  • final_test_large_gap.png      - 10 nucleotide gap")
println("\nAll gaps should be:")
println("  ✓ Clearly visible")
println("  ✓ Not overlapping/touching adjacent logos")
println("  ✓ Appropriately sized\n")
println("="^70 * "\n")
