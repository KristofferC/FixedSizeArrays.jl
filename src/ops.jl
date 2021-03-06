# operations
const unaryOps = (:-, :~, :conj, :abs, 
                  :sin, :cos, :tan, :sinh, :cosh, :tanh, 
                  :asin, :acos, :atan, :asinh, :acosh, :atanh,
                  :sec, :csc, :cot, :asec, :acsc, :acot,
                  :sech, :csch, :coth, :asech, :acsch, :acoth,
                  :sinc, :cosc, :cosd, :cotd, :cscd, :secd,
                  :sind, :tand, :acosd, :acotd, :acscd, :asecd,
                  :asind, :atand, :radians2degrees, :degrees2radians,
                  :log, :log2, :log10, :log1p, :exponent, :exp,
                  :exp2, :expm1, :cbrt, :sqrt, :square, :erf, 
                  :erfc, :erfcx, :erfi, :dawson, :ceil, :floor,
                  :trunc, :round, :significand, :lgamma, :hypot,
                  :gamma, :lfact, :frexp, :modf, :airy, :airyai,
                  :airyprime, :airyaiprime, :airybi, :airybiprime,
                  :besselj0, :besselj1, :bessely0, :bessely1,
                  :eta, :zeta, :digamma)

# vec-vec and vec-scalar
const binaryOps = (:.+, :.-,:.*, :./, :.\, :.^,:*,:/,
                   :.==, :.!=, :.<, :.<=, :.>, :.>=, :+, :-,
                   :min, :max,
                   :div, :fld, :rem, :mod, :mod1, :cmp,
                   :atan2, :besselj, :bessely, :hankelh1, :hankelh2, 
                   :besseli, :besselk, :beta, :lbeta)

const reductions = ((:sum,:+),(:prod,:*),(:minimum,:min),(:maximum,:max))

function gen_functor(func::Symbol, unary::Int)
    functor_name  = gensym()
    arguments     = ntuple(i->symbol("arg$i"), unary)
    functor_expr  = quote 
        immutable $functor_name <: Func{$unary} end
        call(::$functor_name, $(arguments...)) = $func($(arguments...))
    end
    return (functor_name, functor_expr)
end

for (callfun, reducefun) in reductions
    functor_name, functor_expr = gen_functor(reducefun, 2)
    eval(quote 
        $functor_expr
        $(callfun){T <: FixedArray}(x::T) = reduce($functor_name(), x)
    end)
end
for op in unaryOps
    functor_name, functor_expr = gen_functor(op, 1)
    eval(quote 
        $functor_expr
        $(op){T <: FixedArray}(x::T) = map($functor_name(), x)
    end)
end

for op in binaryOps
    functor_name, functor_expr = gen_functor(op, 2)
    eval(quote
        $functor_expr
        $op{T <: FixedArray}(x::T,    y::T)    = map($functor_name(), x, y)
        $op{T <: FixedArray}(x::Real, y::T)    = map($functor_name(), x, y)
        $op{T <: FixedArray}(x::T,    y::Real) = map($functor_name(), x, y)
    end)
end


dot{T <: FixedArray}(a::T, b::T) = sum(a.*b)

cross{T}(a::FixedVector{T, 2}, b::FixedVector{T, 2}) = a[1]*b[2]-a[2]*b[1]
cross{T}(a::FixedVector{T, 3}, b::FixedVector{T, 3}) = typeof(a)(a[2]*b[3]-a[3]*b[2], 
                                                     a[3]*b[1]-a[1]*b[3], 
                                                     a[1]*b[2]-a[2]*b[1])

norm{T, N}(a::FixedVector{T, N})     = sqrt(dot(a,a))
normalize{FSA <: FixedArray}(a::FSA) = a / norm(a)



function convert{T1 <: FixedArray, T2 <: FixedArray}(a::Type{T1}, b::Array{T2})
    @assert sizeof(b) % sizeof(a) == 0 "Type $a, with size: ($(sizeof(a))) doesn't fit into the array b: $(length(b)) x $(sizeof(eltype(b)))"
    reinterpret(a, b, (div(sizeof(b), sizeof(a)),))
end

#Matrix
det{T}(A::FixedMatrix{T, 1, 1}) = A[1]
det{T}(A::FixedMatrix{T, 2, 2}) = A[1,1]*A[2,2] - A[1,2]*A[2,1]
det{T}(A::FixedMatrix{T, 3, 3}) = A[1,1]*(A[2,2]*A[3,3]-A[2,3]*A[3,2]) - A[1,2]*(A[2,1]*A[3,3]-A[2,3]*A[3,1]) + A[1,3]*(A[2,1]*A[3,2]-A[2,2]*A[3,1])
det{T}(A::FixedMatrix{T, 4, 4}) = (
        A[13] * A[10]  * A[7]  * A[4]  - A[9] * A[14] * A[7]  * A[4]   -
        A[13] * A[6]   * A[11] * A[4]  + A[5] * A[14] * A[11] * A[4]   +
        A[9]  * A[6]   * A[15] * A[4]  - A[5] * A[10] * A[15] * A[4]   -
        A[13] * A[10]  * A[3]  * A[8]  + A[9] * A[14] * A[3]  * A[8]   +
        A[13] * A[2]   * A[11] * A[8]  - A[1] * A[14] * A[11] * A[8]   -
        A[9]  * A[2]   * A[15] * A[8]  + A[1] * A[10] * A[15] * A[8]   +
        A[13] * A[6]   * A[3]  * A[12] - A[5] * A[14] * A[3]  * A[12]  -
        A[13] * A[2]   * A[7]  * A[12] + A[1] * A[14] * A[7]  * A[12]  +
        A[5]  * A[2]   * A[15] * A[12] - A[1] * A[6]  * A[15] * A[12]  -
        A[9]  * A[6]   * A[3]  * A[16] + A[5] * A[10] * A[3]  * A[16]  +
        A[9]  * A[2]   * A[7]  * A[16] - A[1] * A[10] * A[7]  * A[16]  -
        A[5]  * A[2]   * A[11] * A[16] + A[1] * A[6]  * A[11] * A[16])


inv{T}(A::FixedMatrix{T, 1, 1}) = A
function inv{T}(A::FixedMatrix{T, 2, 2})
  determinant = det(A)
  typeof(A)(
      A[2,2] /determinant,
      -A[2,1]/determinant,
      -A[1,2]/determinant,
      A[1,1] /determinant)
end
function inv{T}(A::FixedMatrix{T, 3, 3})
    determinant = det(A)
    typeof(A)(
        (A[2,2]*A[3,3]-A[2,3]*A[3,2]) /determinant,
        -(A[2,1]*A[3,3]-A[2,3]*A[3,1])/determinant,
        (A[2,1]*A[3,2]-A[2,2]*A[3,1]) /determinant,

        -(A[1,2]*A[3,3]-A[1,3]*A[3,2])/determinant,
        (A[1,1]*A[3,3]-A[1,3]*A[3,1]) /determinant,
        -(A[1,1]*A[3,2]-A[1,2]*A[3,1])/determinant,

        (A[1,2]*A[2,3]-A[1,3]*A[2,2]) /determinant,
        -(A[1,1]*A[2,3]-A[1,3]*A[2,1])/determinant,
        (A[1,1]*A[2,2]-A[1,2]*A[2,1]) /determinant
    )
end


stagedfunction ctranspose{T, M, N}(A::FixedMatrix{T, M, N})
    returntype = gen_fixedsizevector_type((M,N), A.mutable)
    :($returntype($([:(A[$(M+1-i), $(N+1-j)]) for i=M:-1:1, j=N:-1:1]...)))
end

# Matrix
stagedfunction (*){T, M, N, K}(a::FixedMatrix{T, M, N}, b::FixedMatrix{T, N, K})
    returntype = gen_fixedsizevector_type((M,K), a.mutable)
    expr= :($returntype( 
         $([:(dot(row(a, $i), column(b, $j))) for i=1:M, j=1:K]...)
    ))
    expr
end

function (*){T, FSV <: FixedVector, M, N}(a::FixedMatrix{T, M, N}, b::FSV)
    bb = FixedMatrix{T, length(b), 1}(b...)
    a*bb
end
function (*){T, FSV <: FixedVector, M, N}(a::FSV, b::FixedMatrix{T, M, N})
    aa = FixedMatrix{T, length(a), 1}(a...)
    aa*b
end
function (*){FSV <: FixedVector}(a::FSV, b::FSV)
    FixedMatrix{eltype(FSV), 1, 1}(dot(a,b))
end
#=
Optimized convert version doesn't compile, as the dead code still gets checked for syntax, 
which means if FSA is concrete, there will be FSA{Float32}{eltype(v)} in the emitted code.
Could be solved by calling out to another function...
function convert{FSA <: FixedArray}(::Type{FSA}, v::Array{T})
    if FSA.abstract
        unsafe_load(Ptr{FSA{eltype(v)}}}(pointer(v)))
    else
        unsafe_load(Ptr{FSA}(pointer(v)))
    end
end

=#
function convert{FSAA <: FixedArray}(a::Type{FSAA}, b::FixedArray)
    FSAA(b...)
end
function convert{FSA <: FixedArray}(a::Type{FSA}, b::DenseArray)
    FSA(b...)
end

function convert{DA <: DenseArray, FSA <: FixedArray}(b::Type{DA}, a::FSA)
  reshape([a...], size(FSA))
end