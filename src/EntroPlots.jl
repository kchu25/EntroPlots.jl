module EntroPlots

using Plots

# Constants
include("constants/letters.jl")
include("constants/rectangles.jl")
include("constants/glyphs.jl")
include("constants/palettes.jl")
include("constants/plot_params.jl")

# Core
include("helpers.jl")
include("plot_nothing.jl")
include("plot_logo.jl")

# Legacy gap/spacer plotting (kept for downstream packages)
include("old/helpers_shape.jl")
include("old/helpers_spacers.jl")
include("old/logo_rect_helpers.jl")
include("old/plot_logo_w_arr_gaps.jl")

export logoplot,
    logoplot_with_highlight,
    save_logoplot,
    reduce_entropy!,
    get_rectangle_basic,
    logoplot_with_rect_gaps,
    save_logo_with_rect_gaps,
    filter_counts_by_reference,
    count_fragments,
    apply_count_filter

end
