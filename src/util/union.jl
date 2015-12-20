"""

`union(dim, arrs...)`

Take uinon of arrays of type `LabeledArray`/`DictArray`/`AbstractArrayrapper`. First start with the first array and remove any duplicate slices in there. Then concat the second array along the specified direction. However, skip any duplicate slices. Proceed similarly for the rest of the arrays.

##### Arguments

* `dim` : direction along which to concat.
* `arrs...` : arrays to unite.

##### Examples

```julia
julia> union(1, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
3x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(4)  Nullable(5)  Nullable(6)
 Nullable(5)  Nullable(5)  Nullable(6)

julia> union(2, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
2x4 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)  Nullable(1)
 Nullable(4)  Nullable(5)  Nullable(6)  Nullable(5)

julia> union(1, darr(a=[:x,:y,:z]), darr(a=[:x,:x,:u]), darr(a=[:v,:u,:y]))
5 DictArray

a 
--
x 
y 
z 
u 
v 


julia> union(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:Z,:Y]))
4 x 3 LabeledArray

  |1 |2 |3 
--+--+--+--
  |a |a |a 
--+--+--+--
X |1 |2 |3 
Y |4 |5 |6 
Z |1 |2 |3 
Y |4 |3 |2 
```

"""
Base.union(dim::Int, arr0::LabeledArray, arr_rest::LabeledArray...) = begin
  arrs = (arr0, arr_rest...)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  elems_sofar = Set()
  isdefaxis = isa(permuted_arrs[1].axes[ndimsarr], DefaultAxis)
  result_arrs = if isdefaxis
    map(permuted_arrs) do arr
      arrlastsize = size(arr, ndimsarr)
      coords_toshow = falses(arrlastsize)
      for i in 1:arrlastsize
        full_coords = (remainingcoords..., i)
        oneslice = getindexvalue(arr.data, full_coords...)
        if !(oneslice in elems_sofar)
          push!(elems_sofar, oneslice)
          coords_toshow[i] = true
        end
      end
      arr[remainingcoords..., coords_toshow]
    end
  else
    map(permuted_arrs) do arr
      arrlastsize = size(arr, ndimsarr)
      coords_toshow = falses(arrlastsize)
      for i in 1:arrlastsize
        full_coords = (remainingcoords..., i)
        oneslice = getindexvalue(arr.data, full_coords...)
        labels = arr.axes[ndimsarr][i]
        if !((oneslice,labels) in elems_sofar)
          push!(elems_sofar, (oneslice,labels))
          coords_toshow[i] = true
        end
      end
      arr[remainingcoords..., coords_toshow]
    end
  end
  ipermutedims_if_necessary(cat(ndimsarr, result_arrs...), newdirs)
end


Base.union(dim::Int, arr0::DictArray, arr_rest::DictArray...) = begin
  arrs = (arr0, arr_rest...)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  elems_sofar = Set()
  result_arrs = map(permuted_arrs) do arr
    arrlastsize = size(arr, ndimsarr)
    coords_toshow = falses(arrlastsize)
    for i in 1:arrlastsize
      full_coords = (remainingcoords..., i)
      oneslice = getindexvalue(arr, full_coords...)
      if !(oneslice in elems_sofar)
        push!(elems_sofar, oneslice)
        coords_toshow[i] = true
      end
    end
    arr[remainingcoords..., coords_toshow]
  end
  ipermutedims_if_necessary(cat(ndimsarr, result_arrs...), newdirs)
end

Base.union{T,U}(dim::Int,
                arr0::AbstractArrayWrapper{Nullable{T}},
                arr_rest::AbstractArrayWrapper{Nullable{U}}...) = begin
  arrs = (arr0, arr_rest...)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might be later optimized.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  elems_sofar = Set()
  result_arrs = map(permuted_arrs) do arr
    arrlastsize = size(arr, ndimsarr)
    coords_toshow = falses(arrlastsize)
    for i in 1:arrlastsize
      full_coords = (remainingcoords..., i)
      oneslice = getindex(arr, full_coords...)
      if !(oneslice in elems_sofar)
        push!(elems_sofar, oneslice)
        coords_toshow[i] = true
      end
    end
    arr[remainingcoords..., coords_toshow]
  end
  ipermutedims_if_necessary(cat(ndimsarr, result_arrs...), newdirs)
end
