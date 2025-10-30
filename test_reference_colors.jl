# Activate the local package environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Revise 
using Plots
using EntroPlots

println("Testing LOCAL version of EntroPlots")
println("Package location: ", pathof(EntroPlots))
println()

# Create simple PFMs for testing
pfms = [
    [0.1 0.2 0.3 0.4 0.5 0.6;
     0.3 0.2 0.1 0.2 0.1 0.1;
     0.3 0.3 0.3 0.3 0.3 0.2;
     0.3 0.3 0.3 0.1 0.1 0.1],
    [0.1 0.2 0.3 0.4 0.5 0.6;
     0.3 0.2 0.1 0.2 0.1 0.1;
     0.3 0.3 0.3 0.3 0.3 0.2;
     0.3 0.3 0.3 0.1 0.1 0.1],
]

starting_indices = [28, 66]
total_len = 100

# Create reference matrices
ref_pfm1 = BitMatrix(zeros(4, 6))
ref_pfm1[1,1] = 1  # A at position 1
ref_pfm1[2,2] = 1  # C at position 2  
ref_pfm1[3,3] = 1  # G at position 3
ref_pfm1[4,4] = 1  # T at position 4
ref_pfm1[1,5] = 1  # A at position 5
ref_pfm1[3,6] = 1  # G at position 6

ref_pfm2 = BitMatrix(zeros(4, 6))
ref_pfm2[2,1] = 1  # C at position 1
ref_pfm2[3,2] = 1  # G at position 2
ref_pfm2[4,3] = 1  # T at position 3
ref_pfm2[1,4] = 1  # A at position 4
ref_pfm2[2,5] = 1  # C at position 5
ref_pfm2[3,6] = 1  # G at position 6

reference_pfms = [ref_pfm1, ref_pfm2]

println("Testing reference-based coloring:")
println("Letters matching reference should be BLUE")
println("Letters NOT matching reference should be DARKRED")
println()

# Test with reference
p = logoplot_with_rect_gaps(pfms, starting_indices, total_len; 
    reference_pfms=reference_pfms
)

display(p)

println("\nPlot generated. Check that:")
println("1. Letters at positions matching the reference matrix are BLUE")
println("2. Letters at positions NOT matching the reference matrix are DARKRED")
