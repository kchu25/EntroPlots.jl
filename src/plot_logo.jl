# ===========================
# EntroPlots Logo Plotting
# ===========================

# ===========================
# Utility Functions
# ===========================

"""
    compute_adjusted_heights(col_view, ic_height, perturb)

Scale frequencies by information content and add tiny noise for proper stacking.
"""
function compute_adjusted_heights(col_view, ic_height, perturb)
    return ic_height .* col_view .+ perturb
end

"""
    compute_vertical_offset(adjusted_heights, aa_idx)

Calculate vertical offset for stacking by summing all heights smaller than current character height.
"""
function compute_vertical_offset(adjusted_heights, aa_idx)
    h = adjusted_heights[aa_idx]
    s = 0.0
    @inbounds for i in eachindex(adjusted_heights)
        if adjusted_heights[i] < h
            s += adjusted_heights[i]
        end
    end
    return s
end

"""
    compute_glyph_x_coords(glyph_x, beta, pos_idx, logo_x_offset)

Compute x-coordinates for a glyph based on position and scaling factors.
"""
function compute_glyph_x_coords(glyph_x, beta, pos_idx, logo_x_offset)
    scale = beta * 1.2
    shift = (1 / (beta * 0.9)) * 0.35 + pos_idx + (logo_x_offset - 1)
    return @. scale * glyph_x + shift
end

"""
    compute_glyph_y_coords(adjusted_height, glyph_y, y_offset, logo_y_offset)

Compute y-coordinates for a glyph based on height and vertical offset.
"""
function compute_glyph_y_coords(adjusted_height, glyph_y, y_offset, logo_y_offset)
    return adjusted_height .* glyph_y .+ y_offset .+ logo_y_offset
end

# ===========================
# Main Coordinate Conversion Function
# ===========================

"""
    freq2xy_general(pfm, chars; background, beta, logo_x_offset, logo_y_offset, alphabet_coords, very_small_perturb, scale_by_frequency)

Convert position frequency matrix (PFM) to x/y coordinates for plotting sequence logos.

# Arguments
- `pfm`: Position frequency matrix (rows = characters, columns = positions)
- `chars`: Vector of character names (e.g., ["A", "C", "G", "T"])
- `background`: Background frequencies for each character
- `beta`: Scaling factor for glyph width
- `logo_x_offset`, `logo_y_offset`: Offset coordinates for positioning
- `alphabet_coords`: Dictionary mapping characters to glyph coordinates
- `very_small_perturb`: Small random perturbation to avoid identical heights
- `scale_by_frequency`: If true, scale letters by frequency only (stack to full height). If false (default), scale by information content.

# Returns
Vector of tuples containing character name and (xs, ys) coordinates.
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
    reference_pfm::Union{BitMatrix, Nothing} = nothing # a columnwise one hot matrix to show the reference sequence
)
    n_chars = length(chars)
    background === nothing && (background = fill(1 / n_chars, n_chars))
    very_small_perturb === nothing && (very_small_perturb = 1e-5 .* rand(n_chars))

    all_coords = []

    for (idx, c) in enumerate(chars)
        xs, ys = Float64[], Float64[]
        glyph = get(alphabet_coords, c, BASIC_RECT)
        non_ref_letter = false # flag letters that's not in the reference matrix

        for (pos_idx, col) in enumerate(eachcol(pfm))
            col_view = @view col[1:n_chars]
            
            if !isnothing(reference_pfm)
                non_ref_letter = reference_pfm[idx, pos_idx] == 0
            end

            if scale_by_frequency
                # Scale by frequency only - stack to full height
                adjusted_heights = (col_view .+ very_small_perturb) .* 2
            else
                # Scale by information content (original behavior)
                ic_height = ic_height_here(col_view; background = background)
                adjusted_heights = compute_adjusted_heights(col_view, ic_height, very_small_perturb)
            end
            
            y_offset = compute_vertical_offset(adjusted_heights, idx)

            push!(xs, compute_glyph_x_coords(glyph.x, beta, pos_idx, logo_x_offset)...)
            push!(xs, NaN)
            push!(ys, compute_glyph_y_coords(adjusted_heights[idx], glyph.y, y_offset, logo_y_offset)...)
            push!(ys, NaN)
        end

        push!(all_coords, (c, (; xs, ys), non_ref_letter))
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

"""
LogoPlot recipe for creating sequence logo plots.

Supports DNA, RNA, and protein sequences with extensive customization options.

# Arguments
- `data::LogoPlot`: Contains PFM and optional background frequencies
- `rna::Bool=false`: Set to true for RNA sequences
- `protein::Bool=false`: Set to true for protein sequences  
- `setup_off::Bool=false`: Skip plot setup (for overlays)
- `alpha::Real=1.0`: Transparency level
- `beta::Real=1.0`: Glyph width scaling factor
- `uniform_color::Bool=false`: Use uniform coloring scheme
- `tight::Bool=false`: Use tight plot limits
- `scale_by_frequency::Bool=false`: If true, scale letters by frequency only (stack to full height). If false, scale by information content.
- Additional styling parameters available
"""
@userplot LogoPlot
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
    reference_pfm::Union{BitMatrix, Nothing} = nothing, # a columnwise one hot matrix to show the reference sequence
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
        color_here = get(palette, char, :grey)
        if !isnothing(reference_pfm) && non_ref_letter
            color_here = :lightgrey
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
)

    check_highlighted_regions(highlighted_regions)

    num_columns, range_complement =
        get_numcols_and_range_complement(pfm, highlighted_regions)

    p = nothinglogo(num_columns; protein=protein)
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
    scale_by_frequency = false,
)
    return logoplot_with_highlight(
        pfm,
        protein ? default_protein_background : default_genomic_background,
        highlighted_regions;
        rna = rna,
        protein = protein,
        scale_by_frequency = scale_by_frequency,
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
    @assert all(sum(pfm, dims = 1) .≈ 1) "pfm must be a probability matrix"
    @assert length(background) == 4 || length(background) == 20 "background must be a vector of length 4"
    @assert all(0 .≤ background .≤ 1) "background must be a vector of probabilities"
    @assert sum(background) ≈ 1 "background must sum to 1"

    if protein
        @assert length(background) == 20 "protein background must be length 20"
    else
        @assert length(background) == 4 "nucleotide background must be length 4"
    end

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
        plot!(p, xaxis = false, yaxis = true, 
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
        )
        plot!(p, xaxis = false, yaxis = true, ytickfontsize = 555)
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
