# transparency for non-highlighted regions
const _alpha_ = 0.35
# default_genomic_background
const default_genomic_background = [0.25 for _ = 1:4]
const bg = default_genomic_background
# The maximum length of the crosslinking tendencies
const crosslink_stretch_factor = 6.0
crosslink_stretch_factor2 = 4.0

# maximum height of the logo
const ylim_max = 2
# how much space to leave on the left of the logo
const xlim_min = -0.5
# logo height
const logo_height = 220
# logo yticks
const yticks = 0:1:2
yticks_protein = 0:1:4
const yminorticks = 2
const ytickfontsize = 185
ytickfontsize_protein = 100
# logo xticks
const xtickfontsize = 175
xtickfontsize_protein = 100
# logo font settings
const logo_font = "Helvetica"
const logo_font_size = 45

# default resolution for the logo
const default_dpi = 80

# default thickness_scaling
const thickness_scaling = 0.0525

# default margin 
# const margin = 275Plots.mm # CLIP
const margin = 100Plots.mm # CLIP
