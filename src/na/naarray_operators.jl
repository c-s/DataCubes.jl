# it seems that currently, map operation over Nullable array is not optimzed in julia 0.4.1.

import Base: .+, .-, .*, *, ./, .\, .//, .==, .<, .!=, .<=, .%, .<<, .>>, .^, +, -, ~, &, |, $, ==, !=
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
                                   Base.sort, Base.sort!, Base.sortperm, Base.reverse,
                                   Base.sub, Base.slice)
Base.similar{T,N}(arr::AbstractArrayWrapper, ::Type{T}, dims::NTuple{N,Int}) = AbstractArrayWrapper(similar(arr.a, T, dims))
Base.similar{T<:AbstractFloat,U<:AbstractFloat,N,A,M}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                    ::Type{Nullable{U}},
                                                    dims::NTuple{M,Int}) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a.data, U, dims)))
Base.similar{U<:AbstractFloat,M}(arr::AbstractArrayWrapper,
                                 ::Type{Nullable{U}},
                                 dims::NTuple{M,Int}) =
  AbstractArrayWrapper(FloatNAArray(similar(arr.a, U, dims)))
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
      $(esc(op.args[1]))(x::AbstractArrayWrapper) = begin
        # AbstractArrayWrapper(map($(esc(op.args[2])), x.a))
        result = similar(x.a)
        $(symbol(op.args[1],naop_suffix))(result, x)
        AbstractArrayWrapper(result)
      end
      $(symbol(op.args[1],naop_suffix))(result, x::AbstractArrayWrapper) = begin
        xa = x.a
        for i in eachindex(xa)
          @inbounds result[i] = $(esc(op.args[2]))(xa[i])
        end
      end
      $(symbol(op.args[1],naop_suffix)){T<:AbstractFloat,N,A}(result, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
        @debug_stmt @show "unary float"
        xadata = x.a.data
        resultdata = result.data
        for i in eachindex(xadata)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i])
        end
      end
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

promote_nullable_types{T,U}(::Type{Nullable{T}},::Type{Nullable{U}}) = Nullable{promote_type(T,U)}
promote_nullable_types{T,U}(::Type{T},::Type{Nullable{U}}) = Nullable{promote_type(T,U)}
promote_nullable_types{T,U}(::Type{Nullable{T}},::Type{U}) = Nullable{promote_type(T,U)}
promote_nullable_types{T,U}(::Type{T},::Type{U}) = promote_type(T,U)
#promote_nullable_types(::DataType,::DataType) = Nullable{Any}

preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{Nullable{U}}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{Nullable{T}},::Type{U}, tpe) = Nullable{tpe}
preset_nullable_type{T,U}(::Type{T},::Type{U}, tpe) = tpe

const naop_suffix = "!"

# not used anymore.
macro absarray_binary_wrapper(ops...)
  targetexpr = map(ops) do op
    nullelem = if length(op.args) == 2
      #Expr(:curly, :Nullable, Expr(:call, :promote_type, :T, :U))
      :(promote_nullable_types(T,U))
    elseif length(op.args) == 3
      #Expr(:curly, :Nullable, op.args[3])
      :(preset_nullable_type(T,U,$(op.args[3])))
    end
    quote
      $(esc(op.args[1])){T,U}(x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
        @assert(size(x) == size(y))
        #AbstractArrayWrapper(map((u,v)->$(esc(op.args[2]))(u,v), x.a, y.a))
        result = similar(x, $nullelem)
        $(symbol(op.args[1],naop_suffix))(result.a, x, y)
        AbstractArrayWrapper(result)
      end
      $(symbol(op.args[1],naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::AbstractArrayWrapper{U}) = begin
        xa = x.a
        ya = y.a
        for i in eachindex(xa,ya)
          @inbounds result[i] = $(esc(op.args[2]))(xa[i],ya[i])
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,A,U,B}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                     y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
        @debug_stmt @show "binary array array float float -> float"
        xadata = x.a.data
        yadata = y.a.data
        resultdata = result.data
        for i in eachindex(xadata,yadata)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],yadata[i])
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,A,U<:Nullable}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array float nofloat -> float"
        xadata = x.a.data
        ya= y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xadata,ya)
          @inbounds yai = ya[i]
          if yai.isnull
            @inbounds resultdata[i] = na
          else
            @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],yai.value)
          end
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T<:Nullable,U,B}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
        @debug_stmt @show "binary array array nofloat float -> float"
        xa= x.a
        yadata = y.a.data
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,yadata)
          @inbounds xai = xa[i]
          if xai.isnull
            @inbounds resultdata[i] = na
          else
            @inbounds resultdata[i] = $(esc(op.args[2]))(xai.value, yadata[i])
          end
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T<:Nullable,U<:Nullable}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array nofloat nofloat -> float"
        xa= x.a
        ya = y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,ya)
          @inbounds xai = xa[i]
          @inbounds yai = ya[i]
          if xai.isnull || yai.isnull
            @inbounds resultdata[i] = na
          else
            @inbounds resultdata[i] = $(esc(op.args[2]))(xai.value, yai.value)
          end
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,A,U}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array float nonnull nofloat -> float"
        xadata = x.a.data
        ya= y.a
        resultdata = result.data
        for i in eachindex(xadata,ya)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],ya[i])
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,U,B}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,B}}) = begin
        @debug_stmt @show "binary array array nonnull nofloat float -> float"
        xa= x.a
        yadata = y.a.data
        resultdata = result.data
        for i in eachindex(xa,yadata)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xa[i], yadata[i])
        end
      end

      $(symbol(op.args[1],naop_suffix)){N,K,T<:Nullable,U}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array nonnull nofloat nonnull nofloat -> float"
        xa= x.a
        ya = y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,ya)
          @inbounds v = $(esc(op.args[2]))(xa[i], ya[i])
          @inbounds resultdata[i] = v.isnull ? na : v.value
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,U<:Nullable}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array nonnull nofloat nonnull nofloat -> float"
        xa= x.a
        ya = y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,ya)
          @inbounds v = $(esc(op.args[2]))(xa[i], ya[i])
          @inbounds resultdata[i] = v.isnull ? na : v.value
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T<:Nullable,U<:Nullable}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array nonnull nofloat nonnull nofloat -> float"
        xa= x.a
        ya = y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,ya)
          @inbounds v = $(esc(op.args[2]))(xa[i], ya[i])
          @inbounds resultdata[i] = v.isnull ? na : v.value
        end
      end
      $(symbol(op.args[1],naop_suffix)){N,K,T,U}(result::FloatNAArray{K,N},
                                                     x::AbstractArrayWrapper{T,N},
                                                     y::AbstractArrayWrapper{U,N}) = begin
        @debug_stmt @show "binary array array nonnull nofloat nonnull nofloat -> float"
        xa= x.a
        ya = y.a
        resultdata = result.data
        na = convert(K,NaN)
        for i in eachindex(xa,ya)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xa[i], ya[i])
        end
      end



      $(esc(op.args[1])){T,U<:Nullable}(x::AbstractArrayWrapper{T}, y::U) = begin
        result = similar(x, $nullelem)
        $(symbol(op.args[1],naop_suffix))(result.a, x, y)
        AbstractArrayWrapper(result)
      end
      $(symbol(op.args[1],naop_suffix)){T,U}(result, x::AbstractArrayWrapper{T}, y::U) = begin
        xa = x.a
        for i in eachindex(xa)
          @inbounds result[i] = $(esc(op.args[2]))(xa[i],y)
        end
      end
      #$(symbol(op.args[1],naop_suffix)){K,T,N,U,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y::U) = begin
      #  @debug_stmt @show "binary array scalar float"
      #  xadata = x.a.data
      #  resultdata = result.data
      #  for i in eachindex(xadata)
      #    @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],y)
      #  end
      #end
      $(symbol(op.args[1],naop_suffix)){K,T,U<:Nullable,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y::U) = begin
        @debug_stmt @show "binary array scalar null float"
        if y.isnull
          setna!(result)
        else
          xadata = x.a.data
          yvalue = y.value
          resultdata = result.data
          for i in eachindex(xadata)
            @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],yvalue)
          end
          #$(symbol(op.args[1],naop_suffix))(result, x, y.value)
        end
      end

      $(esc(op.args[1])){T<:Nullable,U}(x::T, y::AbstractArrayWrapper{U}) = begin
        #AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
        result = similar(y, $nullelem)
        $(symbol(op.args[1],naop_suffix))(result.a, x, y)
        AbstractArrayWrapper(result)
      end
      $(symbol(op.args[1],naop_suffix)){T,U}(result, x::T, y::AbstractArrayWrapper{U}) = begin
        ya = y.a
        for i in eachindex(ya)
          @inbounds result[i] = $(esc(op.args[2]))(x,ya[i])
        end
      end
      $(symbol(op.args[1],naop_suffix)){K,T<:Nullable,U,N,A}(result::FloatNAArray{K,N}, x::T, y::AbstractArrayWrapper{Nullable{U},N,FloatNAArray{U,N,A}}) = begin
        @debug_stmt @show "binary scalar null float array scalar"
        if x.isnull
          setna!(result)
        else
          xvalue = x.value
          yadata = y.a.data
          resultdata = result.data
          for i in eachindex(yadata)
            @inbounds resultdata[i] = $(esc(op.args[2]))(xvalue, yadata[i])
          end
        end
      end

      $(symbol(op.args[1],"nulltype2", naop_suffix))(result, x::AbstractArrayWrapper, y) = begin
        xa = x.a
        for i in eachindex(xa)
          @inbounds result[i] = $(esc(op.args[2]))(xa[i],y)
        end
      end
      $(symbol(op.args[1],"nulltype2", naop_suffix)){K,T,N,A}(result::FloatNAArray{K,N}, x::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, y) = begin
        xadata = x.a.data
        resultdata = result.data
        for i in eachindex(xadata)
          @inbounds resultdata[i] = $(esc(op.args[2]))(xadata[i],y)
        end
      end

      $(symbol(op.args[1],"nulltype1", naop_suffix))(result, x, y::AbstractArrayWrapper) = begin
        ya = y.a
        for i in eachindex(ya)
          @inbounds result[i] = $(esc(op.args[2]))(x,ya[i])
        end
      end
      $(symbol(op.args[1],"nulltype1", naop_suffix)){K,N,T,A}(result::FloatNAArray{K,N}, x, y::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
        yadata = y.a.data
        resultdata = result.data
        for i in eachindex(yadata)
          @inbounds resultdata[i] = $(esc(op.args[2]))(x,yadata[i])
        end
      end

      for nulltype in $LiftToNullableTypes
        $(esc(op.args[1]))(x::AbstractArrayWrapper{nulltype}, y::nulltype) = begin
          #AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
          T = eltype(x)
          U = typeof(y)
          result = similar(x, $nullelem)
          $(symbol(op.args[1],"nulltype2",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end

        $(esc(op.args[1]))(x::nulltype, y::AbstractArrayWrapper{nulltype}) = begin
          #AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
          T = typeof(x)
          U = eltype(y)
          result = similar(y, $nullelem)
          $(symbol(op.args[1],"nulltype1",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end

        $(esc(op.args[1])){T<:nulltype}(x::AbstractArrayWrapper{T}, y::nulltype) = begin
          #AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
          U = typeof(y)
          result = similar(x, $nullelem)
          $(symbol(op.args[1],"nulltype2",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end

        $(esc(op.args[1])){U<:nulltype}(x::nulltype, y::AbstractArrayWrapper{U}) = begin
          #AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
          T = typeof(x)
          result = similar(y, $nullelem)
          $(symbol(op.args[1],"nulltype1",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end

        $(esc(op.args[1])){T<:Nullable}(x::AbstractArrayWrapper{T}, y::nulltype) = begin
          #AbstractArrayWrapper(map(u->$(esc(op.args[2]))(u,y), x.a))
          U = typeof(y)
          result = similar(x, $nullelem)
          $(symbol(op.args[1],"nulltype2",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end

        $(esc(op.args[1])){U<:Nullable}(x::nulltype, y::AbstractArrayWrapper{U}) = begin
          #AbstractArrayWrapper(map(v->$(esc(op.args[2]))(x,v), y.a))
          T = typeof(x)
          #map_typed($nullelem, v->$(esc(op.args[2]))(x,v), y)
          result = similar(y, $nullelem)
          $(symbol(op.args[1],"nulltype1",naop_suffix))(result.a, x, y)
          AbstractArrayWrapper(result)
        end
      end
    end
  end
  Expr(:block, targetexpr...)
end

*(x::Integer, y::AbstractArrayWrapper) = x .* y
*(x::AbstractArrayWrapper, y::Integer) = x .* y
*(x::AbstractFloat, y::AbstractArrayWrapper) = x .* y
*(x::AbstractArrayWrapper, y::AbstractFloat) = x .* y
*{T<:Integer}(x::Nullable{T}, y::AbstractArrayWrapper) = x .* y
*{T<:Integer}(x::AbstractArrayWrapper, y::Nullable{T}) = x .* y
*{T<:AbstractFloat}(x::Nullable{T}, y::AbstractArrayWrapper) = x .* y
*{T<:AbstractFloat}(x::AbstractArrayWrapper, y::Nullable{T}) = x .* y

#.*{T<:AbstractFloat,N}(x::Integer, y::AbstractArrayWrapper{Nullable{T},N}) = convert(T,x) .* y


#map_typed(resulttype::DataType, f::Function, arr1::AbstractArrayWrapper, arrs::AbstractArrayWrapper...) = begin
#  result = similar(arr1, resulttype)
#  map_typed!(f, result, arr1, arrs...)
#  result
#end
#
#map_typed!{T,U,N,A,B}(f::Function, result::AbstractArrayWrapper{T,N,A}, arr::AbstractArrayWrapper{U,N,B}) = begin
#  resulta = result.a
#  arra = arr.a
#  for i in eachindex(arra)
#    @inbounds resulta[i] = f(arra[i])
#  end
#end
#
#map_typed!{T,U,N,A,B}(f::Function,
#                      result::AbstractArrayWrapper{T,N,A},
#                      arr1::AbstractArrayWrapper{U,N,B},
#                      arr2::AbstractArrayWrapper{U,N,B}) = begin
#  @assert(size(arr1) == size(arr2))
#  resulta = result.a
#  arr1a = arr1.a
#  arr2a = arr2.a
#  for i in eachindex(arr1a,arr2a)
#    @inbounds resulta[i] = f(arr1a[i],arr2a[i])
#  end
#end

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
        x.isnull || y.isnull ? $nullelem() : $nullelem($(esc(op.args[1]))(x.value, y.value))
      $(esc(op.args[2])){T,V}(x::Nullable{T}, y::V) =
        x.isnull ? $nullelem() : $nullelem($(esc(op.args[1]))(x.value, y))
      $(esc(op.args[2])){T,V}(x::T, y::Nullable{V}) =
        y.isnull ? $nullelem() : $nullelem($(esc(op.args[1]))(x, y.value))
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

@nullable_unary_wrapper((+, naop_plus), (-, naop_minus), (~, naop_not))
@nullable_binary_wrapper((.+, naop_plus), (.-, naop_minus), (.*, naop_mul),
                         (./, naop_div),
                         # could not use .== or .!= over general types such as AbstractString.
                         # let's settle down to using == and != instead for now.
                         # at least, we don't have to provide a blanket definition (.==)(x,y) = x==y then.
                         (.\, naop_invdiv), (.//, naop_frac), (==, naop_eq, Bool), (.<, naop_lt, Bool),
                         (!=, naop_noeq, Bool), (.<=, naop_le, Bool), (.%, naop_mod), (.<<, naop_lsft),
                         (.>>, naop_rsft), (.^, naop_exp),
                         (&, naop_and), (|, naop_or), ($, naop_xor))

#unary_ops = [(:.+,:+), (:.-,:-), (:~,:~), (:+,:+), (:-,:-)]
#binary_ops = [(:.+,:+), (:.-,:-), (:+,:+), (:-,:-),
#              (:.*,:*), (:./,:/), (:~,:~),
#              (:.//,://), (:(.==),:(==),Bool), (:(.!=),:(!=),Bool),
#              (:.<,:<,Bool), (:.<=,:<=,Bool),
#              (:.^,:^), (:.%,:%), (:.<<,:<<), (:.>>,:>>),
#              (:&,:&), (:|,:|), (:$,:$)]
#
#for op in unary_ops
#  @eval begin
#    $(op[1]){T<:Nullable}(arr::AbstractArrayWrapper{T}) = begin
#      nullelem = T()
#      AbstractArrayWrapper(map(x->x.isnull ? nullelem : Nullable($(op[2])(x.value)), arr.a))
#    end
#    $(op[1]){T}(arr::AbstractArrayWrapper{T}) = begin
#      AbstractArrayWrapper(map(x->Nullable($(op[2])(x)), arr.a))
#    end
#  end
#end
#
#promote_nullable_types{T,U}(::Type{Nullable{T}},::Type{Nullable{U}}) = Nullable{promote_type(T,U)}
#promote_nullable_types(::DataType,::DataType) = Any
#
#macro time_debug(x)
#  quote
#    @show $(string(x))
#    @time result = $(esc(x))
#    result
#  end
#end
#
#for op in binary_ops
#  if length(op) == 3
#    nulltype = :(Nullable{$(op[3])})
#    nullelem = :(Nullable{$(op[3])}())
#  else
#    nulltype = :(promote_nullable_types(T,U))
#    nullelem = :(promote_nullable_types(T,U)())
#  end
#  @eval begin
#    $(op[1]){T<:Nullable,U<:Nullable}(arr1::AbstractArrayWrapper{T}, arr2::AbstractArrayWrapper{U}) = begin
#      ne = $nullelem
#      @time_debug AbstractArrayWrapper(map((u,v) -> (u.isnull || v.isnull) ? ne : Nullable($(op[2])(u.value,v.value)), arr1.a, arr2.a))
#    end
#    $(op[1]){T<:Nullable,UU}(arr1::AbstractArrayWrapper{T}, arr2::AbstractArrayWrapper{UU}) = begin
#      U = Nullable{UU}
#      ne = $nullelem
#      @time_debug AbstractArrayWrapper(map((u,v) -> u.isnull ? ne : Nullable($(op[2])(u.value,v)), arr1.a, arr2.a))
#    end
#    $(op[1]){TT,U<:Nullable}(arr1::AbstractArrayWrapper{TT}, arr2::AbstractArrayWrapper{U}) = begin
#      T = Nullable{TT}
#      ne = $nullelem
#      @time_debug AbstractArrayWrapper(map((u,v) -> v.isnull ? ne : Nullable($(op[2])(u,v.value)), arr1.a, arr2.a))
#    end
#    $(op[1]){TT,UU}(arr1::AbstractArrayWrapper{TT}, arr2::AbstractArrayWrapper{UU}) = begin
#      @time_debug AbstractArrayWrapper(map((u,v) -> $(op[2])(u,v), arr1.a, arr2.a))
#    end
#    $(op[1]){T<:Nullable,U<:Nullable}(arr1::AbstractArrayWrapper{T}, elem2::U) = begin
#      ne = $nullelem
#      if elem2.isnull
#        result = similar(arr1.a, $nulltype)
#        fill!(result, ne)
#        @time_debug AbstractArrayWrapper(result)
#      else
#        elem2v = elem2.value
#        @time_debug AbstractArrayWrapper(map(u -> u.isnull ? ne : Nullable($(op[2])(u.value,elem2v)), arr1.a))
#      end
#    end
#    $(op[1]){T<:Nullable,U<:Nullable}(elem1::T, arr2::AbstractArrayWrapper{U}) = begin
#      ne = $nullelem
#      if elem1.isnull
#        result = similar(arr2.a, $nulltype)
#        fill!(result, ne)
#        @time_debug AbstractArrayWrapper(result)
#      else
#        elem1v = elem1.value
#        @time_debug AbstractArrayWrapper(map(v -> v.isnull ? ne : Nullable($(op[2])(elem1v,v.value)), arr2.a))
#      end
#    end
#
#    $(op[1]){TT,U<:Nullable}(arr1::AbstractArrayWrapper{TT}, elem2::U) = begin
#      T = Nullable{TT}
#      ne = $nullelem
#      if elem2.isnull
#        result = similar(arr1.a, $nulltype)
#        fill!(result, ne)
#        @time_debug AbstractArrayWrapper(result)
#      else
#        elem2v = elem2.value
#        @time_debug AbstractArrayWrapper(map(u -> Nullable($(op[2])(u,elem2v)), arr1.a))
#      end
#    end
#    $(op[1]){T<:Nullable,UU}(elem1::T, arr2::AbstractArrayWrapper{UU}) = begin
#      U = Nullable{UU}
#      ne = $nullelem
#      if elem1.isnull
#        result = similar(arr2.a, $nulltype)
#        fill!(result, ne)
#        @time_debug AbstractArrayWrapper(result)
#      else
#        elem1v = elem1.value
#        @time_debug AbstractArrayWrapper(map(v -> Nullable($(op[2])(elem1v,v)), arr2.a))
#      end
#    end
#
#    for nulltype in $LiftToNullableTypes
#      $(op[1]){T<:Nullable,V<:nulltype}(arr1::AbstractArrayWrapper{T}, elem2::V) = begin
#        U = Nullable{V}
#        ne = $nullelem
#        @time_debug AbstractArrayWrapper(map(u -> u.isnull ? ne : Nullable($(op[2])(u.value,elem2)), arr1.a))
#      end
#      $(op[1]){R<:nulltype,U<:Nullable}(elem1::R, arr2::AbstractArrayWrapper{U}) = begin
#        T = Nullable{R}
#        ne = $nullelem
#        @show R,U
#        r = @time_debug AbstractArrayWrapper(map(v -> v.isnull ? ne : $nulltype($(op[2])(elem1,v.value)), arr2.a))
#        @show ne
#        @show typeof(r)
#        @show eltype(r)
#        r
#      end
#      # Don't know why the next 2 definitions remove ambiguity warnings...
#      $(op[1])(arr1::AbstractArrayWrapper{nulltype}, elem2::nulltype) = begin
#        @time_debug AbstractArrayWrapper(map(u->$(op[2])(u,elem2), arr1.a))
#      end
#      $(op[1])(elem1::nulltype, arr2::AbstractArrayWrapper{nulltype}) = begin
#        @time_debug AbstractArrayWrapper(map(v->$(op[2])(elem1,v), arr2.a))
#      end
#      $(op[1]){TT<:nulltype}(arr1::AbstractArrayWrapper{TT}, elem2::nulltype) = begin
#        @time_debug AbstractArrayWrapper(map(u->$(op[2])(u,elem2), arr1.a))
#      end
#      $(op[1]){UU<:nulltype}(elem1::nulltype, arr2::AbstractArrayWrapper{UU}) = begin
#        @time_debug AbstractArrayWrapper(map(v->$(op[2])(elem1,v), arr2.a))
#      end
#    end
#  end
#end
#

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


map_typed{T}(f::Function, ::Type{T}, arr::AbstractArrayWrapper) = AbstractArrayWrapper(map_typed(f, T, arr.a))
map_typed{T}(f::Function, ::Type{T}, arr1::AbstractArrayWrapper, arr2::AbstractArrayWrapper) =
  AbstractArrayWrapper(map_typed(f, T, arr1.a, arr2.a))
map_typed{T}(f::Function, ::Type{T}, arr1::AbstractArrayWrapper, arrs::AbstractArrayWrapper...) =
  AbstractArrayWrapper(map_typed(f, T, arr1.a, map(x->x.a, arrs)...))

map_typed{T}(f::Function, ::Type{T}, arr::AbstractArray) = begin
  result = similar(arr, T)
  for i in eachindex(arr)
    @inbounds result[i]::T = f(arr[i])::T
  end
  result
end

map_typed{T}(f::Function, ::Type{T}, arr1::AbstractArray, arr2::AbstractArray) = begin
  @assert(size(arr1) == size(arr2))
  result = similar(arr1, T)
  for i in eachindex(arr1,arr2)
    @inbounds result[i]::T = f(arr1[i], arr2[i])::T
  end
  result
end

map_typed{T}(f::Function, ::Type{T}, arr1::AbstractArray, arrs::AbstractArray...) = begin
  sizearr1 = size(arr1)
  for arr in arrs
    @assert(sizearr1 == size(arr))
  end
  result = similar(arr1, T)
  for i in eachindex(arr1,arrs...)
    @inbounds result[i]::T = f(arr1[i], map(x->x[i],arrs)...)::T
  end
  result
end
