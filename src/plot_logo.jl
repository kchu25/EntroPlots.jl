
function freq2xy(
    pfm;
    background = [0.25 for _ = 1:4],
    rna = false,
    beta = 1.0, # width of the x-axis for each letter in the motif
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
    alphabet_coords = ALPHABET_GLYPHS,
    very_small_perturb = 1e-5 .* rand(4),
)
    # @assert sum(pfm, dims=1) .≈ 1 "pfm must be a probability matrix"
    all_coords = []
    charnames = rna ? rna_letters : dna_letters
    # For each character (row):
    #   Collect all positions and heights of that character's polygon
    for (j, c) in enumerate(charnames)
        xs, ys = Float64[], Float64[]
        # Get character glyph coords; o/w get the simple rectangle
        charglyph = get(alphabet_coords, c, BASIC_RECT)
        # for each postion in the sequence:
        #     1. Push in the coords for the character's polygon
        #     2. Adjust y_height based on information content and frequency 
        for (xoffset, col) in enumerate(eachcol(pfm))
            acgt = @view col[1:4]
            ic_height = ic_height_here(col; background = background)
            adjusted_height = ic_height .* acgt .+ very_small_perturb
            yoffset = sum(adjusted_height[adjusted_height.<adjusted_height[j]])
            push!(
                xs,
                (
                    (beta * 1.2) .* charglyph.x .+ (1 / ((beta * 0.9))) * 0.35 .+ xoffset .+
                    (logo_x_offset - 1)
                )...,
            )
            push!(xs, NaN)
            push!(ys, (adjusted_height[j] .* charglyph.y .+ yoffset .+ logo_y_offset)...)
            push!(ys, NaN)
        end
        push!(all_coords, (c, (; xs, ys)))
    end
    all_coords
end



@userplot LogoPlot
@recipe function f(
    data::LogoPlot;
    rna = false,
    protein = false,
    xaxis = false,
    yaxis = false,
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
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
)

    if !setup_off
        num_cols = size(data.args[1], 2)
        xlim_here = !tight ? (xlim_min, num_cols + 2) : (0.5, num_cols + 0.5)
        # @info "num_cols: $num_cols"
        ylims --> (0, protein ? 4.32 : ylim_max)
        xlims --> xlim_here
        # logo_size = (_width_factor_(num_cols)*num_cols, logo_height)
        logo_size = 3 .* (_width_factor_(num_cols) * num_cols, logo_height)
        ticks --> :native
        yticks --> (protein ? yticks_protein : yticks)  # Ensure ticks are generated
        ytickfontcolor --> :black
        ytick_direction --> :out

        # framestyle --> :none
        gridlinewidth --> 0.75

        yminorticks --> yminorticks
        ytickfont --> font(logo_font_size, logo_font)
        xtickfontcolor --> :black
        ytickfontsize --> (protein ? ytickfontsize_protein : ytickfontsize)
        xtickfontsize --> (protein ? xtickfontsize_protein : xtickfontsize)
        xaxis && (xaxis --> xaxis)
        yaxis && (yaxis --> yaxis)
        legend --> false
        tickdir --> :out
        grid --> false
        # margin --> _margin_
        margin --> 125Plots.mm
        # thickness_scaling --> thickness_scaling
        thickness_scaling --> 0.2
        size --> logo_size
        # framestyle --> :semi
        framestyle --> :zerolines
    end
    dpi --> dpi
    alpha --> alpha
    pfm = data.args[1]
    background =
        length(data.args) ≥ 2 ? data.args[2] : (protein ? fill(1 / 20, 20) : fill(0.25, 4))
    coords =
        protein ?  # <-- changed
        freq2xy_protein(
            pfm;
            background = background,
            beta = beta,  # <-- changed
            logo_x_offset = logo_x_offset,
            logo_y_offset = logo_y_offset,
        ) :
        freq2xy(
            pfm;
            background = background,
            rna = rna,
            beta = beta,
            logo_x_offset = logo_x_offset,
            logo_y_offset = logo_y_offset,
        )

    if uniform_color
        if pos
            palette = PALETTE_pos
        else
            palette = PALETTE_neg
        end
    end

    for (k, v) in coords
        color_here = uniform_color ? get(palette, k, :grey) : get(AA_PALETTE3, k, :grey)
        @series begin
            fill := 0
            lw --> 0
            label --> k
            color --> color_here
            v.xs, v.ys
        end
    end
    if !setup_off
        xticks --> 1:1:size(data.args[1], 2) # xticks needs to be placed here to avoid fractional xticks? weird
    end
    # xtickslabelcolor --> :white
    xticks --> nothing,   # Remove x-ticks
    xticklabels --> nothing  # Remove x-tick labels

end

# check if there's any overlap in the highlighted region
function chk_overlap(highlighted_regions::Vector{UnitRange{Int}})
    for i = 1:length(highlighted_regions)-1
        if is_overlapping(highlighted_regions[i], highlighted_regions[i+1])
            return true
        end
    end
    return false
end

function check_highlighted_regions(highlighted_regions::Vector{UnitRange{Int}})
    if length(highlighted_regions) > 1
        # if chk_overlap(highlighted_regions)
        #     @info "highlighted regions: $highlighted_regions"
        # end
        @assert !chk_overlap(highlighted_regions) "highlighted_regions shouldn't be overlapping"
    end
end

function get_numcols_and_range_complement(pfm, highlighted_regions::Vector{UnitRange{Int}})
    num_cols = size(pfm, 2)
    range_complement = complement_ranges(highlighted_regions, num_cols)
    return num_cols, range_complement
end

# plot the logo with highlight
function logoplot_with_highlight(
    pfm::AbstractMatrix,
    background::AbstractVector,
    highlighted_regions::Vector{UnitRange{Int}};
    rna = false,
    dpi = 65,
    alpha = _alpha_,
    uniform_color = false,
    pos = false,
)

    check_highlighted_regions(highlighted_regions)

    num_columns, range_complement =
        get_numcols_and_range_complement(pfm, highlighted_regions)

    p = nothinglogo(num_columns)
    for r in range_complement
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            rna = rna,
            alpha = alpha,
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            uniform_color = uniform_color,
            pos = pos,
        )
    end
    for r in highlighted_regions
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            rna = rna,
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            uniform_color = uniform_color,
            pos = pos,
        )

    end
    return p
end

function logoplot_with_highlight(
    pfm::AbstractMatrix,
    highlighted_regions::Vector{UnitRange{Int}};
    rna = false,
)
    return logoplot_with_highlight(
        pfm,
        default_genomic_background,
        highlighted_regions;
        rna = rna,
    )
end


"""
    save_logoplot(pfm, background, save_name; dpi=65)

# Arguments
- `pfm::Matrix{Real}`: Position frequency matrix
- `background::Vector{Real}`: Background probabilities of A, C, G, T
- `save_name::String`: Name of the path/file to save the plot

Note that
- `pfm` must be a probability matrix
    - sum of each column must be 1
- `background` must be a vector of length 4
    - must be a vector of probabilities
    - sum of `background` must be 1

# Example
```julia

pfm =  [0.02  1.0  0.98  0.0   0.0   0.0   0.98  0.0   0.18  1.0
        0.98  0.0  0.02  0.19  0.0   0.96  0.01  0.89  0.03  0.0
        0.0   0.0  0.0   0.77  0.01  0.0   0.0   0.0   0.56  0.0
        0.0   0.0  0.0   0.04  0.99  0.04  0.01  0.11  0.23  0.0]

background = [0.25, 0.25, 0.25, 0.25]

#= save the logo plot in the tmp folder as logo.png =#
save_logoplot(pfm, background, "tmp/logo.png")

#= save the logo plot in the current folder as logo.png with a dpi of 65 =#
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
            # protein=protein, # TODO
            uniform_color = uniform_color,
            pos = pos,
        )
        plot!(p, xaxis = false, yaxis = true, ytickfontsize = 555)
        hline!(p, [0], linewidth = 55, color = :black)  # Add a thick horizontal line (x-axis)
        vline!(p, [0], linewidth = 55, color = :black)  # Add a thick vertical line (y-axis)
    end
    savefig(p, save_name)
end

"""
    save_logoplot(pfm, save_name; dpi=65)

    This is the same as `save_logoplot(pfm, background, save_name; dpi=65)`
    where `background` is set to `[0.25, 0.25, 0.25, 0.25]`

    See `save_logoplot(pfm, background, save_name; dpi=65)` for more details.
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
)
    if protein
        bg = fill(1/20, 20)
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
    )
end
