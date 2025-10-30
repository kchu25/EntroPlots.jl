# EntroPlots: Sequence Logo with Gaps - Quick Start

## Minimal Example

See `demo_simple.jl` for a concise example:

```julia
using Pkg; Pkg.activate(".")
using EntroPlots, Plots

# Create nucleotide PFMs (4×9: A,C,G,T × 9 positions)
pfm1 = [0.7 0.1 0.1 0.1 0.6 0.2 0.1 0.1 0.5;
        0.1 0.7 0.1 0.6 0.1 0.1 0.7 0.1 0.2;
        0.1 0.1 0.7 0.1 0.2 0.6 0.1 0.7 0.2;
        0.1 0.1 0.1 0.2 0.1 0.1 0.1 0.1 0.1]

pfm2 = # ... similar 4×9 matrix

# Reference sequence (BitMatrix: true = expected base)
ref1 = BitMatrix([1 0 0 0 1 0 0 0 1;  # A at positions 1,5,9
                  0 1 0 1 0 0 1 0 0;  # C at positions 2,4,7
                  0 0 1 0 0 1 0 1 0;  # G at positions 3,6,8
                  0 0 0 0 0 0 0 0 0]) # T (none)

# Plot with gaps and reference coloring
p = EntroPlots.logoplot_with_rect_gaps(
    [pfm1, pfm2],
    [10, 21],              # Start positions: motif1@10, motif2@21
    30;                    # Total length
    reference_pfms = [ref1, ref2],  # Optional: Blue=match, Red=mismatch
    xrotation = 45         # Rotate x-labels
)

savefig(p, "output.png")
```

## Features

✓ **Visible gaps**: Small gaps (1-3 positions) shown as strike-through rectangles  
✓ **Reference coloring**: Egyptian Blue (#1434A4) = match, Dark Red = mismatch  
✓ **Nucleotides & Proteins**: Works for DNA/RNA (4 bases) and proteins (20 amino acids)  
✓ **No overlap**: Gaps trimmed to not touch adjacent letters

## Protein Example

```julia
# Protein PFMs: 20×n matrix (20 amino acids)
p = EntroPlots.logoplot_with_rect_gaps(
    [pfm1_protein, pfm2_protein],
    [50, 62],
    80;
    protein = true,        # Enable protein mode
    uniform_color = false
)
```

See `demo_protein_gaps.jl` for complete protein examples.

## All Fixes Applied

1. **Gap visibility**: Minimum display width of 2 units for any gap > 0
2. **Rectangle scaling**: Full width (`num_bt`) instead of reduced (`num_bt-1`)
3. **Overlap prevention**: Aggressive trimming on right side (60-90% depending on gap size)

See `GAP_FIX_SUMMARY.md` for technical details.
