"""

`unique(arr, dims...)`

Return unique elements of an array `arr` of type `LabeledArray`/`DictArray`/`Nullable AbstractArrayWrapper`.

##### Arguments

* `arr` : an array
* `dims...` : either an integer or, if an array is a DictArray or a LabeledArray, a list of integers. It specifies the directions along which to traverse. Any duplicate elements will be replaced by Nullable{T}(). If all components along some direction are missing, those components will be removed and the whole array size will shrink.
If `dims...` is missing, unique elements along the whole directions will be found. It is equivalent to `unique(arr, 1, 2, ..., ndims(arr))`.
Note that it compares each slice spanned by directions orthogonal to `dims...`.

##### Examples

```julia
julia> unique(nalift([1 2 3;3 4 1]))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)
 Nullable(3)  Nullable(4)

julia> unique(nalift([1 2 3;3 4 1]), 1)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(3)  Nullable(4)  Nullable(1)

julia> unique(nalift([1 2 3;3 4 1]), 2)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(3)  Nullable(4)  Nullable(1)

julia> unique(nalift([1 2 3;1 2 3;4 5 6]), 1)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(4)  Nullable(5)  Nullable(6)

julia> t = darr(a=[1 2 1;1 5 1;1 2 1], b=[:a :b :a;:a :c :a;:a :b :a])
3 x 3 DictArray

a b |a b |a b 
----+----+----
1 a |2 b |1 a 
1 a |5 c |1 a 
1 a |2 b |1 a 


julia> unique(t, 1)
2 x 3 DictArray

a b |a b |a b 
----+----+----
1 a |2 b |1 a 
1 a |5 c |1 a 


julia> unique(t, 2)
3 x 2 DictArray

a b |a b 
----+----
1 a |2 b 
1 a |5 c 
1 a |2 b 


julia> m = larr(a=[1 2 1;1 5 1;1 2 1], b=[:a :b :a;:a :c :a;:a :b :a], axis1=["X","Y","Z"])
3 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 a |2 b |1 a 
Y |1 a |5 c |1 a 
Z |1 a |2 b |1 a 


julia> unique(m, 1)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 a |2 b |1 a 
Y |1 a |5 c |1 a 


julia> unique(m, 2)
3 x 2 LabeledArray

  |1   |2   
--+----+----
  |a b |a b 
--+----+----
X |1 a |2 b 
Y |1 a |5 c 
Z |1 a |2 b 
```

"""
Base.unique{T}(arr::AbstractArrayWrapper{Nullable{T}}) = unique(arr, 1:ndims(arr)...)
Base.unique(arr::DictArray, dim::Int, dims::Int...) = unique(arr, 1:ndims(arr)...)
Base.unique(arr::LabeledArray, dim::Int, dims::Int...) = unique(arr, 1:ndims(arr)...)
Base.unique{T}(arr::AbstractArrayWrapper{Nullable{T}}, dim::Int, dims::Int...) = unique_inner(arr, (dim, dims...))[2]
Base.unique(arr::DictArray, dim::Int, dims::Int...) = unique_inner(arr, (dim, dims...))[2]
Base.unique(arr::LabeledArray, dim::Int, dims::Int...) = begin
  dimall = (dim, dims...)
  (coords_toshow, newdata) = unique_inner(arr.data, dimall)
  newaxes = ntuple(length(arr.axes)) do d
    axis = arr.axes[d]
    if d in dimall
      coords = coords_toshow[findfirst(dimall, d)]
      if isa(axis, DefaultAxis)
        DefaultAxis(length(coords))
      else
        arr.axes[d][coords]
      end
    else
      arr.axes[d]
    end
  end
  LabeledArray(newdata, newaxes)
end

@generated unique_inner{N}(arr::DictArray, dims::NTuple{N,Int}) = quote
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  ndimsarr = ndims(arr)
  sizearr = size(arr)
  remainingdirs = filter(x->!(x in dims), 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dims...)
  permuted_arr = permutedims_if_necessary(arr, newdirs)
  elems_sofar = Set()
  axiselems_toshow = [falses(sizearr[dims[i]]) for i in 1:$N]
  result = similar(permuted_arr, eltype(permuted_arr))
  @nloops $N i d->1:sizearr[dims[d]] begin
    coords = @ntuple($N,i)
    full_coords = (remainingcoords...,coords...)
    oneslice = getindexvalue(permuted_arr, full_coords...)
    if oneslice in elems_sofar
      setna!(result, full_coords...)
    else
      push!(elems_sofar, oneslice)
      for (index,coord) in enumerate(coords)
        axiselems_toshow[index][coord] = true
      end
      result[full_coords...] = oneslice
    end
  end
  coords_toshow = [find(axiselems_toshow[i]) for i in 1:$N]
  (coords_toshow, ipermutedims_if_necessary(result[remainingcoords...,coords_toshow...], newdirs))
end

@generated unique_inner{T,N}(arr::AbstractArray{Nullable{T}}, dims::NTuple{N,Int}) = quote
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  ndimsarr = ndims(arr)
  sizearr = size(arr)
  remainingdirs = filter(x->!(x in dims), 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dims...)
  permuted_arr = permutedims_if_necessary(arr, newdirs)
  elems_sofar = Set()
  axiselems_toshow = [falses(sizearr[dims[i]]) for i in 1:$N]
  result = similar(permuted_arr, eltype(permuted_arr))
  @nloops $N i d->1:sizearr[dims[d]] begin
    coords = @ntuple($N,i)
    full_coords = (remainingcoords...,coords...)
    oneslice = permuted_arr[full_coords...]
    if oneslice in elems_sofar
      setna!(result, full_coords...)
    else
      push!(elems_sofar, oneslice)
      for (index,coord) in enumerate(coords)
        axiselems_toshow[index][coord] = true
      end
      result[full_coords...] = oneslice
    end
  end
  coords_toshow = [find(axiselems_toshow[i]) for i in 1:$N]
  (coords_toshow, ipermutedims_if_necessary(result[remainingcoords...,coords_toshow...], newdirs))
end
