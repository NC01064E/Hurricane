#!/usr/bin/env python3
"""Single source of truth for the garage workshop plan: geometry, cut list, leaf weight, budget.
Run:  python3 model.py          (prints a report and runs self-checks)
All dimensions in inches unless noted. H (wall height) is an ASSUMPTION until measured."""
import math, csv, sys, json, os

H = 96.0                      # wall height - MEASURE at 3+ points, use the lowest
L = 228.0                     # partition length (19'0")
PLATE_PT, TOP_PLATES = 1.5, 3.0
HEADER = 5.5 + 0.5 + 5.5      # 2x6 + 1/2" ply + 2x6
OPEN_W = 84.0                 # clear between jack studs
LEAF_W = 41.75
GAP_SIDE, GAP_TOP, GAP_BOT_ABOVE_BAR = 0.125, 0.125, 0.25
BAR = 1.5                     # PT 2x4 laid flat
PACK = 3.0                    # jack + king

# ---- horizontal string (x measured from left exterior wall) ----
left_pack = (0, PACK)
open_l, open_r = PACK, PACK + OPEN_W            # 3 .. 87
right_pack = (open_r, open_r + PACK)            # 87 .. 90
fixed_start = right_pack[1]                     # 90
assert abs(L - (PACK + OPEN_W + (L - open_r))) < 1e-9
plate_right_len = L - open_r                    # 141 = 11'9"  (right pack + fixed wall)
leaf_pair_w = 2 * LEAF_W + 3 * GAP_SIDE         # three 1/8" gaps
opener_cl = L / 2                               # 114 = 9'6" (VERIFY: opener may be offset)

# ---- vertical string ----
open_h = H - TOP_PLATES - HEADER                # slab to underside of header (no plate in opening)
leaf_h = open_h - GAP_TOP - BAR - GAP_BOT_ABOVE_BAR
leaf_h_nobar = open_h - GAP_TOP - GAP_BOT_ABOVE_BAR
stud_len = H - PLATE_PT - TOP_PLATES
jack_len = open_h - PLATE_PT

MID_SEG1 = 39.375          # top rail to mid rail; puts mid-rail centre 38" above leaf bottom (rim deadbolt height)
# ---- leaf weight (SYP 2x4 ~1.28 lb/ft, board psf, hardware) ----
def leaf_weight(h, room_psf=1.4, garage_psf=2.0):
    ft = lambda inch: inch / 12
    stiles = 4 * ft(h) * 1.28
    rails = 3 * ft(LEAF_W - 6) * 1.28
    center = ft(h - 4.5) * 1.28
    z = ft(math.hypot(LEAF_W - 6, h - 3)) * 1.28
    area = LEAF_W * h / 144
    boards = area * (room_psf + garage_psf)
    insul = area * 0.12
    hw = 12.0           # hinges, bolts, wheel, deadbolt, sweep, astragal
    return stiles + rails + center + z + boards + insul + hw, area
LEAF_LB, LEAF_AREA = leaf_weight(leaf_h)

# ---- cut list (2x4x8 = 96", kerf 1/8") ----
def pack(pieces, stock=96.0, kerf=0.125):
    bins = []
    for name, ln in sorted(pieces, key=lambda p: -p[1]):
        for b in bins:
            if b["left"] >= ln + kerf:
                b["cuts"].append((name, ln)); b["left"] -= ln + kerf; break
        else:
            bins.append({"cuts": [(name, ln)], "left": stock - ln - kerf})
    return bins
P = []
P += [("fixed stud", stud_len)] * 9                       # end + 7 intermediate + nailer
P += [("notch trimmer", stud_len)] * 2
P += [("king", stud_len)] * 2 + [("jack", jack_len)] * 2
P += [("notch head/sill", 14.0)] * 4
for nm, ln in [("top plate A1", 96), ("top plate A2", 96), ("top plate A3", 36),
               ("top plate B1", 48), ("top plate B2", 96), ("top plate B3", 84)]:
    P.append((nm, ln))
for leaf in "AB":
    P += [(f"leaf {leaf} stile", leaf_h)] * 4
    P += [(f"leaf {leaf} rail", LEAF_W - 6)] * 3
    P += [(f"leaf {leaf} center stile", MID_SEG1), (f"leaf {leaf} center stile", leaf_h - 1.5 - MID_SEG1 - 1.5 - 1.5)]
    P += [(f"leaf {leaf} Z-brace", math.hypot(LEAF_W - 6, leaf_h - 3))]
    P += [(f"leaf {leaf} blocking", 10.0)] * 2
bins = pack(P)
SOFFIT_ALLOWANCE = 3
STUDS_PACKED = len(bins)
STUDS_BUY = STUDS_PACKED + SOFFIT_ALLOWANCE + 3     # soffit framing + crooked/defect allowance
PT_PACK = pack([("plate (right pack + fixed)", plate_right_len), ("left-pack pad", 3.0),
                ("threshold bar", OPEN_W)], stock=144.0)

if __name__ == "__main__":
    f = lambda x: f"{int(x//12)}'-{x%12:.3f}\""
    print(f"H={H}  open_h={open_h}  leaf_h={leaf_h} ({leaf_h_nobar} w/o bar)  stud={stud_len} jack={jack_len}")
    print(f"opening string: left pack {PACK} + opening {OPEN_W} + plate/right pack/fixed {plate_right_len} = {PACK+OPEN_W+plate_right_len}")
    print(f"leaf pair needs {leaf_pair_w}\" vs opening {OPEN_W}\"; leaf area {LEAF_AREA:.1f} sf; leaf weight ~{LEAF_LB:.0f} lb")
    print(f"opener centerline x={opener_cl}; {opener_cl-open_r}\" right of opening")
    print(f"2x4x8 packed: {STUDS_PACKED}  buy: {STUDS_BUY} (+{SOFFIT_ALLOWANCE} soffit, +3 defects)")
    for i, b in enumerate(bins, 1):
        print(f"  #{i}: " + ", ".join(f"{n} {l:.2f}" for n, l in b['cuts']) + f"  | left {b['left']:.2f}")
    print("PT 2x4x12 boards:", len(PT_PACK))
    for b in PT_PACK: print("  ", [(n, round(l,2)) for n, l in b['cuts']], "left", round(b['left'],2))
    # board layout per face
    print("fixed wall board run:", L - fixed_start, "in -> sheets:", math.ceil((L - fixed_start)/48))
    print("header strip height:", H - open_h, " leaf skin offcut:", H - leaf_h, " 2 offcuts x48 >= 90:", 2*48>=90)
    # G-Floor
    print("G-Floor: 2 rolls 7.5x17 area", 2*127.5, "vs room", 19*12, "; along 19' leaves", 19-17, "ft gap x 12 ft")
    # lighting
    for n in (3, 4): print(f"{n} panels: {n*4692} lm = {n*4692/228:.0f} lm/sf")
