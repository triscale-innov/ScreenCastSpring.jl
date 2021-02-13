module Spring

    using Plots
    using LaTeXStrings #for latex string in plot labels

    export SpringParam,InitParam,AnimParam
    export animate_spring,animate_spring2D
    gr()



    include("params.jl")
    include("animate1D.jl")
    include("animate2D.jl")

 
    


end # module
