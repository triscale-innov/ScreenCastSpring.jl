steady_position(i,ls) = (i-1)*ls

function initial_position(i,ls,λ,shift,pos)
    xs=steady_position(i,ls)
    dx=xs-pos
    ds=(-1/λ^2)*exp(-(dx/λ)^2/2)*shift
    xs+λ*dx*ds
end 

function update_force!(fx,xc,ks)
    ns=length(xc)
    for i ∈ 2:ns-1 # Julia's loops are fast
        fx[i] = -ks*(2xc[i]-xc[i-1]-xc[i+1])
    end
end

function update_position!(xt,xc,xp,fx,δt,ms)
    coef=δt^2/ms
    @. xt = 2xc - xp + fx*coef #Broadcast : eltwise ops
end

function advance_nδtpf(xc,xp,xt,fx,sp,ap)
    ls,ms,ks,ns=getvalues(sp)
    δt,nδt,nδtperframe=getvalues(ap)

    for _ ∈ 1:nδtperframe # Anonymous iter variable (_)
        update_force!(fx,xc,ks)
        update_position!(xt,xc,xp,fx,δt,ms)
        xc,xp,xt=xt,xc,xp # Julia's swap
    end
    xc,xp,xt
end


function animate_spring(sp,ip,ap)
    ls,ms,ks,ns=getvalues(sp)
    λ,shift,pos=getvalues(ip)
    δt,nδt,nδtperframe=getvalues(ap)
    #1D Array comprehensions
    xs=[steady_position(i,ls) for i ∈ 1:ns] 
    xc=[initial_position(i,ls,λ,shift,pos) for i ∈ 1:ns]

    dc,fx,xt=zero(xc),zero(xc),zero(xc)
    xp=copy(xc) # xp=xc <=> zero initial velocities
    @. dc = xc - xs
    mdc=maximum(dc)

    nf=nδt÷nδtperframe  
    t=0.0               # Simulation time
    anim = @animate for i ∈ 1:nf
        xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
        @. dc = xc - xs
        t+=nδtperframe*δt
        plot(xs,dc,ylims=(-mdc,mdc),
            xlabel=L"x_s",ylabel=L"x_c(t) - x_s",
            thickness_scaling = 1.6,size=(600,400),legend=false,
            right_margin = 10Plots.PlotMeasures.mm,title="t=$(Int(round(t)))")
    end

    gif(anim,"toto.gif",fps=15)
end