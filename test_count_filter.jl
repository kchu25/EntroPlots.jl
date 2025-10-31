using Test
using EntroPlots

@testset "Count Matrix Filtering" begin
    
    @testset "Basic filtering logic" begin
        # Test case 1: Column with single entry matching reference
        counts = [10 5 0; 0 5 20; 0 0 0; 0 0 0]
        ref = BitMatrix([1 0 0; 0 1 0; 0 0 1; 0 0 0])
        
        keep = EntroPlots.filter_counts_by_reference(counts, ref)
        
        # Column 1: counts=[10,0,0,0], ref=[1,0,0,0]
        # dot = 10*1 = 10, sum = 10 → 10 == 10 → remove
        # Column 2: counts=[5,5,0,0], ref=[0,1,0,0]  
        # dot = 5*1 = 5, sum = 10 → 5 ≠ 10 → keep
        # Column 3: counts=[0,20,0,0], ref=[0,0,1,0]
        # dot = 0*1 = 0, sum = 20 → 0 ≠ 20 → keep
        @test keep == [2, 3]
    end
    
    @testset "Fragment counting" begin
        # Create count matrices with known fragment patterns
        counts1 = [10 0 0 5 5; 0 10 5 5 0; 0 0 5 0 5; 0 0 0 0 0]
        counts2 = [0 0 10; 10 5 0; 0 5 0; 0 0 0]
        
        ref1 = BitMatrix([1 0 0 0 0; 0 1 0 0 0; 0 0 1 1 1; 0 0 0 0 0])
        ref2 = BitMatrix([0 0 1; 1 0 0; 0 1 0; 0 0 0])
        
        count_matrices = [counts1, counts2]
        reference_pfms = [ref1, ref2]
        
        # Check which columns are kept
        keep1 = EntroPlots.filter_counts_by_reference(counts1, ref1)
        keep2 = EntroPlots.filter_counts_by_reference(counts2, ref2)
        
        println("Kept columns in matrix 1: ", keep1)
        println("Kept columns in matrix 2: ", keep2)
        
        # Count fragments
        starting_indices = [1, 10]
        n_fragments, span = EntroPlots.count_fragments(count_matrices, reference_pfms, starting_indices)
        println("Number of fragments: ", n_fragments)
        println("Span: ", span)
        
        @test n_fragments > 0
        @test !isempty(span)  # Single combined span string
    end
    
    @testset "Apply filter with starting indices" begin
        counts = [10 0 5 5; 0 10 5 0; 0 0 0 5; 0 0 0 0]
        ref = BitMatrix([1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0])
        
        starting_indices = [100]
        
        # Column 1: [10,0,0,0] · [1,0,0,0] = 10 = sum(10) → remove
        # Column 2: [0,10,0,0] · [0,1,0,0] = 10 = sum(10) → remove  
        # Column 3: [5,5,0,0] · [0,0,0,1] = 0 ≠ sum(10) → keep
        # Column 4: [5,0,5,0] · [0,0,1,0] = 5 ≠ sum(10) → keep
        
        new_counts, new_starts, new_refs = EntroPlots.apply_count_filter(
            [counts], starting_indices, [ref]
        )
        
        @test length(new_counts) == 1  # One fragment (columns 3-4 are contiguous)
        @test size(new_counts[1], 2) == 2  # Columns 3-4
        @test new_starts[1] == 102  # Started at 100, kept columns 3-4
    end
    
    @testset "Perfect match - all removed" begin
        # All columns match reference perfectly
        counts = [10 0 0; 0 10 0; 0 0 10; 0 0 0]
        ref = BitMatrix([1 0 0; 0 1 0; 0 0 1; 0 0 0])
        
        keep = EntroPlots.filter_counts_by_reference(counts, ref)
        @test isempty(keep)
        
        n_fragments, span = EntroPlots.count_fragments([counts], [ref], [1])
        @test n_fragments == 0
        @test span == ""  # Empty string for no fragments
    end
    
    @testset "No match - all kept" begin
        # No columns match reference
        counts = [5 5 5; 5 5 5; 0 0 0; 0 0 0]
        ref = BitMatrix([0 0 0; 0 0 0; 1 1 1; 0 0 0])
        
        keep = EntroPlots.filter_counts_by_reference(counts, ref)
        @test keep == [1, 2, 3]
        
        n_fragments, span = EntroPlots.count_fragments([counts], [ref], [1])
        @test n_fragments == 1  # One contiguous fragment
        @test span == "1-3"  # Columns 1-3
    end
    
    @testset "Discontinuous fragments" begin
        # Create pattern: keep, remove, remove, keep, keep, remove, keep
        counts = [5 10 0  5 5 0  5;
                  5 0  10 5 5 10 5;
                  0 0  0  0 0 0  0;
                  0 0  0  0 0 0  0]
        ref = BitMatrix([0 1 0 0 0 0 0;
                         0 0 1 0 0 1 0;
                         1 0 0 1 1 0 1;
                         0 0 0 0 0 0 0])
        
        keep = EntroPlots.filter_counts_by_reference(counts, ref)
        @test keep == [1, 4, 5, 7]  # Columns with mismatches
        
        # Should create 3 fragments: [1], [4,5], [7]
        n_fragments, span = EntroPlots.count_fragments([counts], [ref], [10])
        @test n_fragments == 3
        @test span == "(10, 13-14, 16)"  # Global positions: 10, 13-14, 16
    end
end

println("\nAll tests passed! ✓")
