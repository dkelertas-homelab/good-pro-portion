"""Mockup-only figure copies: coral headband with two tied tails at the back of the head.
Reads the app's assets/figures (untouched) and writes fig/*.svg. Also draws the side-on reverse lunge."""
import re
T='#0F766E'; C='#FF6F61'
def band(cx,cy,r,tail):   # tail: +1 tails trail right, -1 left, 0 = front-facing (peek left-down)
    y=cy-r*0.37; h=r*0.5
    s=(f'<clipPath id="hb"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>'
       f'<rect x="{cx-r-1}" y="{y-h/2}" width="{2*r+2}" height="{h}" fill="{C}" clip-path="url(#hb)"/>')
    d=tail if tail else -1; kx=cx+d*(r-1); w=r*0.34
    ends=[(kx+d*r*1.25,y-r*0.55),(kx+d*r*1.1,y+r*0.5)] if tail else [(kx+d*r*0.85,y+r*0.75),(kx+d*r*0.45,y+r*1.0)]
    for x2,y2 in ends:
        s+=f'<path d="M{kx:.1f},{y:.1f} Q{(kx+x2)/2:.1f},{y2-(3 if tail else 0):.1f} {x2:.1f},{y2:.1f}" stroke="{C}" stroke-width="{w:.1f}" stroke-linecap="round" fill="none"/>'
    return s+f'<circle cx="{kx:.1f}" cy="{y:.1f}" r="{r*0.26:.1f}" fill="{C}"/>'
def headband_copy(n):
    s=open(f'../../../../assets/figures/{n}.svg').read()
    cs=[(float(m[2]),float(m[0]),float(m[1])) for m in re.findall(r'<circle cx="([\d.]+)" cy="([\d.]+)" r="([\d.]+)" fill="#',s)]
    r,cx,cy=max(cs)   # head = largest filled circle
    xs=[float(v) for v in re.findall(r' (?:x1|x2|cx)="([\d.]+)"',s)]; dx=sum(xs)/len(xs)-cx
    tail=0 if abs(dx)<8 else (1 if dx>0 else -1)   # tails trail toward the body
    open(f'fig/{n}.svg','w').write(s.replace('</svg>',band(cx,cy,r,tail)+'</svg>')); return n,tail
for n in ['march','armCircles','squat','goodMorning','pushup','plank','gluteBridge','inclinePushup','wallSit','sidePlank','shoulderTap','splitSquat']:
    print(*headband_copy(n))
def L(x1,y1,x2,y2,c,w=16): return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
def J(x,y,c,r=9): return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'
# Side-on reverse lunge facing right; near (right) leg is the back leg, coral (proposal). Hands on hips, elbows out.
hip=(102,112); fk=(146,112); ff=(148,172); bk=(84,168); bf=(42,170)
s='<svg viewBox="0 0 200 200" width="200" height="200" xmlns="http://www.w3.org/2000/svg">'
s+=f'<ellipse cx="100" cy="182" rx="68" ry="6" fill="{T}" opacity="0.18"/>'
s+=L(112,58,146,80,T,13)+L(146,80,116,104,T,13)+J(146,80,T,7)          # far arm: elbow forward
s+=L(*hip,*fk,T)+L(*fk,*ff,T)+L(148,176,166,176,T,10)+J(*fk,T,10)       # front leg
s+=f'<rect x="92" y="46" width="26" height="70" rx="13" fill="{T}" transform="rotate(4 105 80)"/>'+J(108,28,T,16)
s+=L(*hip,*bk,C)+L(*bk,*bf,C,15)+J(*bk,C,10)+J(38,172,C,7)              # back leg (coral)
s+=L(98,58,62,82,T,13)+L(62,82,94,104,T,13)+J(62,82,T,7)+J(94,104,T,6)  # near arm: elbow back, hand on hip
s+=J(*hip,T,9)+band(108,28,16,-1)+'</svg>'
open('fig/reverseLunge-coral-leg.svg','w').write(s)
