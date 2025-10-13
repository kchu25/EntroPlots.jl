
#=
    Get the increments: 
        the spacing in between all the PFMs
        e.g. if two pfms occupy 4:5  8:9, and 
        the total length is 13, then return a 
        vector of (3, 2, 4) because
            3: the space in between the first and the start (i.e. occupies 1:3)
            2: the space in between the first and the second (i.e. occupies 6:7)
            4: the space in between the second and the end (i.e. occupies 10:13)                
=#

function get_display_increments(starting_indices, pfms, total_len)    
    ending_indices = starting_indices .+ size.(pfms, 2) .- 1

    first_inc = starting_indices[1]-1
    last_inc = total_len - ending_indices[end] 

    increments = vcat(first_inc, 
        (@view starting_indices[2:end]) .- (@view ending_indices[1:end-1]) .- 1,
        last_inc)

    @assert (increments |> sum) + sum(size.(pfms, 2)) == total_len "The total length $(total_len) does not match the sum of PFMs and increments."
    @assert all(increments .≥ 0) "All increments must be non-negative."
    return increments
end

function log2_or_0(x::Integer)
    @assert x ≥ 0 "The input has to be non-negative"
    return x == 0 ? 0 : log2(x)
end

inc_round_up(x) = Int(ceil(log2_or_0(x)))

#=
    starting_indices: starting indices of each PFM in the motif
    pfms: list of pfms in the motif
    total_len: length of the motif (i.e. MSA sequence length)

    Get the offsets from the start of the logo for each PFM
        1. compute the increments in between the PFMs
        2. log transform each increment and round up each of them
        3. compute the offsets from the start of the logo
        4. return the offsets as a vector
=#
function get_offset_from_start(starting_indices, pfms, total_len)

    incs = get_display_increments(starting_indices, pfms, total_len)    
    incs = inc_round_up.(incs)    
    pfm_lens = size.(pfms, 2)
    offsets_from_start = Vector{Int}(undef, (length(pfms),));

    for i in 1:length(pfms)        
        offsets_from_start[i] = sum(incs[1:i]) + sum(pfm_lens[1:i-1])
    end

    total_len_adjusted = sum(incs)+ sum(pfm_lens)

    return offsets_from_start, total_len_adjusted
end



##############################

#= 
    Each PFM has its own spacings, characterized by start:end by UnitRange.
    Check if the UnitRanges overlap. 
=#

function get_ranges_pfm(pfms, starting_indices)
    @assert all(starting_indices .== sort(starting_indices)) "Starting indices must be sorted."
    pfm_lens = size.(pfms, 2)
    pfm_ranges = [s:s+pfm_lens[index]-1 
        for (index, s) in enumerate(starting_indices)]
    return pfm_ranges
end

function ranges_overlap(r1, r2)
    a, b = r1.start, r1.stop
    c, d = r2.start, r2.stop
    return max(a, c) ≤ min(b, d)
end

function check_overlap(pfms, starting_indices)
    pfm_ranges = get_ranges_pfm(pfms, starting_indices)
    for i in 1:(length(pfm_ranges)-1)
        for j in (i+1):length(pfm_ranges)
            if ranges_overlap(pfm_ranges[i], pfm_ranges[j])
                error("PFM ranges $(pfm_ranges[i]) and $(pfm_ranges[j]) overlap.")
            end
        end
    end
    return true
end


