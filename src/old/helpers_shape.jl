mutable struct shape
    x::Vector{Float64}
    y::Vector{Float64}
end

function get_rectangle_basic(; line_scale = 1.0, right = true, x_offset = 0.0)
    #=
        the horizontal line 
            --------
            --------
        part of the arrow (before the arrow head)

        x_offset:
            positive: shift to the right
            negative: shift to the left
    =#
    # Trim the rectangle on the right to avoid overlap with next logo
    # More aggressive trimming for small gaps to prevent touching
    if line_scale <= 2
        right_trim = 0.6  # Very aggressive for 1-2 nucleotide gaps (leaves 40% gap)
    elseif line_scale < 4
        right_trim = 0.75  # Aggressive for small gaps (leaves 25% gap)
    elseif line_scale < 6
        right_trim = 0.85  # Moderate for medium gaps (leaves 15% gap)
    else
        right_trim = 0.9  # Minimal for large gaps (leaves 10% gap)
    end
    
    x =
        [
            0.0,
            right_trim * line_scale,
            right_trim * line_scale,
            0.0
        ] .+ x_offset
    y = [1.015, 1.015, 0.985, 0.985]
    return shape(x, y)
end

function get_arrow_basic(; line_scale = 1.0, right = true, x_offset = 0.0)
    #=
        the horizontal line 
            --------
            --------
        part of the arrow (before the arrow head)

        x_offset:
            positive: shift to the right
            negative: shift to the left
    =#
    arrow_line_width = line_scale * 4.0
    x =
        [
            0.0,
            arrow_line_width,
            arrow_line_width,
            line_scale * 5.5,
            arrow_line_width,
            arrow_line_width,
            0.0,
        ] .+ x_offset
    y = [1.05, 1.05, 1.15, 1.0, 0.85, 0.95, 0.95]
    if right
        return shape(x, y)
    else
        return shape(-x, y)
    end
end

#### helpers #####
get_right_most_point(_shape_::shape) = maximum(_shape_.x)
get_right_most_point(coords::Vector{shape}) = maximum(get_right_most_point.(coords))
get_left_most_point(_shape_::shape) = minimum(_shape_.x)
get_left_most_point(coords::Vector{shape}) = minimum(get_left_most_point.(coords))

get_top_most_point(_shape_::shape) = maximum(_shape_.y)
get_top_most_point(coords::Vector{shape}) = maximum(get_top_most_point.(coords))
get_bottom_most_point(_shape_::shape) = minimum(_shape_.y)
get_bottom_most_point(coords::Vector{shape}) = minimum(get_bottom_most_point.(coords))

x_substract!(_shape_::shape, a) = begin
    _shape_.x .= _shape_.x .- a
end
x_substract!(coords::Vector{shape}, a) = x_substract!.(coords, a)
x_add!(_shape_::shape, a) = begin
    _shape_.x .= _shape_.x .+ a
end
x_add!(coords::Vector{shape}, a) = x_add!.(coords, a)
x_divide!(_shape_::shape, a) = begin
    @assert a != 0.0 "a cannot be zero"
    _shape_.x .= _shape_.x ./ a
end
x_divide!(coords::Vector{shape}, a) = x_divide!.(coords, a)
x_multiply!(_shape_::shape, a) = begin
    _shape_.x .= _shape_.x .* a
end
x_multiply!(coords::Vector{shape}, a) = x_multiply!.(coords, a)

get_width(coords::Vector{shape}) =
    get_right_most_point(coords) - get_left_most_point(coords)
get_height(coords::Vector{shape}) =
    get_top_most_point(coords) - get_bottom_most_point(coords)

y_substract!(_shape_::shape, a) = begin
    _shape_.y .= _shape_.y .- a
end
y_substract!(coords::Vector{shape}, a) = y_substract!.(coords, a)
y_add!(_shape_::shape, a) = begin
    _shape_.y .= _shape_.y .+ a
end
y_add!(coords::Vector{shape}, a) = y_add!.(coords, a)
y_divide!(_shape_::shape, a) = begin
    @assert a != 0.0 "a cannot be zero"
    _shape_.y .= _shape_.y ./ a
end
y_divide!(coords::Vector{shape}, a) = y_divide!.(coords, a)
y_multiply!(_shape_::shape, a) = begin
    _shape_.y .= _shape_.y .* a
end
y_multiply!(coords::Vector{shape}, a) = y_multiply!.(coords, a)

shift_right(_shape_::shape, a) = shape(_shape_.x .+ a, _shape_.y)
shift_right(_shapes_::Vector{shape}, a) = shift_right.(_shapes_, a)
shift_left(_shape_::shape, a) = shape(_shape_.x .- a, _shape_.y)
shift_up(_shape_::shape, a) = shape(_shape_.x, _shape_.y .+ a)
shift_up(_shapes_::Vector{shape}, a) = shift_up.(_shapes_, a)
shift_down(_shape_::shape, a) = shape(_shape_.x, _shape_.y .- a)

Base.copy(_shape_::shape) = shape(copy(_shape_.x), copy(_shape_.y))

###########################

#=
minmax normalize y and returns the 
original top_most_pt and bottom_most_pt of the shape
=#
min_max_normalize_y!(coords::Vector{shape}) = begin
    top_most_pt = get_top_most_point(coords)
    bottom_most_pt = get_bottom_most_point(coords)
    @assert 0 < top_most_pt ≤ 2 "top_most_pt should be in the range of (0,2)"
    @assert 0 ≤ bottom_most_pt < 2 "bottom_most_pt should be in the range of (0,2)"
    @assert top_most_pt > bottom_most_pt "top_most_pt should be greater than bottom_most_pt"
    y_substract!(coords, bottom_most_pt)
    y_divide!(coords, top_most_pt - bottom_most_pt)
end

min_max_normalize_x!(coords::Vector{shape}) = begin
    right_most_pt = get_right_most_point(coords)
    left_most_pt = get_left_most_point(coords)
    @assert right_most_pt > left_most_pt "right_most_pt should be greater than left_most_pt"
    x_substract!(coords, left_most_pt)
    x_divide!(coords, right_most_pt - left_most_pt)
end

function scale_height!(coords::Vector{shape}, scaled_height)
    min_max_normalize_y!(coords)
    y_multiply!(coords, scaled_height) # scale the height
    #= translate the shape so that it keeps the 
       same proportional relation to y = 0 and y = 2. =#
    # y_add!(coords, 1.0 - (scaled_height / 2))
end


function scale_width!(coords::Vector{shape}, scaled_width)
    min_max_normalize_x!(coords)
    x_multiply!(coords, scaled_width)
end

#=
    scale_height_by_proportion!(coords::Vector{shape}, proportion; in_range=(0.0, 2.0))
    scale the height of the shape by the proportion
        proportion: the proportion to scale the height
        in_range: the range of the height after scaling
=#
function scale_width_height_by_proportion!(coords::Vector{shape}, proportion)
    @assert 0.0 < proportion < 1.0 "proportion should be in the range of (0,1)"
    top_most_pt = get_top_most_point(coords)
    bottom_most_pt = get_bottom_most_point(coords)
    orig_height = top_most_pt - bottom_most_pt

    right_most_pt = get_right_most_point(coords)
    left_most_pt = get_left_most_point(coords)
    orig_width = right_most_pt - left_most_pt

    changed_height = orig_height * proportion
    changed_width = orig_width * proportion

    scale_width!(coords, changed_width)
    scale_height!(coords, changed_height)
end

function two_adjusted_glyphs(ALPHABET_GLYPHS_i; stretch_x = 8.0)
    x = stretch_x .* (ALPHABET_GLYPHS_i.x .- minimum(ALPHABET_GLYPHS_i.x))
    # y = (ALPHABET_GLYPHS_i.y .- minimum(ALPHABET_GLYPHS_i.y))
    return shape(x, ALPHABET_GLYPHS_i.y .+ 0.5)
end

function make_in_between_basic(
    num_bt;
    word_increment = 4.0,
    arrow_increment = 1.0,
    arrow_line_scale = 1.25,
    basic_fcn = get_arrow_basic
)
    num_bt = Int(num_bt) # TODO see if this is necessary
    coords = shape[]

    if basic_fcn == get_arrow_basic
        GLYPHS_2_adjusted = merge(
            Dict("$i" => two_adjusted_glyphs(ALPHABET_GLYPHS["$i"]) for i = 0:9), # 0-9
            Dict(
                "b" => two_adjusted_glyphs(ALPHABET_GLYPHS["b"]),
                "p" => two_adjusted_glyphs(ALPHABET_GLYPHS["p"]),
            ),
        )# b and p
        in_bt_str = vcat(split("$num_bt", ""), ["b", "p"])
        k = 0.0
        for i in in_bt_str
            g = copy(GLYPHS_2_adjusted["$i"])
            push!(coords, shift_right(g, k))
            k += word_increment
        end

        push!(
            coords,
            shift_right(
                basic_fcn(; line_scale = arrow_line_scale),
                get_right_most_point(coords) + arrow_increment,
            ),
        )
        push!(
            coords,
            shift_left(
                basic_fcn(; line_scale = arrow_line_scale, right = false),
                arrow_increment,
            ),
        )
    else
        # For rectangles, use the full width (num_bt) instead of (num_bt-1)
        # This ensures small gaps remain visible
        push!(coords,  basic_fcn(; line_scale = num_bt))
    end

    # return coords
    coords = shift_right.(coords, get_left_most_point(coords) * -1.0)  # left aligned to the origin
    bottom_most_pt = get_bottom_most_point(coords)
    y_substract!(coords, bottom_most_pt)
    return coords
end


##################
function get_height_increments(scaled_heights)
    vcat(reverse(cumsum(reverse(scaled_heights)))[2:end], 0)
end

function get_center_point_x(vec_shape::Vector{shape})
    right_most_pt = get_right_most_point(vec_shape)
    left_most_pt = get_left_most_point(vec_shape)
    return (right_most_pt + left_most_pt) / 2
end

function get_center_point_y(vec_shape::Vector{shape})
    top_most_pt = get_top_most_point(vec_shape)
    bottom_most_pt = get_bottom_most_point(vec_shape)
    return (top_most_pt + bottom_most_pt) / 2
end

#=
num_col_each_col!(coords_mat::Matrix{Vector{shape}}, given_len)
    coords_mat: Matrix of arrow-shapes
    given_len: the total length given for all the columns of arrow-shapes
Note that this function does the following: 
    1. scale the width of each arrow-shapes
    2. returns the number of columns for each "column"
=#
function num_col_each_col!(coords_mat::Matrix{Vector{shape}}, given_len)
    widths = get_width.(coords_mat)
    # get the maximum length of each column (set of arrow-shapes)
    max_widths_each_col = maximum(widths, dims = 1)
    each_col_ratio = max_widths_each_col ./ sum(max_widths_each_col)
    num_cols_each = Int.(ceil.(given_len .* each_col_ratio))

    adjusted_lengths = num_cols_each .* (widths ./ max_widths_each_col)
    scale_width!.(coords_mat, adjusted_lengths)
    return num_cols_each
end

function obtain_pfm_regions_and_dstarts(pfms, num_cols_each_d; d_ϵ = 0.5)
    pfm_num_cols_each = size.(pfms, 2)
    pfm_starts = Int[]
    d_starts = Int[]
    offset = 0
    for (ind, p_col) in enumerate(pfm_num_cols_each)
        push!(pfm_starts, offset)
        offset += p_col
        if ind ≤ length(num_cols_each_d)
            push!(d_starts, offset)
            offset += num_cols_each_d[ind]
        end
    end
    return pfm_starts, d_starts .+ d_ϵ
end


# function obtain_pfm_regions_and_dstarts_d()
# end

function process_coords_mat(coords_mat, weights, d_starts; 
        arrow_shape_scale_ratio = 0.8,
        height_top=2.0, 
        basic_fcn = get_arrow_basic)

    # shift heights
    scaled_heights = weights .* height_top
    scale_height!.(coords_mat, scaled_heights)

    # centering 
    center_pts_x_orig = get_center_point_x.(coords_mat)
    center_pts_y_orig = get_center_point_y.(coords_mat)
    max_center_x = maximum(center_pts_x_orig, dims = 1)
    scale_width_height_by_proportion!.(coords_mat, arrow_shape_scale_ratio)
    center_pts_x = get_center_point_x.(coords_mat)
    center_pts_y = get_center_point_y.(coords_mat)

    right_shift_pts = max_center_x .- center_pts_x
    up_shift_pts = center_pts_y_orig .- center_pts_y
    coords_mat = shift_right.(coords_mat, right_shift_pts)
    coords_mat = shift_up.(coords_mat, up_shift_pts)

    # shift the arrow-shapes upwards
    height_increments = get_height_increments(scaled_heights)
    for i in axes(coords_mat, 1)
        for j in axes(coords_mat, 2)
            up = basic_fcn == get_arrow_basic ? height_increments[i] : (0.5 * height_top)
            coords_mat[i, j] = shift_up.(coords_mat[i, j], up)
        end
    end

    # shift right the arrow-shapes
    for (ind, right_inc) in enumerate(d_starts)
        coords_mat[:, ind] .= shift_right.((coords_mat[:, ind]), right_inc)
    end
    return coords_mat
end


function process_coords_mat_rect(coords_mat, d_starts;
    arrow_shape_scale_ratio = 0.8,
    height_top = 2.0, 
    basic_fcn = get_rectangle_basic
    )

    # shift the arrow-shapes upwards
    for i in axes(coords_mat, 1)
        for j in axes(coords_mat, 2)
            coords_mat[i, j] = shift_up.(coords_mat[i, j], 0.5 * height_top)
        end
    end

    # shift right the arrow-shapes
    for (ind, right_inc) in enumerate(d_starts)
        coords_mat[:, ind] .= shift_right.((coords_mat[:, ind]), right_inc)
    end
    return coords_mat
end


function init_coords_mats(ds_mats; basic_fcn=get_arrow_basic)
    coords_mat = map(
        x -> make_in_between_basic(x; arrow_line_scale = log(x), 
        basic_fcn = basic_fcn),
        ds_mats,
    )
    return coords_mat
end

function make_arrow_shapes(
    ds_mats,
    weights,
    dist_cols::Int,
    pfms;
    arrow_shape_scale_ratio = 0.8,
    height_top = 2.0,
    basic_fcn = get_arrow_basic,
)
    coords_mat = init_coords_mats(ds_mats; basic_fcn = basic_fcn)

    # @info "$coords_mat"
    # scale the width of each arrow-shapes and 
    # get the number of columns for each "column"
    num_cols_each_d = num_col_each_col!(coords_mat, dist_cols)

    pfm_starts, d_starts = obtain_pfm_regions_and_dstarts(pfms, num_cols_each_d)
    # @info "pfm_starts: $pfm_starts d_starts: $d_starts"
    # @info "num_cols_each_d: $num_cols_each_d"

    # @info "d_starts: $d_starts"

    # coords_mat = process_coords_mat(coords_mat, weights, d_starts; 
    #     arrow_shape_scale_ratio = arrow_shape_scale_ratio,
    #     height_top = height_top,
    #     basic_fcn = basic_fcn)

    total_pfm_cols = size.(pfms, 2) |> sum
    total_d_cols = num_cols_each_d |> sum
    return coords_mat, pfm_starts, total_pfm_cols, total_d_cols 
end

function make_rect_shape(pfms, pfm_starts, total_len;
    arrow_shape_scale_ratio = 0.8,
    height_top = 2.0,
    basic_fcn = get_rectangle_basic
    )

    d_starts, d_cols = get_spacers(pfms, pfm_starts, total_len)

    coords_mat = init_coords_mats(d_cols; basic_fcn = basic_fcn)

    coords_mat = process_coords_mat_rect(coords_mat, d_starts; 
        arrow_shape_scale_ratio = arrow_shape_scale_ratio,
        height_top = height_top,
        basic_fcn = basic_fcn)

    total_pfm_cols = size.(pfms, 2) |> sum
    total_d_cols = d_cols |> sum

    return coords_mat, total_pfm_cols, total_d_cols
end



