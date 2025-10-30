# Demo Files

This directory contains demonstration scripts for EntroPlots.jl features.

## Available Demos

### demo_simple.jl
Minimal examples showing gap visualization for nucleotide sequences.

**Features demonstrated:**
- Basic gap plotting between sequence motifs
- Reference-based 2-color highlighting (blue for match, red for mismatch)
- Strike-through rectangles marking gaps

**Usage:**
```bash
julia --project=. demo_simple.jl
```

**Output:**
- `simple_gap_demo.png` - Two motifs with a 2-nucleotide gap
- `simple_gap_with_ref.png` - Same plot with reference coloring

---

### demo_protein_gaps.jl
Comprehensive examples for protein (amino acid) sequence logos with gaps.

**Features demonstrated:**
- 20 amino acid visualization
- Multiple protein domains with gaps
- Reference-based coloring for proteins
- Rotated x-axis labels
- Simulated kinase domain architecture

**Usage:**
```bash
julia --project=. demo_protein_gaps.jl
```

**Output:**
- `protein_gap_example1.png` - Two domains with 2-position gap
- `protein_gap_example2.png` - Three domains with multiple gaps
- `protein_gap_example3_with_ref.png` - Reference coloring
- `protein_gap_example4_kinase.png` - Kinase domain simulation
- `protein_gap_saved.png` - Using save function

---

## Gap Visualization Features

All demos showcase the improved gap visibility:

1. **Minimum Display Width**: Even 1-position gaps are clearly visible
2. **No Overlap**: Strike-through rectangles don't touch adjacent logos
3. **Adaptive Sizing**: Gap width scales appropriately with size
4. **Log2 Compression**: Large spacing compressed logarithmically while maintaining small gap visibility

## Quick Examples

### Nucleotide with Gap
```julia
using EntroPlots, Plots

pfm1 = rand(4, 9); pfm1 ./= sum(pfm1, dims=1)
pfm2 = rand(4, 9); pfm2 ./= sum(pfm2, dims=1)

p = logoplot_with_rect_gaps([pfm1, pfm2], [1, 12], 22)
savefig(p, "my_gap_plot.png")
```

### Protein with Gap
```julia
using EntroPlots, Plots

pfm1 = rand(20, 10); pfm1 ./= sum(pfm1, dims=1)
pfm2 = rand(20, 10); pfm2 ./= sum(pfm2, dims=1)

p = logoplot_with_rect_gaps([pfm1, pfm2], [1, 13], 25; protein=true)
savefig(p, "my_protein_gap.png")
```

### With Reference Coloring
```julia
using EntroPlots, Plots

pfm = rand(4, 9); pfm ./= sum(pfm, dims=1)
ref = falses(4, 9)
ref[1, 3] = true  # Mark A at position 3 as reference

p = logoplot_with_rect_gaps([pfm], [1], 9; reference_pfms=[ref])
savefig(p, "with_reference.png")
```

## Testing

Gap visualization features are tested in `test/test_gaps.jl`.

Run tests with:
```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## See Also

- Main README: `../README.md`
- Test suite: `../test/test_gaps.jl`
- Source code: `../src/old/plot_logo_w_arr_gaps.jl`
