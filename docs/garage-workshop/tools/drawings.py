#!/usr/bin/env python3
"""Draws the three schematics as SVG from model.py dimensions (so drawings and numbers cannot disagree)."""
import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
import model as m
OUT = os.path.join(os.path.dirname(__file__), "..", "drawings"); os.makedirs(OUT, exist_ok=True)
INK, MUTE, BLUE, WARN, FILL = "#1b1b1b", "#666", "#0b5cab", "#b45309", "#eef3f8"

def svg(w, h, body, title):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'font-family="Helvetica,Arial,sans-serif" role="img" aria-label="{title}">'
            f'<rect width="{w}" height="{h}" fill="#fff"/>{body}</svg>')
def line(x1,y1,x2,y2,c=INK,w=1,dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{c}" stroke-width="{w}"{d}/>'
def rect(x,y,w,h,fill="none",c=INK,sw=1,dash=None,rx=0):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" fill="{fill}" stroke="{c}" stroke-width="{sw}" rx="{rx}"{d}/>'
def text(x,y,s,size=11,c=INK,anchor="start",weight="normal",rot=None):
    t = f' transform="rotate({rot} {x:.1f} {y:.1f})"' if rot is not None else ""
    return f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{c}" text-anchor="{anchor}" font-weight="{weight}" stroke="#fff" stroke-width="3" paint-order="stroke"{t}>{s}</text>'
def circ(cx,cy,r,fill="none",c=INK,sw=1,dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}" stroke="{c}" stroke-width="{sw}"{d}/>'
def arc(cx,cy,r,a0,a1,c=MUTE,dash="4 3"):
    x0,y0 = cx+r*math.cos(math.radians(a0)), cy-r*math.sin(math.radians(a0))
    x1,y1 = cx+r*math.cos(math.radians(a1)), cy-r*math.sin(math.radians(a1))
    sweep = 0 if a1 > a0 else 1
    return f'<path d="M{x0:.1f} {y0:.1f} A{r:.1f} {r:.1f} 0 0 {sweep} {x1:.1f} {y1:.1f}" fill="none" stroke="{c}" stroke-width="1" stroke-dasharray="{dash}"/>'
def dim(x1,y1,x2,y2,label,off=0,vertical=False,size=11):
    if vertical:
        return (line(x1,y1,x2,y2,MUTE,1)+line(x1-4,y1,x1+4,y1,MUTE)+line(x2-4,y2,x2+4,y2,MUTE)+
                text(x1-6,(y1+y2)/2,label,size,MUTE,"middle",rot=-90))
    return (line(x1,y1,x2,y2,MUTE,1)+line(x1,y1-4,x1,y1+4,MUTE)+line(x2,y2-4,x2,y2+4,MUTE)+
            text((x1+x2)/2,y1-5,label,size,MUTE,"middle"))

# ------------------------------------------------------------------ 1. FLOOR PLAN
def floor_plan():
    s=30; ox,oy=70,70                      # 30 px/ft
    X=lambda ft: ox+ft*s; Y=lambda ft: oy+ft*s
    b=[text(ox,34,"SCHEMATIC 1 - FLOOR PLAN (corrected)",15,INK,weight="bold"),
       text(ox,52,"Garage 19 x 20 ft. Back wall (house side) at top; overhead door at bottom. Scale 30 px = 1 ft. Furniture positions illustrative.",11,MUTE)]
    b.append(rect(X(0),Y(0),19*s,12*s,"#fff"))
    b.append(rect(X(0),Y(12),19*s,8*s,"#f3f4f6"))
    b.append(rect(X(0),Y(0),19*s,20*s,"none",INK,3))
    # partition
    pl = m.PACK/12; o1=(m.PACK+m.OPEN_W)/12
    b.append(line(X(o1+0.25),Y(12),X(19),Y(12),INK,5))
    b.append(rect(X(0),Y(12)-3,pl*s,6,INK))            # left jamb pack
    b.append(rect(X(o1-0.0),Y(12)-3,0.25*s,6,INK))      # right jamb pack
    # leaves + swing arcs (hinged at jambs, swing OUT = down in plan)
    lw=m.LEAF_W/12
    la_h=(pl+0.01); lb_h=(o1-0.01)
    b.append(line(X(la_h),Y(12),X(la_h+lw),Y(12),BLUE,4)); b.append(line(X(lb_h-lw),Y(12),X(lb_h),Y(12),BLUE,4))
    b.append(arc(X(la_h),Y(12),lw*s,0,-90)); b.append(arc(X(lb_h),Y(12),lw*s,180,270))
    b.append(text(X(0.2),Y(12)-8,"HINGED LEAVES 7'-0\" clear - OUTSWING (hinges + pins on storage side)",10,BLUE,weight="bold"))
    # back wall items
    b.append(rect(X(0.3),Y(0.2),6.8*s,1.8*s,"#fff")); b.append(text(X(3.7),Y(1.2),"WORKBENCH",10,INK,"middle",weight="bold"))
    b.append(rect(X(7.3),Y(0.2),1.6*s,1.8*s,"#fff")); b.append(text(X(8.1),Y(1.2),"cab.",9,MUTE,"middle"))
    b.append(rect(X(9.3),Y(0.05),3*s,0.45*s,BLUE)); b.append(text(X(10.8),Y(0.95),"mini-split head (Phase 4)",9,MUTE,"middle"))
    b.append(line(X(13.9),Y(0),X(16.9),Y(0),"#fff",5)); b.append(arc(X(13.9),Y(0),3*s,0,90)); b.append(text(X(15.4),Y(-0.3),"door to house (swings into house)",9,MUTE,"middle"))
    b.append(circ(X(17.8),Y(1.6),1.08*s,"#fff")); b.append(text(X(17.8),Y(1.55),"WH",10,INK,"middle",weight="bold")); b.append(text(X(17.8),Y(1.95),"80 gal",8,MUTE,"middle"))
    b.append(rect(X(18.35),Y(2.9),0.65*s,1.8*s,FILL)); b.append(text(X(18.7),Y(3.8),"NET",8,BLUE,"middle",rot=-90))
    b.append(text(X(18.25),Y(3.9),"network enclosure (right of WH)",9,MUTE,"end"))
    # left wall ext door
    b.append(line(X(0),Y(1.7),X(0),Y(4.7),"#fff",5)); b.append(arc(X(0),Y(1.7),3*s,180,270)); b.append(text(X(0.2),Y(5.5),"ext. door (swings OUT)",9,MUTE))
    # LED panels (4x 2x4)
    for (cx,cy) in [(4.5,3.6),(10,3.6),(4.5,9.3),(14.5,5.6)]:
        b.append(rect(X(cx-2),Y(cy-1),4*s,2*s,"none",MUTE,1,"5 4"))
    
    # rack, treadmill, seating, TV, fans
    b.append(rect(X(0.25),Y(6.0),2.2*s,2.6*s,"#fff")); b.append(text(X(1.35),Y(7.3),"RACK",9,INK,"middle",rot=-90))
    b.append(rect(X(8.6),Y(6.2),2.8*s,5.0*s,"#fff")); b.append(text(X(10.0),Y(9.7),"TREADMILL",9,INK,"middle"))
    b.append(circ(X(10.0),Y(8.1),1.75*s,"none",BLUE,1,"4 3")); b.append(text(X(10),Y(8.1),"fan 1 (42 in)",9,BLUE,"middle"))
    b.append(rect(X(14.3),Y(7.1),3.3*s,3.5*s,"#fff")); b.append(text(X(15.95),Y(8.4),"SEATING",9,INK,"middle",weight="bold")); b.append(text(X(15.95),Y(8.8),"mancave",8,MUTE,"middle"))
    b.append(circ(X(15.95),Y(9.2),1.75*s,"none",BLUE,1,"4 3")); b.append(text(X(15.95),Y(10.1),"fan 2",9,BLUE,"middle"))
    b.append(rect(X(18.8),Y(7.4),0.2*s,4.5*s,BLUE)); b.append(text(X(18.55),Y(9.7),"TV",9,INK,"end"))
    # opener
    b.append(line(X(m.opener_cl/12),Y(12),X(m.opener_cl/12),Y(20),BLUE,1.5,"6 4"))
    b.append(rect(X(m.opener_cl/12-0.9),Y(10),1.8*s,2*s,"rgba(180,83,9,.15)",WARN,1.5,"4 3"))
    b.append(text(X(m.opener_cl/12+1.0),Y(12.6),"opener soffit (assumed 2 ft deep, drawn dashed above)",9,WARN))
    b.append(text(X(m.opener_cl/12+1.0),Y(12.95),"overlaps treadmill front - verify clearance",9,WARN))
    b.append(text(X(m.opener_cl/12+0.15),Y(14.2),"opener rail crosses FIXED wall at 9'-6\"",9,BLUE))
    # storage
    b.append(text(X(9.5),Y(16.3),"STORAGE - UNCONDITIONED",12,INK,"middle",weight="bold")); b.append(text(X(9.5),Y(16.9),"lawn equipment, fuel - 19 x 8 ft (keep leaf swing zones clear)",10,MUTE,"middle"))
    b.append(text(X(9.5),Y(19.2),"OVERHEAD DOOR",11,INK,"middle",weight="bold"))
    # dims + slope
    b.append(dim(X(0),Y(20)+26,X(19),Y(20)+26,"19'-0\""))
    b.append(dim(X(19)+26,Y(0),X(19)+26,Y(12),"12'-0\"",vertical=True)); b.append(dim(X(19)+26,Y(12),X(19)+26,Y(20),"8'-0\"",vertical=True))
    b.append(f'<defs><marker id="a" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0 0L6 3L0 6z" fill="{WARN}"/></marker></defs>')
    b.append(line(X(18),Y(14.6),X(18),Y(18.3),WARN,1.5)); b.append(f'<line x1="{X(18):.1f}" y1="{Y(18.0):.1f}" x2="{X(18):.1f}" y2="{Y(18.6):.1f}" stroke="{WARN}" stroke-width="1.5" marker-end="url(#a)"/>')
    b.append(text(X(17.7),Y(15.5),"slab falls toward door",9,WARN,"end")); b.append(text(X(17.7),Y(15.9),"1/8-1/4 in per ft (1.5-3 in over 12 ft)",9,WARN,"end"))
    return svg(ox*2+19*s+30, oy+20*s+70, "".join(b), "Corrected floor plan")

# ------------------------------------------------------------------ 2. WALL ELEVATION
def elevation():
    k=3.3; ox,oy=80,70                      # px per inch
    X=lambda i: ox+i*k; Y=lambda i: oy+(m.H-i)*k     # i from slab, upward
    W=m.L; H=m.H
    b=[text(ox,34,"SCHEMATIC 2 - PARTITION WALL ELEVATION (from the conditioned room)",15,INK,weight="bold"),
       text(ox,52,f"Assumes {H:.0f}\" wall height - rebuild from the measured lowest ceiling height. All screwed, demountable.",11,MUTE)]
    # top plates, header
    b.append(rect(X(0),Y(H),W*k,m.TOP_PLATES*k,"#e5e7eb"))
    b.append(text(X(130),Y(H)+m.TOP_PLATES*k-2.5,"double 2x4 top plate (stagger joints)",9,MUTE))
    b.append(rect(X(0),Y(H-m.TOP_PLATES),m.right_pack[1]*k,m.HEADER*k,FILL,INK,1.2))
    b.append(text(X(45),Y(H-m.TOP_PLATES)+22,"double 2x6 header + 1/2\" ply spacer",10,MUTE,"middle"))
    b.append(text(X(45),Y(H-m.TOP_PLATES)+36,"(87\" long, hung from top plates)",9,MUTE,"middle"))
    # packs
    for x0 in (0,m.open_r):
        b.append(rect(X(x0),Y(m.H-m.TOP_PLATES-m.HEADER),m.PACK*k,(m.open_h)*k,"#dbe4ee",INK,1))
    # plate
    b.append(rect(X(m.open_r),Y(m.PLATE_PT),m.plate_right_len*k,m.PLATE_PT*k,"#c7d2c4",INK,1))
    b.append(rect(X(0),Y(m.PLATE_PT),m.PACK*k,m.PLATE_PT*k,"#c7d2c4",INK,1))
    # studs
    xs=[m.L-0.75-u for u in (0,16,32,48,64,80,96,128)]+[m.fixed_start+0.75]
    for xc in xs: b.append(rect(X(xc-0.75),Y(H-m.TOP_PLATES),1.5*k,m.stud_len*k,"#fff",INK,0.8))
    # notch (opener)
    nx0,nx1=m.opener_cl-7,m.opener_cl+7
    b.append(rect(X(nx0),Y(H-m.TOP_PLATES),14*k,m.stud_len*k,"#fff","#fff",0))
    for xc in (nx0-0.75,nx1+0.75): b.append(rect(X(xc-0.75),Y(H-m.TOP_PLATES),1.5*k,m.stud_len*k,"#fff",INK,0.8))
    b.append(rect(X(nx0),Y(84),14*k,10*k,"#fde7c8",WARN,1.2,"4 3"))
    b.append(text(X(m.opener_cl),Y(84)-6,"opener notch: FIELD-LOCATE height",9,WARN,"middle"))
    b.append(line(X(m.opener_cl),Y(0),X(m.opener_cl),Y(H),BLUE,1,"6 4"))
    b.append(text(X(m.opener_cl)+4,Y(20),"opener centerline 9'-6\" (verify)",9,BLUE))
    # leaves
    xa=m.open_l+m.GAP_SIDE; xb=xa+m.LEAF_W+m.GAP_SIDE; ytop=m.open_h-m.GAP_TOP; ybot=m.BAR+m.GAP_BOT_ABOVE_BAR
    for x0,lab in ((xa,"LEAF A"),(xb,"LEAF B")):
        b.append(rect(X(x0),Y(ytop),m.LEAF_W*k,(ytop-ybot)*k,"rgba(11,92,171,.07)",BLUE,1.5))
        b.append(text(X(x0+m.LEAF_W/2),Y(ytop)+22,lab,11,BLUE,"middle",weight="bold"))
    # hinges at outer edges (storage side - drawn as ticks), meeting bolts
    for yy in (ytop-7, ytop-7-(ytop-ybot-14)/3, ytop-7-2*(ytop-ybot-14)/3, ybot+7):
        b.append(rect(X(xa)-3,Y(yy)-5,5,10,BLUE)); b.append(rect(X(xb+m.LEAF_W)-2,Y(yy)-5,5,10,BLUE))
    b.append(text(X(xa+m.LEAF_W+0.06),Y(ytop-40),"meeting stiles (doubled 2x4)",8,MUTE,"middle",rot=-90))
    # threshold bar
    b.append(rect(X(m.open_l),Y(m.BAR),m.OPEN_W*k,m.BAR*k,"#fff",INK,1,"3 2"))
    b.append(text(X(m.open_l+m.OPEN_W/2),Y(0)+16,"removable PT threshold bar (bottom-bolt sockets) - 84\"",9,MUTE,"middle"))
    # slab
    b.append(line(X(-8),Y(0),X(W+8),Y(0),INK,3))
    # labels
    b.append(text(X(175),Y(60),"FIXED WALL - 2x4 @ 16\" OC",11,INK,"middle",weight="bold"))
    b.append(text(X(175),Y(60)+15,"R-13, mold-resistant board on garage face, regular 1/2\" on room face",9,MUTE,"middle"))
    b.append(text(X(175),Y(60)+28,"built as two screwed sections; PT plate on sill gasket, Tapcon ~32\" OC",9,MUTE,"middle"))
    # dims
    yb=Y(0)+46
    b.append(dim(X(0),yb,X(m.PACK),yb,"3\"",size=9))
    b.append(dim(X(m.open_l),yb,X(m.open_r),yb,"OPENING 7'-0\" clear"))
    b.append(dim(X(m.open_r),yb,X(m.L),yb,"11'-9\" (incl. right jamb pack 3\")"))
    b.append(dim(X(-14),Y(0),X(-14),Y(m.open_h),f"{m.open_h:.1f}\" clear",vertical=True))
    b.append(dim(X(W)+16,Y(0),X(W)+16,Y(H),f"{H:.0f}\" (assumed)",vertical=True))
    b.append(text(ox,yb+34,f"Leaf: {m.LEAF_W}\" wide x {m.leaf_h:.3f}\" tall (opening {m.open_h:.1f}\" - 1/8\" top gap - {m.BAR}\" bar - 1/4\" over bar). Leaf pair needs {m.leaf_pair_w:.3f}\" of the 84\" opening.",10,MUTE))
    return svg(int(W*k+ox*2+40), int(yb+60), "".join(b), "Corrected wall elevation")

# ------------------------------------------------------------------ 3. LEAF
def leaf():
    k=5.2; ox,oy=70,90
    w=m.LEAF_W*k; h=m.leaf_h*k
    X=lambda i: ox+i*k; Y=lambda i: oy+i*k
    b=[text(30,34,"SCHEMATIC 3 - GATE LEAF CONSTRUCTION (pair is mirrored)",15,INK,weight="bold"),
       text(30,52,"Leaf A shown from the ROOM face: hinge stile left, meeting stile right. Stiles are DOUBLED 2x4 on edge (3\" wide x 3.5\" deep).",11,MUTE)]
    b.append(rect(ox,oy,w,h,"none",INK,2))
    st=3.0
    b.append(rect(X(0),Y(0),st*k,h,"#e8dcc8",INK,1)); b.append(rect(X(m.LEAF_W-st),Y(0),st*k,h,"#e8dcc8",INK,1))
    for yy in (0,1.5+m.MID_SEG1,m.leaf_h-1.5): b.append(rect(X(st),Y(yy),(m.LEAF_W-2*st)*k,1.5*k,"#e8dcc8",INK,1))
    cx=m.LEAF_W/2-0.75
    b.append(rect(X(cx),Y(1.5),1.5*k,(m.leaf_h-3)*k,"#e8dcc8",INK,1))
    b.append(line(X(st),Y(m.leaf_h-1.5),X(m.LEAF_W-st),Y(1.5),BLUE,5))      # Z-brace: low hinge side -> high meeting side
    b.append(text(X(m.LEAF_W)+34,Y(48),"Z-brace: low on hinge side,",9,BLUE)); b.append(text(X(m.LEAF_W)+34,Y(48)+12,"high on meeting side (compression)",9,BLUE))
    for i,yy in enumerate((7, 7+(m.leaf_h-14)/3, 7+2*(m.leaf_h-14)/3, m.leaf_h-7)):
        b.append(rect(X(-0.8),Y(yy)-7,0.8*k+3,14,BLUE))
    b.append(text(ox-8,Y(m.leaf_h/2),"4 NRP hinges, 3\" screws into doubled jamb",9,BLUE,"middle",rot=-90))
    b.append(circ(X(m.LEAF_W-6),Y(m.leaf_h-6),11,"#fff",BLUE,2)); b.append(text(X(m.LEAF_W)+34,Y(m.leaf_h-6)+4,"gate wheel at meeting corner",9,BLUE))
    b.append(rect(X(m.LEAF_W-2.2),Y(38)-8,22,38,BLUE)); b.append(text(X(m.LEAF_W)+34,Y(38)+4,"rim deadbolt @ 38\" (leaf A)",9,BLUE))
    b.append(text(X(m.LEAF_W)+34,Y(6),"top + bottom barrel bolts, room face",9,BLUE))
    b.append(dim(ox,Y(m.leaf_h)+28,ox+w,Y(m.leaf_h)+28,f"{m.LEAF_W}\" per leaf",size=11))
    b.append(dim(ox-40,oy,ox-40,oy+h,f"{m.leaf_h:.3f}\"",vertical=True))
    # section + meeting joint (plan views), to the right
    sx=ox+w+300; 
    b.append(text(sx,oy-6,"SECTION A-A  (top view of one leaf)",11,INK,weight="bold"))
    t=m.PACK*0  # unused
    k2=11.0; d=3.5; skin=0.5
    secw=22*k2/2
    b.append(rect(sx,oy+10,secw,skin*k2,"#d1d5db",INK,1)); b.append(rect(sx,oy+10+(skin+d)*k2,secw,skin*k2,"#d1d5db",INK,1))
    b.append(rect(sx,oy+10+skin*k2,3*k2,d*k2,"#e8dcc8",INK,1)); b.append(rect(sx+secw-3*k2,oy+10+skin*k2,3*k2,d*k2,"#e8dcc8",INK,1))
    b.append(text(sx+secw/2,oy+10+(skin+d/2)*k2+4,"R-13",10,MUTE,"middle"))
    b.append(text(sx+secw+10,oy+10+skin*k2*0.7,"1/2\" mold-resistant board (storage face)",9,MUTE)); b.append(text(sx+secw+10,oy+10+(skin+d+skin*0.8)*k2,"1/2\" regular gypsum (room face)",9,MUTE))
    b.append(text(sx,oy+10+(2*skin+d)*k2+16,"Frame 3.5\" + two 1/2\" skins = 4.5\" thick. Doubled stiles shown at each end.",9,MUTE))
    my=oy+150
    b.append(text(sx,my,"MEETING JOINT - TOP VIEW AT THE LOCK",11,INK,weight="bold"))
    jx=sx+10; jy=my+30; sw_=3*k2+6
    # leaf A (left) and leaf B (right), storage side at bottom
    b.append(rect(jx,jy,100,(2*skin+d)*k2,"#fff",INK,1)); b.append(rect(jx+104,jy,100,(2*skin+d)*k2,"#fff",INK,1))
    b.append(rect(jx+100-3*k2+0,jy+skin*k2,3*k2,d*k2,"#e8dcc8",INK,1)); b.append(rect(jx+104,jy+skin*k2,3*k2,d*k2,"#e8dcc8",INK,1))
    b.append(text(jx+45,jy+(skin+d/2)*k2+4,"LEAF A",9,MUTE,"middle")); b.append(text(jx+160,jy+(skin+d/2)*k2+4,"LEAF B",9,MUTE,"middle"))
    b.append(rect(jx+84,jy-14,40,10,BLUE)); b.append(text(jx+104,jy-18,"jimmy-proof rim deadbolt body (room face)",9,BLUE,"middle"))
    b.append(rect(jx+100,jy+(2*skin+d)*k2+4,8,6,BLUE)); 
    b.append(text(jx+104,jy+(2*skin+d)*k2+26,"astragal + EPDM on leaf B edge (storage side); strike through-bolted into B's doubled stile",9,MUTE,"middle"))
    b.append(text(jx+104,jy+(2*skin+d)*k2+40,"Leaf A opens first, then B. Check that deadbolt, barrel bolts and astragal do not collide on the room face.",9,MUTE,"middle"))
    b.append(text(jx,jy+(2*skin+d)*k2+66,"storage side (bottom)  /  room side (top)",9,MUTE))
    notes=[f"Estimated finished weight ~{m.LEAF_LB:.0f} lb per leaf (range 135-160 lb) - do not assume 110-130 lb.",
           "Build flat: skin storage face first, hang the leaf, then insulate and skin the room face.",
           "Leaf height depends on the MEASURED ceiling height - see CUTLIST.md formula."]
    for i,n in enumerate(notes): b.append(text(30,oy+h+80+i*16,n,10,MUTE))
    return svg(int(sx+260+240), int(oy+h+80+len(notes)*16+20), "".join(b), "Corrected leaf construction")

for name,fn in (("schematic-1-floor-plan.svg",floor_plan),("schematic-2-wall-elevation.svg",elevation),("schematic-3-leaf.svg",leaf)):
    open(os.path.join(OUT,name),"w").write(fn()); print("wrote",name)
