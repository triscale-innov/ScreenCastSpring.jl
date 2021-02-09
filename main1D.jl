using Spring

sp=SpringParam(ls=0.1,ms=1,ks=2.5,ns=1000)
ip=InitParam(λ=2.0,shift=0.1,pos=sp.ls*sp.ns/2)
ap=AnimParam(δt=0.2,nδt=5000,nδtperframe=100)
# sp=SpringParam(ls=0.1,ms=1,ks=1,ns=1000)
# ip=InitParam(λ=1.0,shift=1.5,pos=sp.ls*sp.ns/2)
# ap=AnimParam(δt=1,nδt=1000,nδtperframe=10)

animate_spring(sp,ip,ap)
