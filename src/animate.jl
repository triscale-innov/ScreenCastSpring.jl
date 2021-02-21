using StaticArrays
using LoopVectorization
using CUDA
using StructArrays

steady_position(i,ls) = (i-1)*ls

# PointType(ci::CartesianIndex{N}) where {N}  = Point1D
PointType(ci::CartesianIndex{2}) = Point2D
PointType(ci::CartesianIndex{1}) = Point1D

function steady_position(ci::CartesianIndex{N},ls) where {N} 
    PointType(ci)(steady_position.(Tuple(ci),ls)...)
end

function initial_position(ci,ls,λ,shift,pos)
    rs=steady_position(ci,ls)
    dr=rs-pos
    a=-1/λ^2
    ds=a*exp(dot(dr,dr)*a/2)*shift
    rs+ds*dr
end

function update_position!(rt,rc,rp,f,δt,ms)
    coef=δt^2/ms
    @. rt = 2rc - rp + f*coef #Broadcast : eltwise ops
end


# function update_force!(f,rc,ks)
#     nsx,nsy=size(rc)
#     @inbounds @avx for j ∈ 2:nsy-1
#         for i ∈ 2:nsx-1
#             f[i,j] = -ks*(4rc[i,j]
#             -rc[i,j-1]
#             -rc[i-1,j]
#             -rc[i+1,j]
#             -rc[i,j+1])
#         end
#     end
# end

function update_force!(f,rc,ks)
    ns=size(rc,1)
    r0=1:ns-2
    r1=2:ns-1
    r2=3:ns

    @views @.  f[r1,r1] = -ks*(4rc[r1,r1]
                            -rc[r1,r0]    # Down
                            -rc[r0,r1]    # Left
                            -rc[r2,r1]    # Right
                            -rc[r1,r2])   # Up
end

function advance_nδtpf(rc,rp,rt,f,sp,ap)
    ls,ms,ks,ns=getvalues(sp)
    δt,nδt,nδtperframe=getvalues(ap)

    for _ ∈ 1:nδtperframe # Anonymous iter variable (_)
        update_force!(f,rc,ks)
        update_position!(rt,rc,rp,f,δt,ms)
        rc,rp,rt=rt,rc,rp # Julia's swap
    end
    rc,rp,rt
end


function initialize_arrays(sp,ip,ap,V)
    ls,ms,ks,ns=getvalues(sp)
    λ,shift,pos=getvalues(ip)
    δt,nδt,nδtperframe=getvalues(ap)

    crs=[steady_position(ci,ls) for ci ∈ CartesianIndices(ns)]
    crc=[initial_position(ci,ls,λ,shift,pos) for ci ∈ CartesianIndices(ns)]
    # StructArray(CuArray(aos))
    # vrs=StructArray(crs)
    # vrc=StructArray(crc)
    # @show typeof(vrs)
    # rs=V(vrs)
    # rc=V(vrc)
    # CUDA.allowscalar(true)
    # rs=StructArray(rs)
    # rc=StructArray(rc)
    # CUDA.allowscalar(false)

    rs,rc = V.((crs,crc))
    f,rt,rp=zero(rc),zero(rc),copy(rc)

    rs,rc,rp,rt,f,getproperty.(crs[:,1],:x),getproperty.(crs[1,:],:y)
end

function update_displacement!(dc,rc,rs) 
    @. dc = norm(rc - rs)
end




function display_perf(td,rc,nδt)
    D=dimension(eltype(rc))
    @show D
    nflops=10D # Manual count floating point ops
    nRW=6D    # Manual count Array Reads and Writes
    T=Float64 # i.e. Float64
    floatsize_inbytes=sizeof(T) #Float64 -> 8 Bytes
    nbytes=nRW*floatsize_inbytes # Float64 -> 96 Bytes
    
    mupns=length(rc)*nδt/(td*1.e9) # mass pos updates per ns
    println("$(round((mupns*nflops),sigdigits=3))\t GFLOPS")
    println("$(round((mupns*nbytes),sigdigits=3))\t GB/s")
end

function substract_kernel(rt, rc, rs)
    i = threadIdx().x
    a=rc[i]-rs[i]
    # rt[i]=a
    # setproperty(rc[i],:x) = getproperty(rc[i],:x) - getproperty(rs[i],:x)
    return
end


function animate_spring2D(sp,ip,ap,V)
    δt,nδt,nδtperframe=getvalues(ap)
    ls,ms,ks,ns=getvalues(sp)
    rs,rc,rp,rt,f,xs,ys=initialize_arrays(sp,ip,ap,V)


    # CUDA.@sync update_force!(f,rc,ks)
    # # @show rc[1],f[1]
    # copy!(rc,rt)

    # update_position!(rt,rc,rp,f,δt,ms)

    dc=V(zeros(size(rs)))
    cdc=Array(dc)
    update_displacement!(dc,rc,rs)
    mdc=maximum(dc)
    @show mdc
    @show typeof(dc)
    @show typeof(rc)
    @show typeof(rs)
    @show length.((dc,rc,rs))
    # @cuda threads=length(rt) substract_kernel(rt, rc, rs)
    # mdc=maximum(dc)

    nf=nδt÷nδtperframe # We assume a null remainder
    # return
    t=0.0 # Simulation time 
    tdynamic=0.0 # Computing time for the dynamic
    # for i ∈ 1:nf
        anim = @animate for i ∈ 1:nf
            tdynamic+= @elapsed CUDA.@sync begin
            rc,rp,rt=advance_nδtpf(rc,rp,rt,f,sp,ap)
        end
        update_displacement!(dc,rc,rs)
        @. cdc = dc  # Copy dc (type V) to cdc (type Array{Float64,2})

        t+=nδtperframe*δt
        contour(xs,ys,cdc,clims=(0,mdc/4), #level lines graph
            thickness_scaling = 1.4,size=(600,600),
            xlabel=L"x_s",ylabel=L"y_s",
            right_margin = 10Plots.PlotMeasures.mm,
            title=L"\sqrt{(x_c-x_s)^2+(y_c-y_s)^2}",aspect_ratio=:equal)
    end
    display_perf(tdynamic,rc,nδt)
    gif(anim,"toto.gif",fps=15) # save the animation 
end

function main()
    sp=SpringParam(ls=0.1,ms=1.0,ks=2.5,ns=(800,800))
    center=Point2D(sp.ns[1]*sp.ls/2,sp.ns[2]*sp.ls/2)
    ip=InitParam(λ=2.0,shift=0.1,pos=center)
    ap=AnimParam(δt=0.1,nδt=2000,nδtperframe=2000)

    CUDA.allowscalar(false)
    # V=Array
    # V=StructArray
    V=CuArray

    @time animate_spring2D(sp,ip,ap,V)

    # initialize_arrays(sp,ip,ap)


    # sp,ip,ap
end