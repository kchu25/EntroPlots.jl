
@userplot ArrowPlot
@recipe function f(data::ArrowPlot; arrow_color_palette = nothing)
    coords = data.args[1]
    for (ind, coord) in enumerate(coords)
        color_here = isnothing(arrow_color_palette) ? :grey : arrow_color_palette[ind]
        for v in coord
            @series begin
                fill := 0
                color --> color_here
                lw --> 0
                # label --> k
                v.x, v.y
            end
        end
    end
end

"""
ds_mat: Matrix of distances between the pfms
    e.g. 12 6
         32 8
    number of rows = number of "modes" of distances
    number of columns = number of distance in between the pfms
weights: weights for each mode of distances
optional parameters:
    given_num_cols: the total number of columns that will be occupied for all the arrow-shapes
    arrow_shape_scale_ratio: the ratio by which the width of the arrow-shapes will be scaled
    height_top: the maximum height of the arrow-shapes
"""
function logoplot_with_arrow_gaps(
    pfms,
    ds_mats::AbstractMatrix,
    weights::AbstractVector;
    given_num_cols::Int = 15,
    arrow_shape_scale_ratio::Real = 0.7,
    height_top::Real = 1.7,
    uniform_color = true,
    dpi = 65,
    rna = false,
    basic_fcn = get_arrow_basic
)

    @assert length(pfms) - 1 == size(ds_mats, 2) "The number of columns in ds_mats should be equal to the length of pfms - 1"
    @assert length(weights) == size(ds_mats, 1) "The number of rows in ds_mats should be equal to the length of weights"

    # sort 
    inds_sorted = sortperm(weights)
    weights_sorted = weights[inds_sorted]
    ds_mats_sorted = @view ds_mats[inds_sorted, :]

    # obtain the (organized) arrow shapes
    coords_mat, pfm_starts, total_pfm_cols, total_d_cols = make_arrow_shapes(
        ds_mats_sorted,
        weights_sorted,
        given_num_cols,
        pfms;
        arrow_shape_scale_ratio = arrow_shape_scale_ratio,
        height_top = height_top,
        basic_fcn = basic_fcn
    )

    # plot the logo with arrow shapes
    p = nothinglogo(total_pfm_cols + total_d_cols; xaxis_on = false)

    for (ind, pfm) in enumerate(pfms)
        logo_x_offset = pfm_starts[ind]
        @info "Plotting logo for PFM $(ind) with offset $(logo_x_offset)"
        logoplot!(
            p,
            pfm,
            EntroPlots.bg;
            dpi = dpi,
            rna = rna,
            setup_off = true,
            logo_x_offset = logo_x_offset,
            uniform_color = uniform_color,
        )
    end

    for (_, col) in enumerate(eachcol(coords_mat))
        arrowplot!(p, col; arrow_color_palette = arrow_color_palette)
    end
    return p
end


function save_logo_w_arrows(
    pfms,
    ds_mats::AbstractMatrix,
    weights::AbstractVector,
    save_name::String;
    dpi = default_dpi,
    rna = false,
)
    @assert sum(weights) ≈ 1 "The sum of weights should be 1"
    for pfm in pfms
        @assert all(sum(pfm, dims = 1) .≈ 1) "pfm must be a probability matrix"
    end
    p = logoplot_with_arrow_gaps(pfms, ds_mats, weights; dpi = dpi, rna = rna)
    savefig(p, save_name)
end


