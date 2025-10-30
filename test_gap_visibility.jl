# Activate the local package environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Test
using Revise
using EntroPlots

println("Testing LOCAL version of EntroPlots")
println("Package location: ", pathof(EntroPlots))
println()

@testset "Gap visibility tests" begin
    # Test the inc_round_up function directly
    inc_round_up = EntroPlots.inc_round_up
    
    @testset "inc_round_up function" begin
        @test inc_round_up(0) == 0  # No gap
        @test inc_round_up(1) == 1  # 1 position gap - should be visible
        @test inc_round_up(2) == 1  # 2 position gap - should be visible
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
        
        println("Offsets: $offsets")
        println("Total adjusted: $total_adjusted")
        println("Gap display width: $(offsets[2] - offsets[1] - 9)")
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
            (starting_indices=[39, 50], total_len=60, gap_size=2, desc="2 position gap (original issue)"),
            (starting_indices=[10, 19], total_len=27, gap_size=0, desc="No gap (consecutive)"),
        ]
        
        for (i, tc) in enumerate(test_cases)
            println("\nTest case $i: $(tc.desc)")
            println("  Starting indices: $(tc.starting_indices)")
            println("  Expected gap size: $(tc.gap_size)")
            
            # This should not throw an error
            p = EntroPlots.logoplot_with_rect_gaps(pfms, tc.starting_indices, tc.total_len)
            @test p !== nothing
            
            offsets, _ = EntroPlots.get_offset_from_start(tc.starting_indices, pfms, tc.total_len)
            display_gap = offsets[2] - offsets[1] - 9
            
            if tc.gap_size > 0
                @test display_gap >= 1  # Gap should be visible (at least 1 position)
                println("  ✓ Gap is visible with display width: $display_gap")
            else
                @test display_gap == 0  # No gap expected
                println("  ✓ No gap as expected")
            end
        end
    end
end

println("\n" * "="^60)
println("All tests passed! Small gaps are now visible.")
println("="^60)
