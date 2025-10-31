using EntroPlots

println("=== Complex Fragment Counting Examples ===\n")

# Helper function to visualize filtering
function show_filtering(name, counts, ref, expected_fragments)
    println("$name")
    println("="^60)
    
    keep = filter_counts_by_reference(counts, ref)
    fragments = isempty(keep) ? [] : EntroPlots.group_to_ranges(keep)
    n_fragments = length(fragments)
    
    println("Columns: $(size(counts, 2))")
    println("Filtering result:")
    for col_idx in 1:size(counts, 2)
        col = counts[:, col_idx]
        ref_col = ref[:, col_idx]
        d = EntroPlots.dot_product(col, ref_col)
        s = sum(col)
        status = abs(d - s) > 1e-9 ? "KEEP" : "REMOVE"
        marker = col_idx in keep ? "✓" : "✗"
        println("  [$marker] Col $col_idx: dot=$d, sum=$s → $status")
    end
    
    println("Kept columns: $keep")
    println("Fragments: $fragments")
    println("Fragment count: $n_fragments (expected: $expected_fragments)")
    
    if n_fragments == expected_fragments
        println("✓ PASS\n")
    else
        println("✗ FAIL - Expected $expected_fragments but got $n_fragments\n")
    end
    
    return n_fragments == expected_fragments
end

all_passed = true

# Example 1: One matrix → Two fragments
println("\n### Example 1: One Matrix → Two Fragments ###\n")
# Pattern: KEEP, REMOVE, REMOVE, KEEP, KEEP, REMOVE, KEEP
# Should create 3 fragments: [1], [4,5], [7]
counts1 = [5 10 0  5 5 0  5;   # A
           5 0  10 5 5 10 5;   # C
           0 0  0  0 0 0  0;   # G
           0 0  0  0 0 0  0]   # T

ref1 = BitMatrix([0 1 0 0 0 0 0;   # Reference: C at 2, C at 3, C at 6
                  0 0 1 0 0 1 0;
                  1 0 0 1 1 0 1;
                  0 0 0 0 0 0 0])

all_passed &= show_filtering("Matrix 1 (Should split into 3 fragments)", 
                             counts1, ref1, 3)


# Example 2: One matrix → Two separate fragments
println("\n### Example 2: One Matrix → Two Fragments (Gap in middle) ###\n")
# Pattern: KEEP, KEEP, REMOVE, REMOVE, KEEP, KEEP
# Should create 2 fragments: [1,2], [5,6]
counts2 = [5 5 10 0  5 5;   # A
           5 5 0  10 5 5;   # C
           0 0 0  0  0 0;   # G
           0 0 0  0  0 0]   # T

ref2 = BitMatrix([0 0 1 0 0 0;
                  0 0 0 1 0 0;
                  1 1 0 0 1 1;
                  0 0 0 0 0 0])

all_passed &= show_filtering("Matrix 2 (Two fragments with gap)", 
                             counts2, ref2, 2)


# Example 3: Two matrices → Total of 4 fragments
println("\n### Example 3: Two Matrices → Total of 4 Fragments ###\n")

# First matrix: creates 2 fragments
counts3a = [10 5 5 0  0  5 5;   # A
            0  5 5 10 0  5 5;   # C
            0  0 0 0  10 0 0;   # G
            0  0 0 0  0  0 0]   # T

ref3a = BitMatrix([1 0 0 0 0 0 0;   # A at 1, C at 4, G at 5
                   0 0 0 1 0 0 0;
                   0 1 1 0 1 1 1;
                   0 0 0 0 0 0 0])

# Pattern for 3a: REMOVE, KEEP, KEEP, REMOVE, REMOVE, KEEP, KEEP
# Fragments: [2,3], [6,7]

all_passed &= show_filtering("Matrix 3a (First of two matrices)", 
                             counts3a, ref3a, 2)

# Second matrix: creates 2 fragments  
counts3b = [5 5 10 5 5 0  0  10;   # A
            5 5 0  5 5 10 0  0;    # C
            0 0 0  0 0 0  10 0;    # G
            0 0 0  0 0 0  0  0]    # T

ref3b = BitMatrix([0 0 1 0 0 0 0 1;   # A at 3, A at 8, C at 6, G at 7
                   0 0 0 0 0 1 0 0;
                   1 1 0 1 1 0 1 0;
                   0 0 0 0 0 0 0 0])

# Pattern for 3b: KEEP, KEEP, REMOVE, KEEP, KEEP, REMOVE, REMOVE, REMOVE
# Fragments: [1,2], [4,5]

all_passed &= show_filtering("Matrix 3b (Second of two matrices)", 
                             counts3b, ref3b, 2)

println("\n### Combined Test for Example 3 ###")
total_frags_3 = count_fragments([counts3a, counts3b], [ref3a, ref3b])
println("Total fragments from both matrices: $total_frags_3 (expected: 4)")
if total_frags_3 == 4
    println("✓ PASS\n")
    all_passed &= true
else
    println("✗ FAIL\n")
    all_passed = false
end


# Example 4: Three matrices → Total of 5 fragments
println("\n### Example 4: Three Matrices → Total of 5 Fragments ###\n")

# Matrix 4a: 1 fragment
counts4a = [5 5 5;
            5 5 5;
            0 0 0;
            0 0 0]

ref4a = BitMatrix([0 0 0;
                   0 0 0;
                   1 1 1;
                   0 0 0])

all_passed &= show_filtering("Matrix 4a (All kept - 1 fragment)", 
                             counts4a, ref4a, 1)

# Matrix 4b: 2 fragments
counts4b = [5 10 10 5;
            5 0  0  5;
            0 0  0  0;
            0 0  0  0]

ref4b = BitMatrix([0 1 1 0;
                   1 0 0 1;
                   0 0 0 0;
                   0 0 0 0])

# Pattern: KEEP, REMOVE, REMOVE, KEEP
# Fragments: [1], [4]

all_passed &= show_filtering("Matrix 4b (2 separate fragments)", 
                             counts4b, ref4b, 2)

# Matrix 4c: 2 fragments
counts4c = [5 5 0  0  5 5 0;
            5 5 10 0  5 5 10;
            0 0 0  10 0 0 0;
            0 0 0  0  0 0 0]

ref4c = BitMatrix([0 0 0 0 0 0 0;
                   0 0 1 0 0 0 1;
                   1 1 0 1 1 1 0;
                   0 0 0 0 0 0 0])

# Pattern: KEEP, KEEP, REMOVE, REMOVE, KEEP, KEEP, REMOVE
# Fragments: [1,2], [5,6]

all_passed &= show_filtering("Matrix 4c (2 fragments)", 
                             counts4c, ref4c, 2)

println("\n### Combined Test for Example 4 ###")
total_frags_4 = count_fragments([counts4a, counts4b, counts4c], 
                                [ref4a, ref4b, ref4c])
println("Total fragments from three matrices: $total_frags_4 (expected: 5)")
if total_frags_4 == 5
    println("✓ PASS\n")
    all_passed &= true
else
    println("✗ FAIL\n")
    all_passed = false
end


# Example 5: Edge case - alternating pattern
println("\n### Example 5: Alternating KEEP/REMOVE Pattern ###\n")
counts5 = [5 10 5 10 5 10 5 10;
           5 0  5 0  5 0  5 0;
           0 0  0 0  0 0  0 0;
           0 0  0 0  0 0  0 0]

ref5 = BitMatrix([0 1 0 1 0 1 0 1;
                  1 0 1 0 1 0 1 0;
                  0 0 0 0 0 0 0 0;
                  0 0 0 0 0 0 0 0])

# Pattern: KEEP, REMOVE, KEEP, REMOVE, KEEP, REMOVE, KEEP, REMOVE
# Should create 4 fragments: [1], [3], [5], [7]

all_passed &= show_filtering("Matrix 5 (Alternating pattern - 4 fragments)", 
                             counts5, ref5, 4)


# Example 6: All columns match reference (0 fragments)
println("\n### Example 6: Perfect Match - No Fragments ###\n")
counts6 = [10 0  0  0;
           0  10 0  0;
           0  0  10 0;
           0  0  0  10]

ref6 = BitMatrix([1 0 0 0;
                  0 1 0 0;
                  0 0 1 0;
                  0 0 0 1])

all_passed &= show_filtering("Matrix 6 (Perfect match - 0 fragments)", 
                             counts6, ref6, 0)


# Final summary
println("\n" * "="^60)
if all_passed
    println("✓✓✓ ALL TESTS PASSED ✓✓✓")
else
    println("✗✗✗ SOME TESTS FAILED ✗✗✗")
end
println("="^60)
