"""
Comprehensive test suite for EntroPlots.jl
Tests all functionality including examples from README.md
"""

using EntroPlots
using Test
using Plots

@testset "EntroPlots.jl Tests" begin
    
    # Test data from README examples
    pfm = [0.02  1.0  0.98  0.0   0.0   0.0   0.98  0.0   0.18  1.0
           0.98  0.0  0.02  0.19  0.0   0.96  0.01  0.89  0.03  0.0
           0.0   0.0  0.0   0.77  0.01  0.0   0.0   0.0   0.56  0.0
           0.0   0.0  0.0   0.04  0.99  0.04  0.01  0.11  0.23  0.0]
    
    background = [0.25, 0.25, 0.25, 0.25]
    
    # Generate protein test data
    protein_matrix = rand(20, 25)  # Larger for better testing
    pfm_protein = protein_matrix ./ sum(protein_matrix, dims=1)
    reduce_entropy!(pfm_protein)
    protein_background = fill(1/20, 20)

    @testset "README Examples" begin
        @testset "Basic Examples" begin
            # Example 1: logoplot(pfm, background)
            p1 = logoplot(pfm, background)
            @test p1 isa Plots.Plot
            
            # Example 2: logoplot(pfm) with default background
            p2 = logoplot(pfm)
            @test p2 isa Plots.Plot
            
            # Example 3: Minimal plot (from README)
            p3 = logoplot(pfm; _margin_=0Plots.mm, tight=true, yaxis=false, xaxis=false)
            @test p3 isa Plots.Plot
        end

        @testset "Highlighting Examples" begin
            # Example: highlighted_regions=[4:8] (from README)
            highlighted_regions1 = [4:8]
            p1 = logoplot_with_highlight(pfm, background, highlighted_regions1)
            @test p1 isa Plots.Plot
            
            # Multiple regions (from README)
            highlighted_regions2 = [2:3, 6:8]
            p2 = logoplot_with_highlight(pfm, background, highlighted_regions2)
            @test p2 isa Plots.Plot
        end

        @testset "Protein Examples" begin
            # Example: logoplot(pfm_protein; protein=true) (from README)
            p1 = logoplot(pfm_protein; protein=true)
            @test p1 isa Plots.Plot
            
            # Example: protein with highlighting (from README)
            p2 = logoplot_with_highlight(pfm_protein, [2:5, 8:12, 21:25]; protein=true)
            @test p2 isa Plots.Plot
        end

        @testset "Save Examples" begin
            temp_dir = mktempdir()
            try
                # Example: save_logoplot(pfm, background, "tmp/logo.png") (from README)
                save_path1 = joinpath(temp_dir, "logo.png")
                save_logoplot(pfm, background, save_path1)
                @test isfile(save_path1)
                
                # Example: save_logoplot(pfm, "tmp/logo.png") with default background (from README)
                save_path2 = joinpath(temp_dir, "logo_default.png")
                save_logoplot(pfm, save_path2)
                @test isfile(save_path2)
                
                # Example: protein save (from README)
                save_path3 = joinpath(temp_dir, "logo_protein.png")
                save_logoplot(pfm_protein, save_path3; protein=true)
                @test isfile(save_path3)
                
                # Example: protein with highlighting (from README)
                save_path4 = joinpath(temp_dir, "logo_protein_highlight.png")
                save_logoplot(pfm_protein, save_path4; protein=true, highlighted_regions=[2:5, 7:9])
                @test isfile(save_path4)
                
            finally
                rm(temp_dir; recursive=true, force=true)
            end
        end
    end

    @testset "Core Functionality" begin
        @testset "PFM Validation" begin
            @test size(pfm, 1) == 4  # 4 nucleotides
            @test all(sum(pfm, dims=1) .≈ 1)  # columns sum to 1
            @test all(pfm .>= 0)  # all probabilities non-negative
        end

        @testset "Background Validation" begin
            @test length(background) == 4
            @test sum(background) ≈ 1
            @test all(background .>= 0)
        end

        @testset "Protein Data Validation" begin
            @test size(pfm_protein, 1) == 20  # 20 amino acids
            @test all(sum(pfm_protein, dims=1) .≈ 1)  # columns sum to 1
            @test length(protein_background) == 20
            @test sum(protein_background) ≈ 1
        end
    end

    @testset "Logo Plotting Functions" begin
        @testset "Basic Logo Plots" begin
            # Test basic logoplot with background
            p1 = logoplot(pfm, background)
            @test p1 isa Plots.Plot
            
            # Test logoplot with default background
            p2 = logoplot(pfm)
            @test p2 isa Plots.Plot
            
            # Test protein logoplot
            p3 = logoplot(pfm_protein; protein=true)
            @test p3 isa Plots.Plot
            
            # Test RNA logoplot
            p4 = logoplot(pfm; rna=true)
            @test p4 isa Plots.Plot
        end

    @testset "Advanced Features & Options" begin
        @testset "Styling Variations" begin
            # RNA plotting
            p1 = logoplot(pfm; rna=true)
            @test p1 isa Plots.Plot
            
            # Tight layout
            p2 = logoplot(pfm; tight=true)
            @test p2 isa Plots.Plot
            
            # Custom alpha/beta
            p3 = logoplot(pfm; alpha=0.7, beta=1.5)
            @test p3 isa Plots.Plot
            
            # Uniform coloring
            p4 = logoplot(pfm; uniform_color=true, pos=true)
            @test p4 isa Plots.Plot
        end

        @testset "Custom Backgrounds" begin
            # Non-uniform background
            custom_bg = [0.3, 0.2, 0.2, 0.3]
            p1 = logoplot(pfm, custom_bg)
            @test p1 isa Plots.Plot
            
            # Protein with custom background
            p2 = logoplot(pfm_protein, protein_background; protein=true)
            @test p2 isa Plots.Plot
        end
    end
    end

    @testset "Highlighting Functions" begin
        highlighted_regions = [4:6, 8:10]
        
        @testset "Highlight Validation" begin
            # Test overlap checking
            overlapping_regions = [1:3, 2:4]
            @test_throws AssertionError logoplot_with_highlight(pfm, background, overlapping_regions)
            
            # Test valid regions
            @test !EntroPlots.chk_overlap(highlighted_regions)
            @test EntroPlots.chk_overlap([1:3, 2:4])
        end

        @testset "Highlight Plotting" begin
            # Test with background specified
            p1 = logoplot_with_highlight(pfm, background, highlighted_regions)
            @test p1 isa Plots.Plot
            
            # Test with default background
            p2 = logoplot_with_highlight(pfm, highlighted_regions)
            @test p2 isa Plots.Plot
            
            # Test protein highlighting
            protein_regions = [2:4, 7:9]
            p3 = logoplot_with_highlight(pfm_protein, protein_regions; protein=true)
            @test p3 isa Plots.Plot
        end
    end

    @testset "Helper Functions" begin
        @testset "Character Sets" begin
            @test EntroPlots.get_sequence_characters(false, false) == EntroPlots.dna_letters
            @test EntroPlots.get_sequence_characters(false, true) == EntroPlots.rna_letters  
            @test EntroPlots.get_sequence_characters(true, false) == EntroPlots.protein_letters
        end

        @testset "Color Palettes" begin
            # Test different palette combinations
            palette1 = EntroPlots.get_color_palette(false, false)
            @test palette1 == EntroPlots.AA_PALETTE3
            
            palette2 = EntroPlots.get_color_palette(true, true)
            @test palette2 == EntroPlots.PALETTE_pos
            
            palette3 = EntroPlots.get_color_palette(true, false)  
            @test palette3 == EntroPlots.PALETTE_neg
        end

        @testset "Coordinate Computation" begin
            # Test coordinate generation
            coords = EntroPlots.freq2xy_general(pfm, EntroPlots.dna_letters; background=background)
            @test length(coords) == 4  # 4 nucleotides
            @test all(c -> c[1] ∈ EntroPlots.dna_letters, coords)  # correct characters
            
            # Test protein coordinates
            protein_coords = EntroPlots.freq2xy_general(pfm_protein, EntroPlots.protein_letters; background=protein_background)
            @test length(protein_coords) == 20  # 20 amino acids
        end

        @testset "Utility Functions" begin
            # Test range complement function
            ranges = [2:3, 6:7]
            complement = EntroPlots.complement_ranges(ranges, 10)
            expected = [1:1, 4:5, 8:10]
            @test complement == expected
            
            # Test overlap detection
            @test EntroPlots.is_overlapping(1:3, 2:4) == true
            @test EntroPlots.is_overlapping(1:3, 4:6) == false
        end
    end

    @testset "Save Functions" begin
        @testset "Input Validation" begin
            # Test invalid PFM (doesn't sum to 1)
            invalid_pfm = [0.1 0.2; 0.2 0.3; 0.3 0.4; 0.5 0.1]  # columns sum to 1.1, 1.0 
            @test_throws AssertionError save_logoplot(invalid_pfm, background, "test.png")
            
            # Test invalid background (doesn't sum to 1)  
            invalid_bg = [0.3, 0.3, 0.3, 0.2]  # sums to 1.1, not 1
            @test_throws AssertionError save_logoplot(pfm, invalid_bg, "test.png")
            
            # Test wrong background length for protein
            @test_throws AssertionError save_logoplot(pfm_protein, background, "test.png"; protein=true)
        end

        @testset "File Creation" begin
            # Test basic save functionality (without actually creating files in tests)
            temp_dir = mktempdir()
            try
                # Test DNA save
                save_path1 = joinpath(temp_dir, "test_dna.png")
                save_logoplot(pfm, background, save_path1)
                @test isfile(save_path1)
                
                # Test protein save  
                save_path2 = joinpath(temp_dir, "test_protein.png")
                save_logoplot(pfm_protein, save_path2; protein=true)
                @test isfile(save_path2)
                
                # Test with highlighting
                save_path3 = joinpath(temp_dir, "test_highlight.png") 
                save_logoplot(pfm, background, save_path3; highlighted_regions=[2:4])
                @test isfile(save_path3)
                
            finally
                # Clean up temp directory
                rm(temp_dir; recursive=true, force=true)
            end
        end
    end

    @testset "Constants and Configuration" begin
        @testset "Letter Arrays" begin
            @test EntroPlots.dna_letters == ["A", "C", "G", "T"]
            @test EntroPlots.rna_letters == ["A", "C", "G", "U"] 
            @test length(EntroPlots.protein_letters) == 20
        end

        @testset "Default Values" begin
            @test length(EntroPlots.default_genomic_background) == 4
            @test sum(EntroPlots.default_genomic_background) ≈ 1
            @test length(EntroPlots.default_protein_background) == 20
            @test sum(EntroPlots.default_protein_background) ≈ 1
        end
    end

    @testset "Edge Cases" begin
        @testset "Minimal Data" begin
            # Test single column PFM
            single_col_pfm = [0.25; 0.25; 0.25; 0.25;;]
            p = logoplot(single_col_pfm)
            @test p isa Plots.Plot
        end

        @testset "Empty Ranges" begin
            # Test complement with full coverage
            full_ranges = [1:10]
            empty_complement = EntroPlots.complement_ranges(full_ranges, 10)
            @test isempty(empty_complement)
        end
    end
    
    @testset "Count Matrix Filtering & Fragments" begin
        @testset "Span String Formatting" begin
            # Test single fragment (columns match reference so they're removed, non-matching kept)
            counts1 = [5 5 5; 5 5 5; 0 0 0; 0 0 0]
            ref1 = BitMatrix([0 0 0; 0 0 0; 1 1 1; 0 0 0])
            n1, span1 = EntroPlots.count_fragments([counts1], [ref1], [5])
            @test n1 == 1
            @test span1 == "5-7"  # Single contiguous fragment
            
            # Test multiple fragments in one matrix
            counts2 = [10 5 5 10 5; 0 5 5 0 5; 0 0 0 0 0; 0 0 0 0 0]
            ref2 = BitMatrix([1 0 0 1 0; 0 0 0 0 0; 0 1 1 0 1; 0 0 0 0 0])
            n2, span2 = EntroPlots.count_fragments([counts2], [ref2], [10])
            @test n2 == 2
            @test span2 == "(11-12, 14)"  # Multiple fragments with parentheses
            
            # Test single position
            counts3 = [5 10; 5 0; 0 0; 0 0]
            ref3 = BitMatrix([0 1; 0 0; 1 0; 0 0])
            n3, span3 = EntroPlots.count_fragments([counts3], [ref3], [100])
            @test n3 == 1
            @test span3 == "100"  # Single position
        end
        
        @testset "Combined Spans Across Matrices" begin
            # Two matrices with different starting positions
            counts_a = [10 5 5; 0 5 5; 0 0 0; 0 0 0]
            counts_b = [5 10 5; 5 0 5; 0 0 0; 0 0 0]
            ref_a = BitMatrix([1 0 0; 0 0 0; 0 1 1; 0 0 0])
            ref_b = BitMatrix([0 1 0; 0 0 0; 1 0 1; 0 0 0])
            
            n, span = EntroPlots.count_fragments([counts_a, counts_b], [ref_a, ref_b], [1, 20])
            @test n == 3  # 1 fragment from first + 2 from second
            @test span == "(2-3, 20, 22)"  # All fragments in single parentheses
        end
        
        @testset "Edge Cases for Spans" begin
            # Empty result
            counts_empty = [10 0; 0 10; 0 0; 0 0]
            ref_empty = BitMatrix([1 0; 0 1; 0 0; 0 0])
            n_empty, span_empty = EntroPlots.count_fragments([counts_empty], [ref_empty], [1])
            @test n_empty == 0
            @test span_empty == ""
            
            # Three matrices with various patterns
            c1 = [5 5; 5 5; 0 0; 0 0]
            c2 = [5; 5; 0; 0;;]  # Single column matrix
            c3 = [5 5 10; 5 5 0; 0 0 0; 0 0 0]
            r1 = BitMatrix([0 0; 0 0; 1 1; 0 0])
            r2 = BitMatrix([0; 0; 1; 0;;])  # Single column BitMatrix
            r3 = BitMatrix([0 0 1; 0 0 0; 1 1 0; 0 0 0])
            
            n_multi, span_multi = EntroPlots.count_fragments([c1, c2, c3], [r1, r2, r3], [1, 50, 100])
            @test n_multi == 3  # 1 + 1 + 1
            @test span_multi == "(1-2, 50, 100-101)"  # col 3 of c3 matches reference (single value at row 1)
        end
        
        @testset "Backward Compatibility" begin
            # Test wrapper that assumes start index 1
            counts = [10 5 5; 0 5 5; 0 0 0; 0 0 0]
            ref = BitMatrix([1 0 0; 0 0 0; 0 1 1; 0 0 0])
            
            n, span = EntroPlots.count_fragments([counts], [ref])  # No starting_indices
            @test n == 1
            @test span == "2-3"  # Should start from position 1
        end
    end
    
    # Include gap tests
    include("test_gaps.jl")
end
