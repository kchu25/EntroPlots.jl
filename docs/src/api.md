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

```@docs
logoplot_with_rect_gaps
save_logo_with_rect_gaps
get_rectangle_basic
```
