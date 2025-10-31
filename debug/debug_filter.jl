# Simple dot product implementation
dot_product(a, b) = sum(a .* b)

counts = [10 0 5 0; 0 10 5 0; 0 0 0 10; 0 0 0 0]
ref = BitMatrix([1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])

println("Counts matrix:")
display(counts)
println("\nReference matrix:")
display(ref)

println("\n\nColumn-by-column analysis:")
for col_idx in 1:size(counts, 2)
    col = counts[:, col_idx]
    ref_col = ref[:, col_idx]
    
    d = dot_product(col, ref_col)
    s = sum(col)
    
    println("\nColumn $col_idx:")
    println("  counts: $col")
    println("  ref:    $(Int.(ref_col))")
    println("  dot product: $d")
    println("  sum:         $s")
    println("  dot == sum?  $(d == s)")
    println("  → $(abs(d - s) > 1e-9 ? "KEEP" : "REMOVE")")
end
