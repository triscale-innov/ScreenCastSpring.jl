steady_position(i,ls) = (i-1)*ls

function initial_position(i,ls,λ,shift,pos)
    xs=steady_position(i,ls)
    dx=xs-pos
    xs-λ*dx*shift*exp(-0.5*dx^2/λ^2)
end 

function update_force!(fx,xc,ks)
    ns=length(xc)
    for i ∈ 2:ns-1
        fx[i] = -ks*(2xc[i]-xc[i-1]-xc[i+1])
    end
end

function update_position!(xt,xc,xp,fx,δt,ms)
    coef=δt^2/ms
    @. xt = 2xc - xp + fx*coef
end

function advance_nδtpf(xc,xp,xt,fx,sp,ap)
    ls,ms,ks,ns=getvalues(sp)
    δt,nδt,nδtperframe=getvalues(ap)

    for _ ∈ 1:nδtperframe
        update_force!(fx,xc,ks)
        update_position!(xt,xc,xp,fx,δt,ms)
        xc,xp,xt=xt,xc,xp
    end
    xc,xp,xt
end


function animate_spring(sp,ip,ap)
    ls,ms,ks,ns=getvalues(sp)
    λ,shift,pos=getvalues(ip)
    δt,nδt,nδtperframe=getvalues(ap)

    xs=[steady_position(i,ls) for i ∈ 1:ns]
    xc=[initial_position(i,ls,λ,shift,pos) for i ∈ 1:ns]

    dc=zero(xc)
    fx=zero(xc)
    xt=zero(xc)
    xp=copy(xc)

    nf=nδt÷nδtperframe
    t=0.0
    anim = @animate for i ∈ 1:nf
        xc,xp,xt=advance_nδtpf(xc,xp,xt,fx,sp,ap)
        @. dc = xc - xs
        t+=nδtperframe*δt
        plot(xs,dc,ylims=(-shift*2,shift*2),title="t=$t")
    end

    gif(anim,"toto.gif",fps=15)
end