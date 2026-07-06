using Pkg; Pkg.activate(".")
using EntroPlots

# --- integer COUNT matrices (rows = A, C, G, T). NOT normalized PFMs. ---
cm1 = [70 10 10 60 50;
       10 70 10 10 20;
       10 10 70 20 20;
       10 10 10 10 10]

cm2 = [10 60 70 10 50;
       70 10 10 60 20;
       10 20 10 20 20;
       10 10 10 10 10]

# --- one-hot reference per block (BitMatrix): blue=matches ref, red=differs ---
ref1 = BitMatrix([1 0 0 1 1;
                  0 1 0 0 0;
                  0 0 1 0 0;
                  0 0 0 0 0])
ref2 = BitMatrix([0 1 1 0 1;
                  1 0 0 1 0;
                  0 0 0 0 0;
                  0 0 0 0 0])

# --- mimic your `meta` bundle ---
meta = (
    count_matrices = [cm1, cm2],
    positions      = [3, 15],          # start index of each block
    total_length   = 22,               # gaps -> strike-through line
    references     = [ref1, ref2],
    dpi            = 100,
    use_rna        = false,
    reduction_on_ref = false,          # filter_by_reference: true drops columns matching ref
)

# --- mimic your `paths.png.abs` ---
paths = (png = (abs = "example_save_rect_gaps.png",),)

EntroPlots.save_logo_with_rect_gaps(
    meta.count_matrices, meta.positions, meta.total_length,
    paths.png.abs;
    reference_pfms   = meta.references,
    dpi              = meta.dpi,
    rna              = meta.use_rna,
    xrotation        = 35,
    protein          = size(meta.count_matrices[1], 1) == 20,  # false for 4-row nt
    uniform_color    = true,
    filter_by_reference = meta.reduction_on_ref,
    ref_match_color    = "#1434A4",   # default blue (match)
    ref_mismatch_color = "#2E8B57",   # was :darkred — now sea green
)

println("✓ Saved: ", paths.png.abs)
