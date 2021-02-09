using Spring
using CUDA
function go()
    sp=SpringParam(ls=0.1,ms=1,ks=2.5,ns=400)
    ip=InitParam(λ=2.0,shift=0.1,pos=sp.ls*sp.ns/2)
    ap=AnimParam(δt=0.1,nδt=5000,nδtperframe=50)

    CUDA.allowscalar(false)
    # V=Array{Float64,2}
    V=CuArray{Float64,2}

    @time animate_spring2D(sp,ip,ap,V)
end
go()