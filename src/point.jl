struct Point2D{R<:Real}
    x::R
    y::R
end

# Base extensions
Base.:+(p1::Point2D,p2::Point2D) = Point2D(p1.x+p2.x,p1.y+p2.y)
Base.:-(p1::Point2D,p2::Point2D) = Point2D(p1.x-p2.x,p1.y-p2.y)
Base.:*(a::Real,p::Point2D) = Point2D(p.x*a,p.y*a)
Base.:*(p::Point2D,a::Real) = Point2D(p.x*a,p.y*a)
Base.:/(p::Point2D,a::Real) = Point2D(p.x/a,p.y/a)
Base.zero(::Type{Point2D{R}}) where {R<:Real} = Point2D(R(0),R(0))
dimension(::Type{Point2D{R}}) where {R<:Real} = 2

# Broadcast utility: treat Point2D as a scalar
# Base.broadcastable(m::Point2D{R}) where {R<:Real}= Ref(m)

# Linear algebra
@inline LinearAlgebra.dot(p1::Point2D,p2::Point2D) = p1.x*p2.x + p1.y*p2.y
@inline squared_norm(p::Point2D) = dot(p,p)
LinearAlgebra.norm(p::Point2D) = sqrt(squared_norm(p))

struct Point1D{R<:Real}
    x::R
end

# Base extensions
Base.:+(p1::Point1D,p2::Point1D) = Point1D(p1.x+p2.x)
Base.:-(p1::Point1D,p2::Point1D) = Point1D(p1.x-p2.x)
Base.:*(a::Real,p::Point1D) = Point1D(p.x*a)
Base.:*(p::Point1D,a::Real) = Point1D(p.x*a)
Base.:/(p::Point1D,a::Real) = Point1D(p.x/a)
Base.zero(::Type{Point1D{R}}) where {R<:Real} = Point1D(R(0))

# Broadcast utility: treat Point1D as a scalar
# Base.broadcastable(m::Point1D{R}) where {R<:Real}= Ref(m)

# Linear algebra
@inline LinearAlgebra.dot(p1::Point1D,p2::Point1D) = p1.x*p2.x
@inline squared_norm(p::Point1D) = dot(p,p)
LinearAlgebra.norm(p::Point1D) = sqrt(squared_norm(p))
dimension(::Type{Point1D{R}}) where {R<:Real} = 1

