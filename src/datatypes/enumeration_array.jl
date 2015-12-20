"""

An array type to store elements that have only a few choices.
That is, it is a pooled array.
Use `enumeration` to create an `EnumerationArray`.

"""
immutable EnumerationArray{T,N,V,R<:Integer} <: AbstractArray{Nullable{T},N}
  elems::V
  # element 0 in the `pool` member variable means `NA`.
  pool::Vector{T}
  # it can be confusing if T is Integer, if we do not combine elems and pool as a tuple.
  EnumerationArray(elems_pool::Tuple{V, Vector{T}}) = new(elems_pool[1], elems_pool[2])
end

EnumerationArray{T,V<:AbstractArray}(elems_pool::Tuple{V,Vector{T}}) = EnumerationArray{T,ndims(elems_pool[1]),typeof(elems_pool[1]),eltype(elems_pool[1])}((elems_pool[1], elems_pool[2]))
#EnumerationArray{R<:Integer,N,T}(elems::AbstractArray{R,N}, pool::Vector{T}) = EnumerationArray{T,N,typeof(elems),R}(elems, pool)
EnumerationArray{T,N,V,R<:Integer}(arr::EnumerationArray{T,N,V,R}, poolorder::AbstractVector{T}) = begin
  zeroR = zero(R)
  oneR = one(R)
  counter = R(length(poolorder))
  newpool = Array(T, length(arr.pool))
  ordermap = Array(R, length(arr.pool))
  copy!(newpool, poolorder)
  arrpool = arr.pool
  for i in eachindex(arrpool)
    if arr.pool[i] in poolorder
      ordermap[i] = R(findfirst(poolorder, arrpool[i]))
    else
      counter += oneR
      ordermap[i] = counter
      newpool[counter] = arrpool[i]
    end
  end
  newelems = map(i->ordermap[i], arr.elems)
  EnumerationArray{T,N,V,R}((newelems, newpool))
end
EnumerationArray{R<:Integer,T,N}(::Type{R}, arr::AbstractArray{Nullable{T},N}) = EnumerationArray(R, arr, T[])
EnumerationArray{R<:Integer,T,N}(::Type{R}, arr::AbstractArray{Nullable{T},N}, poolorder::AbstractVector{T}) = begin
  d = Dict{T,R}()
  zeroR = zero(R)
  oneR = one(R)
  counter = oneR
  for p in poolorder
    d[p] = counter
    counter += oneR
  end
  pool = Array(T, length(poolorder))
  copy!(pool, poolorder)
  elems = map(arr) do elem
    if elem.isnull
      zeroR
    elseif haskey(d, elem.value)
      d[elem.value]
    else
      d[elem.value] = counter
      push!(pool, elem.value)
      tempcounter = counter
      counter += oneR
      tempcounter
    end
  end
  EnumerationArray{T,N,typeof(elems),R}((elems, pool))
end
EnumerationArray{T,N}(arr::AbstractArray{Nullable{T},N}) = EnumerationArray(Int, arr)
EnumerationArray{T,N}(arr::AbstractArray{Nullable{T},N}, poolorder::AbstractVector{T}) = EnumerationArray(Int, arr, poolorder)
Base.size(arr::EnumerationArray) = size(arr.elems)
Base.getindex{T,N,V,R}(arr::EnumerationArray{T,N,V,R}, indices...) = begin
  elem = arr.elems[indices...]
  map_nullable(elem, arr.pool) #elem == zero(R) ? Nullable{T}() : Nullable(arr.pool[elem])
end
map_nullable{T,N,R}(elems::AbstractArray{R,N}, pool::Vector{T}) = #map(elem) do x
  #x == zero(R) ? Nullable{T}() : Nullable(pool[x])
  EnumerationArray((elems, pool))
#end
map_nullable{T,R}(elem::R, pool::Vector{T}) =
  elem == zero(R) ? Nullable{T}() : Nullable(pool[elem])

Base.eltype{T,N,V,R}(::Type{EnumerationArray{T,N,V,R}}) = Nullable{T}
Base.length(arr::EnumerationArray) = length(arr.elems)
Base.endof(arr::EnumerationArray) = length(arr)
Base.setindex!{T,N,V,R}(arr::EnumerationArray{T,N,V,R}, v::Nullable{T}, indices...) = begin
  if v.isnull
    setindex!(arr.elems, zero(R), indices...)
    arr
  else
    # note a T value that is not one of the pool values will be assigned to 0.
    # that is, it is treated as null.
    setindex!(arr.elems, R(findfirst(arr.pool, v.value)), indices...)
    arr
  end
end
Base.linearindexing{T,N,V,R}(::Type{EnumerationArray{T,N,V,R}}) = Base.linearindexing(V)
Base.reshape(arr::EnumerationArray, args::Tuple{Vararg{Int}}) = EnumerationArray((reshape(arr.elems, args), arr.pool))
Base.reshape(arr::EnumerationArray, args::Int...) = EnumerationArray((reshape(arr.elems, args...), arr.pool))
Base.reshape(arr::EnumerationArray, args...) = EnumerationArray((reshape(arr.elems, args...), arr.pool))
Base.transpose(arr::EnumerationArray, args...) = EnumerationArray((transpose(arr.elems, args...), arr.pool))
Base.permutedims(arr::EnumerationArray, args...) = EnumerationArray((permutedims(arr.elems, args...), arr.pool))
Base.repeat(arr::EnumerationArray, args...) = EnumerationArray((repeat(arr.elems, args...), arr.pool))
Base.sort(arr::EnumerationArray, args...) = EnumerationArray((sort(arr.elems, args...), arr.pool))
Base.sort!(arr::EnumerationArray, args...) = (sort!(arr.elems, args...); arr)
Base.cat(dim::Int, arr1::EnumerationArray, arrs::EnumerationArray...) = begin
  pool = arr1.pool
  for arr in arrs
    if pool != arr.pool
      throw(ArgumentError("cannot concatenate EnumerationArrays: the pools are different."))
    end
  end
  EnumerationArray((cat(dim, arr1.elems, map(x->x.elems, arrs)...), pool))
end
Base.vcat(arrs::EnumerationArray...) = cat(1, arrs...)
Base.hcat(arrs::EnumerationArray...) = cat(2, arrs...)
Base.sub(arr::EnumerationArray, args::Union{Base.Colon,Int,AbstractVector}...) = EnumerationArray((sub(arr.elems, args...), arr.pool))
Base.slice(arr::EnumerationArray, args::Union{Base.Colon,Int,AbstractVector}...) = EnumerationArray((slice(arr.elems, args...), arr.pool))
Base.reverse(arr::EnumerationArray, args...) = EnumerationArray((reverse(arr.elems, args...), arr.pool))


"""

`enumeration(arr [, poolorder])`

Create an `EnumerationArray`.

##### Arguments

* `arr`: an input array of `Nullable` element type. It is assumed that there are only a few possible values in `arr` and each value is converted into an integer when creating an `EnumerationArray`.
* `poolorder`: a vector to fix some of the integer values in the mapping from the values in `arr` to integers. If there are `n` elements in `poolorder`, those `n` elements in `arr` will be assigned 1...`n` when creating an `EnumerationArray`. All the others are assigned integers in order of their appearance.

##### Examples

```julia
julia> enumeration([:A,:A,:B,:B,:C])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)
 Nullable(:A)
 Nullable(:B)
 Nullable(:B)
 Nullable(:C)

julia> enumeration([:A,:A,:B,:B,:C]).pool
3-element Array{Symbol,1}:
 :A
 :B
 :C

julia> enumeration([:A,:A,:B,:B,:C]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 1
 2
 2
 3

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)
 Nullable(:A)
 Nullable(:B)
 Nullable(:B)
 Nullable(:C)

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B]).pool
3-element Array{Symbol,1}:
 :C
 :B
 :A

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 3
 3
 2
 2
 1
```

"""
function enumeration end

enumeration{T}(arr::AbstractArray{Nullable{T}}) = EnumerationArray(arr)
enumeration(arr::AbstractArray{Nullable}) = EnumerationArray(arr)
enumeration{T}(arr::AbstractArray{T}) = EnumerationArray(nalift(arr))
enumeration{T}(arr::AbstractArray{Nullable{T}}, poolorder::Vector{T}) = EnumerationArray(arr, poolorder)
enumeration{T}(arr::AbstractArray{Nullable}, poolorder::Vector{T}) = EnumerationArray(arr, poolorder)
enumeration(arr::AbstractArray, poolorder::Vector) = EnumerationArray(nalift(arr), poolorder)
enumeration(arr::AbstractArray, poolorder) = EnumerationArray(nalift(arr), collect(poolorder))

"""

`@enumeration(arr [, poolorder])`

Create an `EnumerationArray`. Similar to the `enumeration` function, but you can type in a null element using `NA`.

##### Arguments

* `arr`: an input array of `Nullable` element type. It is assumed that there are only a few possible values in `arr` and each value is converted into an integer when creating an `EnumerationArray`. `NA` is translated into a null element of appropriate type.
* `poolorder`: a vector to fix some of the integer values in the mapping from the values in `arr` to integers. If there are `n` elements in `poolorder`, those `n` elements in `arr` will be assigned 1...`n` when creating an `EnumerationArray`. All the others are assigned integers in order of their appearance.

##### Examples

```julia
julia> @enumeration([:A,:A,:B,NA,NA])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)      
 Nullable(:A)      
 Nullable(:B)      
 Nullable{Symbol}()
 Nullable{Symbol}()

julia> @enumeration([:A,:A,:B,NA,NA]).pool
2-element Array{Symbol,1}:
 :A
 :B

julia> @enumeration([:A,:A,:B,NA,NA]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 1
 2
 0
 0

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)      
 Nullable(:A)      
 Nullable(:B)      
 Nullable{Symbol}()
 Nullable{Symbol}()

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A]).pool
2-element Array{Symbol,1}:
 :B
 :A

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 2
 2
 1
 0
 0
```

"""

macro enumeration(args...)
  if length(args) == 1
    quote
      enumeration(@nalift($(esc(args[1]))))
    end
  elseif length(args) == 2
    quote
      enumeration(@nalift($(esc(args[1]))), $(esc(args[2])))
    end
  else
    error("cannot figure out what to do in this case yet: ", args...)
  end
end


