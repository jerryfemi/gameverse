import numpy as np
from PIL import Image,ImageFilter
W,H,HOR=3200,440,303
def noise(w,h,scale,seed,octaves=5):
  out=np.zeros((h,w),np.float32);amp=1;tot=0;r=np.random.default_rng(seed)
  for o in range(octaves):
    s=max(2,int(scale/(2**o)));g=r.random((h//s+3,w//s+3)).astype(np.float32)
    out+=amp*np.array(Image.fromarray((g*255).astype(np.uint8)).resize((w+3*s,h+3*s),Image.BICUBIC),np.float32)[:h,:w]/255;tot+=amp;amp*=0.5
  return out/tot
y=np.arange(H)[:,None].astype(np.float32)
t=np.clip(y/HOR,0,1)
top=np.array([78,146,218]);hz=np.array([196,224,240])
sky=top*(1-t[...,None]**1.6)+hz*(t[...,None]**1.6)
sky=np.broadcast_to(sky,(H,W,3)).copy()
# clouds: stretched fbm, denser higher up
n=noise(W,H,220,11)
n2=noise(W,H,60,12,4)
cl=np.clip((n*0.8+n2*0.35-0.62)*3.2,0,1)*np.clip(1.15-t,0,1)[...,None][...,0]
shade=np.clip(1.0-0.25*np.clip((n2-0.45)*3,0,1),0.7,1.0)
lo=np.array([196,208,226]);hi=np.array([252,252,253]);cloudcol=lo*(1-shade[...,None])/0.3+hi*(1-(1-shade[...,None])/0.3)
sky=sky*(1-cl[...,None]*0.85)+cloudcol*cl[...,None]*0.85
alpha=np.full((H,W),255.0)
def ridge(base,amp,scale,seed):
  x=np.arange(W,dtype=np.float32)
  r=noise(W,1,scale,seed,6)[0];r=(r-r.min())/(r.max()-r.min())
  return base-amp*r
# far hills (hazy blue-green)
h1=ridge(HOR-30,75,900,21)
m1=(y>=h1[None,:]).astype(np.float32)
c1=np.array([128,160,150])
sky=sky*(1-m1[...,None])+c1*m1[...,None]
# near tree-covered hills: bumpy crowns + texture
h2=ridge(HOR-10,42,520,31)-noise(W,1,26,32,3)[0]*12
m2=(y>=h2[None,:]).astype(np.float32)
tex=noise(W,H,8,33,3)
c2=np.stack([62+28*tex,96+30*tex,66+22*tex],-1)
# haze toward the top of the ridge
c2=c2*0.85+np.array([150,180,170])*0.15
sky=sky*(1-m2[...,None])+c2*m2[...,None]
# tree line right at the horizon (darker, finer crowns)
h3=HOR-2-noise(W,1,9,41,3)[0]*16-noise(W,1,120,42,3)[0]*10
m3=(y>=h3[None,:]).astype(np.float32)
tex3=noise(W,H,4,43,3)
c3=np.stack([40+30*tex3,72+34*tex3,42+22*tex3],-1)
sky=sky*(1-m3[...,None])+c3*m3[...,None]
img=Image.fromarray(np.clip(sky,0,255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))
img.save('sky.png');img.resize((1600,220)).save('sky_prev.jpg');print('ok')
