import Base.==

"""

`intersect(dim, arrs...)`

Take intersection of arrays of type `LabeledArray`/`DictArray`/`AbstractArrayWrapper`. The order is preserved.

##### Arguments

* `dim` : direction along which to intersect.
* `arrs...` : arrays to intersect.

##### Examples

```julia
julia> intersect(1, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
1x3 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)

julia> intersect(2, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
2x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(2)  Nullable(3)
 Nullable(5)  Nullable(6)

julia> intersect(1, darr(a=[:x,:y,:z]), darr(a=[:x,:x,:y]), darr(a=[:y,:y,:y]))
1 DictArray

a 
--
y 


julia> intersect(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:X,:Y]))
1 x 3 LabeledArray

  |1 |2 |3 
--+--+--+--
  |a |a |a 
--+--+--+--
X |1 |2 |3 


julia> intersect(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:Z,:Y]))
0 x 3 LabeledArray

 |1 |2 |3 
-+--+--+--
 |a |a |a 
```

"""
Base.intersect(dim::Integer, arr0::LabeledArray, arr_rest::LabeledArray...) = begin
  arrs = (arr0, arr_rest...)
  # first rearrange the axes so that the calculatioin can be more convenient.
  # this might need to be optimized later.
  # all arrays will be of the same dimensions.
  ndimsarr = ndims(arrs[1])
  remainingdirs = filter(x->x != dim, 1:ndimsarr)
  remainingcoords = ntuple(d->Colon(), length(remainingdirs))
  newdirs = (remainingdirs...,dim)
  permuted_arrs = map(arr->permutedims_if_necessary(arr, newdirs), arrs)
  elems = Dict{Any,Int}()
  isdefaxis = isa(permuted_arrs[1].axes[ndimsarr], DefaultAxis)
  permuted_arrs1 = permuted_arrs[1]
  lastsize = size(permuted_arrs[1], ndimsarr)

  # certainly, this logic is suboptimal...
  if isdefaxis
    for i in 1:lastsize
      full_coords = (remainingcoords..., i)
      # using getindexvalue would have caused the NullException() in the intersect call below.
      # TODO: need to make this intersect method type stable.
      oneslice = getindex(permuted_arrs1.data, full_coords...)
      #push!(elems, oneslice => i)
      if !haskey(elems, oneslice)
        elems[oneslice] = i
      end
    end
  else
    for i in 1:lastsize
      full_coords = (remainingcoords..., i)
      oneslice = getindex(permuted_arrs1.data, full_coords...)
      labels = permuted_arrs1.axes[ndimsarr][i]
      #push!(elems, (oneslice,dummy_nullable_wrap_if_necessary(labels)) => i)
      k = (oneslice,dummy_nullable_wrap_if_necessary(labels))
      if !haskey(elems, k)
        elems[k] = i
      end
    end
  end

  result_arrs = if isdefaxis
    map(permuted_arrs) do arr
      map(1:size(arr, ndimsarr)) do i
        full_coords = (remainingcoords..., i)
        getindex(arr.data, full_coords...)
      end
    end
  else
    map(permuted_arrs) do arr
      map(1:size(arr, ndimsarr)) do i
        full_coords = (remainingcoords..., i)
        oneslice = getindex(arr.data, full_coords...)
        labels = arr.axes[ndimsarr][i]
        (oneslice, dummy_nullable_wrap_if_necessary(labels))
      end
    end
  end
  intersect_slices = intersect(result_arrs...)
  coords_toshow = [elems[slice] for slice in intersect_slices]
  result = permuted_arrs[1][remainingcoords..., coords_toshow]
  permutedims_if_necessary(result, invperm(newdirs))
end

# this is to avoid null exception in doing intersect.
immutable DummyNullableWrapper{T<:Nullable}
  x::T
end

(==)(x::DummyNullableWrapper, y::DummyNullableWrapper) = isnull(x.x) && isnull(y.x) || ignabool(naop_eq(x.x, y.x))

dummy_nullable_wrap_if_necessary(x::Nullable) = DummyNullableWrapper(x)
dummy_nullable_wrap_if_necessary(x) = x

Base.intersect(dim::Int, arr0::DictArray, arr_rest::DictArray...) = begin
  arrs = (arr0, arr_rest...)
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
  intersect_slices = intersect(result_arrs...)
  result = similar(permuted_arrs[1],
                   (size(permuted_arrs[1])[1:end-1]...,
                    length(intersect_slices)))
  for (i,arr) in enumerate(intersect_slices)
    result[remainingcoords...,i] = arr
  end
  permutedims_if_necessary(result, invperm(newdirs))
end

Base.intersect{T,U}(dim::Int,
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
  result_arrs = map(permuted_arrs) do arr
    map(1:size(arr, ndimsarr)) do i
      full_coords = (remainingcoords..., i)
      getindex(arr, full_coords...)
    end
  end
  intersect_slices = intersect(result_arrs...)
  result = similar(permuted_arrs[1],
                   (size(permuted_arrs[1])[1:end-1]...,
                    length(intersect_slices)))
  #                 (size(result_arrs[1])..., length(intersect_slices)))
  for (i,arr) in enumerate(intersect_slices)
    result[remainingcoords...,i] = arr
  end
  permutedims_if_necessary(result, invperm(newdirs))
end
