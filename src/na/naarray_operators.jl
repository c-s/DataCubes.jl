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
@delegate(AbstractArrayWrapper.a, Base.start, Base.next, Base.done, Base.size,
                           Base.ndims, Base.length, Base.setindex!, Base.find)
@delegate_and_lift(AbstractArrayWrapper.a, Base.transpose, Base.permutedims, Base.repeat,
                                   Base.repeat, Base.transpose, Base.permutedims,
                                   Base.sort, Base.sort!, Base.sortperm, Base.similar, Base.reverse)
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
      $(esc(op.args[1]))(x::AbstractArrayWrapper{Nullable}, y::AbstractArrayWrapper{Nullable}) =
        AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))
      $(esc(op.args[1])){T}(x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable}) =
        AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))
      $(esc(op.args[1])){T}(x::AbstractArrayWrapper{Nullable}, y::AbstractArrayWrapper{Nullable{T}}) =
        AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))
      $(esc(op.args[1])){T,U}(x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) =
        AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))

      $(esc(op.args[1]))(x::AbstractArrayWrapper{Nullable}, y::Nullable) =
        AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
      $(esc(op.args[1]))(x::Nullable, y::AbstractArrayWrapper{Nullable}) =
        AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
      $(esc(op.args[1])){T}(x::AbstractArrayWrapper{Nullable{T}}, y::Nullable) =
        AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
      $(esc(op.args[1])){T}(x::Nullable, y::AbstractArrayWrapper{Nullable{T}}) =
        AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))

      for nulltype in $LiftToNullableTypes
        $(esc(op.args[1]))(x::AbstractArrayWrapper{Nullable}, y::nulltype) =
          AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,Nullable(y)), x.a))
        $(esc(op.args[1]))(x::nulltype, y::AbstractArrayWrapper{Nullable}) =
          AbstractArrayWrapper(map(v->$(esc(op.args[2]))(Nullable(x),v), y.a))
        $(esc(op.args[1])){T}(x::AbstractArrayWrapper{Nullable{T}}, y::nulltype) =
          AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,Nullable(y)), x.a))
        $(esc(op.args[1])){T}(x::nulltype, y::AbstractArrayWrapper{Nullable{T}}) =
          AbstractArrayWrapper(map(v->$(esc(op.args[2]))(Nullable(x),v), y.a))
      end
    end
  end
  Expr(:block, targetexpr...)
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
(==){T,U}(x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable{U}}) = x===y ||
  all(map(x, y) do elx,ely
    if elx.isnull && ely.isnull
      return true
    elseif elx.isnull || ely.isnull
      return false
    else
      elx.value == ely.value
    end
  end)
(==)(x::AbstractArrayWrapper{Nullable}, y::AbstractArrayWrapper{Nullable}) = x===y ||
  all(map(x, y) do elx,ely
    if elx.isnull && ely.isnull
      return true
    elseif elx.isnull || ely.isnull
      return false
    else
      elx.value == ely.value
    end
  end)
(==){T}(x::AbstractArrayWrapper{Nullable{T}}, y::AbstractArrayWrapper{Nullable}) = x===y ||
  all(map(x, y) do elx,ely
    if elx.isnull && ely.isnull
      return true
    elseif elx.isnull || ely.isnull
      return false
    else
      elx.value == ely.value
    end
  end)
(==){T}(x::AbstractArrayWrapper{Nullable}, y::AbstractArrayWrapper{Nullable{T}}) = x===y ||
  all(map(x, y) do elx,ely
    if elx.isnull && ely.isnull
      return true
    elseif elx.isnull || ely.isnull
      return false
    else
      elx.value == ely.value
    end
  end)

# TODO make sure this blanket definition is okay.
# remvoed in favor of using == instead of .== for naop_eq (and similarly for naop_noeq).
# (.==)(x, y) = x == y
