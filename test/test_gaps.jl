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
        pfm1 = [0.25 0.3 0.2 0.1 0.4 0.5 0.3 0.2 0.1;
                0.25 0.2 0.3 0.4 0.2 0.1 0.2 0.3 0.4;
                0.25 0.3 0.2 0.3 0.2 0.2 0.3 0.2 0.3;
                0.25 0.2 0.3 0.2 0.2 0.2 0.2 0.3 0.2]
        
        pfm2 = copy(pfm1)
        pfms = [pfm1, pfm2]
        
        # Test various gap sizes
        test_cases = [
            (starting_indices=[10, 20], total_len=30, gap_size=1, desc="1 position gap"),
            (starting_indices=[10, 21], total_len=30, gap_size=2, desc="2 position gap"),
            (starting_indices=[39, 50], total_len=60, gap_size=2, desc="2 position gap (original)"),
            (starting_indices=[10, 19], total_len=27, gap_size=0, desc="No gap"),
        ]
        
        for tc in test_cases
            # This should not throw an error
            p = EntroPlots.logoplot_with_rect_gaps(pfms, tc.starting_indices, tc.total_len)
            @test p !== nothing
            
            offsets, _ = EntroPlots.get_offset_from_start(tc.starting_indices, pfms, tc.total_len)
            display_gap = offsets[2] - offsets[1] - 9
            
            if tc.gap_size > 0
                @test display_gap >= 1  # Gap should be visible
            else
                @test display_gap == 0  # No gap expected
            end
        end
    end
    
    @testset "Protein mode support" begin
        # Create protein PFMs (20 amino acids)
        pfm_protein1 = rand(20, 10)
        pfm_protein1 ./= sum(pfm_protein1, dims=1)
        
        pfm_protein2 = rand(20, 10)
        pfm_protein2 ./= sum(pfm_protein2, dims=1)
        
        # Test protein mode
        p = EntroPlots.logoplot_with_rect_gaps(
            [pfm_protein1, pfm_protein2],
            [1, 13],
            25;
            protein = true
        )
        @test p !== nothing
    end
    
    @testset "Reference coloring support" begin
        pfm1 = rand(4, 9); pfm1 ./= sum(pfm1, dims=1)
        pfm2 = rand(4, 9); pfm2 ./= sum(pfm2, dims=1)
        
        # Create reference PFMs
        ref1 = falses(4, 9)
        ref1[1, 3] = true  # Mark A at position 3
        
        ref2 = falses(4, 9)
        ref2[2, 5] = true  # Mark C at position 5
        
        # Test with reference
        p = EntroPlots.logoplot_with_rect_gaps(
            [pfm1, pfm2],
            [1, 12],
            22;
            reference_pfms = [ref1, ref2]
        )
        @test p !== nothing
    end
end

@testset "Reduction/Filtering feature" begin
    @testset "Reference validation - strict one-hot encoding" begin
        pfm1 = rand(4, 5); pfm1 ./= sum(pfm1, dims=1)
        
        # Valid one-hot reference
        ref_valid = falses(4, 5)
        ref_valid[1, 1] = true
        ref_valid[2, 2] = true
        ref_valid[3, 3] = true
        ref_valid[4, 4] = true
        ref_valid[1, 5] = true
        
        # Test valid reference works
        filtered = EntroPlots.filter_pfms_by_reference(
            [pfm1], [1], [ref_valid]; tolerance=0.01
        )
        @test filtered !== nothing
        
        # Invalid reference - two ones in a column
        ref_invalid1 = falses(4, 5)
        ref_invalid1[1, 1] = true
        ref_invalid1[2, 1] = true  # Two ones in first column
        ref_invalid1[3, 2] = true
        
        @test_throws ErrorException EntroPlots.filter_pfms_by_reference(
            [pfm1], [1], [ref_invalid1]; tolerance=0.01
        )
        
        # Invalid reference - no ones in a column
        ref_invalid2 = falses(4, 5)
        ref_invalid2[1, 2] = true
        ref_invalid2[2, 3] = true
        # Column 1 has no ones
        
        @test_throws ErrorException EntroPlots.filter_pfms_by_reference(
            [pfm1], [1], [ref_invalid2]; tolerance=0.01
        )
    end
    
    @testset "Tolerance sensitivity - capture ≥1% variation" begin
        # Test that tolerance=0.01 correctly distinguishes matching vs non-matching columns
        
        # Column that MATCHES reference (A=0.995, others <0.01)
        col_match = [0.995, 0.003, 0.001, 0.001]
        
        # Column with 1% variation - should NOT match (captures this variation)
        col_1pct_var = [0.99, 0.01, 0.0, 0.0]  # 1% at position 2
        
        # Column with 2% variation - should NOT match
        col_2pct_var = [0.97, 0.02, 0.005, 0.005]  # 2% at position 2
        
        # Column with 5% variation - should NOT match
        col_5pct_var = [0.92, 0.05, 0.02, 0.01]  # 5% at position 2
        
        # Create test PFM with these columns
        pfm_test = hcat(col_match, col_1pct_var, col_2pct_var, col_5pct_var)
        
        ref_test = falses(4, 4)
        ref_test[1, :] .= true  # All A reference
        
        # With tolerance=0.01
        filtered_strict = EntroPlots.filter_pfms_by_reference(
            [pfm_test], [1], [ref_test]; tolerance=0.01
        )
        
        # Should filter out column 1 (matches), keep columns 2-4 (have ≥1% variation)
        @test length(filtered_strict[1]) == 1  # One fragment
        @test size(filtered_strict[1][1], 2) == 3  # Columns 2-4
        @test filtered_strict[2][1] == 2  # Starting at position 2 (1 + 2 - 1)
        
        # Test with looser tolerance=0.02
        filtered_loose = EntroPlots.filter_pfms_by_reference(
            [pfm_test], [1], [ref_test]; tolerance=0.02
        )
        
        # Should filter out columns 1-2 (both match within 2% tolerance), keep columns 3-4
        @test length(filtered_loose[1]) == 1  # One fragment
        @test size(filtered_loose[1][1], 2) == 2  # Columns 3-4
        @test filtered_loose[2][1] == 3  # Starting at position 3
    end
    
    @testset "Fragmentation and start position updates" begin
        # Create PFM with known structure
        pfm1 = zeros(4, 10)
        
        # Columns 1-2: match reference (A with prob > 0.99, all others < 0.01)
        pfm1[:, 1] = [0.994, 0.002, 0.002, 0.002]
        pfm1[:, 2] = [0.997, 0.001, 0.001, 0.001]
        
        # Columns 3-5: DON'T match reference (varied)
        pfm1[:, 3] = [0.25, 0.25, 0.25, 0.25]
        pfm1[:, 4] = [0.1, 0.7, 0.1, 0.1]
        pfm1[:, 5] = [0.3, 0.3, 0.2, 0.2]
        
        # Column 6: matches reference (C with prob > 0.99, all others < 0.01)
        pfm1[:, 6] = [0.002, 0.994, 0.002, 0.002]
        
        # Columns 7-10: DON'T match reference
        pfm1[:, 7] = [0.4, 0.3, 0.2, 0.1]
        pfm1[:, 8] = [0.2, 0.2, 0.3, 0.3]
        pfm1[:, 9] = [0.5, 0.2, 0.2, 0.1]
        pfm1[:, 10] = [0.15, 0.15, 0.35, 0.35]
        
        # Create reference (all A except column 6 which is C)
        ref1 = falses(4, 10)
        ref1[1, :] .= true  # All A
        ref1[1, 6] = false
        ref1[2, 6] = true   # Column 6 is C
        
        # Filter with tolerance 0.01
        filtered_pfms, filtered_indices, filtered_refs = EntroPlots.filter_pfms_by_reference(
            [pfm1], [100], [ref1]; tolerance=0.01
        )
        
        # Should have 2 fragments:
        # Fragment 1: columns 3-5 (positions 102-104)
        # Fragment 2: columns 7-10 (positions 106-109)
        @test length(filtered_pfms) == 2
        @test length(filtered_indices) == 2
        @test length(filtered_refs) == 2
        
        # Check fragment 1 (columns 3-5, starting at position 102)
        @test size(filtered_pfms[1], 2) == 3
        @test filtered_indices[1] == 102  # 100 + 3 - 1
        @test all(filtered_pfms[1] .≈ pfm1[:, 3:5])
        
        # Check fragment 2 (columns 7-10, starting at position 106)
        @test size(filtered_pfms[2], 2) == 4
        @test filtered_indices[2] == 106  # 100 + 7 - 1
        @test all(filtered_pfms[2] .≈ pfm1[:, 7:10])
    end
    
    @testset "Edge cases" begin
        # Edge case 1: All columns match reference - should return empty
        pfm_all_match = zeros(4, 5)
        for i in 1:5
            pfm_all_match[:, i] = [0.994, 0.002, 0.002, 0.002]  # All < 0.01 except reference
        end
        
        ref_all = falses(4, 5)
        ref_all[1, :] .= true  # All A
        
        filtered = EntroPlots.filter_pfms_by_reference(
            [pfm_all_match], [1], [ref_all]; tolerance=0.01
        )
        
        @test length(filtered[1]) == 0  # No fragments
        @test length(filtered[2]) == 0
        @test length(filtered[3]) == 0
        
        # Edge case 2: No columns match reference - should return entire PFM
        pfm_no_match = zeros(4, 5)
        for i in 1:5
            pfm_no_match[:, i] = [0.25, 0.25, 0.25, 0.25]
        end
        
        ref_no_match = falses(4, 5)
        ref_no_match[1, :] .= true  # All A (but PFM has uniform distribution)
        
        filtered2 = EntroPlots.filter_pfms_by_reference(
            [pfm_no_match], [10], [ref_no_match]; tolerance=0.01
        )
        
        @test length(filtered2[1]) == 1  # One fragment (entire PFM)
        @test filtered2[2][1] == 10      # Same starting position
        @test size(filtered2[1][1], 2) == 5  # All 5 columns
        
        # Edge case 3: Multiple PFMs with different fragmentation patterns
        pfm_a = zeros(4, 4)
        pfm_a[:, 1:2] = [0.994 0.994; 0.002 0.002; 0.002 0.002; 0.002 0.002]  # Match
        pfm_a[:, 3:4] = [0.25 0.25; 0.25 0.25; 0.25 0.25; 0.25 0.25]      # Don't match
        
        pfm_b = zeros(4, 4)
        pfm_b[:, 1:4] = [0.25 0.25 0.25 0.25; 0.25 0.25 0.25 0.25; 0.25 0.25 0.25 0.25; 0.25 0.25 0.25 0.25]  # All don't match
        
        ref_a = falses(4, 4)
        ref_a[1, :] .= true
        
        ref_b = falses(4, 4)
        ref_b[2, :] .= true
        
        filtered3 = EntroPlots.filter_pfms_by_reference(
            [pfm_a, pfm_b], [1, 20], [ref_a, ref_b]; tolerance=0.01
        )
        
        # Should have 2 fragments total: 1 from pfm_a (cols 3-4) and 1 from pfm_b (all cols)
        @test length(filtered3[1]) == 2
        @test filtered3[2][1] == 3   # pfm_a fragment starts at position 3 (1 + 3 - 1)
        @test filtered3[2][2] == 20  # pfm_b fragment starts at position 20
    end
    
    @testset "Integration: reduction option in logoplot_with_rect_gaps" begin
        # Create PFMs with known matching/non-matching columns
        pfm1 = zeros(4, 8)
        pfm1[:, 1:2] = [0.994 0.994; 0.002 0.002; 0.002 0.002; 0.002 0.002]  # Match
        pfm1[:, 3:5] = [0.25 0.25 0.25; 0.25 0.25 0.25; 0.25 0.25 0.25; 0.25 0.25 0.25]  # Don't match
        pfm1[:, 6:8] = [0.994 0.994 0.994; 0.002 0.002 0.002; 0.002 0.002 0.002; 0.002 0.002 0.002]  # Match
        
        ref1 = falses(4, 8)
        ref1[1, :] .= true  # All A
        
        # Test without reduction - should plot entire PFM
        p1 = EntroPlots.logoplot_with_rect_gaps(
            [pfm1], [1], 10;
            reference_pfms = [ref1],
            reduction = false
        )
        @test p1 !== nothing
        
        # Test with reduction - should only plot columns 3-5
        p2 = EntroPlots.logoplot_with_rect_gaps(
            [pfm1], [1], 10;
            reference_pfms = [ref1],
            reduction = true
        )
        @test p2 !== nothing
        
        # Verify that reduction actually filtered the PFMs
        # (We can't directly inspect the plot, but we can verify no errors)
    end
    
    @testset "Protein mode with reduction" begin
        # Create protein PFM (20 amino acids)
        pfm_protein = zeros(20, 6)
        
        # Columns 1-2: match reference (first amino acid with >99%, others <1%)
        pfm_protein[:, 1] = vcat([0.992], fill(0.0004, 19))  # 19*0.0004 + 0.992 ≈ 1.0
        pfm_protein[:, 2] = vcat([0.992], fill(0.0004, 19))
        
        # Columns 3-4: don't match
        pfm_protein[:, 3] = fill(0.05, 20)
        pfm_protein[:, 4] = fill(0.05, 20)
        
        # Columns 5-6: match reference
        pfm_protein[:, 5] = vcat([0.992], fill(0.0004, 19))
        pfm_protein[:, 6] = vcat([0.992], fill(0.0004, 19))
        
        # Normalize
        pfm_protein ./= sum(pfm_protein, dims=1)
        
        ref_protein = falses(20, 6)
        ref_protein[1, :] .= true  # All first amino acid
        
        # Test protein mode with reduction
        p = EntroPlots.logoplot_with_rect_gaps(
            [pfm_protein], [1], 10;
            reference_pfms = [ref_protein],
            reduction = true,
            protein = true
        )
        @test p !== nothing
    end
end
