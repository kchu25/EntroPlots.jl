module EntroPlots

using Plots


include("constants/letters.jl")
include("constants/rectangles.jl")
include("constants/glyphs.jl")
include("constants/palettes.jl")
include("constants/plot_params.jl")


include("helpers.jl")
include("plot_nothing.jl")
include("plot_logo.jl")


# include("plot_logo_w_crosslinks.jl")

include("old/helpers_shape.jl")
include("old/helpers_spacers.jl")
include("old/logo_rect_helpers.jl")
include("old/plot_logo_w_arr_gaps.jl")


export logoplot,
    logoplot_with_highlight,
    save_logoplot,
    reduce_entropy!,
    get_rectangle_basic,
    logoplot_with_rect_gaps

# export LogoPlot,
#     logoplotwithcrosslink,
#     logoplot_with_highlight_crosslink,
#     save_crosslinked_logoplot,
#     logoplot_with_arrow_gaps,
#     save_logo_w_arrows,
#     NothingLogo,
#     logoplot_with_rect_gaps

end
