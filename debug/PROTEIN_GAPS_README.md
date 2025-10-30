# Protein Sequence Logos with Gaps

This directory contains examples of protein (amino acid) sequence logos with visible gap indicators.

## Features

- **20 Amino Acids**: Full support for all standard amino acids (A,C,D,E,F,G,H,I,K,L,M,N,P,Q,R,S,T,V,W,Y)
- **Gap Visualization**: Strike-through rectangles clearly mark gaps between protein domains
- **Reference Coloring**: Optional 2-color scheme (blue for matching, red for non-matching)
- **Domain Separation**: Perfect for visualizing multi-domain proteins or alignment gaps

## Quick Start

```julia
using EntroPlots

# Create protein PFMs (20 rows × N columns)
pfm1 = create_your_protein_pfm(10)  # 20×10 matrix
pfm2 = create_your_protein_pfm(10)  # 20×10 matrix

# Plot with gap
p = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [1, 13],      # Domain 1 at pos 1-10, Domain 2 at 13-22, gap at 11-12
    25;           # Total sequence length
    protein = true,
    uniform_color = false
)

# Save
using Plots
savefig(p, "my_protein_logo.png")
```

## Examples Generated

Run `julia --project=. demo_protein_gaps.jl` to generate:

### 1. protein_gap_example1.png
**Two protein domains with a 2-position gap**
- Domain 1: positions 50-59 (10 amino acids)
- Gap: positions 60-61 (strike-through)
- Domain 2: positions 62-71 (10 amino acids)

### 2. protein_gap_example2.png
**Three protein domains with multiple gaps**
- Domain 1: positions 10-19
- Gap 1: position 20 (1 amino acid)
- Domain 2: positions 21-30
- Gap 2: positions 31-32 (2 amino acids)
- Domain 3: positions 33-40
- Demonstrates: Rotated x-axis labels (45°)

### 3. protein_gap_example3_with_ref.png
**Protein domains with reference sequence coloring**
- Uses reference PFMs to highlight conserved vs. variable positions
- Blue amino acids: match reference sequence
- Red amino acids: differ from reference
- Gap: positions 110-114

### 4. protein_gap_example4_kinase.png
**Simulated protein kinase domains**
- ATP-binding domain: positions 200-211
- Linker region (gap): positions 212-219
- Activation loop: positions 220-234
- Demonstrates realistic protein domain architecture

### 5. protein_gap_saved.png
**Using the save function**
- Demonstrates `save_logo_with_rect_gaps()` convenience function
- Simple 2-domain example with clean gap

## Parameters

### logoplot_with_rect_gaps()

```julia
logoplot_with_rect_gaps(
    pfms,                    # Vector of PFMs (each 20×n for proteins)
    starting_indices,        # Starting position of each domain
    total_length;            # Total sequence length
    protein = true,          # Enable protein mode (20 amino acids)
    uniform_color = false,   # Use varied colors for amino acids
    xrotation = 0,          # Rotate x-axis labels (0, 45, 90)
    reference_pfms = nothing,# Optional reference for 2-color mode
    dpi = 65,               # Resolution
    height_top = 2.0        # Maximum height
)
```

### Key Parameters for Proteins

- **protein = true**: Must be set for amino acid sequences (20 rows)
- **uniform_color = false**: Recommended for proteins to distinguish amino acids
- **xrotation = 45**: Useful when many positions (prevents label overlap)
- **reference_pfms**: Vector{BitMatrix} for 2-color highlighting

## Creating Protein PFMs

A protein PFM is a 20×N matrix where:
- 20 rows represent amino acids: A,C,D,E,F,G,H,I,K,L,M,N,P,Q,R,S,T,V,W,Y
- N columns represent sequence positions
- Each column sums to 1.0 (probability distribution)

```julia
# Example: Create a 20×10 protein PFM
pfm = rand(20, 10)
pfm ./= sum(pfm, dims=1)  # Normalize each column

# Make a conserved position (e.g., Lysine at position 5)
pfm[:, 5] .= 0.01
pfm[9, 5] = 0.8  # Lysine (K) is 9th amino acid
pfm[:, 5] ./= sum(pfm[:, 5])
```

## Reference-Based Coloring

```julia
# Create reference matrix (20×N BitMatrix)
ref = falses(20, 10)
ref[9, 5] = true   # Mark Lysine at position 5 as reference
ref[15, 8] = true  # Mark Arginine at position 8 as reference

# Use in plot
p = logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [1, 15],
    25;
    protein = true,
    reference_pfms = [ref1, ref2]  # One reference per PFM
)
```

- Blue (Egyptian Blue #1434A4): Amino acid matches reference
- Dark Red: Amino acid differs from reference

## Gap Visibility

All gaps are automatically visible thanks to three fixes:

1. **Minimum display width**: Even 1-position gaps get width of 2 units
2. **Full rectangle scaling**: Gaps use their full allocated width
3. **Adaptive trimming**: Smaller gaps trimmed more aggressively (60-75%) to prevent overlap

Small gaps (1-3 amino acids) are clearly visible with proper spacing.

## Use Cases

- **Multi-domain proteins**: Visualize conserved domains with linker regions
- **Protein alignments**: Show insertion/deletion regions
- **Motif analysis**: Display catalytic sites separated by variable regions
- **Kinase domains**: ATP-binding, linker, and activation segments
- **Antibody sequences**: CDR regions with framework gaps
- **Transmembrane proteins**: Show membrane-spanning and loop regions

## Tips

1. **Label rotation**: Use `xrotation = 45` for sequences > 30 positions
2. **Height adjustment**: Increase `height_top = 3.0` for very conserved positions
3. **Color schemes**: Set `uniform_color = false` for maximum amino acid distinction
4. **DPI settings**: Use `dpi = 100` or higher for publication-quality figures

## Troubleshooting

**Problem**: Amino acids not displaying
- **Solution**: Ensure `protein = true` is set

**Problem**: Gaps not visible
- **Solution**: This is now fixed! All gaps ≥ 1 position are visible

**Problem**: Labels overlapping
- **Solution**: Use `xrotation = 45` or `xrotation = 90`

**Problem**: Reference colors not showing
- **Solution**: Ensure `reference_pfms` is a Vector{BitMatrix} with same dimensions as PFMs

## Citation

If you use EntroPlots for protein visualization in your research, please cite appropriately.

## See Also

- `demo_protein_gaps.jl` - Full demo script
- `test_gap_visibility.jl` - Gap rendering tests
- `GAP_FIX_SUMMARY.md` - Technical details on gap visibility fixes
