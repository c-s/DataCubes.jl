# it seems that currently, map operation over Nullable array is not optimzed in julia 0.4.1.

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
Base.map(f, arrs::AbstractArrayWrapper...) = AbstractArrayWrapper(map(f, map(x->x.a, arrs)...))

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
        $(esc(op.args[1])){T<:Nullable}(x::AbstractArrayWrapper{T}, y::nulltype) = begin
          AbstractArrayWrapper(specialized_map(u->$(esc(op.args[2]))(u,y), x.a))
        end
        $(esc(op.args[1])){T<:Nullable}(x::nulltype, y::AbstractArrayWrapper{T}) = begin
          # version 1. what is correct, but could be slower. I am experimenting.
          #@show "r is"
          #@time temp = [$(esc(op.args[2]))(x,v) for v in y.a]
          #@show typeof(y.a)
          @time temp = specialized_map(v->$(esc(op.args[2]))(x,v), y.a)
          @time r = AbstractArrayWrapper(temp)
          #@time r = AbstractArrayWrapper(fill(Nullable(true), size(y.a)))
          #@show "r shown"
          r
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

unary_ops = [(:.+,:+), (:.-,:-), (:~,:~)]
binary_ops = [(:.+,:+), (:.-,:-), (:.*,:*), (:./,:/), (:~,:~),
              (:.//,://), (:(.==),:(==),Bool), (:(.!=),:(!=),Bool),
              (:.<,:<,Bool), (:.<=,:<=,Bool),
              (:.^,:^), (:.%,:%), (:.<<,:<<), (:.>>,:>>),
              (:&,:&), (:|,:|), (:$,:$)]

for op in unary_ops
  @eval $(op[1]){T<:Nullable}(arr::AbstractArrayWrapper{T}) = AbstractArrayWrapper(map(x->x.isnull ? Nullable{T}() : $(op[2])(x), arr.a))
end

for op in binary_ops
  if length(op) == 3
    nulltype = :(Nullable{$(op[3])})
    nullelem = :(Nullable{$(op[3])}())
  else
    nulltype = :(Nullable{promote_type(T,U)})
    nullelem = :(Nullable{promote_type(T,U)}())
  end
  @eval begin
    $(op[1]){T<:Nullable,U<:Nullable}(arr1::AbstractArrayWrapper{T}, arr2::AbstractArrayWrapper{U}) = begin
      ne = $nullelem
      AbstractArrayWrapper(map((u,v) -> (u.isnull || v.isnull) ? ne : Nullable($(op[2])(u.value,v.value)), arr1.a, arr2.a))
    end
    $(op[1]){T<:Nullable,U<:Nullable}(arr1::AbstractArrayWrapper{T}, elem2::U) = begin
      ne = $nullelem
      if elem2.isnull
        result = similar(arr1, $nulltype)
        fill!(result, ne)
        result
      else
        elem2v = elem2.value
        AbstractArrayWrapper(map(u -> u.isnull ? ne : Nullable($(op[2])(u.value,elem2v)), arr1.a))
      end
    end
    $(op[1]){T<:Nullable,U<:Nullable}(elem1::T, arr2::AbstractArrayWrapper{U}) = begin
      ne = $nullelem
      if elem1.isnull
        result = similar(arr2, $nulltype)
        fill!(result, ne)
        result
      else
        elem1v = elem1.value
        AbstractArrayWrapper(map(v -> v.isnull ? ne : Nullable($(op[2])(elem1v,v.value)), arr2.a))
      end
    end
    for nulltype in LiftToNullableTypes
      $(op[1]){T<:Nullable,U<:nulltype}(arr1::AbstractArrayWrapper{T}, elem2::U) = begin
        ne = $nullelem
        AbstractArrayWrapper(map(u -> u.isnull ? ne : Nullable($(op[2])(u.value,elem2)), arr1.a))
      end
      $(op[1]){T<:nulltype,U<:Nullable}(elem1::T, arr2::AbstractArrayWrapper{U}) = begin
        ne = $nullelem
        AbstractArrayWrapper(map(v -> v.isnull ? ne : Nullable($(op[2])(elem1,v.value)), arr2.a))
      end
    end
  end
end

#@nullable_unary_wrapper((.+, naop_plus), (.-, naop_minus), (~, naop_not))
#@nullable_binary_wrapper((.+, naop_plus), (.-, naop_minus), (.*, naop_mul),
#                         (./, naop_div),
#                         # could not use .== or .!= over general types such as AbstractString.
#                         # let's settle down to using == and != instead for now.
#                         # at least, we don't have to provide a blanket definition (.==)(x,y) = x==y then.
#                         (.\, naop_invdiv), (.//, naop_frac), (==, naop_eq, Bool), (.<, naop_lt, Bool),
#                         (!=, naop_noeq, Bool), (.<=, naop_le, Bool), (.%, naop_mod), (.<<, naop_lsft),
#                         (.>>, naop_rsft), (.^, naop_exp),
#                         (&, naop_and), (|, naop_or), ($, naop_xor))
#
#@absarray_unary_wrapper((+, naop_plus), (-, naop_minus), (.+, naop_plus), (.-, naop_minus), (~, naop_not))
#@absarray_binary_wrapper((+, naop_plus), (-, naop_minus), (.+, naop_plus), (.-, naop_minus), (.*, naop_mul),
#                         (./, naop_div),
#                         (.\, naop_invdiv), (.//, naop_frac), (.==, naop_eq, Bool), (.<, naop_lt, Bool),
#                         (.!=, naop_noeq, Bool), (.<=, naop_le, Bool), (.%, naop_mod), (.<<, naop_lsft),
#                         (.>>, naop_rsft), (.^, naop_exp),
#                         (&, naop_and), (|, naop_or), ($, naop_xor))

specialized_map(f::Function, x::AbstractArrayWrapper) = AbstractArrayWrapper(specialized_map(f, x.a))
specialized_map(f::Function, xs::AbstractArrayWrapper...) = AbstractArrayWrapper(specialized_map(f, map(x->x.a, xs)...))
specialized_map(f::Function, xs...) = map(f, xs...)
#specialized_map{T}(f::Function, x::AbstractArray{T,1}) = typeof(f(x[1]))[f(elem) for elem in x]
#specialized_map{T,U}(f::Function, x::AbstractArray{T,1}, y::AbstractArray{U,1}) = typeof(f(x[1],y[1]))[f(ex,ey) for (ex,ey) in zip(x,y)]


#specialized_map(f::Function, arr) = begin
#  #if isempty(arr)
#  #  # there is no other better way...
#  #  return similar(arr, 0)
#  #end
#  @show "this called with size ", size(arr)
#  returntype = typeof(f(first(arr)))
#  @show returntype
#  result = similar(arr, returntype)
#  @show typeof(result)
#  @show eltype(result)
#  @show typeof(arr)
#  @show eltype(arr)
#  specialized_map!(f, ntuple(d->0, ndims(arr)), result, arr)
#  result
#end
#@generated specialized_map!{R,T,N}(f::Function, dim::NTuple{N,Int}, result::R, arr::T) = quote
#  @nloops $N i result begin
#    temp = f(@nref($N,arr,i))
#    @inbounds @nref($N,result,i) = true #f(@nref($N,arr,i))
#  end
#end

#specialized_map{T<:AbstractFloat}(f::Function, arr::FloatNAArray{T}) = begin
#  onereturnelem = f(first(arr))
#  specialized_map_float_typed(f, onereturnelem, arr)
#end
#
#specialized_map_float_typed{R<:AbstractFloat,T<:AbstractFloat}(f::Function, oneelem::Nullable{R}, arr::FloatNAArray{T}) = begin
#  result = similar(arr, R)
#  specialized_map_nullfloat_to_nullfloat!(f, result, convert(R,NaN), arr)
#  FloatNAArray(result)
#end
#@generated specialized_map_nullfloat_to_nullfloat!{V,R<:AbstractFloat,T<:AbstractFloat,N,A}(f::Function, result::V, nullelem::Nullable{R}, arr::FloatNAArray{T,N,A}) = quote
#  @nloops $N i result begin
#    v = f(@nref($N,arr,i))
#    @inbounds @nref($N,result,i) = v.isnull ? nullelem : v.value
#  end
#end
#
#specialized_map_float_typed{R<:AbstractFloat,T<:AbstractFloat}(f::Function, oneelem::R, arr::FloatNAArray{T}) = begin
#  result = similar(arr, R)
#  specialized_map_nullfloat_to_float!(f, result, arr)
#  FloatNAArray(result)
#end
#@generated specialized_map_nullfloat_to_float!{V,T<:AbstractFloat,N,A}(f::Function, result::V, arr::FloatNAArray{T,N,A}) = quote
#  @nloops $N i result begin
#    v = f(@nref($N,arr,i))
#    @inbounds @nref($N,result,i) = v
#  end
#end
#
#specialized_map_float_typed{R,T<:AbstractFloat}(f::Function, oneelem::R, arr::FloatNAArray{T}) = begin
#  result = similar(arr, Nullable{R})
#  specialized_map_nullfloat_to_some!(f, result, arr)
#  FloatNAArray(result)
#end
#@generated specialized_map_nullfloat_to_some!{V,T<:AbstractFloat,N,A}(f::Function, result::V, arr::FloatNAArray{T,N,A}) = quote
#  @nloops $N i result begin
#    v = f(@nref($N,arr,i))
#    @inbounds @nref($N,result,i) = Nullable(v)
#  end
#end
#
#specialized_map_float_typed{R,T<:AbstractFloat}(f::Function, oneelem::Nullable{R}, arr::FloatNAArray{T}) = begin
#  result = similar(arr, Nullable{R})
#  specialized_map_nullfloat_to_nullsome!(f, result, arr)
#  FloatNAArray(result)
#end
#@generated specialized_map_nullfloat_to_nullsome!{V,T<:AbstractFloat,N,A}(f::Function, result::V, arr::FloatNAArray{T,N,A}) = quote
#  @nloops $N i result begin
#    v = f(@nref($N,arr,i))
#    @inbounds @nref($N,result,i) = v
#  end
#end


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
