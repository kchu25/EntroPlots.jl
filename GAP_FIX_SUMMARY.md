# Gap Visibility Fix for logoplot_with_rect_gaps

## Problem
When using `logoplot_with_rect_gaps` with PFMs that have small gaps between them (1-3 positions), the strike-through/gap rectangles were not appearing in the plot.

### Example Issue
- PFM1: positions 39-47 (length 9)
- PFM2: positions 50-58 (length 9)  
- Gap: positions 48-49 (2 positions)

The gap at positions 48-49 was not visible in the plot.

## Root Cause
The issue was in the `inc_round_up` function in `src/old/logo_rect_helpers.jl`:

```julia
# OLD CODE (BUGGY)
inc_round_up(x) = Int(ceil(log2_or_0(x)))
```

This function uses log2 transformation to compress large gaps. However, for small gaps:
- Gap of 1: `log2(1) = 0` → `ceil(0) = 0` → **Gap disappears!**
- Gap of 2: `log2(2) = 1` → `ceil(1) = 1` → Gap becomes 1 position (barely visible)
- Gap of 3: `log2(3) ≈ 1.58` → `ceil(1.58) = 2` → Gap becomes 2 positions

## Solution
Modified `inc_round_up` to ensure a minimum display width of 1 for any gap > 0:

```julia
# NEW CODE (FIXED)
inc_round_up(x) = x == 0 ? 0 : max(1, Int(ceil(log2_or_0(x))))
```

Now:
- Gap of 0: returns 0 (no gap, consecutive PFMs)
- Gap of 1: `max(1, ceil(0)) = 1` → **Gap is visible!**
- Gap of 2: `max(1, ceil(1)) = 1` → **Gap is visible!**
- Gap of 3: `max(1, ceil(1.58)) = 2` → Gap is visible with 2 positions
- Larger gaps: still compressed by log2 but always visible

## Testing
Three test files have been created:

### 1. `test_gap_issue.jl`
Visual test with the original issue case and additional test cases for gaps of different sizes.

```bash
julia test_gap_issue.jl
```

Expected output:
- Creates 4 PNG files showing gaps of 0, 1, 2, and 3 positions
- All non-zero gaps should show strike-through rectangles

### 2. `test_gap_visibility.jl`
Automated unit tests that verify:
- The `inc_round_up` function works correctly
- `get_display_increments` calculates gaps properly
- `get_offset_from_start` produces correct offsets
- Integration test with `logoplot_with_rect_gaps`

```bash
julia test_gap_visibility.jl
```

Expected output: All tests pass

### 3. `test_reference_colors.jl`
Tests the reference-based coloring feature (separate from gap issue).

## Files Modified
- `src/old/logo_rect_helpers.jl`: Fixed `inc_round_up` function and added documentation

## Backward Compatibility
This change maintains backward compatibility:
- Gaps of 0 positions: still show no gap (consecutive PFMs)
- Large gaps: still compressed by log2 transformation
- Small gaps (1-3 positions): now VISIBLE instead of invisible/compressed

## Verification
After the fix, run:

```julia
using Revise
using Plots
using EntroPlots

pfm1 = ones(4, 9) ./ 4
pfm2 = ones(4, 9) ./ 4
pfms = [pfm1, pfm2]

# Gap of 2 positions (48-49)
p = EntroPlots.logoplot_with_rect_gaps(pfms, [39, 50], 60)
display(p)
```

You should now see:
1. PFM1 at positions 39-47
2. **Strike-through gap at positions 48-49** ✓
3. PFM2 at positions 50-58
