using Test
using EntroPlots
using Plots
using Random: seed!

@testset "Gap visibility and rendering" begin
    # Test the inc_round_up function directly
    inc_round_up = EntroPlots.inc_round_up
    
    @testset "inc_round_up function" begin
        @test inc_round_up(0) == 0  # No gap
        @test inc_round_up(1) == 2  # 1 position gap - minimum 2 for visibility
        @test inc_round_up(2) == 2  # 2 position gap - minimum 2 for visibility
        @test inc_round_up(3) == 2  # 3 position gap
        @test inc_round_up(4) == 2  # 4 position gap
        @test inc_round_up(7) == 3  # 7 position gap
        @test inc_round_up(8) == 3  # 8 position gap
        @test inc_round_up(16) == 4 # 16 position gap
    end
    
    @testset "get_display_increments function" begin
        # Create simple test PFMs
        pfm1 = ones(4, 9) ./ 4  # 9 positions
        pfm2 = ones(4, 9) ./ 4  # 9 positions
        pfms = [pfm1, pfm2]
        
        # Test case 1: Gap of 2 positions (positions 48-49)
        starting_indices = [39, 50]
        total_len = 60
        
        incs = EntroPlots.get_display_increments(starting_indices, pfms, total_len)
        @test length(incs) == 3  # [before first PFM, between PFMs, after last PFM]
        @test incs[1] == 38  # Positions 1-38
        @test incs[2] == 2   # Gap of 2 positions (48-49)
        @test incs[3] == 2   # Positions 59-60
        
        # Test case 2: Gap of 1 position
        starting_indices2 = [10, 20]  # PFM1: 10-18, Gap: 19, PFM2: 20-28
        total_len2 = 30
        
        incs2 = EntroPlots.get_display_increments(starting_indices2, pfms, total_len2)
        @test incs2[1] == 9   # Positions 1-9
        @test incs2[2] == 1   # Gap of 1 position
        @test incs2[3] == 2   # Positions 29-30
    end
    
    @testset "get_offset_from_start function" begin
        pfm1 = ones(4, 9) ./ 4
        pfm2 = ones(4, 9) ./ 4
        pfms = [pfm1, pfm2]
        
        # Test with 2-position gap
        starting_indices = [39, 50]
        total_len = 60
        
        offsets, total_adjusted = EntroPlots.get_offset_from_start(starting_indices, pfms, total_len)
        
        @test length(offsets) == 2
        @test offsets[1] >= 1  # First PFM should have some offset
        @test offsets[2] > offsets[1] + 9  # Second PFM should be after first + gap
        @test total_adjusted > 0  # Total should be positive
    end
    
    @testset "Integration test: logoplot_with_rect_gaps" begin
        # Create count matrices (not normalized)
        counts1 = [25 30 20 10 40 50 30 20 10;
                   25 20 30 40 20 10 20 30 40;
                   25 30 20 30 20 20 30 20 30;
                   25 20 30 20 20 20 20 30 20]
        
        counts2 = copy(counts1)
        count_matrices = [counts1, counts2]
        
        # Test various gap sizes
        test_cases = [
            (starting_indices=[10, 20], total_len=30, gap_size=1, desc="1 position gap"),
            (starting_indices=[10, 21], total_len=30, gap_size=2, desc="2 position gap"),
            (starting_indices=[39, 50], total_len=60, gap_size=2, desc="2 position gap (original)"),
            (starting_indices=[10, 19], total_len=27, gap_size=0, desc="No gap"),
        ]
        
        for tc in test_cases
            # This should not throw an error
            p = EntroPlots.logoplot_with_rect_gaps(
                count_matrices, tc.starting_indices, tc.total_len;
                filter_by_reference = false
            )
            @test p !== nothing
            
            # Normalize for offset calculation
            pfms_test = [c ./ sum(c, dims=1) for c in count_matrices]
            offsets, _ = EntroPlots.get_offset_from_start(tc.starting_indices, pfms_test, tc.total_len)
            display_gap = offsets[2] - offsets[1] - 9
            
            if tc.gap_size > 0
                @test display_gap >= 1  # Gap should be visible
            else
                @test display_gap == 0  # No gap expected
            end
        end
    end
    
    @testset "Protein mode support" begin
        # Create protein count matrices (20 amino acids)
        counts_protein1 = rand(1:100, 20, 10)
        counts_protein2 = rand(1:100, 20, 10)
        
        # Test protein mode
        p = EntroPlots.logoplot_with_rect_gaps(
            [counts_protein1, counts_protein2],
            [1, 13],
            25;
            protein = true,
            filter_by_reference = false
        )
        @test p !== nothing
    end
    
    @testset "Reference coloring support" begin
        counts1 = rand(1:100, 4, 9)
        counts2 = rand(1:100, 4, 9)
        
        # Create reference PFMs
        ref1 = falses(4, 9)
        ref1[1, 3] = true  # Mark A at position 3
        
        ref2 = falses(4, 9)
        ref2[2, 5] = true  # Mark C at position 5
        
        # Test with reference but no filtering
        p = EntroPlots.logoplot_with_rect_gaps(
            [counts1, counts2],
            [1, 12],
            22;
            reference_pfms = [ref1, ref2],
            filter_by_reference = false
        )
        @test p !== nothing
    end
end

@testset "Count Matrix Filtering feature" begin
    @testset "Basic count filtering" begin
        # Create count matrices
        counts1 = [100 50 50;
                   0   50 50;
                   0   0  0;
                   0   0  0]
        
        ref1 = BitMatrix([1 0 0;
                          0 1 0;
                          0 0 1;
                          0 0 0])
        
        # Column 1: [100,0,0,0] · [1,0,0,0] = 100 = sum(100) → remove
        # Column 2: [50,50,0,0] · [0,1,0,0] = 50 ≠ sum(100) → keep
        # Column 3: [50,50,0,0] · [0,0,1,0] = 0 ≠ sum(100) → keep
        
        keep = EntroPlots.filter_counts_by_reference(counts1, ref1)
        @test keep == [2, 3]
        
        # Apply filter
        filtered_counts, filtered_starts, filtered_refs = EntroPlots.apply_count_filter(
            [counts1], [100], [ref1]
        )
        
        @test length(filtered_counts) == 1
        @test size(filtered_counts[1], 2) == 2
        @test filtered_starts[1] == 101  # 100 + 2 - 1
    end
    
    @testset "Integration with logoplot_with_rect_gaps" begin
        # Create count matrices with some columns matching reference
        counts1 = [100 50 50 20;
                   0   50 50 10;
                   0   0  0  70;
                   0   0  0  0]
        
        ref1 = BitMatrix([1 0 0 0;
                          0 1 0 0;
                          0 0 1 1;
                          0 0 0 0])
        
        # Test with filtering enabled (default)
        p1 = EntroPlots.logoplot_with_rect_gaps(
            [counts1], [1], 10;
            reference_pfms = [ref1],
            filter_by_reference = true
        )
        @test p1 !== nothing
        
        # Test with filtering disabled
        p2 = EntroPlots.logoplot_with_rect_gaps(
            [counts1], [1], 10;
            reference_pfms = [ref1],
            filter_by_reference = false
        )
        @test p2 !== nothing
    end
    
    @testset "Protein mode with count filtering" begin
        # Create protein count matrix (20 amino acids)
        counts_protein = zeros(Int, 20, 6)
        
        # Columns 1-2: match reference
        counts_protein[:, 1] = vcat([100], zeros(Int, 19))
        counts_protein[:, 2] = vcat([100], zeros(Int, 19))
        
        # Columns 3-4: don't match (distributed)
        counts_protein[:, 3] = fill(5, 20)
        counts_protein[:, 4] = fill(5, 20)
        
        # Columns 5-6: match reference
        counts_protein[:, 5] = vcat([100], zeros(Int, 19))
        counts_protein[:, 6] = vcat([100], zeros(Int, 19))
        
        ref_protein = falses(20, 6)
        ref_protein[1, :] .= true  # All first amino acid
        
        # Test protein mode with filtering
        p = EntroPlots.logoplot_with_rect_gaps(
            [counts_protein], [1], 10;
            reference_pfms = [ref_protein],
            filter_by_reference = true,
            protein = true
        )
        @test p !== nothing
    end
end

@testset "Outside fragments" begin
    to_rgb(c) = convert(Plots.RGB, Plots.Colors.parse(Plots.Colorant, string(c)))
    letters = Set(EntroPlots.dna_letters)
    # Letter series of a plot, as (label, rgb, minimum x) tuples. The connector
    # rectangles are not letter series and are skipped.
    function letter_series(p)
        out = Tuple{String,Plots.RGB,Float64}[]
        for s in p.series_list
            lab = string(s[:label])
            lab in letters || continue
            xs = filter(!isnan, s[:x])
            isempty(xs) && continue
            push!(out, (lab, convert(Plots.RGB, s[:fillcolor]), minimum(xs)))
        end
        return out
    end
    # Display columns occupied by fragment k: (offset, offset + width].
    in_fragment(x, off, w) = off < x < off + w + 1

    # Window fragment at 5:7 (A, C, G wild type), one outside site at 12 (T wild type).
    win = [8 1 1; 1 8 1; 1 1 8; 0 0 0]
    win_ref = BitMatrix([1 0 0; 0 1 0; 0 0 1; 0 0 0])
    out_counts = [1; 0; 2; 7;;]                 # 7 T (wild type), 1 A and 2 G mutants
    out_ref = BitMatrix([0; 0; 0; 1;;])
    total = 20

    @testset "nothing / empty outside input leaves the plot unchanged" begin
        dir = mktempdir()
        try
            f0, f1, f2 = (joinpath(dir, "logo_$i.png") for i in 0:2)
            seed!(7); save_logo_with_rect_gaps([win], [5], total, f0; reference_pfms=[win_ref],
                                               filter_by_reference=false)
            seed!(7); save_logo_with_rect_gaps([win], [5], total, f1; reference_pfms=[win_ref],
                                               filter_by_reference=false, outside_count_matrices=nothing)
            seed!(7); save_logo_with_rect_gaps([win], [5], total, f2; reference_pfms=[win_ref],
                                               filter_by_reference=false, outside_count_matrices=Matrix{Int}[],
                                               outside_starting_indices=Int[], outside_reference_pfms=BitMatrix[])
            @test read(f0) == read(f1)
            @test read(f0) == read(f2)
        finally
            rm(dir; recursive=true, force=true)
        end
    end

    @testset "outside fragment after the window: colours, order, tick labels" begin
        p = EntroPlots.logoplot_with_rect_gaps([win], [5], total; reference_pfms=[win_ref],
            filter_by_reference=false, outside_count_matrices=[out_counts],
            outside_starting_indices=[12], outside_reference_pfms=[out_ref])
        pfms = [win ./ sum(win, dims=1), out_counts ./ sum(out_counts, dims=1)]
        offs, total_adj = EntroPlots.get_offset_from_start([5, 12], pfms, total)
        ser = letter_series(p)
        win_ser = filter(t -> in_fragment(t[3], offs[1], 3), ser)
        out_ser = filter(t -> in_fragment(t[3], offs[2], 1), ser)
        @test length(win_ser) + length(out_ser) == length(ser)
        @test !isempty(out_ser)
        # Outside column: wild-type T in slate grey, every other letter orange.
        @test all(t -> t[2] == (t[1] == "T" ? to_rgb("#64748B") : to_rgb("#E69F00")), out_ser)
        # Window columns keep the window colours: wild-type blue, mutants dark red.
        @test any(t -> t[2] == to_rgb("#1434A4"), win_ser)
        @test all(t -> t[2] in (to_rgb("#1434A4"), to_rgb(:darkred)), win_ser)
        # The outside fragment is drawn after the window fragment (sorted by start).
        first_out = findfirst(s -> string(s[:label]) in letters && in_fragment(minimum(filter(!isnan, s[:x])), offs[2], 1),
                              p.series_list)
        last_win = findlast(s -> string(s[:label]) in letters && in_fragment(minimum(filter(!isnan, s[:x])), offs[1], 3),
                            p.series_list)
        @test last_win < first_out
        # Tick labels: consensus positions under every column, including the outside one.
        labels = EntroPlots.make_xtick_labels(pfms, offs, [5, 12], total_adj)
        @test labels[offs[1]+1:offs[1]+3] == ["5", "6", "7"]
        @test labels[offs[2]+1] == "12"
        @test p[1][:xaxis][:ticks][2] == labels
    end

    @testset "outside fragment before the window is sorted first" begin
        p = EntroPlots.logoplot_with_rect_gaps([win], [5], total; reference_pfms=[win_ref],
            filter_by_reference=false, outside_count_matrices=[out_counts],
            outside_starting_indices=[2], outside_reference_pfms=[out_ref])
        pfms = [out_counts ./ sum(out_counts, dims=1), win ./ sum(win, dims=1)]
        offs, total_adj = EntroPlots.get_offset_from_start([2, 5], pfms, total)
        ser = letter_series(p)
        out_ser = filter(t -> in_fragment(t[3], offs[1], 1), ser)
        win_ser = filter(t -> in_fragment(t[3], offs[2], 3), ser)
        @test !isempty(out_ser) && !isempty(win_ser)
        @test all(t -> t[2] in (to_rgb("#64748B"), to_rgb("#E69F00")), out_ser)
        @test all(t -> t[2] in (to_rgb("#1434A4"), to_rgb(:darkred)), win_ser)
        @test p[1][:xaxis][:ticks][2][offs[1]+1] == "2"
        @test p[1][:xaxis][:ticks][2][offs[2]+1:offs[2]+3] == ["5", "6", "7"]
    end

    @testset "touching outside fragment and custom colours" begin
        # Gap 0 between the window (5:7) and the outside site 8: drawn contiguous.
        p = EntroPlots.logoplot_with_rect_gaps([win], [5], total; reference_pfms=[win_ref],
            filter_by_reference=false, outside_count_matrices=[out_counts],
            outside_starting_indices=[8], outside_reference_pfms=[out_ref],
            outside_match_color="#000000", outside_mismatch_color="#00FF00")
        pfms = [win ./ sum(win, dims=1), out_counts ./ sum(out_counts, dims=1)]
        offs, _ = EntroPlots.get_offset_from_start([5, 8], pfms, total)
        @test offs[2] == offs[1] + 3
        out_ser = filter(t -> in_fragment(t[3], offs[2], 1), letter_series(p))
        @test all(t -> t[2] == (t[1] == "T" ? to_rgb("#000000") : to_rgb("#00FF00")), out_ser)
    end

    @testset "filter_by_reference=true filters the window, never the outside fragments" begin
        # The production reduced view. Window 5:7 with an all-wild-type column 6 (dropped by the
        # filter); outside fragment 12:13 whose column 13 is all wild type (kept: never filtered).
        win_f = [8 0 1; 1 10 1; 1 0 8; 0 0 0]
        out2 = [1 0; 0 0; 2 0; 7 9]
        out2_ref = BitMatrix([0 0; 0 0; 0 0; 1 1])
        p = EntroPlots.logoplot_with_rect_gaps([win_f], [5], total; reference_pfms=[win_ref],
            filter_by_reference=true, filter_tolerance=0.5, outside_count_matrices=[out2],
            outside_starting_indices=[12], outside_reference_pfms=[out2_ref])
        kept, kept_starts, _ = EntroPlots.apply_count_filter([win_f], [5], [win_ref]; tol=0.5)
        @test kept_starts == [5, 7]
        pfms = [[k ./ sum(k, dims=1) for k in kept]; [out2 ./ sum(out2, dims=1)]]
        offs, total_adj = EntroPlots.get_offset_from_start([5, 7, 12], pfms, total)
        labels = EntroPlots.make_xtick_labels(pfms, offs, [5, 7, 12], total_adj)
        @test p[1][:xaxis][:ticks][2] == labels
        @test labels[offs[1]+1] == "5" && labels[offs[2]+1] == "7"
        @test labels[offs[3]+1:offs[3]+2] == ["12", "13"]
        @test !("6" in labels)
        ser = letter_series(p)
        win_ser = filter(t -> in_fragment(t[3], offs[1], 1) || in_fragment(t[3], offs[2], 1), ser)
        out_ser = filter(t -> in_fragment(t[3], offs[3], 2), ser)
        @test length(win_ser) + length(out_ser) == length(ser)
        @test all(t -> t[2] in (to_rgb("#1434A4"), to_rgb(:darkred)), win_ser)
        @test all(t -> t[2] == (t[1] == "T" ? to_rgb("#64748B") : to_rgb("#E69F00")), out_ser)
        # The all-wild-type outside column 13 is drawn: a full-height grey T stands there.
        tser = only(filter(s -> string(s[:label]) == "T" &&
                                in_fragment(minimum(filter(!isnan, s[:x])), offs[3], 2), p.series_list))
        col13 = [y for (x, y) in zip(tser[:x], tser[:y]) if !isnan(x) && x > offs[3] + 1.5]
        @test !isempty(col13) && maximum(col13) > 1.0
    end

    @testset "filtering the main fragments to nothing still errors" begin
        all_wt = [10 10; 0 0; 0 0; 0 0]
        all_wt_ref = BitMatrix([1 1; 0 0; 0 0; 0 0])
        @test_throws ErrorException EntroPlots.logoplot_with_rect_gaps([all_wt], [5], total;
            reference_pfms=[all_wt_ref], filter_by_reference=true, outside_count_matrices=[out_counts],
            outside_starting_indices=[12], outside_reference_pfms=[out_ref])
    end

    @testset "input validation" begin
        dir = mktempdir()
        try
            f = joinpath(dir, "bad.png")
            @test_throws AssertionError save_logo_with_rect_gaps([win], [5], total, f;
                reference_pfms=[win_ref], outside_count_matrices=[[-1; 2; 0; 0;;]],
                outside_starting_indices=[12], outside_reference_pfms=[out_ref])
            @test_throws AssertionError save_logo_with_rect_gaps([win], [5], total, f;
                reference_pfms=[win_ref], outside_count_matrices=[zeros(Int, 4, 1)],
                outside_starting_indices=[12], outside_reference_pfms=[out_ref])
            # Outside fragments need references for their colouring.
            @test_throws AssertionError EntroPlots.logoplot_with_rect_gaps([win], [5], total;
                filter_by_reference=false, outside_count_matrices=[out_counts],
                outside_starting_indices=[12], outside_reference_pfms=[out_ref])
            @test_throws AssertionError EntroPlots.logoplot_with_rect_gaps([win], [5], total;
                reference_pfms=[win_ref], filter_by_reference=false, outside_count_matrices=[out_counts],
                outside_starting_indices=[12, 14], outside_reference_pfms=[out_ref])
            # The three outside inputs go together (an assertion, not a MethodError on `nothing`).
            @test_throws AssertionError save_logo_with_rect_gaps([win], [5], total, f;
                reference_pfms=[win_ref], outside_count_matrices=[out_counts],
                outside_reference_pfms=[out_ref])
            @test_throws AssertionError save_logo_with_rect_gaps([win], [5], total, f;
                reference_pfms=[win_ref], outside_count_matrices=[out_counts],
                outside_starting_indices=[12])
            # Each outside count matrix is as wide as its reference.
            @test_throws AssertionError save_logo_with_rect_gaps([win], [5], total, f;
                reference_pfms=[win_ref], outside_count_matrices=[out_counts],
                outside_starting_indices=[12], outside_reference_pfms=[BitMatrix([0 0; 0 0; 0 0; 1 1])])
            @test !isfile(f)
        finally
            rm(dir; recursive=true, force=true)
        end
    end
end
