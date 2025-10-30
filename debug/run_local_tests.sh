#!/bin/bash
# Helper script to run tests with the LOCAL version of EntroPlots

echo "=========================================="
echo "Testing LOCAL EntroPlots"
echo "=========================================="
echo ""
echo "Running from: $(pwd)"
echo ""

# Run the tests
julia --project=. -e '
using Pkg
Pkg.instantiate()

using Revise
using EntroPlots

println("EntroPlots location: ", pathof(EntroPlots))
println("Version info:")
println(Pkg.project())
println()
'

echo ""
echo "To run a specific test file:"
echo "  julia --project=. test_gap_issue.jl"
echo "  julia --project=. test_gap_visibility.jl"
echo "  julia --project=. test_reference_colors.jl"
echo ""
echo "Or start Julia with the local project:"
echo "  julia --project=."
echo "  then: include(\"test_gap_issue.jl\")"
echo ""
