
using Revise 


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


ds_mat = [2 4 4;]

# weights = [1]
weights = [0.05]




p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, )



p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, 
basic_fcn = get_rectangle_basic)


pfms_offsets = [1, 12, 23, 31] .- 1
pfms_offsets = [6, 15, 23, 31] 

logoplot_with_rect_gaps(
    pfms, pfms_offsets, 45,)





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










display(p)


pfm =  [0.02  1.0  0.98  0.0   0.0   0.0   0.98  0.0   0.18  1.0
        0.98  0.0  0.02  0.19  0.0   0.96  0.01  0.89  0.03  0.0
        0.0   0.0  0.0   0.77  0.01  0.0   0.0   0.0   0.56  0.0
        0.0   0.0  0.0   0.04  0.99  0.04  0.01  0.11  0.23  0.0]
background = [0.25, 0.25, 0.25, 0.25]

highlighted_regions1=[4:8]
logoplot_with_highlight(pfm, background, highlighted_regions1)