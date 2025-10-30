# Activate the local package environment
using Pkg
Pkg.activate(".")  # Activates the EntroPlots project in current directory
Pkg.instantiate()  # Install dependencies if needed

using Revise 
using Plots
using EntroPlots

println("Testing LOCAL version of EntroPlots")
println("Package location: ", pathof(EntroPlots))
println()

# Create two PFMs of length 9 each
pfm1 = [0.25 0.3 0.2 0.1 0.4 0.5 0.3 0.2 0.1;
        0.25 0.2 0.3 0.4 0.2 0.1 0.2 0.3 0.4;
        0.25 0.3 0.2 0.3 0.2 0.2 0.3 0.2 0.3;
        0.25 0.2 0.3 0.2 0.2 0.2 0.2 0.3 0.2]

pfm2 = [0.25 0.3 0.2 0.1 0.4 0.5 0.3 0.2 0.1;
        0.25 0.2 0.3 0.4 0.2 0.1 0.2 0.3 0.4;
        0.25 0.3 0.2 0.3 0.2 0.2 0.3 0.2 0.3;
        0.25 0.2 0.3 0.2 0.2 0.2 0.2 0.3 0.2]

pfms = [pfm1, pfm2]

# PFM1: positions 39-47 (length 9)
# PFM2: positions 50-58 (length 9)
# Gap: positions 48-49 (2 positions) - should show strike-through
starting_indices = [39, 50]
total_len = 70

println("PFM1: starts at 39, length $(size(pfm1, 2)), ends at $(39 + size(pfm1, 2) - 1)")
println("PFM2: starts at 50, length $(size(pfm2, 2)), ends at $(50 + size(pfm2, 2) - 1)")
println("Gap should be at positions 48-49 (2 positions)")
println("Total length: $total_len")
println()

# Test the internal function to see what spacers are calculated
offsets_from_start, total_len_adjusted = 
    EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)

println("Offsets from start: $offsets_from_start")
println("Total length adjusted: $total_len_adjusted")
println()

# Plot with gaps
p = EntroPlots.logoplot_with_rect_gaps(
    pfms, starting_indices, total_len
)

display(p)

println("\nCheck the plot:")
println("1. Should see PFM1 from position 39-47")
println("2. Should see a strike-through/gap at positions 48-49")
println("3. Should see PFM2 from position 50-58")

# Additional test cases for different gap sizes
println("\n" * "="^60)
println("Testing different gap sizes:")
println("="^60)

# Test 1: Gap of 1 position
println("\nTest 1: Gap of 1 position")
pfms_test1 = [pfm1, pfm2]
starting_indices_test1 = [10, 20]  # Gap at position 19 (1 position)
total_len_test1 = 30
p1 = EntroPlots.logoplot_with_rect_gaps(pfms_test1, starting_indices_test1, total_len_test1)
savefig(p1, "test_gap_1pos.png")
println("Saved as test_gap_1pos.png - Gap should be visible at position 19")

# Test 2: Gap of 2 positions
println("\nTest 2: Gap of 2 positions")
pfms_test2 = [pfm1, pfm2]
starting_indices_test2 = [10, 21]  # Gap at positions 19-20 (2 positions)
total_len_test2 = 30
p2 = EntroPlots.logoplot_with_rect_gaps(pfms_test2, starting_indices_test2, total_len_test2)
savefig(p2, "test_gap_2pos.png")
println("Saved as test_gap_2pos.png - Gap should be visible at positions 19-20")

# Test 3: Gap of 3 positions
println("\nTest 3: Gap of 3 positions")
pfms_test3 = [pfm1, pfm2]
starting_indices_test3 = [10, 22]  # Gap at positions 19-21 (3 positions)
total_len_test3 = 31
p3 = EntroPlots.logoplot_with_rect_gaps(pfms_test3, starting_indices_test3, total_len_test3)
savefig(p3, "test_gap_3pos.png")
println("Saved as test_gap_3pos.png - Gap should be visible at positions 19-21")

# Test 4: No gap
println("\nTest 4: No gap (consecutive PFMs)")
pfms_test4 = [pfm1, pfm2]
starting_indices_test4 = [10, 19]  # No gap, consecutive
total_len_test4 = 27
p4 = EntroPlots.logoplot_with_rect_gaps(pfms_test4, starting_indices_test4, total_len_test4)
savefig(p4, "test_gap_0pos.png")
println("Saved as test_gap_0pos.png - No gap should appear")

println("\n" * "="^60)
println("All tests complete. Check the saved PNG files.")
println("="^60)
