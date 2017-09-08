# it seems that currently, map operation over Nullable array is not optimzed in julia 0.4.1.

import Base: .+, .-, .*, *, ./, /, .\, .//, .==, .<, .!=, .<=, .%, .<<, .>>, .^, +, -, ~, &, |, $, ==, !=, .>=, .>
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
Base.IndexStyle{T,N,A}(::Type{AbstractArrayWrapper{T,N,A}}) = IndexStyle(A)
Base.view(arr::AbstractArrayWrapper, args::Union{Colon,Int,AbstractVector}...) = AbstractArrayWrapper(view(arr.a, args...))
Base.view(arr::AbstractArrayWrapper, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}})= AbstractArrayWrapper(view(arr.a, args))
Base.repmat{T}(arr::AbstractArrayWrapper{T,1}, n::Int) = AbstractArrayWrapper(repmat(arr.a, n))
Base.repmat{T}(arr::AbstractArrayWrapper{T,2}, n::Int) = AbstractArrayWrapper(repmat(arr.a, n))
Base.repmat{T}(arr::AbstractArrayWrapper{T,1}, m::Int, n::Int) = AbstractArrayWrapper(repmat(arr.a, m, n))
Base.repmat{T}(arr::AbstractArrayWrapper{T,2}, m::Int, n::Int) = AbstractArrayWrapper(repmat(arr.a, m, n))
@delegate(AbstractArrayWrapper.a, Base.start, Base.next, Base.done, Base.size,
                           Base.ndims, Base.length, Base.setindex!, Base.find, Base.fill!)
@delegate_and_lift(AbstractArrayWrapper.a, Base.transpose, Base.permutedims,
                                   Base.sort, Base.sort!, Base.sortperm, Base.reverse, Base.view)
Base.sort(arr::AbstractArrayWrapper, args::Integer) = AbstractArrayWrapper(sort(arr.a, args))
Base.sort!(arr::AbstractArrayWrapper, args::Integer) = AbstractArrayWrapper(sort!(arr.a, args))
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

# necessary to avoid some 'no-op transpose fallback' warning.
Base.transpose(x::Nullable) = x

Base.map(f::Function, arr::AbstractArrayWrapper) = AbstractArrayWrapper(map(f, arr.a))
Base.map(f::Function, arr::AbstractArrayWrapper, arrs::AbstractArrayWrapper...) = AbstractArrayWrapper(map(f, arr.a, map(x->x.a, arrs)...))
Base.push!(arr::AbstractArrayWrapper, elems...) = push!(arr.a, elems...)

absarray_unary_wrapper(op) = begin
  if startswith(string(op[1]), ".")
    typeofop1 = :(typeof($(Symbol(string(op[1])[2:end]))))
    quote
      Base.broadcast(::$typeofop1, arr::DictArray) = mapvalues(x->$(op[1])(x), arr)
      Base.broadcast(::$typeofop1, arr::LabeledArray) = LabeledArray($(op[1])(peel(arr)), pickaxis(arr))
      Base.broadcast(::$typeofop1, x::AbstractArrayWrapper) = begin
        result = similar(x)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x)
        result
      end
      $(Symbol(mangle_dot(op[1]),naop_suffix))(result, x::AbstractArrayWrapper) = begin
        xa = x.a
        for i in eachindex(xa)
          @inbounds result[i] = $(op[2])(xa[i])
        end
      end
      $(Symbol(mangle_dot(op[1]),naop_suffix)){T<:AbstractFloat,N,A}(result, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
        xadata = x.a.data
        resultdata = result.data
        for i in eachindex(xadata)
          @inbounds resultdata[i] = $(op[2])(xadata[i])
        end
      end
    end
  else
    quote
      $(op[1])(arr::DictArray) = mapvalues(x->$(op[1])(x), arr)
      $(op[1])(arr::LabeledArray) = LabeledArray($(op[1])(peel(arr)), pickaxis(arr))
      $(op[1])(x::AbstractArrayWrapper) = begin
        # AbstractArrayWrapper(map($(op[2]), x.a))
        result = similar(x)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x)
        result
      end
      $(Symbol(mangle_dot(op[1]),naop_suffix))(result, x::AbstractArrayWrapper) = begin
        xa = x.a
        for i in eachindex(xa)
          @inbounds result[i] = $(op[2])(xa[i])
        end
      end
      $(Symbol(mangle_dot(op[1]),naop_suffix)){T<:AbstractFloat,N,A}(result, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
        xadata = x.a.data
        resultdata = result.data
        for i in eachindex(xadata)
          @inbounds resultdata[i] = $(op[2])(xadata[i])
        end
      end
    end
  end
end

# Ideally, lift every possible types using some supertypes. However, a lot of annoying ambiguity warnings may occur.
# So, try to fiddle around with possible combinations that do not give any ambiguity warnings.
const LiftToNullableTypes = [:Bool,
                             :Integer,
                             :AbstractFloat,
                             :Rational,
                             :(Irrational{:e}),
                             :Real,
                             :Complex,
                             :AbstractString,
                             :Char,
                             :Symbol]

promote_nullable_optypes{T,U}(op,::Type{Nullable{T}},::Type{Nullable{U}}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{T},::Type{Nullable{U}}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{Nullable{T}},::Type{U}) = Nullable{return_types(op,(T,U))[1]}
promote_nullable_optypes{T,U}(op,::Type{T},::Type{U}) = return_types(op,(T,U))[1]

preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{U}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{U}, tpe) = tpe

const naop_suffix = "!"

mangle_dot(op) = begin
  op = string(op)
  if length(op) > 1 && op[1] == '.'
    Symbol("dot", op[2:end])
  else
    Symbol(op)
  end
end

# some adhoc definitions to suppress ambiguity warnings clashing with irrationals.jl
Base.broadcast(::typeof(^), x::Base.Irrational{:e}, y::AbstractArrayWrapper{Real}) = AbstractArrayWrapper(.^(x, y.a))
Base.broadcast{T<:Real}(::typeof(^), x::Base.Irrational{:e}, y::AbstractArrayWrapper{T}) = AbstractArrayWrapper(.^(x, y.a))

absarray_binary_wrapper(op) = begin
  nullelem = if length(op) == 2
    :(promote_nullable_optypes($(op[1]),T,U))
  elseif length(op) == 3
    :(preset_nullable_type(T,U,$(op[3])))
  end
  preexprs = quote
    $(Symbol(mangle_dot(op[1]),naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
      xa = x.a
      ya = y.a
      for i in eachindex(xa,ya)
        @inbounds result[i] = $(op[2])(xa[i],ya[i])
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,A,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xadata = x.a.data
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(xadata,yadata)
        @inbounds resultdata[i] = $(op[2])(xadata[i],yadata[i])
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,A,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xadata = x.a.data
      ya= y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xadata,ya)
        @inbounds yai = ya[i]
        if isnull(yai)
          @inbounds resultdata[i] = na
        else
          @inbounds resultdata[i] = $(op[2])(xadata[i],yai.value)
        end
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T<:Nullable,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xa= x.a
      yadata = y.a.data
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,yadata)
        @inbounds xai = xa[i]
        if isnull(xai)
          @inbounds resultdata[i] = na
        else
          @inbounds resultdata[i] = $(op[2])(xai.value, yadata[i])
        end
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T<:Nullable,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = isnull(v) ? na : v.value
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,A,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xadata = x.a.data
      ya= y.a
      resultdata = result.data
      for i in eachindex(xadata,ya)
        @inbounds resultdata[i] = $(op[2])(xadata[i],ya[i])
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,U,B}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
      xa= x.a
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(xa,yadata)
        @inbounds resultdata[i] = $(op[2])(xa[i], yadata[i])
      end
    end

    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T<:Nullable,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = isnull(v) ? na : v.value
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,U<:Nullable}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      na = convert(K,NaN)
      for i in eachindex(xa,ya)
        @inbounds v = $(op[2])(xa[i], ya[i])
        @inbounds resultdata[i] = isnull(v) ? na : v.value
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){N,K,T,U}(result::FloatNAArray{K,N},
                                                   x::AbstractArrayWrapper{T,N},
                                                   y::AbstractArrayWrapper{U,N}) = begin
      xa= x.a
      ya = y.a
      resultdata = result.data
      for i in eachindex(xa,ya)
        @inbounds resultdata[i] = $(op[2])(xa[i], ya[i])
      end
    end

    $(Symbol(mangle_dot(op[1]),naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::U) = begin
      xa = x.a
      for i in eachindex(xa)
        @inbounds result[i] = $(op[2])(xa[i],y)
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){K,T,U<:Nullable,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y::U) = begin
      if isnull(y)
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

    $(Symbol(mangle_dot(op[1]),naop_suffix)){T,U}(result, x::T, y::AbstractArrayWrapper{U}) = begin
      ya = y.a
      for i in eachindex(ya)
        @inbounds result[i] = $(op[2])(x,ya[i])
      end
    end
    $(Symbol(mangle_dot(op[1]),naop_suffix)){K,T<:Nullable,U,N,A}(result::FloatNAArray{K,N}, x::T, y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,A}}) = begin
      if isnull(x)
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

    $(Symbol(mangle_dot(op[1]),"adhoctype2", naop_suffix))(result, x::AbstractArrayWrapper, y) = begin
      xa = x.a
      for i in eachindex(xa)
        @inbounds result[i] = $(op[2])(xa[i],y)
      end
    end
    $(Symbol(mangle_dot(op[1]),"adhoctype2", naop_suffix)){K,T,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y) = begin
      xadata = x.a.data
      resultdata = result.data
      for i in eachindex(xadata)
        @inbounds resultdata[i] = $(op[2])(xadata[i],y)
      end
    end

    $(Symbol(mangle_dot(op[1]),"adhoctype1", naop_suffix))(result, x, y::AbstractArrayWrapper) = begin
      ya = y.a
      for i in eachindex(ya)
        @inbounds result[i] = $(op[2])(x,ya[i])
      end
    end
    $(Symbol(mangle_dot(op[1]),"adhoctype1", naop_suffix)){K,N,T,A}(result::FloatNAArray{K,N}, x, y::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
      yadata = y.a.data
      resultdata = result.data
      for i in eachindex(yadata)
        @inbounds resultdata[i] = $(op[2])(x,yadata[i])
      end
    end
  end

  mainexprs = if startswith(string(op[1]), ".")
    typeofop1 = :(typeof($(Symbol(string(op[1])[2:end]))))
    quote
      Base.broadcast{T,U}(::$typeofop1, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
        @assert(size(x) == size(y))
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast{T,U<:Nullable}(::$typeofop1, x::AbstractArrayWrapper{T}, y::U) = begin
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end
      Base.broadcast{T<:Nullable,U}(::$typeofop1, x::T, y::AbstractArrayWrapper{U}) = begin
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end
      Base.broadcast(::$typeofop1, x::Nullable, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::Union{DictArray,LabeledArray}, y::Nullable) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::Union{DictArray,LabeledArray}, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)

      # to avoid some type ambiguity.
      Base.broadcast(::$typeofop1, x::Bool, y::LabeledArray{Bool}) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::LabeledArray{Bool}, y::Bool) = mapvalues($(op[1]), x, y)
    end
  else
    quote
      $(op[1]){T,U}(x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
        @assert(size(x) == size(y))
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end
      $(op[1]){T,U<:Nullable}(x::AbstractArrayWrapper{T}, y::U) = begin
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end
      $(op[1]){T<:Nullable,U}(x::T, y::AbstractArrayWrapper{U}) = begin
        #AbstractArrayWrapper(map(v->$(op[2])(x,v), y.a))
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),naop_suffix))(result.a, x, y)
        result
      end
      $(op[1])(x::Nullable, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)
      $(op[1])(x::Union{DictArray,LabeledArray}, y::Nullable) = mapvalues($(op[1]), x, y)
      $(op[1])(x::Union{DictArray,LabeledArray}, y::Union{DictArray,LabeledArray}) = mapvalues($(op[1]), x, y)

      # to avoid some type ambiguity.
      $(op[1])(x::Bool, y::LabeledArray{Bool}) = mapvalues($(op[1]), x, y)
      $(op[1])(x::LabeledArray{Bool}, y::Bool) = mapvalues($(op[1]), x, y)
    end
  end

  Expr(:block, preexprs, mainexprs)
end

#macro create_op(op, args...)
#  if startswith(string(op), ".")
#    Expr(:call, :(Base.broadcast), :(::typeof($(Symbol(string(op)[2:end])))), args...)
#  else
#    Expr(:($(op)), args...)
#  end
#end

absarray_binary_wrapper_adhoc(op, adhoctype) = begin
  nullelem = if length(op) == 2
    :(promote_nullable_optypes($(op[1]),T,U))
  elseif length(op) == 3
    :(preset_nullable_type(T,U,$(op[3])))
  end

  if startswith(string(op[1]), ".")
    typeofop1 = :(typeof($(Symbol(string(op[1])[2:end]))))
    quote
      Base.broadcast(::$typeofop1, x::AbstractArrayWrapper{$adhoctype}, y::$adhoctype) = begin
        T = eltype(x)
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast(::$typeofop1, x::$adhoctype, y::AbstractArrayWrapper{$adhoctype}) = begin
        T = typeof(x)
        U = eltype(y)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast{T<:$adhoctype}(::$typeofop1, x::AbstractArrayWrapper{T}, y::$adhoctype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast{U<:$adhoctype}(::$typeofop1, x::$adhoctype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast{T<:Nullable}(::$typeofop1, x::AbstractArrayWrapper{T}, y::$adhoctype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast{U<:Nullable}(::$typeofop1, x::$adhoctype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      Base.broadcast(::$typeofop1, x::$adhoctype, y::DictArray) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::$adhoctype, y::LabeledArray) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::DictArray, y::$adhoctype) = mapvalues($(op[1]), x, y)
      Base.broadcast(::$typeofop1, x::LabeledArray, y::$adhoctype) = mapvalues($(op[1]), x, y)
    end
  else
    quote
      $(op[1])(x::AbstractArrayWrapper{$adhoctype}, y::$adhoctype) = begin
        T = eltype(x)
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1])(x::$adhoctype, y::AbstractArrayWrapper{$adhoctype}) = begin
        T = typeof(x)
        U = eltype(y)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){T<:$adhoctype}(x::AbstractArrayWrapper{T}, y::$adhoctype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){U<:$adhoctype}(x::$adhoctype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){T<:Nullable}(x::AbstractArrayWrapper{T}, y::$adhoctype) = begin
        U = typeof(y)
        result = similar(x, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype2",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1]){U<:Nullable}(x::$adhoctype, y::AbstractArrayWrapper{U}) = begin
        T = typeof(x)
        result = similar(y, $nullelem)
        $(Symbol(mangle_dot(op[1]),"adhoctype1",naop_suffix))(result.a, x, y)
        result
      end

      $(op[1])(x::$adhoctype, y::DictArray) = mapvalues($(op[1]), x, y)
      $(op[1])(x::$adhoctype, y::LabeledArray) = mapvalues($(op[1]), x, y)
      $(op[1])(x::DictArray, y::$adhoctype) = mapvalues($(op[1]), x, y)
      $(op[1])(x::LabeledArray, y::$adhoctype) = mapvalues($(op[1]), x, y)
    end
  end
end

*(x::Real, y::AbstractArrayWrapper) = broadcast(*, x, y)
*(x::AbstractArrayWrapper, y::Real) = broadcast(*, x, y)
*(x::Complex, y::AbstractArrayWrapper) = broadcast(*, x, y)
*(x::AbstractArrayWrapper, y::Complex) = broadcast(*, x, y)
*{T<:Real}(x::Nullable{T}, y::AbstractArrayWrapper) = broadcast(*, x, y)
*{T<:Real}(x::AbstractArrayWrapper, y::Nullable{T}) = broadcast(*, x, y)
*{T<:Complex}(x::Nullable{T}, y::AbstractArrayWrapper) = broadcast(*, x, y)
*{T<:Complex}(x::AbstractArrayWrapper, y::Nullable{T}) = broadcast(*, x, y)
/(x::Real, y::AbstractArrayWrapper) = broadcast(/, x, y)
/(x::AbstractArrayWrapper, y::Real) = broadcast(/, x, y)
/(x::Complex, y::AbstractArrayWrapper) = broadcast(/, x, y)
/(x::AbstractArrayWrapper, y::Complex) = broadcast(/, x, y)
/{T<:Real}(x::Nullable{T}, y::AbstractArrayWrapper) = broadcast(/, x, y)
/{T<:Real}(x::AbstractArrayWrapper, y::Nullable{T}) = broadcast(/, x, y)
/{T<:Complex}(x::Nullable{T}, y::AbstractArrayWrapper) = broadcast(/, x, y)
/{T<:Complex}(x::AbstractArrayWrapper, y::Nullable{T}) = broadcast(/, x, y)

*(x::Real, y::Union{DictArray,LabeledArray}) = broadcast(*, x, y)
*(x::Union{DictArray,LabeledArray}, y::Real) = broadcast(*, x, y)
*(x::Complex, y::Union{DictArray,LabeledArray}) = broadcast(*, x, y)
*(x::Union{DictArray,LabeledArray}, y::Complex) = broadcast(*, x, y)
*{T<:Real}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = broadcast(*, x, y)
*{T<:Real}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = broadcast(*, x, y)
*{T<:Complex}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = broadcast(*, x, y)
*{T<:Complex}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = broadcast(*, x, y)
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
/{T,U}(x::LabeledArray{T,2}, y::LabeledArray{U,2}) = begin
  assert(x.axes[end] == y.axes[end])
  LabeledArray(mapvalues(/, x.data, y.data), (x.axes[1], y.axes[1]))
end
/(x::Real, y::Union{DictArray,LabeledArray}) = broadcast(/, x, y)
/(x::Union{DictArray,LabeledArray}, y::Real) = broadcast(/, x, y)
/(x::Complex, y::Union{DictArray,LabeledArray}) = broadcast(/, x, y)
/(x::Union{DictArray,LabeledArray}, y::Complex) = broadcast(/, x, y)
/{T<:Real}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = broadcast(/, x, y)
/{T<:Real}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = broadcast(/, x, y)
/{T<:Complex}(x::Nullable{T}, y::Union{DictArray,LabeledArray}) = broadcast(/, x, y)
/{T<:Complex}(x::Union{DictArray,LabeledArray}, y::Nullable{T}) = broadcast(/, x, y)

nullable_unary_wrapper(op) = begin
  nullelem = if length(op) == 2
    Expr(:curly, :Nullable, :T)
  elseif length(op) == 3
    Expr(:curly, :Nullable, op[3])
  end
  quote
    $(op[2]){T}(x::Nullable{T}) = isnull(x) ? $nullelem() : Nullable($(op[1])(x.value))
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
      isnull(x) || isnull(y) ? $nullelem() : $nullelem($(op[1])(x.value, y.value))
    $(op[2]){T,V}(x::Nullable{T}, y::V) =
      isnull(x) ? $nullelem() : $nullelem($(op[1])(x.value, y))
    $(op[2]){T,V}(x::T, y::Nullable{V}) =
      isnull(y) ? $nullelem() : $nullelem($(op[1])(x, y.value))
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
                         (:.>>, :naop_rsft), (:.^, :naop_exp), (:.>, :naop_gt, Bool), (:.>=, :naop_ge, Bool),
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
                         (:.>>, :naop_rsft), (:.^, :naop_exp), (:.>, :naop_gt, Bool), (:.>=, :naop_ge, Bool),
                         (:&, :naop_and), (:|, :naop_or), (:$, :naop_xor))
  eval(absarray_binary_wrapper(op))
  for adhoctype in LiftToNullableTypes
    eval(absarray_binary_wrapper_adhoc(op, adhoctype))
  end
end

(==){T<:Nullable,U<:Nullable}(x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
  if x === y
    return true
  else
    for (elx, ely) in zip(x.a, y.a)
      if isnull(elx) && !isnull(ely)
        return false
      elseif !isnull(elx) && isnull(ely)
        return false
      elseif !isnull(elx) && !isnull(ely) && elx.value != ely.value
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

#ifelse_inner{T,U,M,N,P,X,Y,Z}(cond::Union{Bool,Nullable{Bool},
#                              AbstractArrayWrapper{Bool,M,X},
#                              AbstractArrayWrapper{Nullable{Bool},M,X}},
#                 x::Union{T,Nullable{T},
#                          AbstractArrayWrapper{T,N,Y},
#                          AbstractArrayWrapper{Nullable{T},N,Y}},
#                 y::Union{U,Nullable{U},
#                          AbstractArrayWrapper{U,P,Z},
#                          AbstractArrayWrapper{Nullable{U},P,Z}}) = begin
#  promoted_type = promote_type(T,U)
#  result = ifelse_inner_similar(cond, x, y, promoted_type)
#  for i in ifelse_inner_eachindex(cond, x, y, result)
#    condi = ifelse_inner_getindex(cond, i)
#    xi = ifelse_inner_getindex(x, i)
#    yi = ifelse_inner_getindex(y, i)
#    result[i] = condi.isnull ? yi : condi.value ? xi : yi
#  end
#  result
#end
ifelse_inner{T}(::Type{T}, cond::AbstractArray, x, y) = begin
  result = ifelse_inner_similar(cond, x, y, Nullable{T})
  nullelem = Nullable{T}()
  for i in ifelse_inner_eachindex(cond, x, y, result)
    condi = ifelse_inner_getindex(cond, i)
    xi = ifelse_inner_getindex(x, i)
    yi = ifelse_inner_getindex(y, i)
    result[i] = isnull(condi) ? nullelem : condi.value ? ifelse_inner_wrap_nullable(xi) : ifelse_inner_wrap_nullable(yi)
  end
  result
end
ifelse_inner{T}(::Type{T}, cond::Bool, x::AbstractArray, y::AbstractArray) = cond ? nalift(x) : nalift(y)
ifelse_inner{T}(::Type{T}, cond::Nullable{Bool}, x::AbstractArray, y::AbstractArray) = isnull(cond) ? ifelse_inner_broadcast_null(T,x) : cond.value ? nalift(x) : nalift(y)
ifelse_inner{T}(::Type{T}, cond::Bool, x::AbstractArray, y) = cond ? nalift(x) : ifelse_inner_broadcast(x,y)
ifelse_inner{T}(::Type{T}, cond::Nullable{Bool}, x::AbstractArray, y) = isnull(cond) ? ifelse_inner_broadcast_null(T,x) : cond.value ? nalift(x) : ifelse_inner_broadcast(x,y)
ifelse_inner{T}(::Type{T}, cond::Bool, x, y::AbstractArray) = cond ? ifelse_inner_broadcast(y,x) : nalift(y)
ifelse_inner{T}(::Type{T}, cond::Nullable{Bool}, x, y::AbstractArray) = isnull(cond) ? ifelse_inner_broadcast_null(T,y) : cond.value ? ifelse_inner_broadcast(y,x) : nalift(y)

ifelse_inner_broadcast{U<:Nullable}(template::AbstractArray, v::U) = (r=similar(template,U);fill!(r,v);r)
ifelse_inner_broadcast{U}(template::AbstractArray, v::U) = (r=similar(template,Nullable{U});nv=Nullable(v);fill!(r,nv);r)

ifelse_inner_broadcast_null{T}(::Type{T}, template::AbstractArray) = (r=similar(template,Nullable{T});n=Nullable{T}();fill!(r,n);r)

ifelse_inner_wrap_nullable(x::Nullable) = x
ifelse_inner_wrap_nullable(x) = Nullable(x)

# it's difficult to avoid all type ambiguity warnings without listing all these methods...
Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)


Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{Nullable{T}}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{Nullable{T}}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{T}, y::AbstractArray{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::AbstractArrayWrapper{Nullable{T}}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArray{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArrayWrapper{Nullable{T}}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::AbstractArrayWrapper{Nullable{T}}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::Nullable{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::Nullable{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::Nullable{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::Nullable{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::T, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::T, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Bool, x::Nullable{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::Nullable{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArray{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::T, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::T, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::Nullable{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::Nullable{T}, y::AbstractArrayWrapper{U}) = ifelse_inner(promote_type(T,U), cond, x, y)

Base.ifelse{T,U}(cond::Bool, x::T, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::Nullable{Bool}, x::T, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArray{T}, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::T, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::T, y::AbstractArrayWrapper{Nullable{U}}) = ifelse_inner(promote_type(T,U), cond, x, y)


Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::Nullable{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArray{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::T, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::Nullable{T}, y::AbstractArray{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::Nullable{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArray{T}, y::AbstractArray{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::AbstractArray{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::T, y::AbstractArray{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Bool}, x::T, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::Nullable{T}, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::T, y::Nullable{U}) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::Nullable{T}, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)
Base.ifelse{T,U}(cond::AbstractArrayWrapper{Nullable{Bool}}, x::T, y::U) = ifelse_inner(promote_type(T,U), cond, x, y)

ifelse_inner_similar(cond::AbstractArray, x::AbstractArray, y::AbstractArray, promoted_type) = similar(cond, promoted_type)
ifelse_inner_similar(cond::AbstractArray, x::AbstractArray, y, promoted_type) = similar(cond, promoted_type)
ifelse_inner_similar(cond::AbstractArray, x, y::AbstractArray, promoted_type) = similar(cond, promoted_type)
ifelse_inner_similar(cond::AbstractArray, x, y, promoted_type) = similar(cond, promoted_type)

ifelse_inner_eachindex(cond::AbstractArray, x::AbstractArray, y::AbstractArray, promoted_type) = eachindex(cond, x, y, promoted_type)
ifelse_inner_eachindex(cond::AbstractArray, x::AbstractArray, y, promoted_type) = eachindex(cond, x, promoted_type)
ifelse_inner_eachindex(cond::AbstractArray, x, y::AbstractArray, promoted_type) = eachindex(cond, y, promoted_type)
ifelse_inner_eachindex(cond::AbstractArray, x, y, promoted_type) = eachindex(cond, promoted_type)

ifelse_inner_getindex{T<:Nullable}(x::AbstractArray{T}, i) = x[i]
ifelse_inner_getindex(x::AbstractArray, i) = Nullable(x[i])
ifelse_inner_getindex(x, i) = x

# TODO make sure this blanket definition is okay.
# remvoed in favor of using == instead of .== for naop_eq (and similarly for naop_noeq).
# (.==)(x, y) = x == y
