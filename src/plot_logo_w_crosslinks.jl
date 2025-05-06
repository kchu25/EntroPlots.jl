function crosslink!(crosslink_mat, all_coords, logo_x_offset, logo_y_offset)
    if !isnothing(crosslink_mat)
        charglyph = C_RECT
        num_rows = size(crosslink_mat, 1)
        for (xoffset, col) in enumerate(eachcol(crosslink_mat))
            vsp = 1e-8 .* rand(length(col)) # vsp: very small perturb
            esh = col .* crosslink_stretch_factor2 .+ vsp # esh: each signiture height
            total_height = sum(esh)
            for r = 1:num_rows
                xs, ys = Float64[], Float64[]
                yoffset = sum(esh[esh.<esh[r]])
                # @info "esh1: $(esh[1]), esh2: $(esh[2])"
                push!(
                    ys,
                    (esh[r] .* charglyph.y .- (total_height - yoffset) .+ logo_y_offset)...,
                )
                push!(ys, NaN)
                push!(xs, ((1.1 .* charglyph.x .+ xoffset .- 0.275)...))
                push!(xs, NaN)
                push!(all_coords, ("$r", (; xs, ys)))
            end
        end
    end
end

function freq2xyWcrosslink(
    crosslink_mat;
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
    alphabet_coords = ALPHABET_GLYPHS,
    very_small_perturb = 1e-5 .* rand(4),
)
    all_coords = []
    crosslink!(crosslink_mat, all_coords, logo_x_offset, logo_y_offset)
    all_coords
end

@userplot LogoCrosslink
@recipe function f(data::LogoCrosslink; alpha = 1.0)
    crosslink_mat = data.args[1]
    alpha --> alpha
    coords = freq2xyWcrosslink(crosslink_mat)
    for (k, v) in coords
        @series begin
            fill := 0
            lw --> 0
            label --> k
            color --> get(crosslink_palette, k, :grey)
            v.xs, v.ys
        end
    end
end

function logoplotwithcrosslink(
    pfm,
    background,
    c;
    alpha = 1.0,
    dpi = default_dpi,
    rna = true,
)
    p = nothinglogo(size(pfm, 2); crosslink = true)
    logoplot!(p, pfm, background; dpi = dpi, setup_off = true, rna = rna, alpha = alpha)
    logocrosslink!(p, c; alpha = alpha)
    return p
end

logoplotwithcrosslink(pfm, c; dpi = default_dpi, rna = true) =
    logoplotwithcrosslink(pfm, default_genomic_background, c; dpi = dpi, rna = rna)

function logoplot_with_highlight_crosslink(
    pfm,
    background,
    c,
    highlighted_regions::Vector{UnitRange{Int}};
    dpi = 65,
    alpha = _alpha_,
    rna = true,
)
    check_highlighted_regions(highlighted_regions)
    num_columns, range_complement =
        get_numcols_and_range_complement(pfm, highlighted_regions)

    p = nothinglogo(num_columns; crosslink = true)
    for r in range_complement
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            alpha = alpha,
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            rna = rna,
        )
    end
    for r in highlighted_regions
        logo_x_offset = r.start - 1
        logoplot!(
            p,
            (@view pfm[:, r]),
            background;
            dpi = dpi,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            rna = rna,
        )
    end
    logocrosslink!(p, c)
    return p
end

function logoplot_with_highlight_crosslink(
    pfm::AbstractMatrix,
    c::AbstractMatrix,
    highlighted_regions::Vector{UnitRange{Int}},
)
    return logoplot_with_highlight_crosslink(
        pfm,
        default_genomic_background,
        c,
        highlighted_regions,
    )
end


"""
    save_crosslinked_logoplot(pfm, background, c, save_name; dpi=65, rna=true)
    Save a logoplot with crosslinks to a file
"""
function save_crosslinked_logoplot(
    pfm,
    background,
    c,
    save_name;
    alpha = 1.0,
    dpi = default_dpi,
    rna = true,
    highlighted_regions = nothing,
)
    @assert all(sum(pfm, dims = 1) .≈ 1) "pfm must be a probability matrix"
    @assert length(background) == 4 "background must be a vector of length 4"
    @assert all(0 .≤ background .≤ 1) "background must be a vector of probabilities"
    @assert sum(background) ≈ 1 "background must sum to 1"
    @assert size(c, 2) == size(pfm, 2) "C must be a vector of length equal to the number of columns in pfm"
    @assert all(0 .≤ c .≤ 1) "C must be a vector of probabilities"
    sum_c = sum(c)
    @assert sum_c ≤ 1.01 "The sum of C must be less than or equal 1; right now it is $(sum_c)"
    if isnothing(highlighted_regions)
        p = logoplotwithcrosslink(pfm, background, c; dpi = dpi, rna = rna, alpha = alpha)
    else
        p = logoplot_with_highlight_crosslink(
            pfm,
            background,
            c,
            highlighted_regions;
            dpi = dpi,
        )
    end
    savefig(p, save_name)
end

function save_crosslinked_logoplot(
    pfm,
    c,
    save_name;
    alpha = 1.0,
    dpi = default_dpi,
    rna = true,
    highlighted_regions = nothing,
)
    save_crosslinked_logoplot(
        pfm,
        default_genomic_background,
        c,
        save_name;
        alpha = alpha,
        dpi = dpi,
        rna = rna,
        highlighted_regions = highlighted_regions,
    )
end
