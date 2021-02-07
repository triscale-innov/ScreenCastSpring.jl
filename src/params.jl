Base.@kwdef struct SpringParam
    ls::Float64 #Spring lenght
    ms::Float64 # Mass
    ks::Float64 # Spring Strength
    ns::Int     # Mass number
end
getvalues(p::SpringParam) = p.ls,p.ms,p.ks,p.ns

Base.@kwdef struct InitParam
    λ::Float64      # Wavelength of the initial deformation
    shift::Float64  # Maximal initial node displacement
    pos::Float64    # Central position of the node displacement
end
getvalues(p::InitParam) = p.λ,p.shift,p.pos

Base.@kwdef struct AnimParam
    δt::Float64      # Time step for the dynamic simulation
    nδt::Int         # Number of timesteps
    nδtperframe::Int # Number of timesteps per animation frame
end
getvalues(p::AnimParam) = p.δt,p.nδt,p.nδtperframe