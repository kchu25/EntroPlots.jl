# Demo: Protein Sequence Logos with Gaps
# This demonstrates amino acid sequence visualization with strike-through gaps

using Pkg
Pkg.activate(".")

using EntroPlots
using Plots

println("\n" * "="^70)
println("PROTEIN SEQUENCE LOGO WITH GAPS - DEMO")
println("="^70 * "\n")

# Helper function to create a protein PFM (20 amino acids)
# Returns a 20×n matrix representing amino acid frequencies
function create_protein_pfm(length::Int; conserved_positions=[], background=0.05)
    """
    Create a protein position frequency matrix
    20 rows (amino acids): A,C,D,E,F,G,H,I,K,L,M,N,P,Q,R,S,T,V,W,Y
    length columns (positions)
    """
    pfm = fill(background, 20, length)
    
    # Add some conserved positions for visual interest
    for (pos, aa_idx) in conserved_positions
        pfm[:, pos] .= background / 5
        pfm[aa_idx, pos] = 0.7  # Make this amino acid dominant
        pfm[:, pos] ./= sum(pfm[:, pos])  # Normalize
    end
    
    # Normalize remaining positions
    for i in 1:length
        if !any(p -> p[1] == i, conserved_positions)
            pfm[:, i] ./= sum(pfm[:, i])
        end
    end
    
    return pfm
end

println("Creating example protein PFMs...")
println("20 amino acids: A,C,D,E,F,G,H,I,K,L,M,N,P,Q,R,S,T,V,W,Y")
println()

# Example 1: Two protein motifs with a small gap (2 amino acids)
println("Example 1: Two protein domains with a 2-position gap")
println("-" * "="^69)

# Create two protein motifs (domains) with some conserved positions
pfm1_protein = create_protein_pfm(10, conserved_positions=[
    (2, 15),   # Position 2: R (Arginine) - index 15
    (5, 7),    # Position 5: H (Histidine) - index 7
    (8, 11),   # Position 8: M (Methionine) - index 11
])

pfm2_protein = create_protein_pfm(10, conserved_positions=[
    (3, 1),    # Position 3: A (Alanine) - index 1
    (6, 10),   # Position 6: L (Leucine) - index 10
    (9, 19),   # Position 9: W (Tryptophan) - index 19
])

# Domain 1: positions 50-59
# Gap: positions 60-61 (2 amino acids)
# Domain 2: positions 62-71
starting_indices_ex1 = [50, 62]
total_length_ex1 = 80

p1 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1_protein, pfm2_protein],
    starting_indices_ex1,
    total_length_ex1;
    protein = true,
    uniform_color = false,
    xrotation = 0
)

savefig(p1, "protein_gap_example1.png")
println("✓ Saved: protein_gap_example1.png")
println("  - Domain 1: positions 50-59")
println("  - Gap (strike-through): positions 60-61")
println("  - Domain 2: positions 62-71")
println()

# Example 2: Three protein domains with small gaps
println("Example 2: Three protein domains with 1 and 2 position gaps")
println("-" * "="^69)

pfm3_protein = create_protein_pfm(8, conserved_positions=[
    (2, 4),    # Position 2: E (Glutamate) - index 4
    (5, 16),   # Position 5: S (Serine) - index 16
])

# Domain 1: positions 10-19
# Gap: position 20 (1 amino acid)
# Domain 2: positions 21-30
# Gap: positions 31-32 (2 amino acids)
# Domain 3: positions 33-40
starting_indices_ex2 = [10, 21, 33]
total_length_ex2 = 45

p2 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1_protein, pfm2_protein, pfm3_protein],
    starting_indices_ex2,
    total_length_ex2;
    protein = true,
    uniform_color = false,
    xrotation = 45  # Rotate labels for better readability
)

savefig(p2, "protein_gap_example2.png")
println("✓ Saved: protein_gap_example2.png")
println("  - Domain 1: positions 10-19")
println("  - Gap 1 (strike-through): position 20")
println("  - Domain 2: positions 21-30")
println("  - Gap 2 (strike-through): positions 31-32")
println("  - Domain 3: positions 33-40")
println()

# Example 3: Protein motifs with reference-based coloring
println("Example 3: Protein domains with reference sequence coloring")
println("-" * "="^69)

# Create reference PFMs (BitMatrix: true = conserved position)
ref1 = falses(20, 10)
ref1[15, 2] = true  # R at position 2
ref1[7, 5] = true   # H at position 5
ref1[11, 8] = true  # M at position 8

ref2 = falses(20, 10)
ref2[1, 3] = true   # A at position 3
ref2[10, 6] = true  # L at position 6
ref2[19, 9] = true  # W at position 9

p3 = EntroPlots.logoplot_with_rect_gaps(
    [pfm1_protein, pfm2_protein],
    [100, 115],  # Gap of 5 positions (110-114)
    125;
    protein = true,
    uniform_color = false,
    reference_pfms = [ref1, ref2],
    xrotation = 0
)

savefig(p3, "protein_gap_example3_with_ref.png")
println("✓ Saved: protein_gap_example3_with_ref.png")
println("  - Domain 1: positions 100-109")
println("  - Gap (strike-through): positions 110-114")
println("  - Domain 2: positions 115-124")
println("  - Blue letters: match reference sequence")
println("  - Red letters: differ from reference sequence")
println()

# Example 4: Realistic protein sequence (simulating kinase domains)
println("Example 4: Simulated protein kinase domains")
println("-" * "="^69)

# Kinase ATP-binding domain (simplified)
kinase_atp = create_protein_pfm(12, conserved_positions=[
    (3, 6),    # G (Glycine) - common in kinases
    (5, 9),    # K (Lysine) - catalytic lysine
    (8, 4),    # E (Glutamate)
])

# Kinase activation loop (simplified)
kinase_activation = create_protein_pfm(15, conserved_positions=[
    (4, 3),    # D (Aspartate) - DFG motif
    (5, 5),    # F (Phenylalanine) - DFG motif
    (6, 6),    # G (Glycine) - DFG motif
    (10, 17),  # T (Threonine) - phosphorylation site
])

p4 = EntroPlots.logoplot_with_rect_gaps(
    [kinase_atp, kinase_activation],
    [200, 220],  # Gap of 8 positions (212-219)
    240;
    protein = true,
    uniform_color = false,
    xrotation = 45,
    height_top = 2.5
)

savefig(p4, "protein_gap_example4_kinase.png")
println("✓ Saved: protein_gap_example4_kinase.png")
println("  - ATP-binding domain: positions 200-211")
println("  - Linker region (gap): positions 212-219")
println("  - Activation loop: positions 220-234")
println()

# Example 5: Export function demonstration
println("Example 5: Using save_logo_with_rect_gaps() function")
println("-" * "="^69)

EntroPlots.save_logo_with_rect_gaps(
    [pfm1_protein, pfm2_protein],
    [1, 13],  # Gap of 2 positions
    25,
    "protein_gap_saved.png";
    protein = true,
    uniform_color = false,
    dpi = 100,
    xrotation = 0
)

println("✓ Saved: protein_gap_saved.png (using save function)")
println()

println("="^70)
println("DEMO COMPLETE")
println("="^70)
println("\nGenerated PNG files:")
println("  1. protein_gap_example1.png - Two domains, 2-position gap")
println("  2. protein_gap_example2.png - Three domains, multiple gaps")
println("  3. protein_gap_example3_with_ref.png - Reference coloring")
println("  4. protein_gap_example4_kinase.png - Kinase domain simulation")
println("  5. protein_gap_saved.png - Using save function")
println("\nAll gaps are visible as strike-through rectangles!")
println("Amino acids are colored and sized by frequency.")
println("="^70 * "\n")
