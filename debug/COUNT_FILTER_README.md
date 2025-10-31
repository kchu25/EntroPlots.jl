# Count Matrix Filtering for LogoPlots

## Overview

This implementation provides a clean, concise solution for filtering count matrices based on reference sequences before plotting. Instead of plotting all positions, only columns that deviate from the reference are kept.

## Core Concept

**Filtering Rule**: For each column vector `col` and reference one-hot vector `ref`:
- If `dot(col, ref) == sum(col)`, the column perfectly matches the reference → **REMOVE**
- Otherwise, the column deviates from reference → **KEEP**

This test identifies columns where:
- A single nucleotide matches the reference position (perfect match → remove)
- Multiple nucleotides are present, OR
- A single nucleotide doesn't match the reference (deviation → keep)

## API Functions

### `filter_counts_by_reference(counts, ref; tol=1e-9)`
Returns indices of columns to keep from a single count matrix.

**Arguments:**
- `counts`: Count matrix (not normalized)
- `ref`: BitMatrix reference sequence (one-hot encoded)
- `tol`: Numerical tolerance for comparison

**Returns:** Vector of column indices to keep

**Example:**
```julia
counts = [10 5 0; 0 5 20; 0 0 0; 0 0 0]
ref = BitMatrix([1 0 0; 0 1 0; 0 0 1; 0 0 0])
keep = filter_counts_by_reference(counts, ref)  # Returns [2, 3]
```

### `count_fragments(count_matrices, reference_pfms; tol=1e-9)`
Counts the number of contiguous fragments after filtering.

**Arguments:**
- `count_matrices`: Vector of count matrices
- `reference_pfms`: Vector of BitMatrix references

**Returns:** Integer number of fragments

**Example:**
```julia
n = count_fragments([counts1, counts2], [ref1, ref2])  # Returns 3
```

### `apply_count_filter(count_matrices, starting_indices, reference_pfms; tol=1e-9)`
Applies filtering and splits matrices into contiguous fragments.

**Arguments:**
- `count_matrices`: Vector of count matrices
- `starting_indices`: Vector of starting positions
- `reference_pfms`: Vector of BitMatrix references

**Returns:** Tuple of (filtered_counts, filtered_starts, filtered_refs)

**Example:**
```julia
filtered_counts, filtered_starts, filtered_refs = apply_count_filter(
    [counts1, counts2], [1, 20], [ref1, ref2]
)
# Each contiguous fragment becomes a separate element
```

## Complete Workflow

```julia
using EntroPlots
using LinearAlgebra

# 1. Create count matrices (NOT normalized)
counts1 = [100 0 50; 0 100 50; 0 0 0; 0 0 0]
counts2 = [0 100; 100 0; 0 0; 0 0]

# 2. Create reference sequences (one-hot encoded BitMatrix)
ref1 = BitMatrix([1 0 0; 0 1 0; 0 0 1; 0 0 0])  # "ACG"
ref2 = BitMatrix([0 1; 1 0; 0 0; 0 0])         # "CA"

# 3. Check how many fragments will result
n_fragments = count_fragments([counts1, counts2], [ref1, ref2])
println("Will create $n_fragments fragments")

# 4. Apply filtering
filtered_counts, filtered_starts, filtered_refs = apply_count_filter(
    [counts1, counts2], 
    [1, 50],           # starting positions
    [ref1, ref2]
)

# 5. Normalize to PFMs
pfms = [c ./ sum(c, dims=1) for c in filtered_counts]

# 6. Calculate total length
total_len = maximum(filtered_starts .+ size.(pfms, 2))

# 7. Plot
p = logoplot_with_rect_gaps(
    pfms, 
    filtered_starts, 
    total_len;
    reference_pfms = filtered_refs
)
```

## Design Principles

✓ **Concise**: Only ~40 lines of implementation code
✓ **Clear**: Simple dot product test for filtering
✓ **Composable**: Separate functions for different tasks
✓ **Tested**: Comprehensive test suite covering edge cases
✓ **Efficient**: Single pass through data

## Test Coverage

The test suite covers:
- ✓ Basic filtering logic
- ✓ Fragment counting
- ✓ Starting index updates
- ✓ Perfect matches (all removed)
- ✓ No matches (all kept)
- ✓ Discontinuous fragments

Run tests with:
```bash
julia --project=. test_count_filter.jl
```
