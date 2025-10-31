ic_height_uniform(x; bg = 0.25, ϵ = 1e-20) = x * log2((x + ϵ) / bg)
ic_height(col, bg; ϵ = 1e-30) = col .* log2.((col .+ ϵ) ./ bg)
ic_height_here(col; background = [0.25 for _ = 1:4]) = sum(ic_height(col, background))

_width_factor_(num_cols) = exp(-0.5 * num_cols + 7) + 25

#=
Group the consecutive integers in a vector into UnitRange{Int}
    vec = [4, 10, 11, 12, 13]
    grouped_ranges = group_to_ranges(vec)
    println(grouped_ranges)  # Output: [4:4, 10:13]
=#
function group_to_ranges(vec::Vector{Int})
    ranges = UnitRange{Int}[]
    start_idx = vec[1]

    for i = 2:length(vec)
        if vec[i] != vec[i-1] + 1
            push!(ranges, start_idx:vec[i-1])
            start_idx = vec[i]
        end
    end
    push!(ranges, start_idx:vec[end])
    return ranges
end

#=
e.g. [1:3, 7:10]; with a input of length 13, 
returns a complement of that vector, i.e. [4:6, 11:13]

complement_ranges([1:3, 7:10], 13)
> [4:6, 11:13]
=#

const place_folder_unit_range_vec = UnitRange{Int}[]

function complement_ranges(ranges::Vector{UnitRange{Int}}, len::Int)
    # Flatten the ranges into a sorted vector of individual indices
    complement_indices = setdiff(collect(1:len), reduce(union, (collect.(ranges))))
    if isempty(complement_indices)
        return place_folder_unit_range_vec
    end
    return group_to_ranges(complement_indices)
end

function is_overlapping(r1::UnitRange{T}, r2::UnitRange{T}) where {T<:Integer}
    max(r1.start, r2.start) ≤ min(r1.stop, r2.stop)
end

# Function to reduce entropy in each column
function reduce_entropy!(pfm_protein; factor = 10)
    for j in axes(pfm_protein, 2)
        # Increase the dominance of the highest value in each column
        max_value = maximum(pfm_protein[:, j])
        pfm_protein[:, j] .= pfm_protein[:, j] .^ factor
        pfm_protein[:, j] ./= sum(pfm_protein[:, j])  # Normalize the column
    end
end

"""
    dot_product(a, b)

Compute dot product of two vectors without LinearAlgebra dependency.
"""
dot_product(a, b) = sum(a .* b)

"""
    filter_counts_by_reference(counts, ref; tol=1e-9)

Keep only columns where dot(col, ref_col) ≠ sum(col).
When equal, the column has single nonzero entry matching reference → remove it.
Returns indices of columns to keep.
"""
function filter_counts_by_reference(counts::AbstractMatrix, ref::BitMatrix; tol=1e-9)
    keep = Int[]
    for i in 1:size(counts, 2)
        col = view(counts, :, i)
        ref_col = view(ref, :, i)
        if abs(dot_product(col, ref_col) - sum(col)) > tol
            push!(keep, i)
        end
    end
    return keep
end

"""
    count_fragments(count_matrices, reference_pfms; tol=1e-9)

Returns number of contiguous fragments after filtering count matrices by reference.
"""
function count_fragments(count_matrices::Vector, reference_pfms::Vector{BitMatrix}; tol=1e-9)
    total = 0
    for (c, r) in zip(count_matrices, reference_pfms)
        keep = filter_counts_by_reference(c, r; tol=tol)
        if !isempty(keep)
            total += length(group_to_ranges(keep))
        end
    end
    return total
end

"""
    apply_count_filter(count_matrices, starting_indices, reference_pfms; tol=1e-9)

Filter count matrices by reference, returning new matrices with only non-matching columns.
Updates starting indices to reflect new fragment positions.
"""
function apply_count_filter(count_matrices::Vector, starting_indices::Vector{Int}, 
                           reference_pfms::Vector{BitMatrix}; tol=1e-9)
    new_counts, new_starts, new_refs = [], Int[], BitMatrix[]
    
    for (counts, start, ref) in zip(count_matrices, starting_indices, reference_pfms)
        keep = filter_counts_by_reference(counts, ref; tol=tol)
        isempty(keep) && continue
        
        # Split into fragments
        for range in group_to_ranges(keep)
            push!(new_counts, view(counts, :, range))
            push!(new_starts, start + first(range) - 1)
            push!(new_refs, view(ref, :, range))
        end
    end
    
    new_counts, new_starts, new_refs
end
