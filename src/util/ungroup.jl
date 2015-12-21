"""

`ungroup(arr, ...)`

Ungroup array elements in an array into scalar elements along some direction.

##### Arguments

* `arr` : an array.
* `...` can be `axis`, `indices`, or `ref_field` : either an axis index along which to ungroup, a range tuple coordinates of the form `(i_1,...,i_k,:,i_{k+1},...,i_n)` for some integer i's, or the selected elements of `arr` after applying those types of tuples.

##### Return

An ungrouped array of the same type as `arr`. If `arr` is `LabeledArray`, the axis along the ungrouping direction will become a new field (a generic field name is provided if it was not a `DictArray` axis.

##### Examples

```julia
julia> t = larr(a=Any[[1,2,3],[4,5]], b=[:x,:x], c=Any[[11,12,13],[14,15]], axis1=[:X,:Y])
2 LabeledArray

  |a       b c          
--+---------------------
X |[1,2,3] x [11,12,13] 
Y |[4,5]   x [14,15]    


julia> ungroup(t, 1)
5 LabeledArray

  |x1 a b c  
--+----------
1 |X  1 x 11 
2 |X  2 x 12 
3 |X  3 x 13 
4 |Y  4 x 14 
5 |Y  5 x 15 


julia> ungroup(t, (:,1))
5 LabeledArray

  |x1 a b c  
--+----------
1 |X  1 x 11 
2 |X  2 x 12 
3 |X  3 x 13 
4 |Y  4 x 14 
5 |Y  5 x 15 


julia> m = nalift(reshape(Any[[1,2],[3,4],[5,6,7],[8,9,10]],2,2))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},2,Array{Nullable{Array{Int64,1}},2}}:
 Nullable([1,2])  Nullable([5,6,7]) 
 Nullable([3,4])  Nullable([8,9,10])

julia> ungroup(m, 2)
2x5 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(5)  Nullable(6)  Nullable(7) 
 Nullable(3)  Nullable(4)  Nullable(8)  Nullable(9)  Nullable(10)
```

"""
function ungroup end

ungroup(arr::AbstractArray, ref_field::AbstractArray) = begin
  (cumsum, offsets) = create_ungroup_offsets(ref_field)
  # the total length of the final ungrouped array will be cumsum-1.
  ungroup(arr, ref_field, cumsum, offsets)
end
ungroup(arr::AbstractArray, indices::Tuple) = ungroup(arr, arr[indices...])
ungroup(arr::AbstractArray, axis::Integer) =
  ungroup(arr, ntuple(d->d==axis ? Colon() :
                          d>axis ? 1 :
                          (1:1), ndims(arr)))

create_ungroup_offsets(ref_field::AbstractArray) = begin
  lenref = length(ref_field)
  offsets = Array(Int, lenref + 1)
  cumsum = 1
  for i in 1:lenref
    @inbounds offsets[i] = cumsum
    @inbounds cumsum += length(ref_field[i].value)
  end
  offsets[lenref+1] = cumsum
  (cumsum, offsets)
end

@generated ungroup{N,M}(arr::AbstractArray{TypeVar(:T),N}, ref_field::AbstractArray{TypeVar(:U),M}, cumsum::Int, offsets::Vector{Int}) = begin
  isym = symbol("i_", M)
  quote
    if length(arr) == 0
      error("not yet determined: what to do when ungrouping an empty array?")
    end
    sizearr = size(arr)
    resultsize = ntuple(ndims(arr)) do d
      if d == $M
        cumsum-1
      else
        sizearr[d]
      end
    end
    elemtype = peel_nullabletype(eltype(arr))
    if elemtype <: AbstractArray
      result = similar(arr, eltype(elemtype), resultsize)
      @nloops $N i arr begin
        elem = (@nref $N arr i).value
        m_coord = offsets[$isym]
        next_m_coord = offsets[$isym + 1]
        m_coord_len = next_m_coord-m_coord
        if m_coord_len != length(elem)
          error("ungroup error: lengths do not match.")
        end
        for j in 1:m_coord_len
          @nref($N, result, k->k==$M ? m_coord+j-1 : i_k) = elem[j]
        end
      end
      wrap_array(nalift(result))
    elseif isa(arr[1].value, AbstractArray)
      # this is when the types are mixed.
      result = similar(arr, Any, resultsize)
      @nloops $N i arr begin
        elem = (@nref $N arr i).value
        m_coord = offsets[$isym]
        next_m_coord = offsets[$isym + 1]
        m_coord_len = next_m_coord-m_coord
        if m_coord_len != length(elem)
          error("ungroup error: lengths do not match.")
        end
        for j in 1:m_coord_len
          @nref($N, result, k->k==$M ? m_coord+j-1 : i_k) = elem[j]
        end
      end
      simplify_array(nalift(result))
    else
      # this is not an element of an array type.
      result = similar(arr, resultsize)
      @nloops $N i arr begin
        elem = (@nref $N arr i).value
        m_coord = offsets[$isym]
        next_m_coord = offsets[$isym + 1]
        for j in 1:next_m_coord-m_coord
          @nref($N, result, k->k==$M ? m_coord+j-1 : i_k) = elem
        end
      end
      wrap_array(result)
    end
  end
end

ungroup(arr::DictArray, ref_field::AbstractArray) =
  DictArray(LDict(arr.data.keys, map(v->ungroup(v, ref_field), arr.data.values)))
ungroup(arr::DictArray, indices::Tuple) = begin
  if length(arr) == 0
    ungroup(arr, [])
  end
  for v in arr.data.values
    if typeof(v[1].value) <: AbstractArray
      return ungroup(arr, v[indices...])
    end
  end
  error("ungroup a DictArray: cannot find an array component whose elements are also arrays.")
end

ungroup(arr::LabeledArray, ref_field::AbstractArray) = begin
  newdata0 = ungroup(arr.data, ref_field)
  axis_index = ndims(ref_field)
  theaxis = arr.axes[axis_index]
  newdata = if isa(theaxis, DefaultAxis)
    newdata0
  else
    ungrouped_axis = if isa(theaxis, DictArray)
      DictArray(LDict(theaxis.data.keys, map(elem->ungroup(BroadcastAxis(elem, arr, axis_index), ref_field), theaxis.data.values)))
    else
      DictArray(create_additional_fieldname(arr) => ungroup(BroadcastAxis(arr.axes[axis_index], arr, axis_index), ref_field))
    end
    newdata = DictArray(LDict([ungrouped_axis.data.keys;newdata0.data.keys],
                              [ungrouped_axis.data.values;newdata0.data.values]))
  end
  newaxes = ntuple(ndims(arr)) do d
    if d == axis_index
      DefaultAxis(size(newdata)[d])
    else
      arr.axes[d]
    end
  end
  LabeledArray(newdata, newaxes)
end

ungroup(arr::LabeledArray, indices::Tuple) = begin
  if length(arr) == 0
    ungroup(arr, [])
  end
  for v in arr.data.data.values
    if typeof(v[1].value) <: AbstractArray
      return ungroup(arr, v[indices...])
    end
  end
  error("ungroup a LabeledArray: cannot find an array component whose elements are also arrays.")
end


