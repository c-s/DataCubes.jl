# it seems that currently, map operation over Nullable array is not optimzed in julia 0.4.1.

import Base: .+, .-, .*, *, ./, /, .\, .//, .==, .<, .!=, .<=, .%, .<<, .>>, .^, +, -, ~, &, |, $, ==, !=
import Base.return_types
import DataFrames: DataFrame

"""

`wrap_array(arr)`

Wrap an array by `AbstractArrayWrapper` if it is not `DictArray` or `labeledArray`, and not already `AbstractArrayWrapper`.

"""
wrap_array(arr::AbstractArrayWrapper) = arr
wrap_array(arr::LabeledArray) = arr
wrap_array(arr::DictArray) = arr
wrap_array(arr::AbstractArray) = AbstractArrayWrapper(arr)
wrap_array(arr::DataFrame) = arr

Base.setindex!{T,N}(arr::AbstractArrayWrapper{T,N}, v::T, arg::Int) = setindex!(arr.a, v, arg)
Base.setindex!{T,N}(arr::AbstractArrayWrapper{T,N}, v::T, args::Int...) = setindex!(arr.a, v, args...)
Base.setindex!{T,N}(arr::AbstractArrayWrapper{Nullable{T},N}, v::T, args::Int...) = setindex!(arr.a, v, args...)
Base.eltype{T,N,A}(::Type{AbstractArrayWrapper{T,N,A}}) = T
Base.linearindexing{T,N,A}(::Type{AbstractArrayWrapper{T,N,A}}) = Base.linearindexing(A)
Base.sub(arr::AbstractArrayWrapper, args::Union{Colon,Int,AbstractVector}...) = AbstractArrayWrapper(sub(arr.a, args...))
Base.slice(arr::AbstractArrayWrapper, args::Union{Colon,Int,AbstractVector}...) = AbstractArrayWrapper(slice(arr.a, args...))
Base.sub(arr::AbstractArrayWrapper, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}})= AbstractArrayWrapper(sub(arr.a, args))
Base.slice(arr::AbstractArrayWrapper, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}}) = AbstractArrayWrapper(slice(arr.a, args))
Base.repmat(arr::Union{AbstractArrayWrapper{TypeVar(:T),1},AbstractArrayWrapper{TypeVar(:T),2}}, n::Int) = AbstractArrayWrapper(repmat(arr.a, n))
Base.repmat(arr::Union{AbstractArrayWrapper{TypeVar(:T),1},AbstractArrayWrapper{TypeVar(:T),2}}, m::Int, n::Int) = AbstractArrayWrapper(repmat(arr.a, m, n))
@delegate(AbstractArrayWrapper.a, Base.start, Base.next, Base.done, Base.size,
                           Base.ndims, Base.length, Base.setindex!, Base.find, Base.fill!)
@delegate_and_lift(AbstractArrayWrapper.a, Base.transpose, Base.permutedims,
                                   Base.sort, Base.sort!, Base.sortperm, Base.reverse,
                                   Base.sub, Base.slice)
Base.reshape(arr::AbstractArrayWrapper, args::Tuple{Vararg{Int}}) = AbstractArrayWrapper(reshape(arr.a, args))
Base.reshape(arr::AbstractArrayWrapper, args::Int...) = AbstractArrayWrapper(reshape(arr.a, args...))
Base.similar{T,N}(arr::AbstractArrayWrapper, ::Type{T}, dims::NTuple{N,Int}) = AbstractArrayWrapper(similar(arr.a, T, dims))
Base.similar{T}(arr::AbstractArrayWrapper, ::Type{T}, dims::Int...) = AbstractArrayWrapper(similar(arr.a, T, dims...))
Base.similar{T<:AbstractFloat,U<:AbstractFloat,N,A,M}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                    ::Type{Nullable{U}},
                                                    dims::NTuple{M,Int}) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a.data, U, dims)))
Base.similar{T<:AbstractFloat,U<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                    ::Type{Nullable{U}},
                                                    dims::Int...) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a.data, U, dims...)))
Base.similar{U<:AbstractFloat,M}(arr::AbstractArrayWrapper,
                                 ::Type{Nullable{U}},
                                 dims::NTuple{M,Int}) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a, U, dims)))
Base.similar{U<:AbstractFloat}(arr::AbstractArrayWrapper,
                                 ::Type{Nullable{U}},
                                 dims::Int...) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a, U, dims...)))
Base.repeat(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(repeat(arr.a; kwargs...))
Base.sort(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(sort(arr.a; kwargs...))
Base.sort!(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(sort!(arr.a; kwargs...))
Base.copy(arr::AbstractArrayWrapper) = AbstractArrayWrapper(copy(arr.a))
Base.copy!(tgt::AbstractArrayWrapper, src::AbstractArrayWrapper) = copy!(tgt.a, src.a)
Base.copy!(tgt::AbstractArrayWrapper, src::AbstractArray) = copy!(tgt.a, src)
Base.cat(dim::Int, arr::AbstractArrayWrapper, arrs::AbstractArrayWrapper...) = AbstractArrayWrapper(cat(dim, arr.a, map(x->x.a, arrs)...))
Base.vcat(arrs::AbstractArrayWrapper...) = cat(1, arrs...)
Base.hcat(arrs::AbstractArrayWrapper...) = cat(2, arrs...)
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, arg::Int) = getindex(arr.a, arg)
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, args::Int...) = getindex(arr.a, args...)
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, indices::CartesianIndex) = getindex(arr.a, indices)
Base.getindex(arr::AbstractArrayWrapper, args...) = begin
  res = getindex(arr.a, args...)
  #if is_scalar_indexing(args)
  #  res
  #else
  AbstractArrayWrapper(res)
  #end
end
getindexvalue(arr::AbstractArrayWrapper, args...) = getindexvalue(arr.a, args...)

Base.map(f::Function, arr::AbstractArrayWrapper) = AbstractArrayWrapper(map(f, arr.a))
Base.map(f::Function, arr::AbstractArrayWrapper, arrs::AbstractArrayWrapper...) = AbstractArrayWrapper(map(f, arr.a, map(x->x.a, arrs)...))
Base.push!(arr::AbstractArrayWrapper, elems...) = push!(arr.a, elems...)

absarray_unary_wrapper(op) = begin
  quote
    $(op[1])(arr::DictArray) = mapvalues(x->$(op[1])(x), arr)
    $(op[1])(arr::LabeledArray) = LabeledArray($(op[1])(peel(arr)), pickaxis(arr))
    $(op[1])(x::AbstractArrayWrapper) = begin
      # AbstractArrayWrapper(map($(op[2]), x.a))
      result = similar(x)
      $(symbol(op[1],naop_suffix))(result.a, x)
      result
    end
    $(symbol(op[1],naop_suffix))(result, x::AbstractArrayWrapper) = begin
      xa = x.a
      for i in eachindex(xa)
        @inbounds result[i] = $(op[2])(xa[i])
      end
    end
    $(symbol(op[1],naop_suffix)){T<:AbstractFloat,N,A}(result, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
      xadata = x.a.data
      resultdata = result.data
      for i in eachindex(xadata)
        @inbounds resultdata[i] = $(op[2])(xadata[i])
      end
    end
  end
end

# Ideally, lift every possible types using some supertypes. However, a lot of annoying ambiguity warnings may occur.
# So, try to fiddle around with possible combinations that do not give any ambiguity warnings.
const LiftToNullableTypes = [Bool,
                             Integer,
                             AbstractFloat,
                             Rational,
                             Irrational{:e},
                             Real,
                             Complex,
                             AbstractString,
                             Char,
                             Symbol]

promote_nullable_optypes{T,U}(op,::Type{Nullable{T}},::Type{Nullable{U}}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{T},::Type{Nullable{U}}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{Nullable{T}},::Type{U}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{T},::Type{U}) = return_types(op,(T,U))[1]

preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{U}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{U}, tpe) = tpe

const naop_suffix = "!"

# some adhoc definitions to suppress ambiguity warnings clashing with irrationals.jl
.^(x::Base.Irrational{:e}, y::AbstractArrayWrapper{Real}) = AbstractArrayWrapper(.^(x, y.a))
.^{T<:Real}(x::Base.Irrational{:e}, y::AbstractArrayWrapper{T}) = AbstractArrayWrapper(.^(x, y.a))

# not used anymore.
absarray_binary_wrapper(op) = begin
  nullelem = if length(op) == 2
    :(promote_nullable_optypes($(op[1]),T,U))
  elseif length(op) == 3
    :(preset_nullable_type(T,U,$(op[3])))
  end
  quote
    $(op[1]){T,U}(x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
      @assert(size(x) == size(y))
      result = similar(x, $nullelem)
      $(symbol(op[1],naop_suffix))(result.a, x, y)
      result
    end
    $(symbol(op[1],naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
      xa = x.a
      ya = y.a
      for i in eachindex(xa,ya)
        @inbounds result[i] = $(op[2])(xa[i],ya[i])
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,A,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xadata = x.a.data
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(xadata,yadata)
        @inbounds resultdata[i] = $(op[2])(xadata[i],yadata[i])
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,A,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xadata = x.a.data
      ya= y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xadata,ya)
        @inbounds yai = ya[i]
        if yai.isnull
          @inbounds resultdata[i] = na
        else
          @inbounds resultdata[i] = $(op[2])(xadata[i],yai.value)
        end
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T<:Nullable,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xa= x.a
      yadata = y.a.data
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,yadata)
        @inbounds xai = xa[i]
        if xai.isnull
          @inbounds resultdata[i] = na
        else
          @inbounds resultdata[i] = $(op[2])(xai.value, yadata[i])
        end
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T<:Nullable,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = v.isnull ? na : v.value
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,A,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xadata = x.a.data
      ya= y.a
      resultdata = result.data
      for i in eachindex(xadata,ya)
        @inbounds resultdata[i] = $(op[2])(xadata[i],ya[i])
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xa= x.a
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(xa,yadata)
        @inbounds resultdata[i] = $(op[2])(xa[i], yadata[i])
      end
    end

    $(symbol(op[1],naop_suffix)){N,K,T<:Nullable,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = v.isnull ? na : v.value
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = v.isnull ? na : v.value
      end
    end
    $(symbol(op[1],naop_suffix)){N,K,T,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      for i in eachindex(xa,ya)
        @inbounds resultdata[i] = $(op[2])(xa[i], ya[i])
      end
    end


    $(op[1]){T,U<:Nullable}(x::AbstractArrayWrapper{T}, y::U) = begin
      result = similar(x, $nullelem)
      $(symbol(op[1],naop_suffix))(result.a, x, y)
      result
    end
    $(symbol(op[1],naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::U) = begin
      xa = x.a
      for i in eachindex(xa)
        @inbounds result[i] = $(op[2])(xa[i],y)
      end
    end
    $(symbol(op[1],naop_suffix)){K,T,U<:Nullable,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y::U) = begin
      if y.isnull
        setna!(result)
      else
        xadata = x.a.data
        yvalue = y.value
        resultdata = result.data
        for i in eachindex(xadata)
          @inbounds resultdata[i] = $(op[2])(xadata[i],yvalue)
        end
      end
    end

    $(op[1]){T<:Nullable,U}(x::T, y::AbstractArrayWrapper{U}) = begin
      #AbstractArrayWrapper(map(v->$(op[2])(x,v), y.a))
      result = similar(y, $nullelem)
      $(symbol(op[1],naop_suffix))(result.a, x, y)
      result
    end
    $(symbol(op[1],naop_suffix)){T,U}(result, x::T, y::AbstractArrayWrapper{U}) = begin
      ya = y.a
      for i in eachindex(ya)
        @inbounds result[i] = $(op[2])(x,ya[i])
      end
    end
    $(symbol(op[1],naop_suffix)){K,T<:Nullable,U,N,A}(result::FloatNAArray{K,N}, x::T, y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,A}}) = begin
      if x.isnull
        setna!(result)
      else
        xvalue = x.value
        yadata = y.a.data
        resultdata = result.data
        for i in eachindex(yadata)
          @inbounds resultdata[i] = $(op[2])(xvalue, yadata[i])
        end
      end
    end

    $(symbol(op[1],"nulltype2", naop_suffix))(result, x::AbstractArrayWrapper, y) = begin
      xa = x.a
      for i in eachindex(xa)
        @inbounds result[i] = $(op[2])(xa[i],y)
      end
    end
    $(symbol(op[1],"nulltype2", naop_suffix)){K,T,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y) = begin
      xadata = x.a.data
      resultdata = result.data
      for i in eachindex(xadata)
        @inbounds resultdata[i] = $(op[2])(xadata[i],y)
      end
    end

    $(symbol(op[1],"nulltype1", naop_suffix))(result, x, y::AbstractArrayWrapper) = begin
      ya = y.a
      for i in eachindex(ya)
        @inbounds result[i] = $(op[2])(x,ya[i])
      end
    end
    $(symbol(op[1],"nulltype1", naop_suffix)){K,N,T,A}(result::FloatNAArray{K,N}, x, y::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(yadata)
        @inbounds resultdata[i] = $(op[2])(x,yadata[i])
      end
    end

    $(op[1])(x::Nullable, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)
    $(op[1])(x::Union{DictArray,LabeledArray}, y::Nullable) = mapvalues($(op[1]), x, y)
    $(op[1])(x::Union{DictArray,LabeledArray}, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)

    # to avoid some type ambiguity.
    $(op[1])(x::Bool, y::LabeledArray{Bool}) = mapvalues($(op[1]), x, y)
    $(op[1])(x::LabeledArray{Bool}, y::Bool) = mapvalues($(op[1]), x, y)

    for nulltype in $LiftToNullableTypes
      $(op[1])(x::AbstractArrayWrapper{nulltype}, y::nulltype) = begin
        T = eltype(x)
        U = typeof(y)
        result = similar(x, $nullelem)
        $(symbol(op[1],"nulltype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1])(x::nulltype, y::AbstractArrayWrapper{nulltype}) = begin
        T = typeof(x)
        U = eltype(y)
        result = similar(y, $nullelem)
        $(symbol(op[1],"nulltype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){T<:nulltype}(x::AbstractArrayWrapper{T}, y::nulltype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(symbol(op[1],"nulltype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){U<:nulltype}(x::nulltype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(symbol(op[1],"nulltype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){T<:Nullable}(x::AbstractArrayWrapper{T}, y::nulltype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(symbol(op[1],"nulltype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){U<:Nullable}(x::nulltype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(symbol(op[1],"nulltype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1])(x::nulltype, y::DictArray) = mapvalues($(op[1]), x, y)
      $(op[1])(x::nulltype, y::LabeledArray) = mapvalues($(op[1]), x, y)
      $(op[1])(x::DictArray, y::nulltype) = mapvalues($(op[1]), x, y)
      $(op[1])(x::LabeledArray, y::nulltype) = mapvalues($(op[1]), x, y)
    end
  end
end

*(x::Real, y::AbstractArrayWrapper) = x .* y
*(x::AbstractArrayWrapper, y::Real) = x .* y
*(x::Complex, y::AbstractArrayWrapper) = x .* y
*(x::AbstractArrayWrapper, y::Complex) = x .* y
*{T<:Real}(x::Nullable{T}, y::AbstractArrayWrapper) = x .* y
*{T<:Real}(x::AbstractArrayWrapper, y::Nullable{T}) = x .* y
*{T<:Complex}(x::Nullable{T}, y::AbstractArrayWrapper) = x .* y
*{T<:Complex}(x::AbstractArrayWrapper, y::Nullable{T}) = x .* y
/(x::Real, y::AbstractArrayWrapper) = x ./ y
/(x::AbstractArrayWrapper, y::Real) = x ./ y
/(x::Complex, y::AbstractArrayWrapper) = x ./ y
/(x::AbstractArrayWrapper, y::Complex) = x ./ y
/{T<:Real}(x::Nullable{T}, y::AbstractArrayWrapper) = x ./ y
/{T<:Real}(x::AbstractArrayWrapper, y::Nullable{T}) = x ./ y
/{T<:Complex}(x::Nullable{T}, y::AbstractArrayWrapper) = x ./ y
/{T<:Complex}(x::AbstractArrayWrapper, y::Nullable{T}) = x ./ y

*(x::Real, y::Union{DictArray,LabeledArray}) = x .* y
*(x::Union{DictArray,LabeledArray}, y::Real) = x .* y
*(x::Complex, y::Union{DictArray,LabeledArray}) = x .* y
*(x::Union{DictArray,LabeledArray}, y::Complex) = x .* y
*{T<:Real}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = x .* y
*{T<:Real}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = x .* y
*{T<:Complex}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = x .* y
*{T<:Complex}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = x .* y
*(x::FloatNAArray, y::FloatNAArray) = FloatNAArray(x.data * y.data)
/(x::FloatNAArray, y::FloatNAArray) = FloatNAArray(x.data / y.data)
# these are not supported yet properly other than for FloatNAArray.
*(x::AbstractArrayWrapper, y::AbstractArrayWrapper) = AbstractArrayWrapper(x.a * y.a)
/(x::AbstractArrayWrapper, y::AbstractArrayWrapper) = AbstractArrayWrapper(x.a / y.a)
*(x::DictArray, y::DictArray) = mapvalues(*, x, y)
/(x::DictArray, y::DictArray) = mapvalues(/, x, y)
*(x::LabeledArray, y::LabeledArray) = begin
  assert(x.axes[end] == y.axes[1])
  LabeledArray(mapvalues(*, x.data, y.data), (x.axes[1:end-1]...,y.axes[2:end]...))
end
/(x::LabeledArray{TypeVar(:T),2}, y::LabeledArray{TypeVar(:T),2}) = begin
  assert(x.axes[end] == y.axes[end])
  LabeledArray(mapvalues(/, x.data, y.data), (x.axes[1], y.axes[1]))
end
/(x::Real, y::Union{DictArray,LabeledArray}) = x ./ y
/(x::Union{DictArray,LabeledArray}, y::Real) = x ./ y
/(x::Complex, y::Union{DictArray,LabeledArray}) = x ./ y
/(x::Union{DictArray,LabeledArray}, y::Complex) = x ./ y
/{T<:Real}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = x ./ y
/{T<:Real}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = x ./ y
/{T<:Complex}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = x ./ y
/{T<:Complex}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = x ./ y

nullable_unary_wrapper(op) = begin
  nullelem = if length(op) == 2
    Expr(:curly, :Nullable, :T)
  elseif length(op) == 3
    Expr(:curly, :Nullable, op[3])
  end
  quote
    $(op[2]){T}(x::Nullable{T}) = x.isnull ? $nullelem() : Nullable($(op[1])(x.value))
    $(op[2]){T}(x::T) = $(op[1])(x)
  end
end

nullable_binary_wrapper(op) = begin
  nullelem = if length(op) == 2
    Expr(:curly, :Nullable, Expr(:ref, Expr(:call, :return_types, op[1], Expr(:tuple, :T, :V)), 1))
    #Expr(:curly, :Nullable, Expr(:call, :promote_type, :T, :V))
  elseif length(op) == 3
    Expr(:curly, :Nullable, op[3])
  end
  quote
    $(op[2]){T,V}(x::Nullable{T}, y::Nullable{V}) =
      x.isnull || y.isnull ? $nullelem() : $nullelem($(op[1])(x.value, y.value))
    $(op[2]){T,V}(x::Nullable{T}, y::V) =
      x.isnull ? $nullelem() : $nullelem($(op[1])(x.value, y))
    $(op[2]){T,V}(x::T, y::Nullable{V}) =
      y.isnull ? $nullelem() : $nullelem($(op[1])(x, y.value))
    $(op[2]){T,V}(x::T, y::V) = $(op[1])(x, y)
  end
end

for op in ((:+, :naop_plus), (:-, :naop_minus), (:~, :naop_not))
  eval(nullable_unary_wrapper(op))
end
for op in ((:.+, :naop_plus), (:.-, :naop_minus), (:.*, :naop_mul),
                         (:./, :naop_div),
                         # could not use .== or .!= over general types such as AbstractString.
                         # let's settle down to using == and != instead for now.
                         # at least, we don't have to provide a blanket definition (:.==)(x,y) = x==y then.
                         (:.\, :naop_invdiv), (:.//, :naop_frac), (:(==), :naop_eq, Bool), (:.<, :naop_lt, Bool),
                         (:!=, :naop_noeq, Bool), (:.<=, :naop_le, Bool), (:.%, :naop_mod), (:.<<, :naop_lsft),
                         (:.>>, :naop_rsft), (:.^, :naop_exp),
                         (:&, :naop_and), (:|, :naop_or), (:$, :naop_xor))
  eval(nullable_binary_wrapper(op))
end

for op in ((:+, :naop_plus), (:-, :naop_minus), (:.+, :naop_plus), (:.-, :naop_minus), (:~, :naop_not))
  eval(absarray_unary_wrapper(op))
end
for op in ((:+, :naop_plus), (:-, :naop_minus), (:.+, :naop_plus), (:.-, :naop_minus), (:.*, :naop_mul),
                         (:./, :naop_div),
                         (:.\, :naop_invdiv), (:.//, :naop_frac), (:.==, :naop_eq, Bool), (:.<, :naop_lt, Bool),
                         (:.!=, :naop_noeq, Bool), (:.<=, :naop_le, Bool), (:.%, :naop_mod), (:.<<, :naop_lsft),
                         (:.>>, :naop_rsft), (:.^, :naop_exp),
                         (:&, :naop_and), (:|, :naop_or), (:$, :naop_xor))
  eval(absarray_binary_wrapper(op))
end

(==){T<:Nullable,U<:Nullable}(x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
  if x === y
    return true
  else
    for (elx, ely) in zip(x.a, y.a)
      if elx.isnull && !ely.isnull
        return false
      elseif !elx.isnull && ely.isnull
        return false
      elseif !elx.isnull && !ely.isnull && elx.value != ely.value
        return false
      end
    end
    return true
  end
end

(==){T<:AbstractFloat,U<:AbstractFloat,N,A,B}(x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
  if x === y
    return true
  else
    for (elx, ely) in zip(x.a.data, y.a.data)
      if !(isnan(elx) && isnan(ely)) && elx != ely
        return false
      end
    end
    return true
  end
end


# TODO make sure this blanket definition is okay.
# remvoed in favor of using == instead of .== for naop_eq (and similarly for naop_noeq).
# (.==)(x, y) = x == y
