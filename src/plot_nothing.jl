
function get_margin(num_cols)
    if num_cols < 30
        return 225Plots.mm
    elseif 30 ≤ num_cols < 40
        return 325Plots.mm
    elseif 40 ≤ num_cols < 50
        return 425Plots.mm
    elseif 50 ≤ num_cols < 60
        return 525Plots.mm
    else
        return 625Plots.mm
    end
end

@userplot NothingLogo
@recipe function f(
    data::NothingLogo;
    xaxis = false,
    yaxis = false,
    xt = xtickfontsize,
    yt = ytickfontsize,
    logo_x_offset = 0.0,
    logo_y_offset = 0.0,
    setup_off = false,
    beta = 1.0,
    dpi = 65,
    protein = false,
    crosslink = false,
    xaxis_on = true,
    tight = false,
    xtick_labels = nothing,
)

    logo_size_height = crosslink ? logo_height + 115 : logo_height
    xaxis = xaxis_on
    xaxis = crosslink ? false : true
    yaxis = crosslink ? false : true
    # _margin_ = crosslink ? 25Plots.mm : margin;
    # _margin_ = crosslink ? 525Plots.mm : margin;
    num_cols = data.args[1]
    _margin_ = get_margin(num_cols)
    if !setup_off
        xaxis --> xaxis
        yaxis --> yaxis
        ylims -->  (0, protein ? 4.32 : ylim_max)
        # (crosslink ? -crosslink_stretch_factor2 : 0, ylim_max)
        xlims_here = !tight ? (xlim_min, num_cols + 2) : (0.5, num_cols + 0.5)
        xlims --> xlims_here
        # xlims --> (xlim_min, num_cols+1)        
        logo_size = 2.5 .* (_width_factor_(num_cols) * num_cols, logo_height)
        # logo_size = (_width_factor_(num_cols)*num_cols, logo_size_height) .* 2.5
        ticks --> :native
        yticks --> (protein ? yticks_protein : yticks) # Ensure ticks are generated
        ytickfontcolor --> :black
        ytick_direction --> :out
        # ytickfontsize --> ytickfontsize
        yminorticks --> yminorticks
        ytickfont --> font(logo_font_size, logo_font)
        xtickfontcolor --> :black
        # xticks --> 1:1:num_cols
        ytickfontsize --> yt
        xtickfontsize --> xt
        # xtickfontsize --> xtickfontsize
        xaxis && (xaxis --> xaxis)
        yaxis && (yaxis --> yaxis)
        legend --> false
        tickdir --> :out
        grid --> false
        margin --> _margin_
        # thickness_scaling --> thickness_scaling
        thickness_scaling --> 0.075
        size --> logo_size
        framestyle --> :zerolines
        dpi --> dpi
    end
    tick_range = 1:1:data.args[1] 
    xticks_label = isnothing(xtick_labels) ? tick_range : (tick_range, xtick_labels)
    # xticks --> tick_range
    # xticks --> 
    # xticks --> (1:1:data.args[1], fill("", data.args[1]))
    xticks --> xticks_label
end
