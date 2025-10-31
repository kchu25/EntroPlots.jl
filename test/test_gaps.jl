using Test
using EntroPlots

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
