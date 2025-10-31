using EntroPlots

println("=== Complete Workflow: Count Filtering → Plotting ===\n")

# Example: Two count matrices that will split into multiple fragments

# Matrix 1: Will split into 2 fragments
println("Creating Matrix 1...")
counts1 = [100 50 50 0   0   50 50 100;   # A
           0   50 50 100 0   50 50 0;     # C  
           0   0  0  0   100 0  0  0;     # G
           0   0  0  0   0   0  0  0]     # T

# Reference: "ACCCGCCA"
ref1 = BitMatrix([1 0 0 0 0 0 0 1;   # A at positions 1, 8
                  0 1 1 1 0 1 1 0;   # C at positions 2, 3, 4, 6, 7
                  0 0 0 0 1 0 0 0;   # G at position 5
                  0 0 0 0 0 0 0 0])

println("Matrix 1: $(size(counts1, 2)) columns")
keep1 = filter_counts_by_reference(counts1, ref1)
println("  Kept columns: $keep1")
frags1 = EntroPlots.group_to_ranges(keep1)
println("  Fragments: $frags1")
println("  Number of fragments: $(length(frags1))")

# Matrix 2: Will split into 3 fragments  
println("\nCreating Matrix 2...")
counts2 = [50 50 0   0   50 100 50 50 0   0;    # A
           50 50 100 0   50 0   50 50 100 0;    # C
           0  0  0   100 0  0   0  0  0   100;  # G
           0  0  0   0   0  0   0  0  0   0]    # T

# Reference: "AACGACAACG"
ref2 = BitMatrix([1 1 0 0 1 1 1 1 0 0;   # A at positions 1,2,5,6,7,8
                  0 0 1 0 0 0 0 0 1 0;   # C at positions 3,9
                  0 0 0 1 0 0 0 0 0 1;   # G at positions 4,10
                  0 0 0 0 0 0 0 0 0 0])

println("Matrix 2: $(size(counts2, 2)) columns")
keep2 = filter_counts_by_reference(counts2, ref2)
println("  Kept columns: $keep2")
frags2 = EntroPlots.group_to_ranges(keep2)
println("  Fragments: $frags2")
println("  Number of fragments: $(length(frags2))")

# Combined test
println("\n" * "="^60)
println("COMBINED TEST:")
println("="^60)

count_matrices = [counts1, counts2]
reference_pfms = [ref1, ref2]
starting_indices = [1, 50]

total_fragments = count_fragments(count_matrices, reference_pfms)
println("Total fragments across both matrices: $total_fragments")
println("Expected: $(length(frags1) + length(frags2))")

# Apply the filter
println("\nApplying filter...")
filtered_counts, filtered_starts, filtered_refs = apply_count_filter(
    count_matrices, starting_indices, reference_pfms
)

println("\nResults after filtering:")
println("  Number of fragment groups: $(length(filtered_counts))")
for (i, (counts, start, ref)) in enumerate(zip(filtered_counts, filtered_starts, filtered_refs))
    println("  Fragment $i:")
    println("    - Size: $(size(counts, 2)) columns")
    println("    - Starting position: $start")
    println("    - Counts sum per column: $(sum(counts, dims=1))")
end

# Normalize to PFMs
println("\nNormalizing to PFMs...")
filtered_pfms = [counts ./ sum(counts, dims=1) for counts in filtered_counts]

# Verify normalization
println("Verifying PFM normalization...")
for (i, pfm) in enumerate(filtered_pfms)
    col_sums = sum(pfm, dims=1)
    all_normalized = all(col_sums .≈ 1.0)
    status = all_normalized ? "✓" : "✗"
    println("  Fragment $i: $status (column sums: $(round.(col_sums, digits=3)))")
end

# Calculate total length needed for plotting
total_len = maximum(filtered_starts .+ size.(filtered_pfms, 2) .- 1)
println("\nPlotting parameters:")
println("  Total length needed: $total_len")
println("  Number of PFM fragments: $(length(filtered_pfms))")
println("  Starting positions: $filtered_starts")
println("  PFM sizes: $(size.(filtered_pfms, 2))")

# Show detailed column breakdown
println("\n" * "="^60)
println("DETAILED BREAKDOWN:")
println("="^60)

for (mat_idx, (counts, ref, start)) in enumerate(zip(count_matrices, reference_pfms, starting_indices))
    println("\nOriginal Matrix $mat_idx (starts at position $start):")
    for col_idx in 1:size(counts, 2)
        col = counts[:, col_idx]
        ref_col = ref[:, col_idx]
        d = EntroPlots.dot_product(col, ref_col)
        s = sum(col)
        status = abs(d - s) > 1e-9 ? "KEEP" : "REMOVE"
        global_pos = start + col_idx - 1
        
        # Show which nucleotide has counts
        nucleotides = ['A', 'C', 'G', 'T']
        col_str = join(["$nuc:$(col[i])" for (i,nuc) in enumerate(nucleotides)], ", ")
        ref_nuc = nucleotides[findfirst(ref_col .== 1)]
        
        marker = status == "KEEP" ? "✓" : "✗"
        println("  [$marker] Global pos $global_pos (col $col_idx): [$col_str] | Ref: $ref_nuc | $status")
    end
end

println("\n" * "="^60)
println("READY TO PLOT!")
println("="^60)
println("\nUse the following code to plot:")
println("""
p = logoplot_with_rect_gaps(
    filtered_pfms, 
    filtered_starts, 
    total_len;
    reference_pfms = filtered_refs
)
display(p)
""")

println("\n✓ Complete workflow executed successfully!")
