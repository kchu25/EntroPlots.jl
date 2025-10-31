using EntroPlots

println("=== Count Matrix Filtering Example ===\n")

# Create count matrices (not normalized!)
counts1 = [100 0   50  20  10;    # A
           0   100 50  10  80;    # C
           0   0   0   70  10;    # G
           0   0   0   0   0]     # T

counts2 = [0   50  100;
           100 50  0;
           0   0   0;
           0   0   0]

# Create reference sequences (one-hot encoded)
# For counts1: reference is "ACGGG"
ref1 = BitMatrix([1 0 0 0 0;    # A at position 1
                  0 1 0 0 0;    # C at position 2
                  0 0 0 1 1;    # G at positions 4, 5
                  0 0 1 0 0])   # T at position 3

# For counts2: reference is "CAA"  
ref2 = BitMatrix([0 0 1;
                  1 0 0;
                  0 1 0;
                  0 0 0])

count_matrices = [counts1, counts2]
reference_pfms = [ref1, ref2]
starting_indices = [1, 20]

println("Original data:")
println("  Matrix 1: $(size(counts1, 2)) columns, starts at position $(starting_indices[1])")
println("  Matrix 2: $(size(counts2, 2)) columns, starts at position $(starting_indices[2])")

# Test: Count fragments before filtering
n_fragments = count_fragments(count_matrices, reference_pfms)
println("\nNumber of fragments after filtering: $n_fragments")

# Show which columns are kept
println("\nDetailed filtering:")
for (i, (counts, ref)) in enumerate(zip(count_matrices, reference_pfms))
    keep = filter_counts_by_reference(counts, ref)
    println("  Matrix $i: keeping columns $keep")
    
    for col_idx in 1:size(counts, 2)
        col = counts[:, col_idx]
        ref_col = ref[:, col_idx]
        d = EntroPlots.dot_product(col, ref_col)
        s = sum(col)
        status = abs(d - s) > 1e-9 ? "KEEP" : "REMOVE"
        println("    Col $col_idx: dot=$d, sum=$s → $status")
    end
end

# Apply the filter
filtered_counts, filtered_starts, filtered_refs = apply_count_filter(
    count_matrices, starting_indices, reference_pfms
)

println("\nAfter filtering:")
println("  Number of fragments: $(length(filtered_counts))")
for (i, (counts, start)) in enumerate(zip(filtered_counts, filtered_starts))
    println("  Fragment $i: $(size(counts, 2)) columns, starts at position $start")
end

# Now normalize to PFMs and plot
println("\nNormalizing to PFMs for plotting...")
filtered_pfms = [counts ./ sum(counts, dims=1) for counts in filtered_counts]

# Verify normalization
for (i, pfm) in enumerate(filtered_pfms)
    @assert all(sum(pfm, dims=1) .≈ 1.0) "PFM $i is not properly normalized"
end

# Calculate total length
total_len = maximum(filtered_starts .+ size.(filtered_pfms, 2))

println("\nReady to plot:")
println("  Total length: $total_len")
println("  Number of PFM fragments: $(length(filtered_pfms))")
println("  Starting positions: $filtered_starts")

# Uncomment to plot:
# p = logoplot_with_rect_gaps(
#     filtered_pfms, 
#     filtered_starts, 
#     total_len;
#     reference_pfms = filtered_refs
# )
# display(p)

println("\n✓ Example complete!")
