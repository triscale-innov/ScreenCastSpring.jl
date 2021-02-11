# Spring.jl
## A simple Julia Tutorial dedicated to the dynamic of 1D and 2D sets of masses connected with springs.

### 1D System :

![](images/s1d.png)


```julia
] activate .
] instantiate
include("main1D.jl")
```

![](images/spring1D.gif)

### 2D System :


![](images/s2d.png)


```julia
] activate .
] instantiate
include("main1D.jl")
include("main1D.jl") #run twice to get proper timings
```

![](images/spring2dplots.gif)

### 2D System with Makie display (requires OpenGL capable machine)

```julia
cd("MakiePlots")
] activate .
] instantiate
include("main_makie.jl")
```
![](images/output.gif)


