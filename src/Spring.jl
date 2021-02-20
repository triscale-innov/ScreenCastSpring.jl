module Spring

    using Plots
    using LaTeXStrings #for latex string in plot labels
    using LinearAlgebra

    export SpringParam,InitParam,AnimParam
    export animate_spring,animate_spring2D
    gr()


    include("point.jl")
    include("params.jl")
    # include("animate1D.jl")
    include("animate.jl")

 
    


end # module
