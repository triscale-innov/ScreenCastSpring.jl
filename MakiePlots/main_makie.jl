using Spring
using Spring: getvalues,advance_nδtpf,initialize_arrays
using CUDA
using Makie
using PlotUtils #for colorant and color gradient (cgrad)


"""
    density_shift!(dc,xc,yc,ls)

Approximate density variation for the 2D mass system :

    dc[i,j]=δρij≃1/(Sij)-1/(4ls) where 

        Sij is the surounding surface related to ij mass 
        Sij= (xc[i+1,j]-xc[i-1,j])*(yc[i,j+1]-yc[i-1,j])

        and 
        
        4ls is the steady surrounding surface 

"""
function density_shift!(dc,xc,yc,ls)
    ns=size(xc,1) #assuming square array
    r0,r1,r2=1:ns-2,2:ns-1,3:ns # UnitRange
    ds=1/(4ls^2)  #steady density
    @views @. dc[r1,r1] = 1/((xc[r2,r1] - xc[r0,r1])*(yc[r1,r2] - yc[r1,r0])) - ds
end


function setup_scene(xaxis,dc,nf)
    scene = Scene(resolution = (800, 800))
    dcnode = Node(dc)

    xM=maximum(xaxis)
    dM=maximum(dc)*0.01
    lim=FRect3D((0,0,0),(xM,xM,dM))

    surface!(scene,xaxis,xaxis,lift(d->d,dcnode),limits=lim,colormap=corporate_gradient(),colorrange = (-dM,dM))
    scale!(scene, 1, 1, 0.5/dM)

      translate_cam!(scene,(10,10,2))
        update_cam!(scene, Vec3f0(0, 0, 5), Vec3f0(0.01, 0.01, 0))
        rotate_cam!(scene,(π/4 ,-π/2 ,0))
        αstep=-(π/4)/(nf÷2)
        lift(d->rotate_cam!(scene,(0 ,αstep ,0)),dcnode)



    scene,dcnode
end

#Triscale colors ;)
corporate_gradient() = cgrad([colorant"#177272",colorant"#fafafa",colorant"#ee6f40"])


function animate_makie(sp,ip,ap,V)
    δt,nδt,nδtperframe=Spring.getvalues(ap)
    xs,xc,xp,xt,fx,ys,yc,yp,yt,fy=initialize_arrays(sp,ip,ap,V)

    dc=zero(xc)
    cdc=Array(xc)

    xaxis=Array(xs[:,1])
    yaxis=Array(ys[1,:])
    nf=nδt÷nδtperframe
    density_shift!(dc,xc,yc,sp.ls)
    # @. dc = sqrt((xc - xs)^2+(yc - ys)^2)
    @. cdc = dc 
    scene,dcnode=setup_scene(xaxis,cdc,nf)
    display(scene)
    
    t=0.0
    tdynamic=0.0
    # Makie.record(scene, "output.gif", 1:nf, framerate=15) do i
    for i ∈ 1:nf
        tdynamic+= @elapsed CUDA.@sync begin
            xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
            yc,yp,yt=advance_nδtpf(yc,yp,yt,fy,sp,ap)
        end
        # @. dc = sqrt((xc - xs)^2+(yc - ys)^2)
        density_shift!(dc,xc,yc,sp.ls)
        @. cdc = dc 
        dcnode[] = cdc
        sleep(0.01)
        t+=nδtperframe*δt
    end
end

function go()
    sp=SpringParam(ls=0.1,ms=1,ks=2.5,ns=1000)
    ip=InitParam(λ=3.0,shift=0.1,pos=sp.ls*sp.ns/2)
    ap=AnimParam(δt=0.1,nδt=10000,nδtperframe=20)

    CUDA.allowscalar(false)
    # V=Array{Float64,2}
    V=CuArray{Float64,2}

    @time animate_makie(sp,ip,ap,V)
end
go()



