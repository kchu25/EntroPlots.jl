ic_height_uniform(x; bg = 0.25, ϵ = 1e-20) = x * log2((x + ϵ) / bg)
ic_height(col, bg; ϵ = 1e-30) = col .* log2.((col .+ ϵ) ./ bg)
ic_height_here(col; background=[0.25 for _ = 1:4]) = sum(ic_height(col, background))

_width_factor_(num_cols) = exp(-0.5*num_cols+7)+25

#=
Group the consecutive integers in a vector into UnitRange{Int}
    vec = [4, 10, 11, 12, 13]
    grouped_ranges = group_to_ranges(vec)
    println(grouped_ranges)  # Output: [4:4, 10:13]
=#
function group_to_ranges(vec::Vector{Int})
    ranges = UnitRange{Int}[]
    start_idx = vec[1]

    for i in 2:length(vec)
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

function is_overlapping(r1::UnitRange{T}, r2::UnitRange{T}) where T <: Integer
    max(r1.start, r2.start) ≤ min(r1.stop, r2.stop)
end

# Function to reduce entropy in each column
function reduce_entropy!(pfm_protein; factor=10)
    for j in axes(pfm_protein, 2)
        # Increase the dominance of the highest value in each column
        max_value = maximum(pfm_protein[:, j])
        pfm_protein[:, j] .= pfm_protein[:, j] .^ factor
        pfm_protein[:, j] ./= sum(pfm_protein[:, j])  # Normalize the column
    end
end