# provides some helper tools to deal with NA elements (i.e. elements of type Nullable{T}()).

import DataFrames: DataFrame

"""

A thin wrapper around AbstractArray. The reason to introduce this wrapper is to redefine
the dotted operators such as .+, .-. Those operators will be mapped to arrays, elementwise just as before,
but, if each element is null, those operators will be applied to the one inside the Nullable.
For example,

```julia
julia> AbstractArrayWrapper([Nullable(1), Nullable(2)]) .+ AbstractArrayWrapper([Nullable{Int}(), Nullable(3)])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable{Int64}()
 Nullable(5)      
```

Note that this means lifting those dotted operators via the list(AbstractArray) and maybe(Nullable) functors.

It is possible to redefine those operators for AbstractArray, but concerning about compatibility, it may be
best to introduce a new wrapper class for that.

"""
immutable AbstractArrayWrapper{T,N,A<:AbstractArray} <: AbstractArray{T,N}
  a::A #AbstractArray{T,N} # this is a thin array wrapper
end

AbstractArrayWrapper(a) = AbstractArrayWrapper{eltype(a),ndims(a),typeof(a)}(a)

# delegate the functionality of a type into its component.
# use it when you simply wrap some other data type, but want to use the funcitonality defiend for that data type
# for the new type.
macro delegate(source, targets...)
  if !(:head in fieldnames(source) && source.head == :.)
    throw(ArgumentError("cannot create a delegate statement from the macro @delegate."))
  else
    typename = source.args[1]
    fieldname = source.args[2].args[1]
    targetexpr = map(targets) do target
      Expr(:(=),
           Expr(:call, target, Expr(:(::), :x, typename), Expr(:..., :args)),
           Expr(:call, target, Expr(:., :x, QuoteNode(fieldname)), Expr(:..., :args)))
    end
    esc(Expr(:block, targetexpr...))
  end
end

# similar to delegate, but wraps the final result again using the new data type.
macro delegate_and_lift(source, targets...)
  if !(:head in fieldnames(source) && source.head == :.)
    throw(ArgumentError("cannot create a delegate statement from the macro @delegate."))
  else
    typename = source.args[1]
    fieldname = source.args[2].args[1]
    targetexpr = map(targets) do target
      Expr(:(=),
           Expr(:call, esc(target), Expr(:(::), :x, typename), Expr(:..., :args)),
           Expr(:call, typename, Expr(:call, esc(target), Expr(:., :x, QuoteNode(fieldname)), Expr(:..., :args))))
    end
    Expr(:block, targetexpr...)
  end
end


# used in naliftexp.
naliftexpriter(expriter) = begin
  if all(x->:head in fieldnames(x) && x.head == :row, expriter)
    begin
      vcat_expr = vcat(map(x->x.args, expriter)...)
      test_expr = filter(x->x!=:NA, vcat_expr)
      type_expr = Expr(:call, :eltype, Expr(:vect, test_expr...))
      newexpriter = map(expriter) do expr
        rowexpr = map(expr.args) do subexpr
          if subexpr == :NA
            Expr(:call, Expr(:curly, :Nullable, esc(type_expr)))
          else
            naliftexp(subexpr)
          end
        end
        Expr(:row, rowexpr...)
      end
      newexpriter
    end
  else
    begin
      test_expr = filter(x -> x!=:NA, expriter)
      type_expr = Expr(:call, :eltype, Expr(:vect, test_expr...))
      newexpriter = map(expriter) do expr
        if expr == :NA
          Expr(:call, Expr(:curly, :Nullable, esc(type_expr)))
        else
          naliftexp(expr)
        end
      end
      newexpriter
    end
  end
end

# reads an array expression and replaces a marker NA with an appropriate Nullable{T}().
# the way it does it now is to create an array without that NA marker, and check the resulting array type (say, T),
# then replace the NA marker with Nullable{T}().
naliftexp(expr) = begin
  new_expr =
    if :head in fieldnames(expr)
      if expr.head == :vect || expr.head == :vcat || expr.head == :hcat || expr.head == :row
        new_args = naliftexpriter(expr.args)
        Expr(expr.head, new_args...)
      elseif (expr.head == :ref && isupper(string(expr.args[1])[1])) ||
             expr.head == :typed_vcat ||
             expr.head == :typed_hcat
        Expr(expr.head, expr.args[1], naliftexpriter(expr.args[2:end])...)
      else
        nalift_expwrap(expr)
      end
    else
      nalift_expwrap(expr)
    end
  new_expr
end

nalift_expwrap(expr) = Expr(:call, :nalift_nested, esc(expr))

# a simple wrapper of a floating point array. For floating points, there is a dedicated NaN value,
# so there is no need to use the Nullable element type such as in Array{Nullable{Float64}}.
immutable FloatNAArray{T<:AbstractFloat,N,A} <: AbstractArray{Nullable{T},N}
  data::A #AbstractArray{T,N}
end

FloatNAArray{T<:AbstractFloat,N}(data::AbstractArray{T,N}) = FloatNAArray{T,N,typeof(data)}(data)
FloatNAArray{T<:AbstractFloat,N}(data::AbstractArray{Nullable{T},N}) = begin
  nulldata = convert(T, NaN)
  projdata = map(x->x.isnull ? nulldata : x.value, data)
  FloatNAArray(projdata)
end
Base.eltype{T<:AbstractFloat,N,A}(::Type{FloatNAArray{T,N,A}}) = Nullable{T}
Base.getindex{T<:AbstractFloat}(arr::FloatNAArray{T}, arg::Int) = (r=getindex(arr.data, arg);isnan(r) ? Nullable{T}() : Nullable(r))
Base.getindex{T<:AbstractFloat}(arr::FloatNAArray{T}, arg::CartesianIndex) = (r=getindex(arr.data, arg);isnan(r) ? Nullable{T}() : Nullable(r))
Base.getindex{T<:AbstractFloat}(arr::FloatNAArray{T}, args::Int...) = (r=getindex(arr.data, args...);isnan(r) ? Nullable{T}() : Nullable(r))
Base.getindex{T<:AbstractFloat}(arr::FloatNAArray{T}, args...) = FloatNAArray(getindex(arr.data, args...))
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::Nullable, arg::Int) = (nulldata=convert(T,NaN);setindex!(arr.data, if v.isnull;nulldata else v.value end, arg))
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::Nullable, args::Int...) = (nulldata=convert(T,NaN);setindex!(arr.data, if v.isnull;nulldata else v.value end, args...))
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::Nullable, args...) = (nulldata=convert(T,NaN);setindex!(arr.data, if v.isnull;nulldata else v.value end, args...))
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::AbstractFloat, args::Int...) = setindex!(arr.data, v, args...)
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::AbstractFloat, arg::Int) = setindex!(arr.data, v, arg)
Base.setindex!{T<:AbstractFloat}(arr::FloatNAArray{T}, v::AbstractFloat, arg::Int) = setindex!(arr.data, v, arg)
Base.setindex!{T<:AbstractFloat,V<:AbstractFloat}(arr::FloatNAArray{T}, v::AbstractArray{V}, args...) = setindex!(arr.data, v, args...)
Base.setindex!{T<:AbstractFloat,V<:Nullable}(arr::FloatNAArray{T}, v::AbstractArray{V}, args...) = (nulldata=convert(T,NaN);setindex!(arr.data, map(x->if x.isnull;nulldata else x.value end, v), args...))

Base.reshape(arr::FloatNAArray, args::Tuple{Vararg{Int}}) = FloatNAArray(reshape(arr.data, args))
Base.reshape(arr::FloatNAArray, args::Int...) = FloatNAArray(reshape(arr.data, args...))
Base.repeat(arr::FloatNAArray; kwargs...) = FloatNAArray(repeat(arr.data; kwargs...))

Base.next{T}(arr::FloatNAArray{T}, state) = ((x,ns)=next(arr.data, state);isnan(x) ? (Nullable{T}(),ns) : (Nullable(x),ns))
Base.linearindexing{T<:AbstractFloat,N,A}(::Type{FloatNAArray{T,N,A}}) = Base.linearindexing(A)
Base.sub(arr::FloatNAArray, args::Union{Colon,Int,AbstractVector}...) = FloatNAArray(sub(arr.data, args...))
Base.slice(arr::FloatNAArray, args::Union{Colon,Int,AbstractVector}...) = FloatNAArray(slice(arr.data, args...))
Base.sub(arr::FloatNAArray, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}})= FloatNAArray(sub(arr.data, args...))
Base.slice(arr::FloatNAArray, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}}) = FloatNAArray(slice(arr.data, args...))
@delegate(FloatNAArray.data, Base.start, Base.done, Base.size, Base.find)
@delegate_and_lift(FloatNAArray.data, Base.transpose, Base.permutedims, Base.repeat, Base.reshape, Base.sort, Base.sort!, Base.reverse,
                                      Base.sub, Base.slice)
Base.similar{T,N}(arr::FloatNAArray, ::Type{T}, dims::NTuple{N,Int}) = similar(arr.data, T, dims)
Base.similar{T<:AbstractFloat,N}(arr::FloatNAArray, ::Type{Nullable{T}}, dims::NTuple{N,Int}) = FloatNAArray(similar(arr.data, T, dims))
Base.map(f::Function, arr0::FloatNAArray, arrs::AbstractArray...) = begin
  if isempty(arr0)
    return similar(arr0, Nullable{Any})
  end
  firstelem = f(arr0[1], map(x->x[1], arrs)...)
  returntype = typeof(firstelem)
  result = similar(arr0, returntype)
  floatnaarray_map_inner!(result, firstelem, f, arr0, arrs)
  result
end

floatnaarray_map_inner!(result::AbstractArray, firstelem, f::Function, arr0::FloatNAArray, arrs) = begin
  after_first = false
  result[1] = firstelem #f(arr0[1], map(x->x[1], arrs)...)
  for i in eachindex(arr0,arrs...)
    if after_first
      result[i] = f(arr0[i], map(x->x[i], arrs)...)
    end
    after_first = true
  end
end

Base.repeat(arr::FloatNAArray; kwargs...) = FloatNAArray(repeat(arr.data; kwargs...))
Base.sort(arr::FloatNAArray; kwargs...) = FloatNAArray(sort(arr.data; kwargs...))
Base.sort!(arr::FloatNAArray; kwargs...) = FloatNAArray(sort!(arr.data; kwargs...))
Base.cat(dim::Int, arr::FloatNAArray, arrs::FloatNAArray...) = FloatNAArray(cat(dim, arr.data, map(x->x.data, arrs)))
Base.vcat(arrs::FloatNAArray...) = cat(1, arrs...)
Base.hcat(arrs::FloatNAArray...) = cat(2, arrs...)
Base.sub(arr::FloatNAArray, args::Union{Base.Colon,Int,AbstractVector}...) = FloatNAArray(sub(arr.data, args...))
Base.slice(arr::FloatNAArray, args::Union{Base.Colon,Int,AbstractVector}...) = FloatNAArray(slice(arr.data, args...))
simplify_floatarray(arr::FloatNAArray) = arr
simplify_floatarray{T<:AbstractFloat,N,A}(arr::FloatNAArray{T,N,A}) = arr
simplify_floatarray{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = arr
simplify_floatarray{T<:AbstractFloat}(arr::AbstractArrayWrapper{Nullable{T}}) =
  AbstractArrayWrapper(simplify_floatarray(arr.a))
simplify_floatarray{T<:AbstractFloat,N}(arr::AbstractArray{Nullable{T},N}) = begin
  if isempty(arr)
    # for some reason, if arr is empty, projected has the type Nullable{T}[] !
    # isempty(projected) ? FloatNAArray(Array(T,fill(0,N)...)) : FloatNAArray(projected)
    FloatNAArray(zeros(T, size(arr)))
  else
    FloatNAArray(map(arr) do elem
      if elem.isnull
        convert(T, NaN)::T
      else
        elem.value::T
      end
    end)
  end
end
simplify_floatarray(arr) = arr
# simplify things. Ideally it can perform some other checks,
# currently, it constrains the element type further if possible,
# use FloatNAArray if necessary, and wrap it over AbstractArrayWrapper if necessary.
simplify_array(arr::AbstractArray) = wrap_array(simplify_floatarray(type_array(arr)))
simplify_array(nonarray) = nonarray

"""

`nalift(arr)`

Lift each element in an array `arr` to `Nullable` if it is not already so.
Unlike `@nalift`, it does not perform lifting recursively.
It returns `arr` itself when applied to a `DictArray`/`LabeledArray`.

##### Examples

```julia
julia> nalift(Any[[1,2,3],[4,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},1,Array{Nullable{Array{Int64,1}},1}}:
 Nullable([1,2,3])
 Nullable([4,5])  

julia> nalift([1,2,3])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(2)
 Nullable(3)

julia> nalift(Any[[1,2,3],[4,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},1,Array{Nullable{Array{Int64,1}},1}}:
 Nullable([1,2,3])
 Nullable([4,5])  

julia> nalift(darr(a=[1 2;3 4;5 6], b=[:x :y;:z :w;:u :v]))
3 x 2 DictArray

a b |a b 
----+----
1 x |2 y 
3 z |4 w 
5 u |6 v 
```

"""
function nalift end

nalift(x::Nullable) = x
nalift{T}(x::AbstractArray{Nullable{T}}) = wrap_array(x)
nalift{F<:AbstractFloat}(x::FloatNAArray{F}) = wrap_array(x)
nalift{F<:AbstractFloat}(x::AbstractArray{F}) = wrap_array(FloatNAArray(x))
nalift(x::AbstractArray) = begin
  if isempty(x)
    wrap_array(similar(x, Nullable{eltype(x)}))
  elseif isa(x[1], Nullable) && all(elem->isa(elem, Nullable), x)
    # something is fishy... Even though x does not claim it is Nullable, its elements
    #@show "something is fishy... Even though x does not claim it is Nullable, its elements"
    #Nullable[x...]
    result = similar(x, Nullable)
    copy!(result, x)
    wrap_array(result)
  else
    wrap_array(map(Nullable, x))
  end
end
nalift(x::DictArray) = x
nalift(x::LabeledArray) = x
nalift(x::DataFrame) = x
nalift{T,N,AXES,TN}(x::AbstractArray{LabeledArray{T,N,AXES,TN}}) = x
nalift{K,N,VS,SV}(x::AbstractArray{DictArray{K,N,VS,SV}}) = x
nalift(x) = Nullable(x)

# nalift nonmacro version. Read the input array and put Nullable wrappers appropriately.
nalift_nested(x::Nullable) = begin
  if !x.isnull && isa(x.value, AbstractArray)
    Nullable(simplify_array(map(elem->nalift(nalift_nested(elem)), x.value)))
  else
    x
  end
end
nalift_nested(x::DictArray) = x
nalift_nested(x::LabeledArray) = x
nalift_nested(x::DataFrame) = x
nalift_nested{T<:AbstractFloat}(x::AbstractArray{T}) = wrap_array(FloatNAArray(x))
nalift_nested{T}(x::AbstractArray{Nullable{T}}) = begin
  if isempty(x)
    x
  elseif isa(x[1].value, AbstractArray)
    simplify_array(map(elem->Nullable(nalift(nalift_nested(elem.value))), x))
  else
    simplify_array(x)
  end
end
nalift_nested(x::AbstractArray{Nullable}) = begin
  if isempty(x)
    x
  elseif isa(x[1].value, AbstractArray)
    simplify_array(map(elem->Nullable(nalift(nalift_nested(elem.value))), x))
  else
    simplify_array(x)
  end
end
#
#nalift_nested(x::AbstractArray{Nullable}) = simplify_array(x)
nalift_nested(x::AbstractArray) = begin
  if isempty(x)
    wrap_array(similar(x, Nullable{eltype(x)}))
  else
    r = map(elem->nalift_nested(elem), x)
    simplify_array(r)
  end
end
nalift_nested(x) = Nullable(x)

"""

`@nalift(arr)`

Lift each element in an array `arr` to `Nullable` if it is not already so.
It is mainly used to translate a manually typed array expression such as `[1,2,3,NA,5]` into a `Nullable` array.
Unlike `nalift`, it performs lifting recursively.
It returns `arr` itself when applied to a `DictArray`/`LabeledArray`.

##### Examples

```julia
julia> @nalift([1,2,3])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(2)
 Nullable(3)

julia> @nalift([1,2,NA])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)      
 Nullable(2)      
 Nullable{Int64}()

julia> @nalift(Any[[1,2,3],[NA,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}},1,Array{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}},1}}:
 Nullable([Nullable(1),Nullable(2),Nullable(3)])
 Nullable([Nullable{Int64}(),Nullable(5)])      

julia> @nalift(larr(a=[1 2;3 4;5 6], b=[:x :y;:z :w;:u :v]))
3 x 2 LabeledArray

  |1   |2   
--+----+----
  |a b |a b 
--+----+----
1 |1 x |2 y 
2 |3 z |4 w 
3 |5 u |6 v 
```

"""
macro nalift(expr)
  new_expr = naliftexp(expr)
  quote
    nalift(simplify_array(recursive_wrap_array($new_expr)))
  end
end

# had to devise this hackish function...
recursive_wrap_array{T<:AbstractArray}(x::AbstractArray{Nullable{T}}) = begin
  if T<:AbstractArray
    map(x->x.isnull ? x : Nullable(recursive_wrap_array(x.value)), x)
  else
    wrap_array(x)
  end
end
recursive_wrap_array(x::AbstractArray) = begin
  if (eltype(x) <: Nullable) || (!isempty(x) && isa(x[1], Nullable)) #type(typeof(x[1])) <: AbstractArray)
    wrap_array(map(x->x.isnull ? x : Nullable(recursive_wrap_array(x.value)), x))
  else
    wrap_array(map(recursive_wrap_array, x))
  end
end
recursive_wrap_array(x) = x
recursive_wrap_array(x::DictArray) = x
recursive_wrap_array(x::LabeledArray) = x
recursive_wrap_array{T,N,A<:FloatNAArray}(x::AbstractArrayWrapper{T,N,A}) = x

type NAElementException <: Exception end

"""

`setna!(arr, args...)`

Set the element of an array `arr` at `args` to `NA`.
If `args...` is omitted, all elements are set to `NA`.

* If `arr` is an array of element type `Nullable{T}`, `NA` means `Nullable{T}()`.
* If `arr` is a `DictArray`, `NA` means all fields at that position are `NA`.
* If `arr` is a `LabeledArray`, `NA` means the base of `arr` at that position is `NA`.

##### Examples

```julia
julia> setna!(@nalift([1,2,NA,4,5]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()

julia> setna!(@nalift([1,2,NA,4,5]), 2)
5-element Array{Nullable{Int64},1}:
 Nullable(1)      
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable(4)      
 Nullable(5)      

julia> setna!(@darr(a=[1 2 NA;4 5 6], b=[:x :y :z;:u :v :w]), 1:2, 1)
2 x 3 DictArray

a b |a b |a b 
----+----+----
    |2 y |  z 
    |5 v |6 w 


julia> setna!(larr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w], axis1=[:X,:Y]), 1, 2:3)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 x |    |    
Y |4 u |5 v |6 w 
```

"""
function setna! end

setna!{T}(arr::AbstractArray{Nullable{T}}) = fill!(arr, Nullable{T}())
setna!(arr::AbstractArray{Nullable}) = fill!(arr, Nullable{Any}())
setna!{T}(arr::AbstractArray{Nullable{T}}, args...) = setindex!(arr, Nullable{T}(), args...)
setna!(arr::AbstractArray{Nullable}, args...) = setindex!(arr, Nullable{Any}(), args...)
setna!{T<:AbstractFloat}(arr::FloatNAArray{T}, args...) = setindex!(arr.data, convert(T,NaN), args...)
setna!{T<:AbstractFloat}(arr::FloatNAArray{T}) = fill!(arr.data, convert(T,NaN))
setna!(arr::AbstractArrayWrapper, args...) = setna!(arr.a, args...)
setna!(arr::DictArray, args...) = begin
  map(tgt -> setna!(tgt, args...), arr.data.values)
  arr
end
setna!(arr::LabeledArray, args...) = begin
  setna!(arr.data, args...)
  arr
end


"""

`igna(arr [, nareplace])`

Ignore null elements from `arr`.
Null elements will be replaced by `nareplace`, if provided.
If not, the behavior is implementation specific: depending on the array type, it may give some default value or raise an error.
Most likely, a nullable element in an array of `Nullable{F}` element type for some `AbstractFloat` `F` can be replaced by a version of `NaN`.
But for other types, it may be better to raise an error.

* `igna(arr::AbstractArray{Nullable{T},N} [, na_replace])`: ignores null elements from `arr` and return an `AbstractArray{T,N}`. A null value is replaced by `na_replace` if provided. Otherwise, the result is implementation specific.

* `igna(ldict::LDict [, na_replace])` ignores null values from `ldict` and replace them with `na_replace` if provided. Otherwise, the result is implementation specific.

##### Examples

```julia
julia> igna(@nalift([1,2,NA,4,5]))
ERROR: MultidimensionalTables.NAElementException()
 in anonymous at /Users/changsoonpark/.julia/v0.4/MultidimensionalTables/src/na/na.jl:315
 in map_to! at abstractarray.jl:1289
 in map at abstractarray.jl:1311
 in igna at /Users/changsoonpark/.julia/v0.4/MultidimensionalTables/src/na/na.jl:313

julia> igna(@nalift([1.0,2.0,NA,4.0,5.0]))
5-element MultidimensionalTables.AbstractArrayWrapper{Float64,1,Array{Float64,1}}:
   1.0
   2.0
 NaN  
   4.0
   5.0

julia> igna(@nalift([1,2,NA,4,5]), 3)
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 2
 3
 4
 5

julia> igna(LDict(:a=>Nullable(3), :b=>Nullable{Int}()), 1)
MultidimensionalTables.LDict{Symbol,Int64} with 2 entries:
  :a => 3
  :b => 1
```

"""
function igna end

igna{T}(arr::AbstractArray{Nullable{T}}) = if isempty(arr)
  similar(arr, T)
else
  map(arr) do elem
    if elem.isnull
      throw(NAElementException())
    else
      elem.value
    end
  end
end
igna(arr::AbstractArray{Nullable}) = map(arr) do elem
  if elem.isnull
    throw(NAElementException())
  else
    elem.value
  end
end
igna{T}(arr::AbstractArray{Nullable{T}}, na_replace::T) = if isempty(arr)
  similar(arr, T)
else
  map(arr) do elem
    if elem.isnull
      na_replace
    else
      elem.value
    end
  end
end
igna(arr::AbstractArray{Nullable}, na_replace) = map(arr) do elem
  if elem.isnull
    na_replace
  else
    elem.value
  end
end
igna{T<:AbstractFloat}(arr::FloatNAArray{T}) = arr.data
igna{T<:AbstractFloat}(arr::FloatNAArray{T}, na_replace::T) = if isempty(arr)
  similar(arr, T)
else
  map(arr.data) do elem
    isnan(elem) ? na_replace : elem
  end
end
igna{T<:AbstractFloat}(arr::AbstractArray{Nullable{T}}) = igna(arr, convert(T, NaN))
igna{T<:AbstractFloat}(arr::AbstractArray{Nullable{T}}, na_replace::T) = if isempty(arr)
  similar(arr, T)
else
  map(arr) do elem
    if elem.isnull; na_replace else elem.value end
  end
end
igna{T}(elem::Nullable{T}, na_replace::T) = elem.isnull ? na_replace : elem.value

"""

`ignabool(arr)`

Ignore the `Nullable` part of of either a `Nullable` array or a `Nullable` variable.
It is mainly used in the condition statement for @select or @update, where it assumes that only Nullable(true) chooses the element.  Nullable(false) or Nullable{T}() will be regarded as false.

* `ignabool(::AbstractArray{Nullable{Bool}}) returns an `AbstractArray{Bool}` where null and `Nullable(false)` elements are converted into `false` and `Nullable(true)` into `true`.
* `ignabool(::Nullable{Bool})` converts null and `Nullable(false)` elements into `false` and `Nullable(true)` into true.

##### Examples

```julia
julia> ignabool(Nullable{Bool}())
false

julia> ignabool(Nullable(true))
true

julia> ignabool(Nullable(false))
false

julia> ignabool(@nalift([true true NA;false NA true]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
  true   true  false
 false  false   true
```

"""
function ignabool end

ignabool(arr::AbstractArrayWrapper{Nullable{Bool}}) = AbstractArrayWrapper(ignabool(arr.a))
# this turns to be definitely faster than `map`.
ignabool(arr::AbstractArray{Nullable{Bool}}) = begin
  result = similar(arr, Bool)
  for i in eachindex(arr)
    @inbounds result[i] = ignabool(arr[i])
  end
  result
end
#ignabool(arr::AbstractArray{Nullable{Bool}}) = map_typed(ignabool, Bool, arr)
ignabool(elem::Nullable{Bool}) = !elem.isnull && elem.value
ignabool(arr::AbstractArray{Bool}) = arr
ignabool(elem::Bool) = elem

"""

`isna(arr [, coords...])`

Checks `NA` for each element and produces an AbstractArray{Bool} of the same shape as `arr`.
If `coords...` are provided, `isna` checks `NA` at that position.

* If an input array is `AbstractArray{Nullable{T}}`, it checkes whether an element is null.
* If an input array is `DictArray`, it tests whether all values of the dictionary values for each element are null.
* If an input array is `LabeledArray`, it applies `isna` to the base of `arr`.

##### Examples

```julia
julia> t = @darr(a=[1 NA 3;4 5 NA], b=[NA NA :z;:u :v :w])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1   |    |3 z 
4 u |5 v |  w 


julia> isna(t)
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false   true  false
 false  false  false

julia> isna(t, 2, 2:3)
1x2 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false  false

julia> isna(@larr(t, axis1[NA,:Y], axis2[NA,NA,"W"]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false   true  false
 false  false  false

julia> isna(@nalift([1 2 NA;NA 5 6]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false  false   true
  true  false  false
```

"""
function isna end

isna{T}(arr::AbstractArray{Nullable{T}}) = map(elem->elem.isnull, arr)
isna(arr::AbstractArray{Nullable}) = map(elem->elem.isnull, arr)
isna{T<:AbstractFloat}(arr::FloatNAArray{T}) = map(isnan, arr.data)
isna{T,N,A}(arr::AbstractArrayWrapper{T,N,A}) = AbstractArrayWrapper(isna(arr.a))
isna{T<:AbstractFloat}(arr::AbstractArray{Nullable{T}}) = map(elem->elem.isnull || isnan(elem.value), arr)
isna(x::Nullable) = x.isnull
isna(arr::AbstractArray, coords...) = isna(arr[coords...])

# this is a little bit out of place...
(==)(::AbstractArrayWrapper, ::DefaultAxis) = false
(==)(::DefaultAxis, ::AbstractArrayWrapper) = false
