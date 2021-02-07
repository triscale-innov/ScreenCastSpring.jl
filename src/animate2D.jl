using CUDA
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

function update_force!(fx::CuArray{Float64,2},xc::CuArray{Float64,2},ks)
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


function animate_spring2D(sp,ip,ap)

    CUDA.allowscalar(false)

    ls,ms,ks,ns=getvalues(sp)
    λ,shift,pos=getvalues(ip)
    δt,nδt,nδtperframe=getvalues(ap)

    V=CuArray{Float64,2}


    cxs=[steady_position(i,ls) for i ∈ 1:ns, j ∈ 1:ns]
    cys=[steady_position(j,ls) for i ∈ 1:ns, j ∈ 1:ns]

    xaxis=[steady_position(i,ls) for i ∈ 1:ns]


    cxc=[initial_position(i,j,ls,λ,shift,pos,pos)[1] for i ∈ 1:ns, j ∈ 1:ns]
    cyc=[initial_position(i,j,ls,λ,shift,pos,pos)[2] for i ∈ 1:ns, j ∈ 1:ns]

    xs,ys,xc,yc=V.((cxs,cys,cxc,cyc))

    dc=zero(xc)
    cdc=zero(cxc)

    fx=zero(xc)
    xt=zero(xc)
    xp=copy(xc)

    fy=zero(yc)
    yt=zero(yc)
    yp=copy(yc)

    nf=nδt÷nδtperframe
    t=0.0
    te=0.0
    anim = @animate for i ∈ 1:nf
        te+=@elapsed CUDA.@sync begin
            xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
            yc,yp,yt=advance_nδtpf(yc,yp,yt,fy,sp,ap)
        end
        @. dc = sqrt((xc - xs)^2+(yc - ys)^2)
        @. cdc = dc 
        t+=nδtperframe*δt
        contour(xaxis,xaxis,cdc,clims=(0,shift/2),
        title="t=$t",aspect_ratio=:equal)
    end

    cupns=ns^2*nδt/(te*1.e9)
    nflops=20
    nbytes=12*sizeof(eltype(xc))

    println("$(cupns*nflops) GFLOPS")
    println("$(cupns*nbytes) GB/s")


    gif(anim,"toto.gif",fps=15)
end