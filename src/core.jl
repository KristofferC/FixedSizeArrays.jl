importall Base
import Base.Func

# Alot of workarounds for not having triangular dispatch
const TYPE_PARAM_POSITION = 1
const NDIM_PARAM_POSITION = 2
const SIZE_PARAM_POSITION = 3

abstract FixedArray{T, NDim, SIZE} 
abstract MutableFixedArray{T, NDim, SIZE} <: FixedArray{T, NDim, SIZE}

typealias MutableFixedVector{T, CARDINALITY} MutableFixedArray{T, 1, (CARDINALITY,)}
typealias MutableFixedMatrix{T, M, N} 		 MutableFixedArray{T, 2, (M, N)}

typealias FixedVector{T, CARDINALITY} FixedArray{T, 1, (CARDINALITY,)}
typealias FixedMatrix{T, M, N}        FixedArray{T, 2, (M, N)}

abstract FixedArrayWrapper{T <: FixedArray} <: FixedArray


eltype{T,N,SZ}(A::FixedArray{T,N,SZ}) 				= T
eltype{T <: FixedArray}(A::Type{T})                 = first(T.types) 

length{T,N,SZ}(A::FixedArray{T,N,SZ})           	= prod(SZ)
length{T <: FixedArray}(A::Type{T})                 = prod(super(T).parameters[SIZE_PARAM_POSITION])
length{T,N,SZ}(A::Type{FixedArray{T,N,SZ}})         = prod(SZ)

endof{T,N,SZ}(A::FixedArray{T,N,SZ})                = length(A)


ndims{T,N,SZ}(A::FixedArray{T,N,SZ})            	= N
ndims{T <: FixedArray}(A::Type{T})            		= super(T).parameters[NDIM_PARAM_POSITION]

size{T,N,SZ}(A::FixedArray{T,N,SZ})             	= SZ
size{T,N,SZ}(A::FixedArray{T,N,SZ}, d::Integer) 	= SZ[d]

size{T <: FixedArray}(A::Type{T})            		= super(T).parameters[SIZE_PARAM_POSITION]
size{T <: FixedArray}(A::Type{T}, d::Integer) 		= super(T).parameters[SIZE_PARAM_POSITION][d]

# Iterator 
start(A::FixedArray)            					= 1
next (A::FixedArray, state::Integer) 				= (A[state], state+1)
done (A::FixedArray, state::Integer) 				= length(A) < state


#Utilities:
name(typ::DataType) = string(typ.name.name)
fieldname(i) = symbol("i_$i")
# Function to strip of parameters from a type definition, to avoid conversion.
# eg: Point{Float32}(1) would end up as Point{Float32}(convert(Float32, 1))
# whereas Point(1) -> Point{Int}(1)
# Main is needed, as the resulting type is mostly defined in Main, so it wouldn't be found otherwise
function without_params{T}(::Type{T})
    eval(:(Main.$(symbol(name(T)))))
end