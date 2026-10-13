import json, math, os, sys, shutil, time
from array import array
from collections import defaultdict
from shapely.geometry import shape, LineString, box, mapping
from shapely.ops import linemerge, unary_union
from shapely.strtree import STRtree
OUT = sys.argv[1]
T0=time.time()
def log(*a): print(f'[{time.time()-T0:6.1f}s]', *a, flush=True)
M2 = 111320**2 * math.cos(math.radians(52.5))
ROOT = tuple(int(v) for v in os.environ.get('ROOT','-660000,4980000,210000,5600000').split(','))   # x0,y0,x1,y1 in 1e-5 deg
PFX = os.environ.get('PFX','e_')
RC = {'motorway':1,'motorway_link':1,'trunk':2,'trunk_link':2,'primary':3,'primary_link':3,'secondary':4,'secondary_link':4,'tertiary':5,'residential':6,'unclassified':6,'living_street':6,'pedestrian':7}
def q(v): return int(round(v*1e5))
def qc(coords): 
    a=array('i')
    for x,y in coords: a.append(q(x)); a.append(q(y))
    return a
def parts(g):
    t=g.geom_type
    if t in ('LineString','Polygon'): return [g]
    if hasattr(g,'geoms'): return [x for x in g.geoms]
    return []
def feats(fn):
    with open(fn) as f:
        for line in f:
            line=line.strip()
            if line: yield json.loads(line)
# item: [kind, cls, name, data, rx, ry, size]  kind: 'L' line(array), 'P' poly(list of arrays), 'T' label (x,y)
mid=[]; det=[]; baseL=defaultdict(list); baseW=[]; baseLab=[]; gaz=[]
def add_line(dest, cls, name, a):
    n=len(a)//2
    if n<2: return
    dest.append(['L',cls,name,a,a[(n//2)*2],a[(n//2)*2+1], 4+n*2.6+(6 if name else 0)])
log('roads')
for f in feats(PFX+'roads.geojsonl'):
    p=f['properties']; c=RC.get(p.get('highway'))
    if not c or not f['geometry']: continue
    nm=p.get('name') or ''
    g=shape(f['geometry'])
    for l in parts(g):
        if c>=6: l=l.simplify(0.00005)
        a=qc(l.coords)
        add_line(mid if c<=4 else det, c, nm, a)
        if c<=2: baseL[c].append(l)
log('roads done', len(mid), len(det))
for f in feats(PFX+'rail.geojsonl'):
    if not f['geometry'] or '"service"' in ((f['properties'] or {}).get('other_tags') or ''): continue
    for l in parts(shape(f['geometry'])): add_line(mid, 8, '', qc(l.coords))
for f in feats(PFX+'waterways.geojsonl'):
    if not f['geometry']: continue
    p=f['properties']; c = 9 if p.get('waterway')=='river' else 10
    for l in parts(shape(f['geometry'])): add_line(mid if c==9 else det, c, p.get('name') or '', qc(l.coords))
log('lines done', len(mid), len(det))
GREEN={'park','garden','common','recreation_ground','golf_course','nature_reserve','grass','meadow','village_green','allotments'}
WOOD={'forest','wood','heath','grassland','scrub','wetland'}
for f in feats(PFX+'areas.geojsonl'):
    if not f['geometry']: continue
    p=f['properties']; ot=p.get('other_tags') or ''
    vals={p.get('leisure'),p.get('landuse'),p.get('natural')}
    if 'water' in vals: c=20
    elif vals & WOOD: c=22
    elif 'cemetery' in vals: c=23
    elif vals & GREEN: c=21
    else: continue
    try: g=shape(f['geometry'])
    except Exception: continue
    if not g.is_valid: g=g.buffer(0)
    area=g.area*M2
    lu=p.get('landuse'); le=p.get('leisure')
    if area < (3000 if c==20 else 8000): continue
    if lu=='grass' and area<40000: continue
    if lu=='meadow' and area<300000: continue
    if c==22 and area<30000: continue
    if c==21 and le not in ('park','common','nature_reserve') and area<15000: continue
    if le=='garden' and area<15000: continue
    if c==22 and p.get('natural') in ('scrub','grassland') and area<40000: continue
    nm=p.get('name') or ''
    big = area>=300000 or (c==20 and area>=100000)
    rings=[]
    for poly in parts(g):
        if poly.geom_type!='Polygon' or poly.is_empty: continue
        poly=poly.simplify(0.00006 if big else 0.00005, preserve_topology=True)
        rs=[qc(poly.exterior.coords)]+[qc(r.coords) for r in poly.interiors if r.length>0.0004 or not big]
        rings += [r for r in rs if len(r)>=6]
    if not rings: continue
    rp=g.representative_point(); rx,ry=q(rp.x),q(rp.y)
    sz=4+sum(len(r) for r in rings)*1.3
    (mid if big else det).append(['P',c,'',rings,rx,ry,sz])
    if c==20 and area>5e6:
        baseW.append(g.simplify(0.0005, preserve_topology=True))
    if nm and c in (21,22,23) and area>=40000:
        (mid if area>=300000 else det).append(['T',30 if area>=300000 else 31,nm,None,rx,ry,8+len(nm)])
log('areas done', len(mid), len(det))
PR={'city':0,'town':1,'suburb':2,'village':2,'quarter':3,'neighbourhood':3}
for f in feats(PFX+'places.geojsonl'):
    p=f['properties']; nm=p.get('name'); ot=p.get('other_tags') or ''
    if not nm or not f['geometry'] or f['geometry']['type']!='Point': continue
    x,y=f['geometry']['coordinates']; rx,ry=q(x),q(y)
    pl=p.get('place')
    if pl in PR:
        c=PR[pl]
        gaz.append([nm,rx,ry,c])
        if c<=1: baseLab.append([c,nm,rx,ry])
        else: (mid if c==2 else det).append(['T',c,nm,None,rx,ry,8+len(nm)])
    elif '"railway"=>"station"' in ot or 'railway' in p:
        if '"station"=>"subway"' in ot or '"network"' in ot or '"operator"' in ot or '"railway"=>"station"' in ot:
            det.append(['T',5,nm,None,rx,ry,8+len(nm)])
log('places done', len(mid), len(det), 'baseLab', len(baseLab))
# quadtree
def build_tree(items, limit, maxd=13):
    leaves=[]
    stack=[(ROOT, list(range(len(items))), 0)]
    while stack:
        (x0,y0,x1,y1), idx, d = stack.pop()
        tot=sum(items[i][6] for i in idx)
        if tot<=limit or d>=maxd:
            leaves.append(((x0,y0,x1,y1), idx)); continue
        mx=(x0+x1)//2; my=(y0+y1)//2
        kids=[[],[],[],[]]
        for i in idx:
            it=items[i]; k=(1 if it[4]>=mx else 0)+(2 if it[5]>=my else 0); kids[k].append(i)
        bbs=[(x0,y0,mx,my),(mx,y0,x1,my),(x0,my,mx,y1),(mx,my,x1,y1)]
        for k in range(4): stack.append((bbs[k], kids[k], d+1))
    return leaves
def uv(b,n):
    while n>=0x80: b.append((n&0x7f)|0x80); n>>=7
    b.append(n)
def sv(b,n): uv(b, n<<1 if n>=0 else ((-n)<<1)-1)
def encode_leaf(bb, its, extra_polys=()):
    ox,oy=bb[0],bb[1]
    names=[]; ni={}
    def N(s):
        if not s: return 0
        if s not in ni: ni[s]=len(names); names.append(s)
        return ni[s]+1
    groups=defaultdict(list); polys=[]; labs=[]
    for it in its:
        if it[0]=='L': groups[(it[1],it[2])].append(it[3])
        elif it[0]=='P': polys.append((it[1],it[3]))
        else: labs.append((it[1],it[2],it[4],it[5]))
    lines=[]
    for (c,nm),arrs in groups.items():
        if len(arrs)>1:
            ls=[LineString([(a[i],a[i+1]) for i in range(0,len(a),2)]) for a in arrs]
            m=linemerge(ls)
            for l in parts(m):
                a=array('i'); 
                for x,y in l.coords: a.append(int(x)); a.append(int(y))
                lines.append((c,nm,a))
        else: lines.append((c,nm,arrs[0]))
    for c,rings in extra_polys: polys.append((c,rings))
    b=bytearray()
    body=bytearray()
    uv(body,len(lines))
    for c,nm,a in lines:
        uv(body,c); uv(body,N(nm)); n=len(a)//2; uv(body,n)
        px,py=ox,oy
        for i in range(0,len(a),2):
            sv(body,a[i]-px); sv(body,a[i+1]-py); px,py=a[i],a[i+1]
    uv(body,len(polys))
    for c,rings in polys:
        uv(body,c); uv(body,0); uv(body,len(rings))
        for a in rings:
            uv(body,len(a)//2); px,py=ox,oy
            for i in range(0,len(a),2):
                sv(body,a[i]-px); sv(body,a[i+1]-py); px,py=a[i],a[i+1]
    uv(body,len(labs))
    for c,nm,x,y in labs:
        uv(body,c); uv(body,N(nm)); sv(body,x-ox); sv(body,y-oy)
    uv(b,len(names))
    for s in names:
        e=s.encode('utf-8'); uv(b,len(e)); b+=e
    return bytes(b+body)
# land polygons
log('land')
land=[]
for f in feats(PFX+'land.geojsonl'):
    g=shape(f['geometry'])
    if not g.is_valid: g=g.buffer(0)
    land.append(g)
tree=STRtree(land)
log('land loaded', len(land))
def land_rings(bb):
    x0,y0,x1,y1=[v/1e5 for v in bb]
    bx=box(x0,y0,x1,y1)
    hits=tree.query(bx)
    if len(hits)==0: return None
    geoms=[land[i] for i in hits]
    u=unary_union([g.intersection(bx) for g in geoms if g.intersects(bx)])
    if u.is_empty: return None
    if u.area >= bx.area*0.9999: return 'full'
    u=u.simplify(0.00007, preserve_topology=True)
    out=[]
    for poly in parts(u):
        if poly.geom_type!='Polygon' or poly.is_empty: continue
        if poly.area*M2<4000: continue
        out.append(qc(poly.exterior.coords))
        for r in poly.interiors:
            if box(*r.bounds).area*M2>4000: out.append(qc(r.coords))
    return [r for r in out if len(r)>=6] or None
for d in ('m','d'):
    p=os.path.join(OUT,d); shutil.rmtree(p, ignore_errors=True); os.makedirs(p)
shutil.rmtree(os.path.join(OUT,'t'), ignore_errors=True)
index={}
for layer, items, limit in (('m', mid, int(sys.argv[2])), ('d', det, int(sys.argv[3]))):
    est=defaultdict(float)
    for it in items: est[it[0]]+=it[6]
    log(layer,'estimated MB by kind', {k:round(v/1e6,1) for k,v in est.items()})
    leaves=build_tree(items, limit)
    rows=[]; tot=0; nfiles=0
    for k,(bb,idx) in enumerate(leaves):
        extra=[]; flag=1
        if layer=='m':
            lr=land_rings(bb)
            if lr=='full': extra=[(40,[array('i',[bb[0],bb[1],bb[2],bb[1],bb[2],bb[3],bb[0],bb[3],bb[0],bb[1]])])]
            elif lr: extra=[(40,lr)]
            if not idx and not extra: rows.append([k,*bb,0]); continue
        elif not idx: continue
        data=encode_leaf(bb,[items[i] for i in idx],extra)
        open(os.path.join(OUT,layer,f'{k}.bin'),'wb').write(data); tot+=len(data); nfiles+=1
        rows.append([k,*bb,1])
    index[layer]=rows
    log(layer, 'leaves', len(leaves), 'files', nfiles, 'MB', round(tot/1e6,2), 'max KB', max((os.path.getsize(os.path.join(OUT,layer,f)) for f in os.listdir(os.path.join(OUT,layer))),default=0)//1000)
# base json
def enc(coords):
    out=[]; px=py=0; first=True
    for x,y in coords:
        X,Y=q(x),q(y)
        if first: out+=[X,Y]; first=False
        elif X!=px or Y!=py: out+=[X-px,Y-py]
        else: continue
        px,py=X,Y
    return out
base={"names":[], "lines":[], "polys":[], "labels":[]}
ni={}
def N(s):
    if not s: return -1
    if s not in ni: ni[s]=len(base['names']); base['names'].append(s)
    return ni[s]
for c,ls in baseL.items():
    m=linemerge(ls).simplify(0.00025)
    for l in parts(m):
        e=enc(l.coords)
        if len(e)>=4: base['lines'].append([c,-1,e])
for g in baseW:
    for poly in parts(g):
        if poly.geom_type=='Polygon': base['polys'].append([20,-1,enc(poly.exterior.coords)])
for c,nm,x,y in baseLab: base['labels'].append([c,N(nm),x,y])
b=json.load(open('boroughs.geojson'))
bor=[]
for f in b['features']:
    g=shape(f['geometry']).simplify(0.00025, preserve_topology=True)
    rings=[]
    for p in parts(g): rings.append(enc(p.exterior.coords))
    bor.append([N(f['properties']['name']), *rings])
lon=unary_union([shape(f['geometry']) for f in b['features']]).buffer(0.0002).buffer(-0.0002).simplify(0.0003)
base['london']=[enc(p.exterior.coords) for p in parts(lon)]
base['boroughs']=bor
landp=[]
for f in json.load(open('ne10c.geojson'))['features']:
    if f['properties']['ADM0_A3'] in ('GBR','IRL','FRA','BEL','NLD','IMN'):
        g=shape(f['geometry']).intersection(box(-11,49,5,61)).simplify(0.002)
        for p in parts(g):
            if p.geom_type=='Polygon' and p.area>0.0005: landp.append([enc(p.exterior.coords)])
base['land']=landp
uk=[]
for f in json.load(open('ne10p.geojson'))['features']:
    p=f['properties']
    if p.get('adm0_a3')!='GBR' or p.get('name')=='London': continue
    pop=p.get('pop_max') or 0
    if pop<40000: continue
    r=1 if pop>=1000000 else 2 if pop>=250000 else 3
    x,y=f['geometry']['coordinates']; uk.append([r,p['name'],q(x),q(y)])
base['uk']=uk
base['mid']=index['m']; base['det']=index['d']
s=json.dumps(base,separators=(',',':'),ensure_ascii=False)
open(os.path.join(OUT,os.environ.get('BASE','base.json')),'w').write(s)
log('base bytes', len(s))

open(os.path.join(OUT,'places.json'),'w').write(json.dumps(gaz,separators=(',',':'),ensure_ascii=False))
log('places', len(gaz))
