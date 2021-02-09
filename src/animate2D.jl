using CUDA 
gr() #default Plots.jl backend

function initial_position(i,j,ls,λ,shift,posx,posy)
    xs=steady_position(i,ls)
    ys=steady_position(j,ls)
    dx=xs-posx
    dy=ys-posy
    dr=sqrt(dx^2+dy^2)
    ds=exp(-0.5*dr^2/λ^2)*λ*shift
    xs-dx*ds,ys-dy*ds
end 

function update_force!(fx::Array{Float64,2},xc::Array{Float64,2},ks)
    nsx,nsy=size(xc)
    @inbounds for j ∈ 2:nsy-1
        for i ∈ 2:nsx-1
            fx[i,j] = -ks*(4xc[i,j]
            -xc[i,j-1]
            -xc[i-1,j]
            -xc[i+1,j]
            -xc[i,j+1])
        end
    end
end

function update_force!(fx::AbstractArray{Float64,2},xc::AbstractArray{Float64,2},ks)
    ns=size(xc,1)
    r0=1:ns-2
    r1=2:ns-1
    r2=3:ns

    @views @. fx[r1,r1] = -ks*(4*xc[r1,r1]
        -xc[r1,r0]
        -xc[r0,r1]
        -xc[r2,r1]
        -xc[r1,r2])
end

function density_shift!(dc,xc,yc,ls)
    ns=size(xc,1)
    r0,r1,r2=1:ns-2,2:ns-1,3:ns
    ds=1/(4ls^2)
    @views @. dc[r1,r1] = 1/((xc[r2,r1] - xc[r0,r1])*(yc[r1,r2] - yc[r1,r0])) - ds
end



function initialize_arrays(sp,ip,ap,V)
    ls,ms,ks,ns=getvalues(sp)
    λ,shift,pos=getvalues(ip)
    δt,nδt,nδtperframe=getvalues(ap)

    cxs=[steady_position(i,ls) for i ∈ 1:ns, j ∈ 1:ns]
    cys=[steady_position(j,ls) for i ∈ 1:ns, j ∈ 1:ns]

    xaxis=[steady_position(i,ls) for i ∈ 1:ns]

    cxc=[initial_position(i,j,ls,λ,shift,pos,pos)[1] for i ∈ 1:ns, j ∈ 1:ns]
    cyc=[initial_position(i,j,ls,λ,shift,pos,pos)[2] for i ∈ 1:ns, j ∈ 1:ns]

    xs,ys,xc,yc=V.((cxs,cys,cxc,cyc))

    fx,xt,xp=zero(xc),zero(xc),copy(xc)
    fy,yt,yp=zero(yc),zero(yc),copy(yc)


    xs,xc,xp,xt,fx,ys,yc,yp,yt,fy
end



function display_perf(td,xc,nδt)
    nflops=20
    nRW=12
    T=eltype(xc) # Float64
    floatsize_inbytes=sizeof(T) #Float64 -> 8 Bytes
    nbytes=nRW*floatsize_inbytes # Float64 -> 96 Bytes
    
    mupns=length(xc)*nδt/(td*1.e9) # mass pos update per ns
    println("$(round((mupns*nflops),sigdigits=3))\t GFLOPS")
    println("$(round((mupns*nbytes),sigdigits=3))\t GB/s")
end


function animate_spring2D(sp,ip,ap,V=Array{Float64,2})
    δt,nδt,nδtperframe=getvalues(ap)
    xs,xc,xp,xt,fx,ys,yc,yp,yt,fy=initialize_arrays(sp,ip,ap,V)

    dc=zero(xc)
    cdc=Array(xc)

    xaxis=Array(xs[:,1])
    yaxis=Array(ys[1,:])
    nf=nδt÷nδtperframe

    t=0.0
    tdynamic=0.0
    anim = @animate for i ∈ 1:nf
        tdynamic+= @elapsed CUDA.@sync begin
            xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
            yc,yp,yt=advance_nδtpf(yc,yp,yt,fy,sp,ap)
        end
        @. dc = sqrt((xc - xs)^2+(yc - ys)^2)
        @. cdc = dc 
        t+=nδtperframe*δt
        contour(xaxis,yaxis,cdc,clims=(0,ip.shift/2),
        title="t=$t",aspect_ratio=:equal)
    end

    display_perf(tdynamic,xc,nδt)

    gif(anim,"toto.gif",fps=15)
end