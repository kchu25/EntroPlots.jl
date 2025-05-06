function freq2xy_protein(pfm;
                         background=fill(1/20, 20),
                         beta=1.0,
                         logo_x_offset=0.0,
                         logo_y_offset=0.0,
                         alphabet_coords=ALPHABET_GLYPHS,
                         very_small_perturb=1e-5 .* rand(20),
                         aa_order=protein_letters)
    all_coords = []
    for (j, aa) in enumerate(aa_order)
        xs, ys = Float64[], Float64[]
        glyph = get(alphabet_coords, aa, BASIC_RECT)
        for (xoffset, col) in enumerate(eachcol(pfm))
            col_view = @view col[1:20]
            ic_height = ic_height_here(col_view; background=background)
            adjusted_height = ic_height .* col_view .+ very_small_perturb
            yoffset = sum(adjusted_height[adjusted_height .< adjusted_height[j]])
            push!(xs, ((beta * 1.2) .* glyph.x .+ (1 / (beta * 0.9)) * 0.35 .+ xoffset .+ (logo_x_offset - 1))...)
            push!(xs, NaN)
            push!(ys, (adjusted_height[j] .* glyph.y .+ yoffset .+ logo_y_offset)...)
            push!(ys, NaN)
        end
        push!(all_coords, (aa, (; xs, ys)))
    end
    return all_coords
end