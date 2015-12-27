import Base: .+, .-, .*, ./, .\, .//, .==, .<, .!=, .<=, .%, .<<, .>>, .^, +, -, ~, &, |, $, ==, !=
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
Base.sub(arr::AbstractArrayWrapper, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}})= AbstractArrayWrapper(sub(arr.a, args...))
Base.slice(arr::AbstractArrayWrapper, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}}) = AbstractArrayWrapper(slice(arr.a, args...))
@delegate(AbstractArrayWrapper.a, Base.start, Base.next, Base.done, Base.size,
                           Base.ndims, Base.length, Base.setindex!, Base.find)
@delegate_and_lift(AbstractArrayWrapper.a, Base.transpose, Base.permutedims, Base.repeat,
                                   Base.repeat, Base.transpose, Base.permutedims,
                                   Base.sort, Base.sort!, Base.sortperm, Base.similar, Base.reverse,
                                   Base.sub, Base.slice)
Base.repeat(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(repeat(arr.a; kwargs...))
Base.sort(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(sort(arr.a; kwargs...))
Base.sort!(arr::AbstractArrayWrapper; kwargs...) = AbstractArrayWrapper(sort!(arr.a; kwargs...))
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, arg::Int) = getindex(arr.a, arg)
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, args::Int...) = getindex(arr.a, args...)
Base.getindex{T,N}(arr::AbstractArrayWrapper{T,N}, indices::CartesianIndex) = getindex(arr.a, indices.I...)
Base.getindex(arr::AbstractArrayWrapper, args...) = begin
  res = getindex(arr.a, args...)
  if is_scalar_indexing(args)
    res
  else
    AbstractArrayWrapper(res)
  end
end
Base.map(f, arr::AbstractArrayWrapper) = AbstractArrayWrapper(map(f, arr.a))
Base.map(f, arr::AbstractArrayWrapper...) = AbstractArrayWrapper(map(f, map(x->x.a, arr)...))

macro absarray_unary_wrapper(ops...)
  targetexpr = map(ops) do op
    quote
      $(esc(op.args[1]))(x::AbstractArrayWrapper) = AbstractArrayWrapper(map($(esc(op.args[2])), x.a))
    end
  end
  Expr(:block, targetexpr...)
end

# Ideally, lift every possible types using some supertypes. However, a lot of annoying ambiguity warnings may occur.
# So, try to fiddle around with possible combinations that do not give any ambiguity warnings.
const LiftToNullableTypes = [Bool,
                             Integer,
                             AbstractFloat,
                             Rational,
                             Complex,
                             AbstractString,
                             Char,
                             Symbol]

macro absarray_binary_wrapper(ops...)
  targetexpr = map(ops) do op
    quote
      $(esc(op.args[1])){T<:Nullable,U<:Nullable}(x::AbstractArrayWrapper{T},
                                                  y::AbstractArrayWrapper{U}) =
        AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))

      $(esc(op.args[1])){T<:Nullable}(x::AbstractArrayWrapper{T}, y::Nullable) =
        AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
      $(esc(op.args[1])){T<:Nullable}(x::Nullable, y::AbstractArrayWrapper{T}) =
        AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))

      for nulltype in $LiftToNullableTypes
        $(esc(op.args[1])){T<:Nullable,U<:nulltype}(x::AbstractArrayWrapper{T}, y::U) = begin
          AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
          #returntype = Base.return_types($(esc(op.args[2])), (T, U))[1]
          #xa = x.a
          #result = similar(xa, returntype)
          #absarray_binnary_wrapper_inner1!(result, $(esc(op.args[2])), xa, y)
          #AbstractArrayWrapper(result)
        end
        $(esc(op.args[1])){T<:Nullable}(x::nulltype, y::AbstractArrayWrapper{T}) = begin
          # version 1. what is correct, but could be slower. I am experimenting.
          AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
        end
        #$(esc(op.args[1])){T<:Nullable,U<:nulltype}(x::U, y::AbstractArrayWrapper{T}) = begin
        #  # version 2. correct as well, but could be faster. Let's experiment.
        #  returntype = Base.return_types($(esc(op.args[2])), (U, T))[1]
        #  ya = y.a
        #  result = similar(ya, returntype)
        #  absarray_binnary_wrapper_inner2!(result, $(esc(op.args[2])), x, ya)
        #  AbstractArrayWrapper(result)
        #end
      end
    end
  end
  Expr(:block, targetexpr...)
end

absarray_binnary_wrapper_inner1!{T<:Nullable,U<:Nullable,V,N}(result::AbstractArray{T,N}, f::Function, xa::AbstractArray{U,N}, y::V) = begin
  for i in eachindex(xa)
    @inbounds result[i] = f(xa[i], y)::T
  end
end

absarray_binnary_wrapper_inner2!{T<:Nullable,U,V<:Nullable,N}(result::AbstractArray{T,N}, f::Function, x::U, ya::AbstractArray{V,N}) = begin
  for i in eachindex(ya)
    @inbounds result[i] = f(x, ya[i])::T
  end
end

macro nullable_unary_wrapper(ops...)
  targetexpr = map(ops) do op
    nullelem = if length(op.args) == 2
      Expr(:curly, :Nullable, :T)
    elseif length(op.args) == 3
      Expr(:curly, :Nullable, op.args[3])
    end
    quote
      $(esc(op.args[2])){T}(x::Nullable{T}) = x.isnull ? $nullelem() : Nullable($(esc(op.args[1]))(x.value))
      $(esc(op.args[2])){T}(x::T) = $(esc(op.args[1]))(x)
    end
  end
  Expr(:block, targetexpr...)
end

macro nullable_binary_wrapper(ops...)
  targetexpr = map(ops) do op
    nullelem = if length(op.args) == 2
      Expr(:curly, :Nullable, Expr(:call, :promote_type, :T, :V))
    elseif length(op.args) == 3
      Expr(:curly, :Nullable, op.args[3])
    end
    quote
      $(esc(op.args[2])){T,V}(x::Nullable{T}, y::Nullable{V}) =
        x.isnull || y.isnull ? $nullelem() : Nullable($(esc(op.args[1]))(x.value, y.value))
      $(esc(op.args[2])){T,V}(x::Nullable{T}, y::V) =
        x.isnull ? $nullelem() : Nullable($(esc(op.args[1]))(x.value, y))
      $(esc(op.args[2])){T,V}(x::T, y::Nullable{V}) =
        y.isnull ? $nullelem() : Nullable($(esc(op.args[1]))(x, y.value))
      $(esc(op.args[2])){T,V}(x::T, y::V) = $(esc(op.args[1]))(x, y)

      #$(esc(op.args[2])){T,V}(x::Nullable{T}, y::Nullable{V}, nullelem::Nullable) =
      #  x.isnull || y.isnull ? nullelem : Nullable($(esc(op.args[1]))(x.value, y.value))
      #$(esc(op.args[2])){T,V}(x::Nullable{T}, y::V, nullelem::Nullable) =
      #  x.isnull ? nullelem : Nullable($(esc(op.args[1]))(x.value, y))
      #$(esc(op.args[2])){T,V}(x::T, y::Nullable{V}, nullelem::Nullable) =
      #  y.isnull ? nullelem : Nullable($(esc(op.args[1]))(x, y.value))
    end
  end
  Expr(:block, targetexpr...)
end

@nullable_unary_wrapper((.+, naop_plus), (.-, naop_minus), (~, naop_not))
@nullable_binary_wrapper((.+, naop_plus), (.-, naop_minus), (.*, naop_mul),
                         (./, naop_div),
                         # could not use .== or .!= over general types such as AbstractString.
                         # let's settle down to using == and != instead for now.
                         # at least, we don't have to provide a blanket definition (.==)(x,y) = x==y then.
                         (.\, naop_invdiv), (.//, naop_frac), (==, naop_eq, Bool), (.<, naop_lt, Bool),
                         (!=, naop_noeq, Bool), (.<=, naop_le, Bool), (.%, naop_mod), (.<<, naop_lsft),
                         (.>>, naop_rsft), (.^, naop_exp),
                         (&, naop_and), (|, naop_or), ($, naop_xor))

@absarray_unary_wrapper((+, naop_plus), (-, naop_minus), (.+, naop_plus), (.-, naop_minus), (~, naop_not))
@absarray_binary_wrapper((+, naop_plus), (-, naop_minus), (.+, naop_plus), (.-, naop_minus), (.*, naop_mul),
                         (./, naop_div),
                         (.\, naop_invdiv), (.//, naop_frac), (.==, naop_eq, Bool), (.<, naop_lt, Bool),
                         (.!=, naop_noeq, Bool), (.<=, naop_le, Bool), (.%, naop_mod), (.<<, naop_lsft),
                         (.>>, naop_rsft), (.^, naop_exp),
                         (&, naop_and), (|, naop_or), ($, naop_xor))

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

(==){T<:AbstractFloat,U<:AbstractFloat,N,A,B}(x::AbstractArrayWrapper{T,N,FloatNAArray{T,N,A}}, y::AbstractArrayWrapper{U,N,FloatNAArray{U,N,B}}) = begin
  if x === y
    return true
  else
    for (elx, ely) in zip(x.a.data, y.a.data)
      if elx != ely
        return false
      end
    end
    return true
  end
end


# TODO make sure this blanket definition is okay.
# remvoed in favor of using == instead of .== for naop_eq (and similarly for naop_noeq).
# (.==)(x, y) = x == y
