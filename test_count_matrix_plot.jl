using EntroPlots
using Plots

println("=== Testing logoplot_with_rect_gaps with Count Matrices ===\n")

# Create count matrices (NOT normalized)
counts1 = [100 50 50 20;   # A
           0   50 50 10;   # C
           0   0  0  70;   # G
           0   0  0  0]    # T

counts2 = [0   50;
           100 50;
           0   0;
           0   0]

# Create reference sequences
# counts1 reference: "ACGG"
ref1 = BitMatrix([1 0 0 0;   # A at position 1
                  0 1 0 0;   # C at position 2
                  0 0 1 1;   # G at positions 3, 4
                  0 0 0 0])

# counts2 reference: "CA"
ref2 = BitMatrix([0 0;
                  1 0;
                  0 1;
                  0 0])

count_matrices = [counts1, counts2]
reference_pfms = [ref1, ref2]
starting_indices = [1, 20]
total_length = 30

println("Input count matrices:")
println("  Matrix 1: $(size(counts1, 2)) columns, starts at $(starting_indices[1])")
println("  Matrix 2: $(size(counts2, 2)) columns, starts at $(starting_indices[2])")

# Check how many fragments will be created
n_fragments = count_fragments(count_matrices, reference_pfms)
println("\nExpected fragments after filtering: $n_fragments")

# Detailed analysis
println("\nDetailed filtering analysis:")
for (i, (counts, ref, start)) in enumerate(zip(count_matrices, reference_pfms, starting_indices))
    println("  Matrix $i:")
    keep = filter_counts_by_reference(counts, ref)
    println("    Kept columns: $keep")
    for col_idx in 1:size(counts, 2)
        col = counts[:, col_idx]
        ref_col = ref[:, col_idx]
        d = EntroPlots.dot_product(col, ref_col)
        s = sum(col)
        status = abs(d - s) > 1e-9 ? "KEEP" : "REMOVE"
        global_pos = start + col_idx - 1
        println("      Col $col_idx (global pos $global_pos): dot=$d, sum=$s → $status")
    end
end

println("\n" * "="^60)
println("Creating plot with filter_by_reference=true...")
println("="^60)

try
    p = logoplot_with_rect_gaps(
        count_matrices, 
        starting_indices, 
        total_length;
        reference_pfms = reference_pfms,
        filter_by_reference = true
    )
    
    println("✓ Plot created successfully!")
    println("  Displaying plot...")
    display(p)
    
    # Save the plot
    savefig(p, "test_count_matrix_plot.png")
    println("  Saved to: test_count_matrix_plot.png")
    
catch e
    println("✗ Error creating plot:")
    println("  ", e)
    rethrow(e)
end

println("\n" * "="^60)
println("Creating plot WITHOUT filtering (filter_by_reference=false)...")
println("="^60)

try
    p2 = logoplot_with_rect_gaps(
        count_matrices, 
        starting_indices, 
        total_length;
        reference_pfms = reference_pfms,
        filter_by_reference = false
    )
    
    println("✓ Plot created successfully!")
    println("  Displaying plot...")
    display(p2)
    
    savefig(p2, "test_count_matrix_plot_nofilter.png")
    println("  Saved to: test_count_matrix_plot_nofilter.png")
    
catch e
    println("✗ Error creating plot:")
    println("  ", e)
    rethrow(e)
end

println("\n✓ All tests completed successfully!")
