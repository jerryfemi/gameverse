import numpy as np
from PIL import Image,ImageFilter
rng=np.random.default_rng(7)
def tile_noise(n,sigma,seed):
  r=np.random.default_rng(seed).standard_normal((n,n))
  f=np.fft.fft2(r);ky=np.fft.fftfreq(n)[:,None];kx=np.fft.fftfreq(n)[None,:]
  g=np.exp(-(kx**2+ky**2)*(2*np.pi*sigma)**2/2);x=np.real(np.fft.ifft2(f*g));x=(x-x.mean())/x.std();return x
N=1024
# grass: blades (fine anisotropic), clumps, patches
fine=tile_noise(N,0.8,1);blade=np.zeros_like(fine)
# vertical-ish blade streaks: blur fine noise anisotropically via fft
r=np.random.default_rng(2).standard_normal((N,N));f=np.fft.fft2(r);ky=np.fft.fftfreq(N)[:,None];kx=np.fft.fftfreq(N)[None,:]
blade=np.real(np.fft.ifft2(f*np.exp(-((kx*1.2)**2+(ky*6)**2)*(2*np.pi)**2*1.2)));blade=(blade-blade.mean())/blade.std()
clump=tile_noise(N,6,3);patch=tile_noise(N,40,4)
lum=0.55+0.07*blade+0.06*fine+0.05*clump+0.05*patch
dry=np.clip(0.18+0.22*patch+0.08*clump,0,0.7)  # 0 lush .. 1 dry
lush=np.array([58,104,40]);dryc=np.array([112,118,62])
col=(lush[None,None]*(1-dry[...,None])+dryc[None,None]*dry[...,None])*lum[...,None]/0.55
# sparse dark specks (soil showing) and light specks (dead blades)
sp=np.random.default_rng(5).random((N,N))
col[sp<0.004]*=0.45;col[sp>0.997]=col[sp>0.997]*0.6+np.array([190,180,120])*0.4
Image.fromarray(np.clip(col,0,255).astype(np.uint8)).save('grass.png')
# mud decal (worn ground) with soft alpha
M=512;y,x=np.mgrid[0:M,0:M]/M-0.5
d=np.sqrt((x/0.5)**2+(y/0.42)**2)
n1=tile_noise(M,10,8);n2=tile_noise(M,2,9)
a=np.clip((1-d)*2.2+0.35*n1-0.25,0,1)**0.9
mc=np.array([92,72,50])*(0.85+0.10*n2[...,None]+0.08*n1[...,None])
mc=mc*(1-0.15*np.clip(n1,0,1)[...,None])
Image.fromarray(np.dstack([np.clip(mc,0,255),a*235]).astype(np.uint8),'RGBA').save('mud.png')
print('ok')
