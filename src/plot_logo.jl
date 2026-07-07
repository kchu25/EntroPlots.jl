# ===========================
# EntroPlots Logo Plotting
# ===========================

# ===========================
# Utility Functions
# ===========================

# Fill `adj` with the stacked per-character heights for a single column.
# `adj` depends only on the column (not on the character being drawn), so
# `freq2xy_general` computes it once per column and reuses it across all glyphs.
# Kept as a standalone function (an explicit-argument function barrier) so the
# hot loop stays type-stable regardless of how the parent captures variables.
function _fill_adjusted_heights!(adj, col, background, very_small_perturb,
                                 scale_by_frequency, n_chars)
    if scale_by_frequency
        @inbounds for k in 1:n_chars
            adj[k] = (col[k] + very_small_perturb[k]) * 2
        end
    else
        # Column information content: sum(col .* log2((col + ϵ) / background)).
        ic = 0.0
        @inbounds for k in 1:n_chars
            ic += col[k] * log2((col[k] + 1e-30) / background[k])
        end
        @inbounds for k in 1:n_chars
            adj[k] = ic * col[k] + very_small_perturb[k]
        end
    end
    return adj
end

# Vertical stacking offset for a glyph of height `h`: the sum of all heights
# strictly smaller than `h`, accumulated in ascending index order to match the
# original element-wise summation bit-for-bit.
@inline function _vertical_offset(adj, h, n_chars)
    s = 0.0
    @inbounds for i in 1:n_chars
        adj[i] < h && (s += adj[i])
    end
    return s
end

# ===========================
# Main Coordinate Conversion Function
# ===========================

"""
    freq2xy_general(pfm, chars; kwargs...) -> Vector

Convert a position frequency matrix to plotting coordinates for sequence logos.

Returns a vector of `(char, (; xs, ys), is_nonref)` tuples, one per character (or
two per character when `reference_pfm` is given — one bucket for positions that
match the reference, one for those that differ).

# Arguments
- `pfm`: rows = characters, columns = positions.
- `chars`: character names matching `pfm`'s rows (e.g. `["A", "C", "G", "T"]`).

# Keyword arguments
- `background`: per-character background frequencies (default: uniform).
- `beta`: glyph width scaling factor.
- `logo_x_offset`, `logo_y_offset`: position offsets.
- `alphabet_coords`: dict mapping each character to glyph polygon coords.
- `very_small_perturb`: tiny per-row noise to break ties when stacking.
- `scale_by_frequency`: if `true`, stack to full height by frequency only;
  if `false` (default), scale by information content.
- `reference_pfm`: optional column-wise one-hot `BitMatrix` marking the reference
  letter at each position; enables match/mismatch coloring.

# Implementation notes
Positions are iterated in the outer loop so the per-column stacked heights are
computed once per column and shared across all glyphs (rather than recomputed once
per character × column). Glyph polygons are prefetched into a concretely-typed
vector and written into exact-preallocated per-character buffers, avoiding dynamic
dispatch and `append!`/`push!` regrowth. Output is numerically identical to the
previous character-major implementation.
"""
function freq2xy_general(
    pfm,
    chars;
    background = nothing,
    beta = 1.0,
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
    alphabet_coords = ALPHABET_GLYPHS,
    very_small_perturb = nothing,
    scale_by_frequency = false,
    reference_pfm::Union{BitMatrix, Nothing} = nothing,  # column-wise one-hot reference sequence
)
    n_chars = length(chars)
    background === nothing && (background = fill(1 / n_chars, n_chars))
    very_small_perturb === nothing && (very_small_perturb = 1e-5 .* rand(n_chars))
    L = size(pfm, 2)

    # Prefetch glyph polygons into a concretely-typed vector; with the concrete
    # `ALPHABET_GLYPHS` value type this keeps the inner loop free of dynamic dispatch.
    glyphs = [get(alphabet_coords, c, BASIC_RECT) for c in chars]

    CoordNT = @NamedTuple{xs::Vector{Float64}, ys::Vector{Float64}}
    all_coords = Tuple{String, CoordNT, Bool}[]

    beta_scale = beta * 1.2
    adj = Vector{Float64}(undef, n_chars)  # reused per column

    if reference_pfm === nothing
        # One exact-sized buffer per character: each column adds a glyph polygon plus one
        # NaN separator to break the polyline.
        xs = [Vector{Float64}(undef, L * (length(g.x) + 1)) for g in glyphs]
        ys = [Vector{Float64}(undef, L * (length(g.x) + 1)) for g in glyphs]
        ptr = ones(Int, n_chars)
        @inbounds for pos in 1:L
            col = view(pfm, 1:n_chars, pos)
            _fill_adjusted_heights!(adj, col, background, very_small_perturb,
                                    scale_by_frequency, n_chars)
            shift = (1 / (beta * 0.9)) * 0.35 + pos + (logo_x_offset - 1)
            for idx in 1:n_chars
                g = glyphs[idx]; gx = g.x; gy = g.y
                h = adj[idx]
                yoff = _vertical_offset(adj, h, n_chars)
                bx = xs[idx]; by = ys[idx]; p = ptr[idx]
                for j in eachindex(gx)
                    bx[p] = beta_scale * gx[j] + shift
                    by[p] = h * gy[j] + yoff + logo_y_offset
                    p += 1
                end
                bx[p] = NaN; by[p] = NaN; p += 1
                ptr[idx] = p
            end
        end
        for idx in 1:n_chars
            push!(all_coords, (chars[idx], (xs = xs[idx], ys = ys[idx]), false))
        end
    else
        # Match/mismatch split is data-dependent, so grow the buckets with push! — still on
        # concretely-typed buffers.
        xs_match = [Float64[] for _ in 1:n_chars]; ys_match = [Float64[] for _ in 1:n_chars]
        xs_diff  = [Float64[] for _ in 1:n_chars]; ys_diff  = [Float64[] for _ in 1:n_chars]
        @inbounds for pos in 1:L
            col = view(pfm, 1:n_chars, pos)
            _fill_adjusted_heights!(adj, col, background, very_small_perturb,
                                    scale_by_frequency, n_chars)
            shift = (1 / (beta * 0.9)) * 0.35 + pos + (logo_x_offset - 1)
            for idx in 1:n_chars
                g = glyphs[idx]; gx = g.x; gy = g.y
                h = adj[idx]
                yoff = _vertical_offset(adj, h, n_chars)
                if reference_pfm[idx, pos] == 1
                    bx = xs_match[idx]; by = ys_match[idx]
                else
                    bx = xs_diff[idx];  by = ys_diff[idx]
                end
                for j in eachindex(gx)
                    push!(bx, beta_scale * gx[j] + shift)
                    push!(by, h * gy[j] + yoff + logo_y_offset)
                end
                push!(bx, NaN); push!(by, NaN)
            end
        end
        for idx in 1:n_chars
            c = chars[idx]
            isempty(xs_match[idx]) || push!(all_coords, (c, (xs = xs_match[idx], ys = ys_match[idx]), false))
            isempty(xs_diff[idx])  || push!(all_coords, (c, (xs = xs_diff[idx],  ys = ys_diff[idx]),  true))
        end
    end

    return all_coords
end

# ===========================
# Main Plotting Recipe
# ===========================

"""
    get_sequence_characters(protein, rna)

Return the appropriate character set based on sequence type.
"""
function get_sequence_characters(protein::Bool, rna::Bool)
    return protein ? protein_letters :
           rna ? rna_letters :
           dna_letters
end

"""
    get_color_palette(uniform_color, pos)

Return the appropriate color palette based on settings.
"""
function get_color_palette(uniform_color::Bool, pos::Bool)
    if uniform_color
        return pos ? PALETTE_pos : PALETTE_neg
    end
    return AA_PALETTE3
end

# Sequence logo recipe. The user-facing `logoplot` / `logoplot!` functions are generated by
# `@userplot`; see the docstring attached to `logoplot` below for usage.
@userplot LogoPlot

"""
    logoplot(pfm[, background]; kwargs...)

Render a sequence logo from a position frequency matrix.

# Arguments
- `pfm`: position frequency matrix (`4 × N` for DNA/RNA, `20 × N` for protein), each column
  summing to 1.
- `background`: optional background frequencies (length 4 for nucleotides, 20 for protein).
  Defaults to a uniform background.

# Keyword arguments
- `protein::Bool=false`: treat the PFM as a 20-row amino-acid matrix.
- `rna::Bool=false`: use `A, C, G, U` glyphs instead of `A, C, G, T`.
- `tight::Bool=false`: use tight plot limits (drops padding around the logo).
- `xaxis`, `yaxis`: toggle axis display.
- `alpha`, `beta`: glyph transparency and width scaling.
- `uniform_color::Bool=false`: use a single color for all glyphs.
- `scale_by_frequency::Bool=false`: scale letters by frequency only (stack to full height)
  instead of by information content.
- `dpi`, `_margin_`, `pos`, `xrotation`, and additional styling parameters are also accepted.

See also [`logoplot_with_highlight`](@ref) and [`save_logoplot`](@ref).
"""
logoplot

@recipe function f(
    data::LogoPlot;
    rna = false,
    protein = false,
    xaxis = false,
    yaxis = false,
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
    xrotation = 0,
    setup_off = false,
    alpha = 1.0,
    beta = 1.0,
    dpi = 125,
    _margin_ = margin,
    uniform_color = false,
    tight = false,
    pos = false,
    color_positive = "#FFA500",
    color_negative = "#0047AB",
    xticks_nothing = true,
    scale_by_frequency = false,
    reference_pfm = nothing, # a columnwise one hot matrix to show the reference sequence
    ref_match_color = "#1434A4",   # color for letters matching the reference
    ref_mismatch_color = :darkred, # color for letters differing from the reference
)
    # Extract and validate input data
    pfm = data.args[1]
    background = length(data.args) ≥ 2 ? data.args[2] : 
                 (protein ? fill(1/20, 20) : fill(0.25, 4))
    
    # Configure plot settings if not disabled
    if !setup_off
        num_cols = size(pfm, 2)
        xlim_here = !tight ? (xlim_min, num_cols + 2) : (0.5, num_cols + 0.5)
        logo_size = 3 .* (_width_factor_(num_cols) * num_cols, logo_height)
        
        # Apply plot settings
        ylims --> (0, protein ? 4.32 : ylim_max)
        xlims --> xlim_here
        size --> logo_size
        ticks --> :native
        yticks --> (protein ? yticks_protein : yticks)
        ytickfontcolor --> :black
        ytick_direction --> :out
        gridlinewidth --> 0.75
        yminorticks --> yminorticks
        ytickfont --> font(logo_font_size, logo_font)
        xtickfontcolor --> :black
        # rotate the xticks?
        xrotation --> xrotation
        ytickfontsize --> (protein ? ytickfontsize_protein : ytickfontsize)
        xtickfontsize --> (protein ? xtickfontsize_protein : xtickfontsize)
        legend --> false
        tickdir --> :out
        grid --> false
        margin --> 125Plots.mm
        thickness_scaling --> 0.2
        framestyle --> :zerolines
        
        # Handle axis settings
        xaxis && (xaxis --> xaxis)
        yaxis && (yaxis --> yaxis)
    end
    
    # Set basic properties
    dpi --> dpi
    alpha --> alpha
    
    # Generate coordinates for all characters
    chars = get_sequence_characters(protein, rna)
    coords = freq2xy_general(
        pfm, chars;
        background = background,
        beta = beta,
        logo_x_offset = logo_x_offset,
        logo_y_offset = logo_y_offset,
        scale_by_frequency = scale_by_frequency,
        reference_pfm = reference_pfm
    )
    
    # Get appropriate color palette
    palette = get_color_palette(uniform_color, pos)
    
    # Create series for each character
    for (char, coord_data, non_ref_letter) in coords
        # When reference_pfm is provided, use match/mismatch coloring scheme
        if !isnothing(reference_pfm)
            color_here = non_ref_letter ? ref_mismatch_color : ref_match_color
        else
            color_here = get(palette, char, :grey)
        end
        @series begin
            fill := 0
            lw --> 0
            label --> char
            color --> color_here
            coord_data.xs, coord_data.ys
        end
    end
    
    # Handle x-tick settings
    if !setup_off
        xticks --> 1:1:size(pfm, 2)
    else
        if xticks_nothing
            xticks --> nothing
        else
            xticks --> (1:1:size(pfm, 2), 3:size(pfm,2)+2)
        end
    end
end

# ===========================
# Highlighting Functions
# ===========================

"""
    chk_overlap(highlighted_regions)

Check if any highlighted regions overlap with each other.
"""
function chk_overlap(highlighted_regions::Vector{UnitRange{Int}})
    for i = 1:length(highlighted_regions)-1
        if is_overlapping(highlighted_regions[i], highlighted_regions[i+1])
            return true
        end
    end
    return false
end

"""
    check_highlighted_regions(highlighted_regions)

Validate that highlighted regions do not overlap.
"""
function check_highlighted_regions(highlighted_regions::Vector{UnitRange{Int}})
    if length(highlighted_regions) > 1
        @assert !chk_overlap(highlighted_regions) "highlighted_regions shouldn't be overlapping"
    end
end

"""
    get_numcols_and_range_complement(pfm, highlighted_regions)

Get number of columns and complement ranges (non-highlighted regions).
"""
function get_numcols_and_range_complement(pfm, highlighted_regions::Vector{UnitRange{Int}})
    num_cols = size(pfm, 2)
    range_complement = complement_ranges(highlighted_regions, num_cols)
    return num_cols, range_complement
end

# ===========================
# Logo Plotting with Highlighting
# ===========================

"""
    logoplot_with_highlight(pfm, background, highlighted_regions; kwargs...)

Plot a sequence logo with specific regions highlighted.

# Arguments
- `pfm`: Position frequency matrix
- `background`: Background frequencies
- `highlighted_regions`: Vector of UnitRange{Int} specifying positions to highlight
- `scale_by_frequency::Bool=false`: If true, scale letters by frequency only (stack to full height)
- Additional keyword arguments for customization
"""
function logoplot_with_highlight(
    pfm::AbstractMatrix,
    background::AbstractVector,
    highlighted_regions::Vector{UnitRange{Int}};
    protein = false,
    rna = false,
    dpi = 65,
    alpha = _alpha_,
    uniform_color = false,
    pos = false,
    scale_by_frequency = false,
    _margin_ = nothing,
    tight = false,
)

    check_highlighted_regions(highlighted_regions)

    num_columns, range_complement =
        get_numcols_and_range_complement(pfm, highlighted_regions)

    p = nothinglogo(num_columns; protein=protein, tight=tight, _margin_=_margin_)
    for r in range_complement
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            rna = rna,
            protein = protein,
            alpha = alpha,
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            uniform_color = uniform_color,
            pos = pos,
            scale_by_frequency = scale_by_frequency,
        )
    end
    for r in highlighted_regions
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            rna = rna,
            protein = protein,
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            uniform_color = uniform_color,
            pos = pos,
            scale_by_frequency = scale_by_frequency,
        )

    end
    return p
end

"""
    logoplot_with_highlight(pfm, highlighted_regions; kwargs...)

Plot a sequence logo with highlighted regions using default background frequencies.
"""
function logoplot_with_highlight(
    pfm::AbstractMatrix,
    highlighted_regions::Vector{UnitRange{Int}};
    protein = false,
    rna = false,
    dpi = 65,
    scale_by_frequency = false,
    _margin_ = nothing,
    tight = false,
)
    return logoplot_with_highlight(
        pfm,
        protein ? default_protein_background : default_genomic_background,
        highlighted_regions;
        rna = rna,
        protein = protein,
        dpi = dpi,
        scale_by_frequency = scale_by_frequency,
        _margin_ = _margin_,
        tight = tight,
    )
end

# ===========================
# Save Functions
# ===========================

"""
    save_logoplot(pfm, background, save_name; kwargs...)

Save a sequence logo plot to a file.

# Arguments
- `pfm::Matrix{Real}`: Position frequency matrix (rows = characters, columns = positions)
- `background::Vector{Real}`: Background probabilities for each character
- `save_name::String`: File path to save the plot
- `scale_by_frequency::Bool=false`: If true, scale letters by frequency only (stack to full height)

# Requirements
- `pfm` must be a probability matrix (each column sums to 1)
- `background` must be a vector of probabilities that sum to 1
- For nucleotides: `background` length = 4; for proteins: length = 20

# Example
```julia
pfm = [0.02 1.0 0.98 0.0; 0.98 0.0 0.02 0.19; ...]
background = [0.25, 0.25, 0.25, 0.25]
save_logoplot(pfm, background, "logo.png"; dpi=65)
```
"""
function save_logoplot(
    pfm,
    background,
    save_name::String;
    alpha = 1.0,
    rna = false,
    protein = false,
    dpi = default_dpi,
    xaxis = true,
    yaxis = true,
    highlighted_regions = nothing,
    uniform_color = false,
    pos = false,
    _margin_ = margin,
    tight = false,
    scale_by_frequency = false,
)
    expected_bg_len = protein ? 20 : 4
    @assert all(sum(pfm, dims = 1) .≈ 1) "pfm must be a probability matrix (each column sums to 1)"
    @assert length(background) == expected_bg_len "background must have length $expected_bg_len for $(protein ? "protein" : "nucleotide") logos"
    @assert all(0 .≤ background .≤ 1) "background must contain probabilities in [0, 1]"
    @assert sum(background) ≈ 1 "background must sum to 1"

    if isnothing(highlighted_regions)
        p = logoplot(
            pfm,
            background;
            rna = rna,
            protein=protein,
            alpha = alpha,
            dpi = dpi,
            xaxis = xaxis,
            yaxis = yaxis,
            highlighted_regions = highlighted_regions,
            _margin_ = _margin_,
            tight = tight,
            uniform_color = uniform_color,
            pos = pos,
            scale_by_frequency = scale_by_frequency,
        )
        plot!(p, xaxis = false, yaxis = yaxis, 
            ytickfontsize = (protein ? ytickfontsize_protein : 295))
        hline!([0], linewidth = 25, color = :black)  # Add a thick horizontal line (x-axis)
        vline!([0], linewidth = 25, color = :black)  # Add a thick vertical line (y-axis)
    else
        p = logoplot_with_highlight(
            pfm,
            background,
            highlighted_regions;
            dpi = dpi,
            rna = rna,            
            protein=protein, 
            uniform_color = uniform_color,
            pos = pos,
            scale_by_frequency = scale_by_frequency,
            _margin_ = _margin_,
            tight = tight,
        )
        plot!(p, xaxis = false, yaxis = yaxis, ytickfontsize = 555)
        hline!(p, [0], linewidth = 55, color = :black)  # Add a thick horizontal line (x-axis)
        vline!(p, [0], linewidth = 55, color = :black)  # Add a thick vertical line (y-axis)
    end
    savefig(p, save_name)
end

"""
    save_logoplot(pfm, save_name; kwargs...)

Save a sequence logo plot using default background frequencies.

This is equivalent to `save_logoplot(pfm, background, save_name; kwargs...)`
where `background` is set to uniform frequencies for the sequence type.
"""
function save_logoplot(
    pfm,
    save_name::String;
    rna = false,
    protein = false,
    alpha = 1.0,
    dpi = 160,
    highlighted_regions = nothing,
    uniform_color = false,
    pos = false,
    xaxis = true,
    yaxis = true,
    _margin_ = margin,
    tight = false,
    scale_by_frequency = false,
)
    if protein
        bg = default_protein_background
    else
        bg = default_genomic_background  # assume [0.25, 0.25, 0.25, 0.25]
    end
    save_logoplot(
        pfm,
        bg,
        save_name;
        rna = rna,
        protein = protein,
        alpha = alpha,
        dpi = dpi,
        xaxis = xaxis,
        yaxis = yaxis,
        highlighted_regions = highlighted_regions,
        _margin_ = _margin_,
        tight = tight,
        uniform_color = uniform_color,
        pos = pos,
        scale_by_frequency = scale_by_frequency,
    )
end
