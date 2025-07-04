
using Revise 

using Plots
using EntroPlots

pfms = [
    [0.1 0.2 0.3 0.4 0.5 0.6;
     0.3 0.2 0.1 0.2 0.1 0.1;
     0.3 0.3 0.3 0.3 0.3 0.2;
     0.3 0.3 0.3 0.1 0.1 0.1],
    [0.1 0.2 0.3 0.4 0.5 0.6;
     0.3 0.2 0.1 0.2 0.1 0.1;
     0.3 0.3 0.3 0.3 0.3 0.2;
     0.3 0.3 0.3 0.1 0.1 0.1],
    [0.4 0.2 0.1 0.1 0.1 0.1;
     0.2 0.2 0.2 0.2 0.2 0.2;
     0.2 0.2 0.2 0.3 0.4 0.4;
     0.2 0.4 0.5 0.4 0.3 0.3],
    [0.4 0.3 0.2 0.1 0.05 0.05;
     0.2 0.3 0.2 0.1 0.1 0.1;
     0.2 0.2 0.3 0.5 0.5 0.5;
     0.2 0.2 0.3 0.3 0.35 0.35],
]

reduce_entropy!.(pfms)

# ds_mat = [2 4 4;]

# # weights = [1]
# weights = [0.05]
starting_indices = [28, 66, 190, 250]
total_len = 290

# offsets_from_start, total_len_adjusted = 
#     EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)

logoplot_with_rect_gaps(
    pfms, starting_indices, total_len; 
    )

# p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, )



# p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, 
# basic_fcn = get_rectangle_basic)


# pfms_offsets = [1, 12, 23, 31] .- 1
pfms_offsets = [6, 15, 23, 31] 
ending_indices = starting_indices .+ size.(pfms, 2) .- 1


@assert all(starting_indices .== sort(starting_indices)) "Starting indices must be sorted."

offsets_from_start, total_len_adjusted =
    get_offset_from_start(starting_indices, pfms, total_len)



offsets_from_start
pfms
total_len



xtick_labels = EntroPlots.make_xtick_labels(
    pfms, offsets_from_start, starting_indices, total_len_adjusted)

logoplot_with_rect_gaps(
    pfms, offsets_from_start, starting_indices, total_len_adjusted
    )



total_len = 360
total_len = 360
# compute the offset




xtick_labels = EntroPlots.make_xtick_labels(
    pfms, pfms_offsets, starting_indices, total_len)

logoplot_with_rect_gaps(
    pfms, pfms_offsets, starting_indices, total_len)





pfms


size.(pfms)


function check_valid_indexing(pfms, indices)
    @assert length(pfms) == length(indices) "The number of PFMs should match the number of indices provided."
    for i = 1:(length(pfms)-1)
        i_cols = size(pfms[i],2)
        i_start = indices[i]
        if i_start + i_cols > indices[i+1]
            error("PFM $(i) with start index $(i_start) 
                of column count $(i_cols) exceeds the 
                    next PFM's start index $(indices[i+1]).")
        end
    end
    return true
end


check_valid_indexing(pfms, indices) 



using DataFrames

df = DataFrame(a = 1:5, b = rand(5))

# Keep only rows where :a > 2 (i.e., remove others)
filter!(:a => x -> x .> 2, df)






display(p)


pfm =  [0.02  1.0  0.98  0.0   0.0   0.0   0.98  0.0   0.18  1.0
        0.98  0.0  0.02  0.19  0.0   0.96  0.01  0.89  0.03  0.0
        0.0   0.0  0.0   0.77  0.01  0.0   0.0   0.0   0.56  0.0
        0.0   0.0  0.0   0.04  0.99  0.04  0.01  0.11  0.23  0.0]
background = [0.25, 0.25, 0.25, 0.25]

highlighted_regions1=[4:8]
logoplot_with_highlight(pfm, background, highlighted_regions1)