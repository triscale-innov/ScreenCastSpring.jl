using Spring
using Spring: getvalues,advance_nδtpf,initialize_arrays
using CUDA
using Makie

function setup_scene(xaxis,dc,nf)
    scene = Scene(resolution = (800, 800))
    dcnode = Node(dc)

    xM=maximum(xaxis)
    dM=maximum(dc)*0.05
    lim=FRect3D((0,0,0),(xM,xM,dM))

    surface!(scene,xaxis,xaxis,lift(d->d,dcnode),limits=lim,colormap=corporate_gradient(),colorrange = (-dM,dM))
    scale!(scene, 1, 1, 0.1*xM/dM)
    scene,dcnode
end


function animate_makie(sp,ip,ap,V)
    δt,nδt,nδtperframe=Spring.getvalues(ap)
    xs,xc,xp,xt,fx,ys,yc,yp,yt,fy=initialize_arrays(sp,ip,ap,V)

    dc=zero(xc)
    cdc=Array(xc)

    xaxis=Array(xs[:,1])
    yaxis=Array(ys[1,:])
    nf=nδt÷nδtperframe

    scene,dcnode=setup_scene(xaxis,cdc,nf)
    display(scene)
    
    t=0.0
    tdynamic=0.0
    for i ∈ 1:nf
        tdynamic+= @elapsed CUDA.@sync begin
            xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
            yc,yp,yt=advance_nδtpf(yc,yp,yt,fy,sp,ap)
        end
        # @. dc = sqrt((xc - xs)^2+(yc - ys)^2)
        density_shift!(dc,xc,yc,ls)
        @. cdc = dc 
        dcnode[] = cdc
        sleep(0.01)
        t+=nδtperframe*δt
    end
end

function go()
    sp=SpringParam(ls=0.1,ms=1,ks=2.5,ns=1000)
    ip=InitParam(λ=2.0,shift=0.1,pos=sp.ls*sp.ns/2)
    ap=AnimParam(δt=0.2,nδt=5000,nδtperframe=5000)

    CUDA.allowscalar(false)
    # V=Array{Float64,2}
    V=CuArray{Float64,2}

    @time animate_makie(sp,ip,ap,V)
end
go()


