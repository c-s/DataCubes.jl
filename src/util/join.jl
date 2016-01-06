"""

`leftjoin(base, src, join_axis...)`

Left join a `LabeledArray` into another `LabeledArray`.
Note that the left array (base) can be multidimensional. The function creates a dictionary from the right array (`src`).

##### Arguments

* `base` : the left `LabeledArray`.
* `src` : the right `LabeledArray`.
* `join_axes...` can be one of the following forms:
    * integers for the directions in `src` along which to join. In this case, the keys is the `base` side are found by matching the field names in the join directions in `src` with those in `base`.
    * a list of integer=>integer or integer=>vector of arrays, each of the same shape as `base`.

Ultimately, `join_axes...` produces pairs of direction in `src` => vector of arrays, each of the shape of `base`. If the value in key=>value is an integer, the axis along that direction in `base` is taken, after broadcast. The field values are combined into a vector of arrays. If the right hand side is missing (i.e. just an integer), the field names in the axis along the integer direction are used to create an array for `base`.

##### Return

A left joined `LabeledArray`. The join is performed as follows: Given an `i=>arr` form as an element in `join_axes`, the keys in `i`th direction in `src` are used as keys and `arr` are used the keys in the `base` side to left join. The values will be the sliced subarrays for each value in the `join_axes`. Note that `join_axis...` chooses multiple axes for keys.
The output number of dimensions is `ndims(base) + ndims(src) - length(join_axes)`.
Note that when `join_axis` is empty, the result is the tensor product of `base` and `src` from `tensorprod`.

##### Examples

```julia
julia> b = larr(k=[:x :x :y;:z :u :v], axis1=[:x,:y], axis2=darr(r=[:x, :y, :z]))
2 x 3 LabeledArray

r |x |y |z 
--+--+--+--
  |k |k |k 
--+--+--+--
x |x |x |y 
y |z |u |v 


julia> s = larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6])
6 LabeledArray

k |b 
--+--
x |1 
y |2 
z |3 
m |4 
n |5 
p |6 


julia> leftjoin(b, s, 1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 2 
y |z 3 |u   |v   


julia> leftjoin(b, s, 1=>1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 1 
y |z 2 |u 2 |v 2 


julia> leftjoin(b, s, 1=>Any[nalift([:x :z :n;:y :m :p])])
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 3 |y 5 
y |z 2 |u 4 |v 6 
```

"""
function leftjoin end

leftjoin{N}(base::LabeledArray{TypeVar(:V),N}, src::LabeledArray, join_axes::Int...) = begin
  # needs to find corresponding fields in base, so src axes for joining should be DictArray.
  for axis_index in join_axes
    @assert isa(src.axes[axis_index], DictArray)
  end
  base_key_arrays = AbstractArray{TypeVar(:V),N}[]
  for axis_index in join_axes
    for field in src.axes[axis_index].data.keys
      push!(base_key_arrays, selectfield(base, field))
    end
  end
  perform_leftjoin(base, src, (base_key_arrays...), join_axes)
end

leftjoin(base::LabeledArray, src::LabeledArray) = tensorprod(base, src)

leftjoin(base::DictArray, src::LabeledArray, join_axes::Int...) = leftjoin(LabeledArray(base), src, join_axes...)
leftjoin(base::DictArray, src::LabeledArray) = leftjoin(LabeledArray(base), src)
leftjoin(base::DictArray, src::LabeledArray, join_pairs::Pair{Int}...) = leftjoin(LabeledArray(base), src, join_pairs...)

leftjoin{N}(base::LabeledArray{TypeVar(:V),N}, src::LabeledArray, join_pairs::Pair{Int}...) = begin
  join_axes = Int[join_pair[1] for join_pair in join_pairs]
  axis_labeled_src = LabeledArray(src.data, ntuple(length(src.axes)) do d
    srcaxesd = src.axes[d]
    if in(d, join_axes) && !isa(srcaxesd, DictArray)
      create_dictarray_nocheck(create_ldict_nocheck(:dummy => srcaxesd))
    else
      srcaxesd
    end
  end)
  base_key_arrays = AbstractArray{TypeVar(:V),N}[]
  for (axis_index, axis_values0) in join_pairs
    axis_values = lift_axis_values0_helper1(axis_values0, base, src.axes[axis_index])
    push!(base_key_arrays, axis_values...)
  end
  perform_leftjoin(base, axis_labeled_src, (base_key_arrays...), (join_axes...))
end

lift_axis_values0_helper1(axis_values0::Integer, base, srcaxis) = lift_axis_values0_helper2(BroadcastAxis(base.axes[axis_values0], base, axis_values0), srcaxis)
lift_axis_values0_helper1(axis_values0::DictArray, base, srcaxis) = values(axis_values0)
lift_axis_values0_helper1(axis_values0, base, srcaxis) = axis_values0

lift_axis_values0_helper2(arr::DictArray, srcaxis::DictArray) = begin
  if keys(srcaxis) != keys(arr)
    throw(ArgumentError("field names do not match: $(keys(srcaxis)) vs $(keys(arr))"))
  end
  values(arr)
end
lift_axis_values0_helper2(arr::DictArray, srcaxis) = values(arr)
lift_axis_values0_helper2(arr, srcaxis) = Any[arr]

@generated perform_leftjoin{N,M,L,K}(base::LabeledArray{TypeVar(:T),N},
               src::LabeledArray{TypeVar(:U),M},
               base_key_arrays::NTuple{L,AbstractArray{TypeVar(:V),N}},
               src_key_axis_indices::NTuple{K,Int},
               concat_function::Function=default_concat_array_function) = begin
  rest_dims = M - K
  quote
    @assert $L == sum(i->length(src.axes[i].data), src_key_axis_indices)
    rest_src_axis_indices = filter(i->!(i in src_key_axis_indices), 1:$M) #length(src.axes))
    new_src_indices_ordering = [rest_src_axis_indices...;src_key_axis_indices...]
    permuted_src = permutedims_if_necessary(src, (new_src_indices_ordering...))
    src_axis_index_offset = length(rest_src_axis_indices)
    bymaps = ntuple($K) do i
      axis = permuted_src.axes[i+src_axis_index_offset] #src_key_axis_indices[i]]
      create_join_bymap(axis, Tuple{[eltype(v) for v in axis.data.values]...})
    end
    offset = 1
    bymaps_tuple_positions = ntuple($K) do i
      r = length(src.axes[i+src_axis_index_offset].data)
      offset0 = offset
      offset += r
      offset0
    end
    base_to_src_loc_map = similar(base_key_arrays[1], NTuple{K,Int})
    create_base_to_src_loc_map_all!(base_to_src_loc_map, base_key_arrays, ntuple(d->0,length(base_key_arrays)), bymaps_tuple_positions, bymaps)
    extra_dims = ntuple(d->length(permuted_src.axes[d]), $rest_dims)
    extra_axes = ntuple(d->permuted_src.axes[d], $rest_dims)
    src_mapped_to_base = LabeledArray(similar(src.data, (size(base_to_src_loc_map)...,extra_dims...)), (base.axes...,extra_axes...))
    srctobasedata = src_mapped_to_base.data
    permutedsrcdata = permuted_src.data

    fill_srctobasedata_join_helper!(srctobasedata, base_to_src_loc_map, permutedsrcdata)

    lifted_base = expand_dims(base, (), extra_axes)
    concat_function(lifted_base, src_mapped_to_base)
  end
end


"""

`innerjoin(base, src, join_axis...)`

Inner join an LabeledArray into another LabeledArray. `innerjoin` is different from `leftjoin` in that only elements in the left array that have the corresponding elements in the right array will be kept. Otherwise, the elements will be set to null. If the entire elements along some direction are null, they will be all removed in the output.
Note that the left array (base) can be multidimensional. The function creates a dictionary from the right array (`src`).

##### Arguments

* `base` : the left `LabeledArray`.
* `src` : the right `LabeledArray`.
* `join_axes...` can be one of the following forms:
    * integers for the directions in `src` along which to join.
    * a list of integer=>integer or integer=>vector of arrays, each array of the same shape as `base`.

Ultimately, `join_axes...` produces pairs of direction in `src` => vector of arrays, each of the shape of `base`. If the value in key=>value is an integer, the axis along that direction in `base` is taken, after broadcast. The field values are combined into a vector of arrays. If the right hand side is missing (i.e. just an integer), the field names in the axis along the integer direction are used to create an array for `base`.

##### Return

An inner joined `LabeledArray`. The join is performed as follows: Given an `i=>arr` form as an element in `join_axes`, the keys in `i`th direction in `src` are used as keys and `arr` are used the keys in the `base` side to inner join. The values will be the sliced subarrays for each value in the `join_axes`. Note that `join_axis...` chooses multiple axes for keys.
The output number of dimensions is `ndims(base) + ndims(src) - length(join_axes)`.
Note that when `join_axis` is empty, the result is the tensor product of `base` and `src` from `tensorprod`.

##### Examples

```julia
julia> b = larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z]))
2 x 3 LabeledArray

r |x |y |z 
--+--+--+--
  |k |k |k 
--+--+--+--
x |x |x |y 
u |z |u |v 


julia> s = larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6])
6 LabeledArray

k |b 
--+--
x |1 
y |2 
z |3 
m |4 
n |5 
p |6 


julia> innerjoin(b, s, 1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 2 
u |z 3 |u   |v   


julia> innerjoin(b, s, 1=>1)
1 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 1 


julia> innerjoin(b, s, 1=>Any[nalift([:o :x :x;:q :r :y])])
2 x 2 LabeledArray

r |y   |z   
--+----+----
  |k b |k b 
--+----+----
x |x 1 |y 1 
u |u   |v 2 
```

"""
function innerjoin end

innerjoin{N}(base::LabeledArray{TypeVar(:V),N}, src::LabeledArray, join_axes::Int...) = begin
  # needs to find corresponding fields in base, so src axes for joining should be DictArray.
  for axis_index in join_axes
    @assert isa(src.axes[axis_index], DictArray)
  end
  base_key_arrays = AbstractArray{TypeVar(:V),N}[]
  for axis_index in join_axes
    for field in src.axes[axis_index].data.keys
      push!(base_key_arrays, selectfield(base, field))
    end
  end
  perform_innerjoin(base, src, (base_key_arrays...), join_axes)
end
innerjoin(base::LabeledArray, src::LabeledArray) = tensorprod(base, src)

innerjoin(base::DictArray, src::LabeledArray, join_axes::Int...) = innerjoin(LabeledArray(base), src, join_axes...)
innerjoin(base::DictArray, src::LabeledArray) = innerjoin(LabeledArray(base), src)
innerjoin(base::DictArray, src::LabeledArray, join_pairs::Pair{Int}...) = innerjoin(LabeledArray(base), src, join_pairs...)

innerjoin{N}(base::LabeledArray{TypeVar(:V),N}, src::LabeledArray, join_pairs::Pair{Int}...) = begin
  join_axes = Int[join_pair[1] for join_pair in join_pairs]
  axis_labeled_src = LabeledArray(src.data, ntuple(length(src.axes)) do d
    srcaxesd = src.axes[d]
    if in(d, join_axes) && !isa(srcaxesd, DictArray)
      create_dictarray_nocheck(create_ldict_nocheck(:dummy => srcaxesd))
    else
      srcaxesd
    end
  end)
  base_key_arrays = AbstractArray{TypeVar(:V),N}[]
  for (axis_index, axis_values0) in join_pairs
    axis_values = lift_axis_values0_helper1(axis_values0, base, src.axes[axis_index])
    push!(base_key_arrays, axis_values...)
  end
  perform_innerjoin(base, axis_labeled_src, (base_key_arrays...), (join_axes...))
end


@generated perform_innerjoin{N,M,L,K}(base::LabeledArray{TypeVar(:T),N},
               src::LabeledArray{TypeVar(:U),M},
               base_key_arrays::NTuple{L,AbstractArray{TypeVar(:V),N}},
               src_key_axis_indices::NTuple{K,Int},
               concat_function::Function=default_concat_array_function) = begin
  rest_dims = M - K
  quote
    @assert $L == sum(i->length(src.axes[i].data), src_key_axis_indices)
    rest_src_axis_indices = filter(i->!(i in src_key_axis_indices), 1:$M) #length(src.axes))
    new_src_indices_ordering = [rest_src_axis_indices...;src_key_axis_indices...]
    permuted_src = permutedims(src, (new_src_indices_ordering...))
    src_axis_index_offset = length(rest_src_axis_indices)
    bymaps = ntuple($K) do i
      axis = permuted_src.axes[i+src_axis_index_offset] #src_key_axis_indices[i]]
      create_join_bymap(axis, Tuple{[eltype(v) for v in axis.data.values]...})
    end
    offset = 1
    bymaps_tuple_positions = ntuple($K) do i
      r = length(src.axes[i+src_axis_index_offset].data)
      offset0 = offset
      offset += r
      offset0
    end
    base_to_src_loc_map_all = similar(base_key_arrays[1], NTuple{K,Int})
    create_base_to_src_loc_map_all!(base_to_src_loc_map_all, base_key_arrays, ntuple(d->0,length(base_key_arrays)), bymaps_tuple_positions, bymaps)
    base_axes_to_display = ntuple(d->falses(size(base,d)), $N)
    join_helper_populate_base_axes_to_display!(base_axes_to_display, base_to_src_loc_map_all)
    base_to_src_loc_map = base_to_src_loc_map_all[base_axes_to_display...]
    extra_dims = ntuple(d->length(permuted_src.axes[d]), $rest_dims)
    extra_axes = ntuple(d->permuted_src.axes[d], $rest_dims)
    src_mapped_to_base = LabeledArray(similar(src.data, (size(base_to_src_loc_map)...,extra_dims...)),
                                      ([axis[base_axes_to_display[i]] for (i,axis) in enumerate(base.axes)]...,extra_axes...))
    srctobasedata = src_mapped_to_base.data
    permutedsrcdata = permuted_src.data
    fill_srctobasedata_join_helper!(srctobasedata, base_to_src_loc_map, permutedsrcdata)

    lifted_base = expand_dims(base[base_axes_to_display...], (), extra_axes)
    concat_function(lifted_base, src_mapped_to_base)
  end
end

@generated join_helper_populate_base_axes_to_display!{T,K,N}(base_axes_to_display::T,
                                                             base_to_src_loc_map_all::AbstractArray{NTuple{K,Int},N}) = quote
  @nloops $N i base_to_src_loc_map_all begin
    if @nref($N,base_to_src_loc_map_all,i)[1] > 0
      @nexprs $N j->(base_axes_to_display[j][i_j] = true)
    end
  end
end

@generated fill_srctobasedata_join_helper!{N,K,MKN,M}(srctobasedata::AbstractArray{TypeVar(:KK),MKN},
                                                      base_to_src_loc_map::AbstractArray{NTuple{K,Int},N},
                                                      permutedsrcdata::AbstractArray{TypeVar(:TT),M}) = begin
  rest_dims = M - K
  @assert(MKN == M-K+N)
  quote
    @nloops $N i base_to_src_loc_map begin
      src_coords = @nref($N,base_to_src_loc_map,i)
      if src_coords[1] == 0
        setna!(srctobasedata, @ntuple($N,i)..., @ntuple($rest_dims, d->Colon())...)
      else
        setindex_nocheck!(srctobasedata, @nref($M,permutedsrcdata,d->d<=$rest_dims ? Colon() : src_coords[d-$rest_dims]), @ntuple($N,i)...,@ntuple($rest_dims,d->Colon())...)
      end
    end
  end
end

fill_srctobasedata_join_helper!{N,K,MKN,M}(srctobasedata::DictArray{TypeVar(:KK),MKN},
                                           base_to_src_loc_map::AbstractArray{NTuple{K,Int},N},
                                           permutedsrcdata::DictArray{TypeVar(:TT),M}) = begin
  for i in eachindex(srctobasedata.data.values, permutedsrcdata.data.values)
    fill_srctobasedata_join_helper!(srctobasedata.data.values[i], base_to_src_loc_map, permutedsrcdata.data.values[i])
  end
end

create_join_bymap{T}(axis::DictArray, ::Type{T}) = begin
  result = Dict{T,Int}()
  for i in 1:length(axis)
    result[getindexvalue(axis,i)] = i
  end
  result
end

@generated create_base_to_src_loc_map_all!{N,L,V1,A}(result::AbstractArray{NTuple{1,Int},N},
                                      base_key_arrays::A, #NTuple{L}, #::NTuple{L,AbstractArray{TypeVar(:V),N}},
                                      ::NTuple{L,Int},
                                      bymaps_tuple_positions::NTuple{1,Int},
                                      bymaps::Tuple{Dict{V1,Int}}) = quote
  zerocoords = (0,) # K=1
  bymaps1::Dict{V1,Int} = bymaps[1]
  for i in eachindex(result, base_key_arrays...)
    k::V1 = @ntuple $L d->base_key_arrays[d][i]
    result[i] = if haskey(bymaps1, k)
      (bymaps1[k],)
    else
      zerocoords
    end
  end
end

@generated create_base_to_src_loc_map_all!{K,N,L,A}(result::AbstractArray{NTuple{K,Int},N},
                                    base_key_arrays::A, #::NTuple{L}, #::NTuple{L,AbstractArray{TypeVar(:V),N}},
                                    ::NTuple{L,Int},
                                    bymaps_tuple_positions::NTuple{K,Int},
                                    bymaps) = quote
  zerocoords = ntuple(k->0, $K)
  for i in eachindex(result, base_key_arrays...)
    base_indices = @ntuple $L d->base_key_arrays[d][i]
    na_flag = false
    src_coords = ntuple($K) do i
      k = base_indices[bymaps_tuple_positions[i]:(i==$K ? L:bymaps_tuple_positions[i+1]-1)]
      bymapsi = bymaps[i]
      if haskey(bymapsi, k)
        bymapsi[k]
      else
        na_flag = true
        0
      end
    end
    result[i] = if na_flag
      zerocoords
    else
      src_coords
    end
  end
end

default_concat_array_function{N}(x::LabeledArray{TypeVar(:T),N}, y::LabeledArray{TypeVar(:T),N}) = begin
  tracker = Any[allfieldnames(x)...;allfieldnames(y)...] # need Array, not AbstractArrayWrapper, hence ...
  xdata = if isa(x.data, DictArray)
    x.data
  else
    create_dictarray_nocheck(create_ldict_nocheck(create_additional_fieldname(x, tracker) => x.data))
  end
  ydata = if isa(y.data, DictArray)
    y.data
  else
    create_dictarray_nocheck(create_ldict_nocheck(create_additional_fieldname(y, tracker) => y.data))
  end
  data = DictArray(LDict([xdata.data.keys;ydata.data.keys], [xdata.data.values;ydata.data.values]))
  axes = x.axes
  LabeledArray(data, axes)
end
