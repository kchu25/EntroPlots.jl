# ===========================
# EntroPlots Constants
# ===========================
# This file defines all constants used throughout EntroPlots.jl

# ===========================
# Transparency Settings
# ===========================
const _alpha_ = 0.35  # Transparency for non-highlighted regions

# ===========================
# Background Frequencies
# ===========================
const default_genomic_background = [0.25 for _ = 1:4]
const default_protein_background = fill(1/20, 20)
const bg = default_genomic_background

# ===========================
# Crosslinking Parameters
# ===========================
const crosslink_stretch_factor = 6.0
const crosslink_stretch_factor2 = 4.0  # TODO: Make const or remove if unused

# ===========================
# Logo Dimensions & Limits
# ===========================
const ylim_max = 2              # Maximum height of the logo
const xlim_min = -0.5           # Space to leave on the left of the logo
const logo_height = 220         # Logo height in pixels

# ===========================
# Tick Settings
# ===========================
const yticks = 0:1:2
const yticks_protein = 0:1:4
const yminorticks = 2

# Font sizes for different contexts
const ytickfontsize = 185
const xtickfontsize = 175
const ytickfontsize_protein = 125
const xtickfontsize_protein = 100
const ytickfontsize_protein_rect = 275
const xtickfontsize_protein_rect = 250

# ===========================
# Font Settings
# ===========================
const logo_font = "Helvetica"
const logo_font_size = 45

# ===========================
# Rendering Settings
# ===========================
const default_dpi = 80          # Default resolution for logos
const thickness_scaling = 0.0525 # Default thickness scaling
const margin = 100Plots.mm      # Default margin (was 275 previously)
