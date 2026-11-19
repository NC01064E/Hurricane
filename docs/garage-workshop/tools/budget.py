#!/usr/bin/env python3
"""Re-adds every line of the original plan's priced list, applies corrections, and emits budget.csv + budget.md.
Unit prices are the plan's own 'checked 2026-11-19' Home Depot prices; they were NOT re-verified (no store access)."""
import csv, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import model
OUT = os.path.join(os.path.dirname(__file__), "..")
TAX = 0.07

# (phase, item, qty_plan, qty_now, unit, note)
L = [
 (1,"2x4x8 #2 SYP stud",30,model.STUDS_BUY,3.25,f"cut list packs {model.STUDS_PACKED} boards + 3 soffit + 3 defects"),
 (1,"PT 2x4x12",2,2,6.96,"out of stock at E Fort Lauderdale; check WPB/delivery"),
 (1,"2x6x8 (header pair)",4,2,9.68,"meeting stiles are now doubled 2x4, so only the header pair needs 2x6"),
 (1,"Plytanium 15/32 BC plywood 4x8",1,1,44.38,"header spacer, soffit hatch"),
 (1,"USG Mold Tough 1/2 in 4x8 (garage face)",5,5,24.88,"paper-faced per sources; DECISION: glass-mat board (price not checked) if you keep the plan's 'no paper face' rule"),
 (1,"USG UltraLight 1/2 in 4x8 (room face)",5,6,13.98,"+1 sheet for soffit box / hatch backing"),
 (1,"CertainTeed R-13 15in x 32ft roll",4,4,27.97,""),
 (1,"NRP security ball-bearing hinges 4.5 in, set of 3",2,3,18.48,"4 hinges per leaf (8) instead of 3 because leaf is ~135-160 lb; verify load rating on spec sheet"),
 (1,"Prime-Line jimmy-proof rim deadbolt U 9970",1,1,26.87,""),
 (1,"Everbilt 4 in spring gate caster",2,2,29.67,""),
 (1,"Everbilt 6 in barrel bolt",4,4,11.47,"4th by delivery"),
 (1,"Owens Corning sill gasket 5.5in x 50ft",1,1,11.64,""),
 (1,"Frost King EPDM tape 3/8 in x 17 ft",2,2,5.54,"~34 ft; need ~28 ft (jambs+header ~21 ft, astragal ~7 ft)"),
 (1,"Tapcon 3/16 x 3-1/4 in, 75 pc",1,1,20.97,"~12 anchors needed; spare covers threshold bar"),
 (1,"Titebond acoustic sealant, 12-pack case",1,1,106.48,"only sold as case; pro-rata for 3 tubes is $26.62 - buy loose tubes elsewhere to save ~$80"),
 (1,"3M Fire Block sealant",1,1,8.48,""),
 (2,"UltraLight 1/2 in 4x8 (ceiling)",8,8,13.98,"check joist/truss spacing: 24 in OC needs 5/8 in or sag-resistant 1/2 in"),
 (2,"CertainTeed R-30 24x48 batts (88 sf/pack)",3,3,129.00,"264 sf for 228 sf"),
 (2,"Joint compound 4.5 gal",1,1,23.90,""),
 (2,"Paper tape",1,1,2.98,"ceiling only; use mesh tape on the mold-resistant garage face"),
 (2,"Drywall screws 1 lb",1,1,5.97,"covers ceiling only - see added fasteners"),
 (2,"Behr ceiling paint + primer 1 gal",1,1,33.98,"1 gal ~350-400 sf/coat; 228 sf ceiling x 2 coats needs ~1.3 gal"),
 (2,"Lithonia CPX 2x4 switchable CCT panels, 2-pack",2,2,101.24,"4 panels = 18,768 lm (82 lm/sf); 3 panels = 14,076 lm (62 lm/sf) already meets the plan's 50 lm/sf target"),
 (2,"eLEDing 2x4 surface-mount frames",4,4,42.99,"unverified; ~$107 4-pack alternative"),
 (2,"Lutron Caseta dimmers",2,2,64.95,"CPX panels are 0-10V dimming - phase-cut Caseta dimmers will not dim them (see AUDIT)"),
 (2,"LINJO 42 in smart DC flush fan",2,2,109.00,""),
 (2,"Commercial Electric fan brace box",2,2,11.38,""),
 (3,"G-Floor Levant 7.5x17 ft slate grey",2,2,229.99,"one retailer search page showed $379.99/roll - re-verify before buying"),
 (3,"Rubber-Cal stall mat 4x6x3/4",4,4,89.81,"premium; farm-supply mats ~half"),
 (3,"Defiant smart leak sensor",1,1,29.98,""),
 (3,"AcuRite hygrometer",1,1,12.98,""),
 (3,"Zerust VCI drawer liner",1,1,10.29,""),
 (3,"Electrical materials (breaker 7.26 + 50ft 12/2 73.00 + receptacles 19.10)",1,1,99.36,"see added items: one breaker and 50 ft cover one circuit, not four"),
]
# (id, item, low, high, note)  - estimates, NOT checked prices
A = [
 ("A1","Fasteners: 3in structural + 1-5/8in drywall (5 lb each) + 3/16 masonry bit (plan carried $10-15)",55,85,"plan's placeholder was far too small for ~11 sheets of wall board + framing"),
 ("A2","Mesh tape + setting-type compound for garage-face seams",15,30,""),
 ("A3","Primer + paint: second ceiling coat and garage face of partition (~760 sf total)",50,90,""),
 ("A4","2 in PVC raceway to attic: ~15 ft pipe, 2 long-sweep elbows, straps, pull string, firestop",30,60,"specified in plan, never priced"),
 ("A5","Lutron Smart Hub (needed for Caseta app/voice control)",80,100,"requirement confirmed by web search; price is an estimate"),
 ("A6","0-10V dimming for CPX panels (swap dimmers or panels)",0,120,"decision item; could be cost-neutral"),
 ("A7","GFCI receptacles in place of 4 of the 10 standard receptacles (garage requires GFCI)",65,65,"~$18 ea less $1.91"),
 ("A8","Three more 20A breakers (plan has one)",22,22,"treadmill, bench/TV, network/UPS"),
 ("A9","Extra 12/2 cable (plan has 50 ft total; depends on panel distance)",75,300,"$1.46/ft at plan price"),
 ("A10","Network enclosure + UPS + Cat6/keystones (decided in plan, never priced)",250,600,"optional if you reuse existing gear"),
 ("A11","Electrician labor, Phase 3 circuits (plan: $300-700 incl. $99 materials already counted)",200,600,"not in the $3,111 materials total"),
]
P4 = {"hessaire":1398.00,"mrcool":2309.00}
P4_SVC = [("240V circuit + disconnect (electrician)",250,750),("pad / cover / misc",100,250),("permit (treat as expected, not optional)",100,400)]

def main():
    rows=[]; tot_plan={1:0,2:0,3:0}; tot_now={1:0,2:0,3:0}
    for ph,item,qp,qn,u,note in L:
        ep=round(qp*u,2); en=round(qn*u,2); tot_plan[ph]+=ep; tot_now[ph]+=en
        rows.append([ph,item,qp,qn,u,ep,en,round(en-ep,2),note])
    plan_total=round(sum(tot_plan.values()),2); now_total=round(sum(tot_now.values()),2)
    with open(os.path.join(OUT,"budget.csv"),"w",newline="") as f:
        w=csv.writer(f); w.writerow(["phase","item","qty_in_plan","qty_corrected","unit_price","plan_extended","corrected_extended","delta","note"])
        w.writerows(rows)
        w.writerow([]); w.writerow(["id","added/omitted item (ESTIMATE)","low","high","note"])
        for r in A: w.writerow(r)
    a_lo=sum(r[2] for r in A); a_hi=sum(r[3] for r in A)
    mat_lo=now_total+sum(r[2] for r in A if r[0] not in("A11",)); mat_hi=now_total+sum(r[3] for r in A if r[0] not in("A11",))
    tax_lo=round(mat_lo*TAX,2); tax_hi=round(mat_hi*TAX,2)
    lab_lo,lab_hi=200,600
    p13_lo=mat_lo+tax_lo+lab_lo; p13_hi=mat_hi+tax_hi+lab_hi
    svc_lo=sum(s[1] for s in P4_SVC); svc_hi=sum(s[2] for s in P4_SVC)
    out=[]
    out.append(f"plan phases (re-added): P1 {tot_plan[1]:.2f}  P2 {tot_plan[2]:.2f}  P3 {tot_plan[3]:.2f}  total {plan_total:.2f}  (plan states 828.40 / 1310.77 / 971.83 / 3111.00)")
    out.append(f"corrected: P1 {tot_now[1]:.2f}  P2 {tot_now[2]:.2f}  P3 {tot_now[3]:.2f}  total {now_total:.2f}")
    out.append(f"additions est: materials {mat_lo-now_total:.0f}-{mat_hi-now_total:.0f}; labor {lab_lo}-{lab_hi}")
    out.append(f"tax 7% on materials: {tax_lo:.0f}-{tax_hi:.0f}")
    out.append(f"phases 1-3 realistic: {p13_lo:,.0f} - {p13_hi:,.0f}")
    for k,v in P4.items():
        lo=p13_lo+v*(1+TAX)+svc_lo; hi=p13_hi+v*(1+TAX)+svc_hi
        out.append(f"full project w/ {k}: {lo:,.0f} - {hi:,.0f}  (unit {v:.0f} + tax {v*TAX:.0f}; services {svc_lo}-{svc_hi})")
    core_lo=p13_lo-250*(1+TAX); core_hi=p13_hi-600*(1+TAX)
    out.append(f"phases 1-3 WITHOUT A10 (network gear): {core_lo:,.0f} - {core_hi:,.0f}")
    print("\n".join(out))
    # sanity vs plan's own figures
    assert (round(plan_total,2),round(tot_plan[1],2),round(tot_plan[2],2),round(tot_plan[3],2))==(3111.00,828.40,1310.77,971.83)
    return dict(tot_plan=tot_plan,tot_now=tot_now,plan_total=plan_total,now_total=now_total,mat_lo=mat_lo,mat_hi=mat_hi,
                tax_lo=tax_lo,tax_hi=tax_hi,p13_lo=p13_lo,p13_hi=p13_hi,svc=(svc_lo,svc_hi),A=A,rows=rows,P4=P4,P4_SVC=P4_SVC)
if __name__=="__main__": main()
