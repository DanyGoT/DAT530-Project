# (task, t, mob, demob, scrapID, skipIfScrap, level, ops)
T=[("OD gauge & visual tube",78.5,60,40,1,0,1,1),("UT wall thickness",32,290,90,1,0,1,1),("Internal plastic coating",30,55,30,1,0,1,1),
("Clean connections",74.5,330,152,0,1,0,1),("Grind tong marks",99,205,170,0,1,0,1),("MPI fluorescent",182.5,280,275,1,1,1,1),
("Heat check",180,55,120,1,1,1,2),("Blow dry connections",11.5,90,60,0,0,0,1),("RFID tags",53,210,70,0,0,1,1),
("Threads visual inspection",84,340,60,1,0,2,1),("Measurements",124.5,250,120,1,0,1,1),("Length measurement",6,120,50,0,0,1,3),
("Hardbanding inspection",28,105,30,0,0,1,1),("Inspection report",48,60,0,0,0,2,1),("Field repair",75,180,160,0,1,0,1),
("Painting, connections",20,170,40,0,0,0,1),("Painting, tubes",21,70,20,0,0,0,1),("Painting, contrast tubes",12,60,20,0,0,0,1),
("Laser jet marking",17,390,30,0,0,1,1),("Dope",44,160,60,0,0,0,1),("Cap",26,300,0,0,0,0,1),("Restamp",138.5,110,75,0,1,1,1),
("Report check",19,225,20,0,0,2,2),("UT/EMI calibration",3980,0,0,0,1,3,1),("UT/EMI scan",96.2,1675,1675,1,1,3,1)]
per=[x for x in T if x[0]!="UT/EMI calibration"]
s=sum(x[1] for x in per); print("per-joint sum", s, s/60)
sk=sum(x[1] for x in per if x[5]); print("skippable per-joint", sk, "scrap-from-start", s-sk)
print("bottleneck", max(per,key=lambda x:x[1])[:2], "joints/h", 3600/182.5)
print("mob sum",sum(x[2] for x in T),"demob",sum(x[3] for x in T),"calib",3980,"total overhead h",(sum(x[2]+x[3] for x in T)+3980)/3600)
print("mob+demob max single", max(T,key=lambda x:x[2]+x[3])[:4])
for L in range(4):
    ts=[x for x in per if x[6]==L]
    print(f"L{L}: tasks {len(ts)+(1 if L==3 else 0)} wall {sum(x[1] for x in ts):.1f}s operator-s {sum(x[1]*x[7] for x in ts):.1f} maxops {max([x[7] for x in ts]+[0])}")
print("scrapID tasks", [i+1 for i,x in enumerate(T) if x[4]])
print("skip tasks", [i+1 for i,x in enumerate(T) if x[5]])
for mu,var,n in [(6.89,26.95,"recv"),(4.85,21.71,"hall"),(4.93,14.45,"DT")]:
    p=mu/var; r=mu*mu/(var-mu); print(n,"NB r=%.2f p=%.3f"%(r,p))
# pipelined batch time for n joints: fill + (n-1)*bottleneck
for n in [1,2,6,30,90,300]: print(n, "joints: serial-one-line h %.2f"%((s + (n-1)*182.5)/3600))
