```@meta
CurrentModule = EntroPlots
```

# API Reference

```@index
```

## Plotting

```@docs
logoplot
logoplot_with_highlight
save_logoplot
```

## PFM utilities

```@docs
reduce_entropy!
```

## Count-matrix filtering

Utilities for working with count matrices and reference sequences — used to keep only the
columns that deviate from a reference before plotting.

```@docs
filter_counts_by_reference
count_fragments
apply_count_filter
```

## Legacy: gapped / spacer logos

These functions render multiple logo fragments along a track, joined by rectangular
connectors. They are retained for downstream packages.

Both `logoplot_with_rect_gaps` and `save_logo_with_rect_gaps` accept optional outside fragments:
`outside_count_matrices`, `outside_starting_indices` and `outside_reference_pfms` (default
`nothing`), drawn unfiltered with `outside_match_color` (default `"#64748B"`) for reference
letters and `outside_mismatch_color` (default `"#E69F00"`) for the others. See the guide section
"Outside fragments in a second colour pair".

```@docs
logoplot_with_rect_gaps
save_logo_with_rect_gaps
get_rectangle_basic
```
