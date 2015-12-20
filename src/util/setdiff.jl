"""

`setdiff(dim, arr1, arr2)`

Take difference of two arrays of type `LabeledArray`/`DictArray`/`AbstractArrayWrapper`.
The order is preserved in the sense that the first array order is kept except that only duplicate elements in the first array have been removed.

##### Arguments

* `dim` : direction along which to concat.
* `arr1` : array 1.
* `arr2` : array 2. The return value is array1 - array2, where arrays are treated as sets.

##### Examples

```julia
julia> setdiff(1, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
1x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(4)  Nullable(5)  Nullable(6)

julia> setdiff(2, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
2x1 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)
 Nullable(4)

julia> setdiff(1, darr(a=[:x,:y,:z]), darr(a=[:x,:x,:u]))
2 DictArray

a 
--
y 
z 


julia> setdiff(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:X,:Y]))
1 x 3 LabeledArray

  |1 |2 |3 
--+--+--+--
  |a |a |a 
--+--+--+--
Y |4 |5 |6 


julia> setdiff(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:Z,:Y]))
2 x 3 LabeledArray

  |1 |2 |3 
--+--+--+--
  |a |a |a 
--+--+--+--
X |1 |2 |3 
Y |4 |5 |6 
```

"""
Base.setdiff(dim::Int, arr1::LabeledArray, arr2::LabeledArray) = begin
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  arrs = (arr1, arr2)
  ndimsarr = ndims(arr1)
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  elems = Dict{Any,Int}()
  isdefaxis = isa(permuted_arrs[1].axes[ndimsarr], DefaultAxis)
  permuted_arrs1 = permuted_arrs[1]
  lastsize = size(permuted_arrs[1], ndimsarr)
  if isdefaxis
    for i in 1:lastsize
      full_coords = (remainingcoords..., i)
      oneslice = getindexvalue(permuted_arrs1.data, full_coords...)
      push!(elems, oneslice => i)
    end
  else
    for i in 1:lastsize
      full_coords = (remainingcoords..., i)
      oneslice = getindexvalue(permuted_arrs1.data, full_coords...)
      labels = permuted_arrs1.axes[ndimsarr][i]
      push!(elems, (oneslice,labels) => i)
    end
  end
  if isdefaxis
    parrs2 = permuted_arrs[2]
    for i in 1:size(parrs2,ndimsarr)
      slice = getindexvalue(parrs2.data, remainingcoords..., i)
      if haskey(elems, slice)
        delete!(elems, slice)
      end
    end
  else
    parrs2 = permuted_arrs[2]
    for i in 1:size(parrs2,ndimsarr)
      slice = getindexvalue(parrs2.data, remainingcoords..., i)
      labels = parrs2.axes[ndimsarr][i]
      pair = (slice, labels)
      if haskey(elems, pair)
        delete!(elems, pair)
      end
    end
  end
  #setdiff_slices = setdiff(result_arrs...)
  coords_toshow = sort(collect(values(elems))) #[elems[slice] for slice in setdiff_slices]
  result = permuted_arrs[1][remainingcoords..., coords_toshow]
  ipermutedims_if_necessary(result, newdirs)
end


Base.setdiff(dim::Int, arr1::DictArray, arr2::DictArray) = begin
  arrs = (arr1, arr2)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  result_arrs = map(permuted_arrs) do arr
    map(1:size(arr, ndimsarr)) do i
      full_coords = (remainingcoords..., i)
      getindex(arr, full_coords...)
    end
  end
  setdiff_slices = setdiff(result_arrs...)
  result = similar(permuted_arrs[1],
                   (size(permuted_arrs[1])[1:end-1]...,
                    length(setdiff_slices)))
  for (i,arr) in enumerate(setdiff_slices)
    result[remainingcoords...,i] = arr
  end
  ipermutedims_if_necessary(result, newdirs)
end

Base.setdiff{T,U}(dim::Int,
                  arr1::AbstractArrayWrapper{Nullable{T}},
                  arr2::AbstractArrayWrapper{Nullable{U}}) = begin
  arrs = (arr1, arr2)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  result_arrs = map(permuted_arrs) do arr
    map(1:size(arr, ndimsarr)) do i
      full_coords = (remainingcoords..., i)
      getindex(arr, full_coords...)
    end
  end
  setdiff_slices = setdiff(result_arrs...)
  result = similar(permuted_arrs[1],
                   (size(permuted_arrs[1])[1:end-1]...,
                    length(setdiff_slices)))
  for (i,arr) in enumerate(setdiff_slices)
    result[remainingcoords...,i] = arr
  end
  ipermutedims_if_necessary(result, newdirs)
end
