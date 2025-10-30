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

EntroPlots.logoplot_with_rect_gaps(
    pfms, starting_indices, total_len; 
    )

# p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, )



pfms = [
    [0.1;
     0.3;
     0.3;
     0.3],
    [0.5; 
     0.1; 
     0.3; 
     0.1],
    [0.1;
     0.2;
     0.4;
     0.3],
    [0.4;
     0.2;
     0.2;
     0.2],
]




reduce_entropy!(pfms)

# ds_mat = [2 4 4;]

# # weights = [1]
# weights = [0.05]
starting_indices = [28, 66, 190, 250]
total_len = 290

# offsets_from_start, total_len_adjusted = 
#     EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)

EntroPlots.logoplot_with_rect_gaps(
    pfms, starting_indices, total_len; 
    )












# p = logoplot_with_arrow_gaps(pfms, ds_mat, weights; given_num_cols=12, 
# basic_fcn = get_rectangle_basic)


# pfms_offsets = [1, 12, 23, 31] .- 1
pfms_offsets = [6, 15, 23, 31] 
ending_indices = starting_indices .+ size.(pfms, 2) .- 1


@assert all(starting_indices .== sort(starting_indices)) "Starting indices must be sorted."

offsets_from_start, total_len_adjusted =
    EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)



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





# Answer: To provide a reference and plot with 2 colors for deviating letters:
#
# 1. Create reference matrices as BitMatrix (one-hot encoded) for each PFM:
#    reference_pfms = [BitMatrix for each position in your PFMs]
#    Each reference_pfm[i,j] = 1 if position j should have letter i, 0 otherwise
#
# 2. Pass reference_pfms to logoplot_with_rect_gaps:
#    logoplot_with_rect_gaps(pfms, starting_indices, total_len; reference_pfms=reference_pfms)
#
# Example:
# For a 4x6 PFM (4 letters, 6 positions), if reference sequence is "ACGTAG":
ref_pfm1 = BitMatrix(zeros(4, 6))
ref_pfm1[1,1] = 1  # A at position 1
ref_pfm1[2,2] = 1  # C at position 2  
ref_pfm1[3,3] = 1  # G at position 3
ref_pfm1[4,4] = 1  # T at position 4
ref_pfm1[1,5] = 1  # A at position 5
ref_pfm1[3,6] = 1  # G at position 6

# Define ref_pfm2 for the second PFM (same dimensions as pfms[2])
ref_pfm2 = BitMatrix(zeros(4, 6))
ref_pfm2[2,1] = 1  # C at position 1
ref_pfm2[3,2] = 1  # G at position 2
ref_pfm2[4,3] = 1  # T at position 3
ref_pfm2[1,4] = 1  # A at position 4
ref_pfm2[2,5] = 1  # C at position 5
ref_pfm2[3,6] = 1  # G at position 6

# Define ref_pfm3 for the third PFM (same dimensions as pfms[3])
ref_pfm3 = BitMatrix(zeros(4, 6))
ref_pfm3[1,1] = 1  # A at position 1
ref_pfm3[4,2] = 1  # T at position 2
ref_pfm3[2,3] = 1  # C at position 3
ref_pfm3[3,4] = 1  # G at position 4
ref_pfm3[3,5] = 1  # G at position 5
ref_pfm3[3,6] = 1  # G at position 6

# Define ref_pfm4 for the fourth PFM (same dimensions as pfms[4])
ref_pfm4 = BitMatrix(zeros(4, 6))
ref_pfm4[1,1] = 1  # A at position 1
ref_pfm4[2,2] = 1  # C at position 2
ref_pfm4[3,3] = 1  # G at position 3
ref_pfm4[3,4] = 1  # G at position 4
ref_pfm4[3,5] = 1  # G at position 5
ref_pfm4[3,6] = 1  # G at position 6

# Create similar reference matrices for all your PFMs
reference_pfms = [ref_pfm1, ref_pfm2, ref_pfm3, ref_pfm4]  # one for each PFM

# Letters matching reference will be colored normally, deviating letters will be lightgrey
logoplot_with_rect_gaps(pfms, starting_indices, total_len; reference_pfms=reference_pfms)

# Example usage of save_logo_with_rect_gaps function:
# This function saves the plot generated by logoplot_with_rect_gaps to a file

# Basic usage without reference
save_logo_with_rect_gaps(pfms, starting_indices, total_len, "logo_rect_gaps.png")

# Usage with reference sequences for 2-color highlighting
save_logo_with_rect_gaps(
    pfms, starting_indices, total_len, "logo_rect_gaps_with_ref.png";
    reference_pfms = reference_pfms,
    dpi = 150,
    uniform_color = true
)

# Example with rotated x-axis labels (45 degrees)
logoplot_with_rect_gaps(pfms, starting_indices, total_len; 
    reference_pfms = reference_pfms,
    xrotation = 25,  # Rotate x-tick labels by 45 degrees
    uniform_color = false
)

# Save with rotated labels
save_logo_with_rect_gaps(
    pfms, starting_indices, total_len, "logo_rotated_labels.png";
    reference_pfms = reference_pfms,
    xrotation = 25,  # Rotate x-tick labels by 90 degrees (vertical)
    dpi = 150
)













# Letters matching reference will be colored normally, deviating letters will be lightgrey
logoplot_with_rect_gaps(pfms, starting_indices, total_len; reference_pfms=reference_pfms)


# Example with rotated x-axis labels (45 degrees)
logoplot_with_rect_gaps(pfms, starting_indices, total_len; 
    reference_pfms = reference_pfms,
    xrotation = 25,  # Rotate x-tick labels by 45 degrees
    uniform_color = true
)