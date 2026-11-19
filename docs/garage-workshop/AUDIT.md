# Audit of the Garage Workshop Conversion plan (2026-11-19)

Scope: all 11 pages of the original PDF - the three schematics, the written plan, the priced shopping list and the budget. I re-added every price, re-derived every dimension and board/lumber quantity from the plan's own framing, and checked specific product and code claims against public sources.

**What this audit is not.** It is not an engineer's or inspector's sign-off. Prices were not re-checked at a store. Code items are flags to confirm with your building department, not rulings.

## Summary

| # | Type | Finding | Where fixed |
|---|---|---|---|
| 1 | **Fix** | A 2x6 meeting stile cannot be used in a 3-1/2" deep leaf; the single 2x4 hinge stile gives only 1-1/2" of screw bite | CUTLIST (doubled 2x4 stiles) |
| 2 | **Fix** | Leaf height "77-3/4"" does not follow from the framing; threshold bar and "no plate across the opening" contradict each other | CUTLIST formulas |
| 3 | **Fix** | Leaf weight is understated (110-130 lb vs ~135-160 lb); hinge count/rating needs to rise | CUTLIST hardware |
| 4 | **Fix** | 2x4x8 count is short (plan ~30; framing needs ~35 packed, 41 to buy) | CUTLIST |
| 5 | **Fix** | The plan says "NOT paper-faced" board, then buys USG Mold Tough, which is described as paper-faced | BUDGET / PLAN |
| 6 | **Fix** | Two 7.5 x 17 ft G-Floor rolls cannot cover a 19 x 12 ft room with "one center seam" | PLAN |
| 7 | **Fix** | Lithonia CPX panels dim 0-10V; Lutron Caseta dimmers are phase-cut. App/voice also needs the Smart Hub | PLAN / BUDGET |
| 8 | **Fix** | Electrical list covers one circuit, not four; garage receptacles need GFCI; 2" raceway is specified but never priced | BUDGET |
| 9 | **Fix** | Budget totals omit tax, Phase 3 electrician labor, permit, network gear, realistic fasteners and paint | BUDGET |
| 10 | **Decide** | 18K mini-split contradicts the plan's own "don't oversize" humidity rule | PLAN |
| 11 | **Decide** | The two exterior block walls and the exterior door are never addressed as humidity/heat paths | PLAN |
| 12 | **Decide** | The opener soffit lands on the treadmill's front end; gym equipment sits on a sloped slab | PLAN |
| 13 | **Verify** | Field measurements and code checks before cutting lumber | CHECKLIST Phase 0 |

## Fix before building

### 1. Stile geometry (build plan error)
The leaf frame is 2x4 on edge, so it is 3-1/2" deep and the finished leaf is 4-1/2" with two 1/2" skins. A nominal 2x6 is 5-1/2" on its long side, so a "2x6 meeting stile" either sticks out 2" or has to lie flat (1-1/2" deep), neither of which is what Schematic 3 shows. Separately, the hinge stile is a single 2x4 on edge, which is 1-1/2" wide: the plan's 3" hinge screws would pass through it and out the far side.
**Fix:** double the 2x4 stiles at both edges (3" wide x 3-1/2" deep). The hinge screws now bite 3", the rim-deadbolt strike through-bolts into solid wood, and the astragal screws get real meat. This changes the buy list: 2x6x8 drops from 4 to 2, 2x4x8 rises by about 4.

### 2. Leaf height and the threshold bar
With an 8'-0" wall, a double top plate (3") and the plan's 11-1/2" header (2x6 + 1/2" ply + 2x6) directly under it, the opening is 81-1/2" high. Subtracting a 1/8" top gap, a 1-1/2" flat bar and 1/4" over the bar gives a leaf **79-5/8"** tall (81-1/8" with no bar). The plan's 77-3/4" has no derivation in the text. Also, page 6 forbids a bottom plate across the opening as a trip hazard, then page 6 and 7 add a "removable threshold bar" across the opening. Both can be true only if the leaf is built to clear the bar; the bar is a trip hazard whenever it is in place.
**Fix:** use `leaf = H - 16.375"` (with bar) from the measured lowest ceiling height H. Decide whether you are willing to live with the bar in place. Unscrew it only to move equipment; the sweep seals to the bar, so the seal is lost while it is out.

### 3. Leaf weight and hinges
Recomputed from the cut list (frame lumber, 2.0 psf garage board, 1.4 psf room board, insulation, 12 lb hardware): about **156 lb** at H = 96". Use 135-160 lb as the design load. Each leaf is 41-3/4" wide and 4-1/2" thick, so the hinge load is not trivial.
**Fix:** four hinges per leaf (eight total) instead of three, and read the rated load on the Global Door Controls spec sheet before buying. The \$18.48 three-hinge set is a residential price point; if the rating is below roughly 75 lb per hinge, use heavy-weight 5" hinges. The spring gate wheel stays.

### 4. Lumber count
Packing the plan's own framing (9 fixed studs, 2 notch trimmers, 2 kings, 2 jacks, double top plate, two leaves of doubled stiles, rails, center stiles and a Z-brace each) onto 8-foot boards takes **35** boards, plus soffit framing and defects: **41**. The plan said about 30. See `CUTLIST.md` for the board-by-board packing.

### 5. Mold-resistant board
The plan says the garage face lives in hot humid air and must be fiberglass-faced ("NOT paper-faced board"), lists "USG Mold Tough class" among the examples, then prices and buys *USG Mold Tough*. A Fine Homebuilding review describes Mold Tough as a **paper-faced** panel with a mold-inhibitor in the paper; USG's own comparison page is less clear, so check the current datasheet. DensArmor Plus is the glass-mat product ([GP](https://www.buildgp.com/densarmorplus-high-performance-gypsum-panels), [Fine Homebuilding](https://finehomebuilding.com/2009/09/30/sheetrock-mold-tough-review)). If your rule is "no paper face", buy glass-mat and use mesh tape with setting compound; the plan's paper tape is for the ceiling only.

### 6. Flooring layout
Two 7.5 x 17 ft rolls have the right *area* (255 sf for 228 sf) but not the right *shape*. The room is 19 ft wide. Laid lengthwise, 17 ft leaves a 2 x 12 ft gap; laid crosswise, 15 ft of rolls leaves a 4 x 12 ft gap. Two rolls can work only with a cross seam, filling the 2 ft end gap from the roll's offcut. The plan's "one center seam" is wrong; expect two seams and plan the offcut before cutting. 7.5 x 17 is a real G-Floor size ([listing](https://www.lowes.com/pd/G-Floor-Levant-7-1-2-ft-x-17-ft-Slate-Grey-Leather-Garage-Floor-Roll/1000602163)).

### 7. Dimming
The plan puts "standard fixtures on one smart dimmer" and chooses the Lithonia CPX 2x4 4,692 lm panel. A distributor listing for exactly that panel (4000K, 39 W, 4,692 lm) specifies **0-10V dimming**, and Acuity lists 0-10V as the CPX dimming protocol ([Border States](https://borderstates.com/All-Products/Lighting/Lighting-Fixtures-Components/Indoor-Lighting/LED-Panels/Lithonia-CPX-Series-LED-Panels/Lithonia-CPX-Series-LED-Panels-2-x-4-ft-4000-K-39-W-0---10-V-Dimming-4692-lm/p/3554979), [Acuity](https://www.acuitybrands.com/products/detail/1065807/lithonia-lighting/cpx/led-panel)). Lutron Caseta wall dimmers are phase-cut and will not drive a 0-10V dimming lead. Separately, Caseta dimmers work on their own, but app and voice control need the Lutron Smart Hub ([Lutron support](https://support.lutron.com/us/en/product/casetawireless/article/using-the-app/Amazon-Alexa-and-how-to-Set-Up-and-Troubleshoot-within-the-Caseta-or-RA2-Select-Systems)), which is not on the list.
**Fix:** pick one: (a) keep the CPX panels and add 0-10V wall dimmers, (b) choose a phase-dimmable panel to keep Caseta, or (c) drop smart dimming. Add the hub if you keep Caseta. Confirm the exact catalog number before buying.
Lumens, for reference: 3 panels = 14,076 lm (62 lm/sf) already exceed the plan's own 50 lm/sf target for 228 sf; 4 panels = 18,768 lm (82 lm/sf). Four are fine if you want two zones.

### 8. Electrical list
The plan wants a dedicated treadmill circuit, bench outlets, a TV wall, a dedicated 20A for the network UPS and a 240V mini-split circuit. The Phase 3 materials are **one** 20A breaker, **50 ft** of 12/2 and ten standard receptacles for \$99.36. Receptacles in a garage must be GFCI-protected (NEC 210.8; confirm your edition), and a panel run is usually longer than 50 ft. The 2" PVC raceway to the attic, long-sweep elbows, straps, pull string and firestop sealant are specified in Phase 2 but not priced.
**Fix:** see `BUDGET.md` additions A4, A7-A9 and A11.

### 9. Budget completeness
Arithmetic is right (see "Verified correct" below). The *list* is incomplete: no sales tax, no Phase 3 electrician labor, no permit, no network enclosure/UPS/Cat6, fasteners at \$10-15 for about 11 sheets of wall board plus structural framing, no masonry bit, no second ceiling coat or garage-face paint, and Phases 1 and 2 priced above their own rough ranges. Realistic: **Phases 1-3 about \$4.3-5.6k** (not \$3.1k), **full project about \$6.2-8.5k with the Hessaire** and \$7.2-9.4k with the MRCOOL. Details in `BUDGET.md`.

## Decide

### 10. 18K vs 12K
The plan's central goal is low RH for steel, and it warns that oversizing short-cycles the unit and leaves humidity high. Its own justification for 18K is gym heat. A hand estimate of peak load for 228 sf (insulated ceiling and partition, two uninsulated block walls, exterior door, two people exercising, a running treadmill, the towers, lights and the water-heater standby) lands around **7,000-9,500 BTU/h**, which is a 12K unit's range, not 18K's. This is a rough estimate. Run a free Manual J or ask the installer before buying; do not buy on the whole-garage sizing the plan started from.

### 11. The room's other envelope
The plan insulates the partition and ceiling, but the conditioned room also has two exterior walls (about 190 sf, probably block), an exterior door, and the slab. These are the largest moisture and heat paths for steel storage. Decide whether to leave them (seal and paint the block, weatherstrip the door, VCI and desiccant for the steel) or furr and insulate them. Confirm what the walls are made of first.

### 12. Opener soffit, treadmill and slab slope
- The soffit around the opener rail and motor projects 1-2 ft into the room on the opener centerline, which on the plan runs through the treadmill's front end. A runner on an 8-10" deck is near 6'-10" tall at the front. Keep the soffit bottom well above that or move the treadmill. The plan's optional jackshaft (side-mount) opener (\$400-\$500) removes the rail and soffit entirely.
- The slab falls 1/8-1/4" per ft toward the door. Over the 12 ft room that is 1.5-3" of fall. The plan uses this for the leaf swing but never mentions it for the treadmill, rack and bench; plan to shim and level them.
- The rack drawn is about 2.2 x 2.6 ft, smaller than a typical power rack. A 7 ft bar needs clearance on both sides, and the left wall and exterior-door arc are close.

## Verify in the field (Phase 0)
Measure ceiling height at 3+ points and use the lowest. Locate the opener centerline, motor, and the rail height where it crosses the wall (it is often not centered). Measure the overhead door height and how far the open door panels and track extend back; the partition is only 8 ft off the door, and a taller door pushes the open panels farther back. Confirm joist/truss spacing and direction (24" OC needs 5/8" or sag-resistant 1/2" board for the ceiling). Run the slab moisture test. Find the panel's spare capacity and the distance to the garage. Identify the exterior wall construction. Read the hinge rating on the spec sheet. Confirm the house door meets code: Florida's 2017 residential supplement lists a solid-wood (1-3/8"), solid or honeycomb steel, or 20-minute rated door **with a self-closing device** between garage and residence, and the current edition may differ ([FBC supplement](https://www.floridabuilding.org/fbc/commission/fbc_0617/May/Supplement_HB_1021.pdf)). Ask the building department whether the mini-split and the 240V circuit need permits and a licensed contractor; the plan treats the permit as optional.

## Verified correct

- Phase totals \$828.40 / \$1,310.77 / \$971.83 = \$3,111.00, and the 7% tax (\$3,329). The Phase 1 "exact quantities" figure (\$748.53) is also consistent with the sealant case premium.
- Phase 4 and full-project sums (\$4,859-\$5,509 Hessaire, \$5,770-\$6,420 MRCOOL).
- Areas: 19 x 8 = 152 sf, 19 x 12 = 228 sf; 5 sheets per face (3 for the fixed run + 2 for the leaves, with offcuts covering the header strip); 8 sheets for the ceiling; R-13 (4 rolls) and R-30 (264 sf for 228 sf) coverage; lumens.
- The dimension string closes: 3" left pack + 7'-0" opening + 11'-9" (right pack + fixed) = 19'-0". The opener centerline at 9'-6" lands 27" (2'-3") right of the opening, and two leaves plus three 1/8" gaps = 83-7/8" fit the 84" opening. A 87" header fits a 2x6x8.
- The Z-brace direction (low at hinge side, high at meeting side) is correct for a leaf in compression.
- The swing reasoning is correct: a slab that falls toward the door makes an outswing leaf swing downhill and gain clearance.
- The soffit-and-hatch approach for the opener and the sealing/firestopping of the raceway and notch are sound in principle.

## Stale or contradictory text in the original
- "The right jamb is the hinge post for the heavier side" - the two leaves are identical; both jambs get the same treatment.
- Schematic labels overlap in the PDF (page 2 notch labels, "2x6 MEETING STILES", "FIXED WALL" note); the redrawn schematics fix this.
- Schematic 1 draws the 42" fans at about 2 ft diameter; at true scale (3.5 ft) fan 2 would cross the partition. The redrawn plan moves it.

## Sources
- Lithonia CPX: [Acuity product page](https://www.acuitybrands.com/products/detail/1065807/lithonia-lighting/cpx/led-panel), [Border States listing](https://borderstates.com/All-Products/Lighting/Lighting-Fixtures-Components/Indoor-Lighting/LED-Panels/Lithonia-CPX-Series-LED-Panels/Lithonia-CPX-Series-LED-Panels-2-x-4-ft-4000-K-39-W-0---10-V-Dimming-4692-lm/p/3554979)
- Lutron Caseta hub: [Lutron support](https://support.lutron.com/us/en/product/casetawireless/article/using-the-app/Amazon-Alexa-and-how-to-Set-Up-and-Troubleshoot-within-the-Caseta-or-RA2-Select-Systems), [Lowe's hub page](https://www.lowes.com/pd/Lutron-Caseta-White-Smart-Control-Hub/1000449709)
- Mold Tough vs DensArmor Plus: [Fine Homebuilding review](https://finehomebuilding.com/2009/09/30/sheetrock-mold-tough-review), [GP DensArmor Plus](https://www.buildgp.com/densarmorplus-high-performance-gypsum-panels)
- Garage-to-house door: [Florida Building Commission supplement](https://www.floridabuilding.org/fbc/commission/fbc_0617/May/Supplement_HB_1021.pdf)
- G-Floor Levant 7.5 x 17: [Lowe's listing](https://www.lowes.com/pd/G-Floor-Levant-7-1-2-ft-x-17-ft-Slate-Grey-Leather-Garage-Floor-Roll/1000602163)
