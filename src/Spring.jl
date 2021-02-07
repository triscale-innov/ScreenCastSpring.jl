module Spring

    using Plots

    export SpringParam,InitParam,AnimParam
    export animate_spring,animate_spring2D

    include("params.jl")
    include("animate1D.jl")
    include("animate2D.jl")

 
    


end # module
