# -----------------------------
# Rectangles
# -----------------------------
rectangle(x, y, w, h) = (; x = (x .+ [0, w, w, 0]), y = (y .+ [0, 0, h, h]))

const BASIC_RECT = rectangle(0.2, 0.0, 0.6, 1.0)
const C_RECT = rectangle(0.0, 0.0, 0.5, 1.0)
