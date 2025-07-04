module EntroPlots

using Plots

include("const.jl")
include("const_glyphs.jl")
include("helpers.jl")
include("helpers_shape.jl")
include("helpers_spacers.jl")
include("plot_logo.jl")
include("plot_logo_w_crosslinks.jl")
include("plot_nothing.jl")
include("logo_rect_helpers.jl")
include("plot_logo_w_arr_gaps.jl")


export LogoPlot,
    logoplotwithcrosslink,
    logoplot_with_highlight,
    logoplot_with_highlight_crosslink,
    save_logoplot,
    save_crosslinked_logoplot,
    logoplot_with_arrow_gaps,
    save_logo_w_arrows,
    reduce_entropy!,
    NothingLogo,
    get_rectangle_basic,
    logoplot_with_rect_gaps




end
