
#=
Check if the indices provided for the PFMs are valid.
    pfms: Vector of frequency matrices
    indices: Vector of starting indices (positions) for each pfm

    The indices should not be in the range covered by the previous PFM.
=#
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
end

#=
Check if the indices and PFMs exceed the total length.
=#
function check_bounds(pfms, indices, total_len)
    @assert all(map((x,y)->x+size(y,2)-1 ≤ total_len, indices, pfms)) "Indices and PFMs exceed total length."
end

#=
Given pfms, indices, and a total_len parameter
    return the complement of the indices.
    
=#

function get_complement(pfms, pfms_offsets, total_len)
    num_cols_each_d = Int[]
    d_start = Float64[]
    pfm_cols = size.(pfms, 2)
    # [(start, end) for each pfm]
    pfm_start_inds = pfms_offsets .+ 1
    start_and_ends = [(i, i+c-1) for (i,c) in zip(pfm_start_inds, pfm_cols)]

    # get the spacers 
    start_inds =  pushfirst!([i[2]+1 for i in start_and_ends], 1)
    end_inds = push!([i[1]-1 for i in start_and_ends], total_len)

    @info "Start indices: $(start_inds), End indices: $(end_inds)"
    for (s, e) in zip(start_inds, end_inds)
        push!(num_cols_each_d, e - s + 1)
        push!(d_start, s)
    end
    # obtain the mask for the spacers
    mask = map(x->x>0, num_cols_each_d)
    d_cols = num_cols_each_d[mask]
    d_starts = d_start[mask]
    return d_cols, d_starts
end

#=
Get the spacers for a list of pfms and list of each of its starting indices.
    pfms: Vector of frequency matrices
    indices: Vector of starting indices (positions) for each pfm
    total_len: Total length of all the available positions
=#
function get_spacers(pfms, indices::Vector{Int}, total_len::Int; inc=0.0)
    # check the indices are valid
    check_valid_indexing(pfms, indices)
    check_bounds(pfms, indices, total_len)

    d_cols, d_starts = get_complement(pfms, indices, total_len)
    
    # to satisfy the requirements of the arrow shapes
    # d_starts .+= inc

    # @info "Spacers starts: $(d_starts), Spacers cols: $(d_cols)"
    d_cols = reshape(d_cols, (1, length(d_cols)))
    return d_starts, d_cols
end

# d_starts, d_cols = get_spacers(pfms, indices, 28)

# intervals = [(1, 3), (5, 9)]
# len = 13
# exclusive_complement(intervals, len)
# println())  # [(4, 4), (10, 13)]