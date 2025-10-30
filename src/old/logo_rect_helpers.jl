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

# Round up log2, but ensure minimum of 2 for any gap > 0
# This ensures small gaps (1-3 positions) are clearly visible
# A gap of 1 display position is often too thin to see, so we use minimum of 2
function inc_round_up(x)
    if x == 0
        return 0
    else
        return max(2, Int(ceil(log2_or_0(x))))
    end
end

#=
    starting_indices: starting indices of each PFM in the motif
    pfms: list of pfms in the motif
    total_len: length of the motif (i.e. MSA sequence length)

    Get the offsets from the start of the logo for each PFM
        1. compute the increments in between the PFMs
        2. log transform each increment and round up each of them
           - IMPORTANT: Ensure minimum of 1 for any gap > 0 so small gaps remain visible
           - Without this, gaps of 1-3 positions would be compressed to 0 or become invisible
        3. compute the offsets from the start of the logo
        4. return the offsets as a vector
        
    Example:
        - Gap of 1 position: log2(1) = 0 → max(1, ceil(0)) = 1 (visible)
        - Gap of 2 positions: log2(2) = 1 → max(1, ceil(1)) = 1 (visible)
        - Gap of 3 positions: log2(3) = 1.58 → max(1, ceil(1.58)) = 2 (visible)
        - Gap of 0 positions: returns 0 (no gap, consecutive PFMs)
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

#=
Filter PFMs by removing columns that match the reference.
Returns fragmented PFMs and their adjusted starting indices.

Args:
    pfms: Vector of PFMs
    starting_indices: Starting position of each PFM
    reference_pfms: Vector of reference PFMs (BitMatrix, one-hot encoded)
    tolerance: Maximum allowed deviation from reference (default 0.05)

Returns:
    (filtered_pfms, filtered_indices, filtered_refs)
=#
function filter_pfms_by_reference(
    pfms::Vector, 
    starting_indices::Vector{Int},
    reference_pfms::Vector{BitMatrix};
    tolerance::Float64 = 0.05
)
    # Validate reference PFMs (each column must have exactly one entry = 1)
    for (idx, ref) in enumerate(reference_pfms)
        for col in eachcol(ref)
            if sum(col) != 1
                error("Reference PFM $idx has invalid column: each column must have exactly one entry = 1 (one-hot encoded)")
            end
        end
    end
    
    filtered_pfms = Vector{Matrix{Float64}}()
    filtered_indices = Vector{Int}()
    filtered_refs = Vector{BitMatrix}()
    
    for (pfm_idx, (pfm, start_pos, ref)) in enumerate(zip(pfms, starting_indices, reference_pfms))
        @assert size(pfm) == size(ref) "PFM and reference must have same dimensions"
        
        # Find columns that DON'T match reference
        keep_cols = Bool[]
        for col_idx in 1:size(pfm, 2)
            pfm_col = pfm[:, col_idx]
            ref_col = ref[:, col_idx]
            
            # Get the reference nucleotide/amino acid (the one with value 1)
            ref_nt_idx = findfirst(ref_col)
            
            # Check if PFM column matches reference within tolerance
            # Match means: the reference nucleotide has high frequency (> 1 - tolerance)
            # and all others have low frequency (< tolerance)
            matches = (pfm_col[ref_nt_idx] > (1.0 - tolerance)) &&
                     all(pfm_col[i] < tolerance for i in 1:length(pfm_col) if i != ref_nt_idx)
            
            push!(keep_cols, !matches)  # Keep if it DOESN'T match
        end
        
        # Fragment the PFM based on keep_cols
        if !any(keep_cols)
            # All columns match reference - skip this entire PFM
            continue
        end
        
        # Find contiguous regions of kept columns
        regions = Vector{UnitRange{Int}}()
        in_region = false
        region_start = 0
        
        for i in 1:length(keep_cols)
            if keep_cols[i] && !in_region
                # Start new region
                region_start = i
                in_region = true
            elseif !keep_cols[i] && in_region
                # End region
                push!(regions, region_start:(i-1))
                in_region = false
            end
        end
        
        # Handle last region
        if in_region
            push!(regions, region_start:length(keep_cols))
        end
        
        # Create fragments for each region
        for region in regions
            fragment_pfm = pfm[:, region]
            fragment_ref = ref[:, region]
            fragment_start = start_pos + first(region) - 1
            
            push!(filtered_pfms, fragment_pfm)
            push!(filtered_indices, fragment_start)
            push!(filtered_refs, fragment_ref)
        end
    end
    
    return filtered_pfms, filtered_indices, filtered_refs
end


