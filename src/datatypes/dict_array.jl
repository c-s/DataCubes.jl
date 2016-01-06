import Base.==, Base.!=

"""

A multidimensional array whose elements are ordered dictionaries with common keys.
Internally, it is represented as an ordered dictionary from keys to multidimensional arrays.
Note that most functions return a new `DictArray` rather than modify the existing one.
However, the new `DictArray` just shallow copies the key vector and the value vector
of the underlying `LDict`. Therefore, creating a new `DictArray` is cheap, but you have to be
careful when you modify the underlying array elements directly.

Because a `DictArray` can be multidimensional we will call the keys in the key vector of the underlying `LDict` the *field names*.
The values in the value vector will be called *fields*. With a slight bit of abuse of notation, we sometimes call a field name and a field tuple collectively just a field.

Use the function `darr` to construct a `DictArray`.

##### Constructors
DictArraay is internally just a wrapper of `LDict`. Therefore, the constructors takes the same kind of arguments:

```julia
DictArray(data::LDict{K,V})
DictArray{K,V}(dict::Dict{K,V})
DictArray{K,V}(dict::Dict{K,V}, ks)
DictArray{K}(ks::Vector{K}, vs::Vector)
DictArray(ps::Pair...)
DictArray(tuples::Tuple...)
DictArray(;kwargs...)
```

"""
immutable DictArray{K,N,VS,SV} <: AbstractArray{LDict{K,SV}, N}
  # each element is of type LDictt{K,SV}. The values are combined as a tuple of type V (V is taken out for now).
  # the number of dimensions is N.
  # The values of the array have type VS as a vector of arrays.
  data::LDict{K,VS}
  DictArray(data::LDict{K,VS}) = begin
    dictsize = length(data)
    if dictsize > 0
      commonlen = size(data.values[1])
    end
    for i in 2:dictsize
      len = size(data.values[i])
      if len != commonlen
        throw(ArgumentError("field lengths are not the same"))
      end
    end
    new(data)
  end
end

(==)(arr1::DictArray, arr2::DictArray) = arr1.data == arr2.data

type ZeroNumberOfFieldsException <: Exception end
type KeysDoNotMatchException <: Exception
  keys1::AbstractVector
  keys2::AbstractVector
end

DictArray{K,VS}(data::LDict{K,VS}) = begin
  wrapped_dict = mapvalues(simplify_array, data)
  DictArray{K,
            ndims(data.values[1]),
            eltype(wrapped_dict.values),
            promote_type([eltype(v) for v in wrapped_dict.values]...)}(wrapped_dict)
end
create_dictarray_nocheck{K,VS}(data::LDict{K,VS}) = begin
  DictArray{K,
            ndims(data.values[1]),
            eltype(data.values),
            promote_type([eltype(v) for v in data.values]...)}(data)
end
DictArray() = throw(ZeroNumberOfFieldsException())
DictArray(dict::Associative) = DictArray(LDict(dict))
DictArray(dict::Associative, ks) = DictArray(LDict(dict, ks))
DictArray(ks::Vector, vs::Vector) = DictArray(LDict(ks, vs))
DictArray(ps::Pair...) = DictArray(LDict(ps...))
DictArray(tuples::Tuple...) = DictArray(LDict(tuples...))
DictArray(;kwargs...) = DictArray(kwargs...)
DictArray{K,V,N}(arr::AbstractArray{Nullable{LDict{K,V}},N}) = DictArray(map(x->mapvalues(apply_nullable, x.value), arr))
DictArray{T<:LDict,N}(arr::AbstractArray{T,N}) = DictArray(map(x->map(apply_nullable,x), arr))
DictArray{K,V<:Nullable,N}(arr::AbstractArray{LDict{K,V},N}) = begin
  if isempty(arr)
    error("the size of the input array should at least be 1.")
  end
  # first check if all keys of the elements in arr match with each other.
  common_keys = keys(first(arr))
  for elem in arr
    if common_keys != keys(elem)
      throw(KeysDoNotMatchException(common_keys, keys(elem)))
    end
  end
  # now we know all keys are the same.
  # first, let's figure out the element types.
  eltypes = map(typeof, values(first(arr)))
  # then, create result arrays to fill in later.
  results = [similar(arr, tp) for tp in eltypes]
  # let's fill in.
  for i in 1:length(common_keys)
    map!(x->x.values[i], results[i], arr)
  end
  DictArray(common_keys, results)
end
convert_to_dictarray_if_possible{K,V,N}(arr::AbstractArray{Nullable{LDict{K,V}},N}) = if any(x->x.isnull, arr)
  arr
else
  convert_to_dictarray_if_possible(map(x->mapvalues(apply_nullable, x.value), arr))
end
convert_to_dictarray_if_possible{K,V<:Nullable,N}(arr::AbstractArray{Nullable{LDict{K,V}},N}) = if any(x->x.isnull, arr)
  arr
else
  convert_to_dictarray_if_possible(map(x->x.value, arr))
end
convert_to_dictarray_if_possible{K,V<:Nullable,N}(arr::AbstractArray{LDict{K,V},N}) = begin
  if isempty(arr)
    arr
  end
  # first check if all keys of the elements in arr match with each other.
  common_keys = keys(first(arr))
  for elem in arr
    if common_keys != keys(elem)
      return arr
    end
  end
  # now we know all keys are the same.
  # first, let's figure out the element types.
  eltypes = map(typeof, values(first(arr)))
  # then, create result arrays to fill in later.
  results = [similar(arr, tp) for tp in eltypes]
  # let's fill in.
  for i in 1:length(common_keys)
    map!(x->x.values[i], results[i], arr)
  end
  DictArray(common_keys, results)
end
Base.convert(::Type{DictArray}, arr::DictArray) = arr
Base.convert{K,N,VS,SV<:Nullable}(::Type{DictArray}, arr::DictArray{K,N,VS,SV}) = DictArray(arr)
Base.convert{K,V,N}(::Type{DictArray}, arr::AbstractArray{Nullable{LDict{K,V}},N}) = DictArray(arr)
Base.convert{K,V<:Nullable,N}(::Type{DictArray}, arr::AbstractArray{LDict{K,V},N}) = DictArray(arr)

Base.getindex(arr::DictArray, arg::Symbol) = selectfield(arr, arg)
Base.getindex(arr::DictArray, arg::Symbol, args::Symbol...) = [selectfield(arr, a) for a in [arg;args...]]
Base.getindex{N}(arr::DictArray, args::Tuple{N,Symbol}) = map(a->selectfield(arr, a), args)
Base.getindex(arr::DictArray, args::AbstractVector{Symbol}) = selectfields(arr, args...)

Base.getindex(arr::DictArray, indices::CartesianIndex) = #getindex(arr, indices.I...)
  create_ldict_nocheck(arr.data.keys, map(x->getindex(x, indices), arr.data.values))

# some standard implementations to make a DictArray an AbstractArray.
Base.getindex(arr::DictArray, args...) = begin
  res = LDict(arr.data.keys, map(x->getindex(x, args...), arr.data.values))
  #if is_scalar_indexing(args)
  #  res
  #else
  create_dictarray_nocheck(res)
  #end
end
Base.getindex{K,SV}(arr::DictArray{K,TypeVar(:N),TypeVar(:VS),SV}, args::Int...) =
  create_ldict_nocheck(arr.data.keys, map(x->getindex(x, args...), arr.data.values))
Base.setindex!(arr::DictArray, v::DictArray, args...) = begin
  if arr.data.keys != v.data.keys
    throw(KeysDoNotMatchException(arr.data.keys, v.data.keys))
  end
  for (tgt,src) in zip(arr.data.values, v.data.values) #map(arr.data.values, v.data.values) do tgt, src
    setindex!(tgt, src, args...)
  end
  arr
end
# used internally to skip key check.
setindex_nocheck!(arr::DictArray, v::DictArray, args...) = begin
  for (tgt,src) in zip(arr.data.values, v.data.values)
    setindex!(tgt, src, args...)
  end
  arr
end
setindex_nocheck!(arr::AbstractArray, v::LDict, args...) = setindex!(arr, v, args...)
setindex_nocheck!(arr::AbstractArray, v, args...) = setindex!(arr, v, args...)

Base.sub(arr::DictArray, args::Union{Colon, Int64, AbstractArray{TypeVar(:T),1}}...) =
  DictArray(LDict(arr.data.keys, map(x->sub(x, args...), arr.data.values)))
Base.slice(arr::DictArray, args::Union{Colon, Int64, AbstractArray{TypeVar(:T), 1}}...) =
  DictArray(LDict(arr.data.keys, map(x->slice(x, args...), arr.data.values)))

"""

`getindexvalue(arr::DictArray, args...)`

Return the value tuple of `arr` at index `args`.

"""
getindexvalue(arr::DictArray, args...) = ntuple(length(arr.data)) do i
  arr.data.values[i][args...]
end
getindexvalue{T}(arr::DictArray, ::Type{T}, args...) = error("need more specifics")
"""

`getindexvalue(arr::AbstractArray, args...)`

Return `arr[args...]`.

"""
getindexvalue(arr::AbstractArray, args...) = getindex(arr, args...)
getindexvalue{T}(arr::AbstractArray, ::Type{T}, args...) = getindex(arr, args...)::T
# for internal use to impose type constraints. Similarly for other getindexvalue methods below.
# note that these versions are used only to access one element, and not a range.
getindexvalue{T1}(arr::DictArray, ::Type{Tuple{T1}}, args...) =
  (arr.data.values[1][args...]::T1,)
getindexvalue{T1,T2}(arr::DictArray, ::Type{Tuple{T1,T2}}, args...) =
  (arr.data.values[1][args...]::T1,
    arr.data.values[2][args...]::T2)
getindexvalue{T1,T2,T3}(arr::DictArray, ::Type{Tuple{T1,T2,T3}}, args...) =
  (arr.data.values[1][args...]::T1,
    arr.data.values[2][args...]::T2,
    arr.data.values[3][args...]::T3)
getindexvalue{T1,T2,T3,T4}(arr::DictArray, ::Type{Tuple{T1,T2,T3,T4}}, args...) =
  (arr.data.values[1][args...]::T1,
    arr.data.values[2][args...]::T2,
    arr.data.values[3][args...]::T3,
    arr.data.values[4][args...]::T4)
getindexvalue{T1,T2,T3,T4,T5}(arr::DictArray, ::Type{Tuple{T1,T2,T3,T4,T5}}, args...) =
  (arr.data.values[1][args...]::T1,
    arr.data.values[2][args...]::T2,
    arr.data.values[3][args...]::T3,
    arr.data.values[4][args...]::T4,
    arr.data.values[5][args...]::T5)
getindexvalue(arr::DictArray, ::Type, args...) = getindexvalue(arr, args...)

Base.setindex!(arr::DictArray, v::Tuple, args::Int...) = begin
  for (tgt, sr) in zip(arr.data.values, v)
    setindex!(tgt, sr, args...)
  end
  arr
end
Base.setindex!(arr::DictArray, v::LDict, args::Int...) = begin
  if arr.data.keys != v.keys
    throw(KeysDoNotMatchException(arr.data.keys, v.keys))
  end
  for (tgt, sr) in zip(arr.data.values, v.values)
    setindex!(tgt, sr, args...)
  end
  arr
end
Base.setindex!(arr::DictArray, v0::Associative, args::Int...) = begin
  v = LDict(v0, arr.data.keys)
  if arr.data.keys != v.keys
    throw(KeysDoNotMatchException(arr.data.keys, v.keys))
  end
  for (tgt, sr) in zip(arr.data.values, v.values)
    setindex!(tgt, sr, args...)
  end
  arr
end
Base.setindex!(arr::DictArray, src::DictArray, args...) = begin
  if arr.data.keys != src.data.keys
    throw(KeysDoNotMatchException(arr.data.keys, v.keys))
  end
  for (tgt, sr) in zip(arr.data.values, src.data.values)
    setindex!(tgt, sr, args...)
  end
  arr
end
# this is internally used when setting a DictArray using the value parts only.
Base.setindex!(arr::DictArray, src::Tuple, args...) = begin
  for (tgt, sr) in zip(arr.data.values, src)
    setindex!(tgt, sr, args...)
  end
  arr
end


Base.size{N}(arr::DictArray{TypeVar(:K),N}) = if isempty(arr.data)
  throw(ZeroNumberOfFieldsException())
else
  size(arr.data.values[1])::NTuple{N,Int}
end

# assume that each column has the same linearindexing..
Base.linearindexing(arr::DictArray) = if isempty(arr.data)
  throw(ZeroNumberOfFieldsExceptin())
else
  Base.linearindexing(typeof(arr.data.values[1]))
end

# assume all arrays in DictArray are of the same form.
Base.eachindex(arr::DictArray) = eachindex(arr.data.values[1])
Base.start(arr::DictArray) = (iter=eachindex(arr.data.values[1]);(iter, start(iter)))
Base.next(arr::DictArray, state) = begin
  nextelem,nextstate=next(state[1],state[2])
  arr[nextelem], (state[1], nextstate)
end
Base.done(arr::DictArray, state) = done(state[1], state[2])
Base.length(arr::DictArray) = if isempty(arr.data)
  throw(ZeroNumberOfFieldsException())
else
  length(arr.data.values[1])
end
Base.eltype{K,N,VS,SV}(::Type{DictArray{K,N,VS,SV}}) = LDict{K,SV}
Base.endof(arr::DictArray) = length(arr)
Base.findfirst(arr::DictArray, v::Tuple) = findfirst(arr, LDict(arr.data.keys, [v...]))
Base.transpose(arr::DictArray{TypeVar(:T),2}) = create_dictarray_nocheck(mapvalues(transpose, arr.data))
Base.permutedims(arr::DictArray, perm) = create_dictarray_nocheck(mapvalues(v->permutedims(v,perm), arr.data))
Base.reshape(arr::DictArray, dims::Int...) = create_dictarray_nocheck(mapvalues(x->reshape(x, dims...), arr.data))
Base.reshape(arr::DictArray, dims::Tuple{Vararg{Int}}) = reshape(arr, dims...)

arrayadd(arr1::DictArray, arr2::DictArray) = DictArray(merge(arr1.data, arr2.data))
arrayadd(arr1::DictArray, args...;kwargs...) = arrayadd(arr1, darr(args...;kwargs...))
arrayadd(arr1::DictArray, args::AbstractArray) = throw(ArgumentError("cannot implement."))
arrayadd(arr1::AbstractArray, arr2::AbstractArray) = reshape(collect(zip(arr1, arr2)), size(arr1))

"""

`merge(::DictArray, ::DictArray)`

Merge the two `DictArray`s. A duplicate field in the second `DictArray` will override that in the first one. Otherwise, the new field in the second `DictArray` will be appened after the first `DictArray` fields.
If the first is `DictArray` and the remaining arguments are used to construct a `DictArray` and then the two are merged.

##### Example

```julia
julia> merge(darr(a=[1,2,3], b=[4,5,6]), darr(b=[:x,:y,:z], c=["A","B","C"]))
3 DictArray

a b c 
------
1 x A 
2 y B 
3 z C 
```
"""
Base.merge(arr1::DictArray, arr2::DictArray) = arrayadd(arr1, arr2)
"""

`merge(::DictArray, args...)`

Construct a `DictArray` using `args...`, and merges the two `DictArray`s together.

##### Example

```julia
julia> merge(darr(a=[1,2,3], b=[4,5,6]), b=[:x,:y,:z], :c=>["A","B","C"])
3 DictArray

a b c 
------
1 x A 
2 y B 
3 z C 
```

"""
Base.merge(arr1::DictArray, args...;kwargs...) = arrayadd(arr1, args...;kwargs...)

# select and delete fields from DictArray and return a new DictArray.
deletefields(arr::DictArray, fields...) = DictArray(deletekeys(arr.data, fields...))
selectfields(arr::DictArray, fields...) = DictArray(selectkeys(arr.data, fields...))
selectfield(arr::DictArray, name) = arr.data[name]

"""

`show(io::IO, arr::DictArray [; height::Int=..., width::Int=..., alongorow::Bool=true])`

Show a `DictArray` in `io` in a square box of given `height` and `width`. If not provided, the current terminal's size is used to get the default `height` and `weight`. `alongrow` determines whether to display field names along row or columns.

##### Examples
```julia
julia> show(STDOUT, darr(a=[1,2,3], b=[:x,:y,:z]))
3 DictArray

a b 
----
1 x 
2 y 
3 z 

julia> show(STDOUT, darr(a=[1,2,3], b=[:x,:y,:z]), alongrow=false)
3 DictArray

a |1 
b |x 
--+--
a |2 
b |y 
--+--
a |3 
b |z 
```

"""
Base.show{N}(io::IO, arr::DictArray{TypeVar(:K),N}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow=toshow_alongrow) = begin
  # show is implemented for a DictArray with dimesion 1 and 2 separately, and
  # show for a DictArray with dimension greater than 2 calls the 1 and 2 dimensional versions recursively.
  print(io, join(size(arr), " x "))
  print(io, " DictArray")
  print(io, '\n')
  ndimstable = ndims(arr)
  for index=1:last(size(arr))
    coords = [fill(:,ndimstable-1);index]
    print(io, '\n')
    show_indent(io, indent)
    print(io, '[')
    for i in 1:length(coords)-1
      print(io, ":,")
    end
    print(io, index)
    print(io, ']')
    print(io, '\n')
    show(io, getindex(arr, coords...), indent+4;height = height, width=width, alongrow=alongrow)
  end
end

Base.show(io::IO, arr::DictArray{TypeVar(:K),0}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow=toshow_alongrow) = begin
  println(io, "0 dimensional DictArray")
  show(io, mapvalues(x->x[1], arr.data))
end

Base.show(io::IO, arr::DictArray{TypeVar(:K),1}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow=toshow_alongrow) = begin
  print(io, join(size(arr), " x "))
  print(io, " DictArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(arr; height=height, width=width)
  else
    create_string_reprmat_alongcol(arr; height=height, width=width)
  end
  show_string_matrix(io, result, height, width, indent, hlines, vlines)
end

create_string_reprmat_alongrow(arr::DictArray{TypeVar(:K),1}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = arr
  nrows = min(show_height, length(arr) + 1)
  nkeys = 0
  ncols = max(nkeys, min(show_width, nkeys + arr_width(tabledata)))
  result = fill("", nrows, ncols)
  result[1,nkeys+1:ncols] = map(string, tabledata.data.keys[1:ncols-nkeys])
  for i in nkeys+1:ncols
    result[2:nrows,i] = map(cell_to_string, tabledata.data.values[i-nkeys][1:nrows-1])
  end
  (result, [2], [])
end

create_string_reprmat_alongcol(arr::DictArray{TypeVar(:K),1}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = arr
  widthtabledata = arr_width(tabledata)
  nrows = min(show_height, widthtabledata*length(arr))
  nkeys = 0
  ncols = max(nkeys, min(show_width, nkeys + 2))
  result = fill("", nrows, ncols)
  for i in 1:nrows
    result[i,nkeys+1] = string(tabledata.data.keys[1+(i-1) % widthtabledata]) #string(data.keys[i loop_key_index])
    result[i,nkeys+2] = cell_to_string(tabledata.data.values[1+(i-1) % widthtabledata][1+div(i-1,widthtabledata)])
  end
  (result, collect(1+widthtabledata*(1:1+fld(nrows,widthtabledata))), [2])
end

Base.show(io::IO, arr::DictArray{TypeVar(:K),2}, indent; height::Int=show_size()[1], width::Int=show_size()[2], alongrow=toshow_alongrow) = begin
  print(io, join(size(arr), " x "))
  print(io, " DictArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(arr; height=height, width=width)
  else
    create_string_reprmat_alongcol(arr; height=height, width=width)
  end
  show_string_matrix(io, result, height, width, indent, hlines, vlines)
end

create_string_reprmat_alongrow(arr::DictArray{TypeVar(:K),2}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = arr
  sizearr2 = size(arr, 2)
  (tableheight,tablewidth) = size(tabledata)
  widthtabledata = arr_width(tabledata)
  nrows = min(show_height, tableheight + 1)
  nkeys = 0
  ncols = max(nkeys, min(show_width, nkeys + sizearr2*widthtabledata))
  result = fill("", nrows, ncols)
  # fill in the key columns.
  if isa(tabledata, DictArray)
    if 1 <= nrows
      for i in 1:sizearr2
        for j in 1:widthtabledata
          ind = nkeys+widthtabledata*(i-1)+j
          if ind>ncols break end
          result[1,ind] = string(tabledata.data.keys[j])
        end
      end
      for i in 2:nrows
        for j in 1:sizearr2
          for k in 1:widthtabledata
            ind = nkeys+widthtabledata*(j-1)+k
            if ind>ncols break end
            result[i,ind] = cell_to_string(tabledata.data.values[k][i-1,j])
          end
        end
      end
    end
  else
    result[2:nrows,nkeys+1:ncols] = map(cell_to_string, tabledata[1:nrows-1,1:ncols-nkeys])
  end
  (result, [2], map(x->1+widthtabledata*(x-1),2:ncols))
end

create_string_reprmat_alongcol(arr::DictArray{TypeVar(:K),2}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = arr
  (tableheight,tablewidth) = size(tabledata)
  widthtabledata = arr_width(tabledata)
  nrows = min(show_height, widthtabledata*tableheight)
  nkeys = 0
  ncols = max(nkeys, min(show_width, nkeys + tablewidth + 1))
  result = fill("", nrows, ncols)
  # fill in the key columns.
  if isa(tabledata, DictArray)
    for j in 1:nrows
      result[j,nkeys+1] = string(tabledata.data.keys[1+(j-1) % widthtabledata])
    end
    for i in 1:nrows
      for j in 1:tablewidth
        ind = nkeys + 1 + j
        if ind>ncols break end
        result[i,ind] = cell_to_string(tabledata.data.values[1+(i-1) % widthtabledata][div(i-1, widthtabledata)+1,j])
      end
    end
  else
    result[1:nrows,nkeys+2:ncols] = map(cell_to_string, tabledata[1:nrows,1:ncols-nkeys-1])
  end
  (result, collect(1+widthtabledata*(1:1+fld(nrows-1,widthtabledata))), [2])
end

"""

`allfieldnames(::DictArray)`

Return all field names in the input `DictArray`, which are just the keys in the underlying `LDict`.

##### Examples

```julia
julia> allfieldnames(darr(a=reshape(1:6,3,2),b=rand(3,2)))
2-element Array{Symbol,1}:
 :a
 :b
```

"""
allfieldnames(arr::DictArray) = arr.data.keys
Base.Multimedia.writemime(io::IO, ::MIME"text/plain", arr::DictArray) = show(io, arr)
Base.similar{K,N,VS,SV}(arr::DictArray{K,N,VS,SV}, ::Type{LDict{K,SV}}, dims::NTuple{TypeVar(:M),Int}) = begin
  newvals = map(arr.data.values) do elemarr
    similar(elemarr, dims)
  end
  create_dictarray_nocheck(create_ldict_nocheck(arr.data.keys, newvals))
end


isna(arr::DictArray) = isna(arr.data)
isna(arr::DictArray, indices...) = isna(arr[indices...])

Base.copy(arr::DictArray) = DictArray(copy_arrayvalues(arr.data))

# expand DictArrays so that they have common field names.
expand_array_fields(arrs::DictArray...) = begin
  eltypemap = LDict{Any,Any}()
  for arr in arrs
    for (k,v) in arr.data
      if haskey(eltypemap, k)
        # 2 eltypes because it is AbstractArray{Nullable{?}}.
        eltypemap[k] = promote_type(eltype(eltype(v)), eltypemap[k])
      else
        eltypemap[k] = eltype(eltype(v))
      end
    end
  end
  expanded_arrays = map(arrs) do arr
    create_dictarray_nocheck(create_ldict_nocheck(map(eltypemap) do kv
      k = kv[1]
      v = kv[2]
      if haskey(arr.data, k)
        arrdatak = arr.data[k]
        k => if eltype(eltype(arrdatak)) === v
          arrdatak
        else
          # copy if type promotion is necessary.
          copied = similar(arrdatak, Nullable{v})
          copy!(copied, arrdatak)
          copied
        end
      else
        k => fill(Nullable{v}(), size(arr))
      end
    end...))
  end
end

"""

`cat(catdim::Integer, arrs::DictArray...)`

Concatenate the `DictArray`s `arrs` along the `catdim` direction.
The common fields are concatenated field by field.
If a field name does not exist in all of `arrs`, a null field with that field name will be added to those `DictArray`s with that missing field name, and then the arrays will be concatenated field by field.

##### Examples
```julia
julia> cat(1, darr(a=[1 2 3], b=[:x :y :z]),
              darr(c=[3 2 1], b=[:m :n :p]))
2 x 3 DictArray

a b c |a b c |a b c 
------+------+------
1 x   |2 y   |3 z   
  m 3 |  n 2 |  p 1 

julia> cat(2, darr(a=[1 2 3], b=[:x :y :z]),
              darr(c=[3 2 1], b=[:m :n :p]))
1 x 6 DictArray

a b c |a b c |a b c |a b c |a b c |a b c 
------+------+------+------+------+------
1 x   |2 y   |3 z   |  m 3 |  n 2 |  p 1 
```

"""
Base.cat(catdim::Integer, arrs::DictArray...) = begin
  if length(arrs) == 1
    arrs[1]
  else
    common_keys = arrs[1].data.keys
    common_value_eltypes = map(eltype, arrs[1].data.values)
    for i in 2:length(arrs)
      if arrs[i].data.keys != common_keys || map(eltype, arrs[i].data.values) != common_value_eltypes
        return cat(catdim, expand_array_fields(arrs...)...)
      end
    end
    newvalues = map(map(x->x.data.values, arrs)...) do values...
      cat(catdim, values...)
    end
    DictArray(LDict(common_keys, newvalues))
  end
end
Base.vcat(arrs::DictArray...) = cat(1, arrs...)
Base.hcat(arrs::DictArray...) = cat(2, arrs...)

"""

`repeat(arr::DictArray [; inner=..., outer=...])`

Apply `repeat` field by field to the `DictArray` `arr`.

"""
Base.repeat(arr::DictArray; inner::Array{Int}=ones(Int,ndims(arr)), outer::Array{Int}=ones(Int,ndims(arr))) =
  DictArray(LDict(arr.data.keys, map(v->repeat(v, inner=inner, outer=outer), arr.data.values)))
# cannot define this convert because LabeledArray has not been defined yet.
# move this to LabeledArray.jl
#Base.convert(::Type{DictArray}, larr::LabeledArray) = selectfields(larr, allfieldnames(larr)...)

Base.Multimedia.writemime{N}(io::IO,
                             ::MIME"text/html",
                             arr::DictArray{TypeVar(:T),N};
                             height::Int=dispsize()[1],
                             width::Int=dispsize()[2],
                             alongrow::Bool=todisp_alongrow) = begin
  print(io, join(size(arr), " x "))
  print(io, " DictArray")
  print(io, '\n')
  ndimstable = ndims(arr)
  print(io, "<ul>")
  for index=1:last(size(arr))
    coords = [fill(:,ndimstable-1);index]
    print(io, "<li>")
    print(io, '[')
    for i in 1:length(coords)-1
      print(io, ":,")
    end
    print(io, index)
    print(io, ']')
    print(io, '\n')
    Base.Multimedia.writemime(io, MIME("text/html"), getindex(arr, coords...); height=height, width=width, alongrow=alongrow)
    print(io, "</li>")
  end
  print(io, "</ul>")
end

Base.Multimedia.writemime(io::IO, ::MIME"text/html", table::DictArray{TypeVar(:T),0}; height::Int=dispsize()[1], width::Int=dispsize()[2], alongrow::Bool=todisp_alongrow) = begin
  print(io, "0 dimensional DictArray")
end

Base.Multimedia.writemime(io::IO, ::MIME"text/html", table::Union{DictArray{TypeVar(:T),1},DictArray{TypeVar(:T),2}}; height=dispsize()[1], width=dispsize()[2], alongrow::Bool=todisp_alongrow) = begin
  print(io, join(size(table), " x "))
  print(io, " DictArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(table; height=height, width=width)
  else
    create_string_reprmat_alongcol(table; height=height, width=width)
  end
  print_string_reprmat_to_html_table(io, result, height, width, hlines, vlines)
end


# This is a generic verion of map. Need to develop an optimized version later.
"""

`map(f::Function, arr::DictArray)`

Apply the function `f` to each element of `arr`.
`f` will take an `LDict` and produces a value of type, say `T`.
The return value will have the same size as `arr` and its elements have type `T`.
If the return element type `T` is not nullable, the result elements are wrapped by `Nullable`.
If the return element type `T` is `LDict`, the result will be again a `DictArray`.
However, in this case, the `LDict` should be of the type `LDict{K,Nullable{V}}`.

##### Examples

```julia
julia> map(x->x[:a].value + x[:b].value, darr(a=[1 2;3 4], b=[1.0 2.0;3.0 4.0]))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},2,MultidimensionalTables.FloatNAArray{Float64,2,Array{Float64,2}}}:
 Nullable(2.0)  Nullable(4.0)
 Nullable(6.0)  Nullable(8.0)

julia> map(x->LDict(:c=>Nullable(x[:a].value + x[:b].value)), darr(a=[1 2;3 4], b=[1.0 2.0;3.0 4.0]))
2 x 2 DictArray

c   |c   
----+----
2.0 |4.0 
6.0 |8.0 
```
"""
Base.map(f::Function, arr::DictArray) = mapslices(f, arr, [])

"""

`reducedim(f::Function, arr::DictArray, dims [, initial])`

Reduce a two argument function `f` along dimensions of `arr`. `dims` is a vector specifying the dimensions to reduce, and `initial` is the initial value to use in the reduction.
* If `dims` includes all dimensions, `reduce` will be applied to the whole `arr` with initial value `initial.
* Otherwise, `reduce` is applied with the function `f` to each slice spanned by the directions with initial value `initial`.
`initial` can be omitted if the underlying `reduce` does not require it.

```julia
julia> reducedim((acc,d)->acc+d[:a].value, darr(a=[1 2 3;4 5 6]), [1], 0)
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(5)
 Nullable(7)
 Nullable(9)

julia> reducedim((acc,d)->acc+d[:a].value, darr(a=[1 2 3;4 5 6]), [2], 0)
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(6) 
 Nullable(15)

julia> reducedim((acc,d)->acc+d[:a].value, darr(a=[1 2 3;4 5 6]), [1,2], 0)
Nullable(21)
```

"""
Base.reducedim(f::Function, arr::DictArray, dims, initial) = begin
  mapslices(arr, dims) do slice
    reduce(f, initial, slice)
  end
end

Base.reducedim(f::Function, arr::DictArray, dims) = begin
  mapslices(arr, dims) do slice
    reduce(f, slice)
  end
end

"""

`mapslices(f::Function, arr::DictArray, dims)`

Apply the function `f` to each slice of `arr` specified by `dims`. `dims` is a vector of integers along which direction to reduce.

* If `dims` includes all dimensions, `f` will be applied to the whole `arr`.
* If `dims` is empty, `mapslices` is the same as `map`.
* Otherwise, `f` is applied to each slice spanned by the directions.

##### Return

Return a dimensionally reduced array along the directions in `dims`.
If the return value of `f` is an `LDict`, the return value of the corresponding `mapslices` is a `DictArray`.
Otherwise, the return value is an `Array`.

```julia
julia> mapslices(d->d[:a] .* 2, darr(a=[1 2 3;4 5 6], b=[10 11 12;13 14 15]), [1])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}}},1,Array{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}}},1}}:
 Nullable([Nullable(2),Nullable(8)]) 
 Nullable([Nullable(4),Nullable(10)])
 Nullable([Nullable(6),Nullable(12)])

julia> mapslices(d->d[:a] .* 2, darr(a=[1 2 3;4 5 6], b=[10 11 12;13 14 15]), [2])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}}},1,Array{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}}},1}}:
 Nullable([Nullable(2),Nullable(4),Nullable(6)])  
 Nullable([Nullable(8),Nullable(10),Nullable(12)])

julia> mapslices(d->LDict(:c=>sum(d[:a]), :d=>sum(d[:b] .* 3)), darr(a=[1 2 3;4 5 6], b=[10 11 12;13 14 15]), [2])
2 DictArray

c  d   
-------
6  99  
15 126 
```

"""
Base.mapslices(f::Function, arr::DictArray, dims::AbstractVector) = begin
  if length(dims) != length(unique(dims))
    throw(ArgumentError("the dims argument should be an array of distinct elements."))
  end
  dimtypes = ntuple(ndims(arr)) do d
    if d in dims
      Colon()
    else
      0
    end
  end
  result = mapslices_inner(f, arr, dimtypes)
  if ndims(result) == 0
    isa(result, DictArray) ? mapvalues(x->x[1], result) : result[1]
  else
    result
  end
end

@generated mapslices_inner{K,N,VS,SV,T}(f::Function, arr::DictArray{K,N,VS,SV}, dims::T) = begin
  dimtypes = dims.types
  slice_ndims = foldl((acc,x)->acc + (x==Int), 0, dimtypes)
  slice_indices = Int[map(it->it[1], filter(it->it[2]==Int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(slice(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array(Any, $N)
    # assume that the types are all the same.
    fill!(coords, Colon())
    coords[$slice_indices] = 1
    testslice = $slice_exp
    # testres is the first component.
    testres = f(testslice)
    reseltype = typeof(testres)
    result = Array(reseltype, sizearr[$slice_indices]...)
    mapslices_inner_typed!(result, f, arr, dims, testres)
  end
end

@generated mapslices_inner_typed!{KK,VV,M,K,N,VS,SV,T}(result::AbstractArray{LDict{KK,VV},M}, f::Function, arr::DictArray{K,N,VS,SV}, dims::T, testres::LDict{KK,VV}) = begin
  dimtypes = dims.types
  slice_ndims = foldl((acc,x)->acc + (x==Int), 0, dimtypes)
  slice_indices = Int[map(it->it[1], filter(it->it[2]==Int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(slice(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array(Any, $N)
    # assume that the types are all the same.
    ldict_keys_sofar = Nullable{Vector{KK}}() #testres.keys
    same_ldict::Bool = true
    is_the_first = true
    @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      oneslice = $slice_exp
      oneres = if is_the_first
        is_the_first = false
        testres
      else
        f(oneslice)
      end
      if same_ldict
        same_ldict &= (ldict_keys_sofar.isnull || ldict_keys_sofar.value == oneres.keys)
        if ldict_keys_sofar.isnull
          ldict_keys_sofar = Nullable(oneres.keys)
        end
      end
      @nref($slice_ndims, result, i) = oneres
    end
    if same_ldict
      valuetypes = [typeof(v) for v in result[1].values]
      valuevects = map(valuetypes) do vtype
        similar(result, vtype)
      end
      valuevectslen = length(valuevects)
      for j in 1:valuevectslen
        map!(r->r.values[j], valuevects[j], result)
      end
      DictArray(ldict_keys_sofar.value, map(wrap_array, valuevects))
    else
      result
    end
  end
end

@generated mapslices_inner_typed!{U,M,K,N,VS,SV,T}(result::AbstractArray{U,M}, f::Function, arr::DictArray{K,N,VS,SV}, dims::T, testres::U) = begin
  dimtypes = dims.types
  slice_ndims = foldl((acc,x)->acc + (x==Int), 0, dimtypes)
  slice_indices = Int[map(it->it[1], filter(it->it[2]==Int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(slice(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array(Any, $N)
    is_the_first = true
    # assume that the types are all the same.
    @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      oneslice = $slice_exp #slice(arr, coords...)
      oneres = if is_the_first
        is_the_first = false
        testres
      else
        f(oneslice)
      end
      @nref($slice_ndims, result, i) = oneres
    end
    @rap wrap_array nalift result
  end
end

# if dims spans all dimensions, f! cannot be inplace. It will be f!::U->T. Otherwise, f will be f!(AbstractArray{T,N}, AbstractArray{U,N}).
map_array_preserve_shape!{T,U,N}(f!::Function, tgt::AbstractArray{T,N}, src::AbstractArray{U,N}, dims::Int...;rev=false) = begin
  if length(dims) != length(unique(dims))
    throw(ArgumentError("the dims argument should be distinct."))
  end
  dimtypes = ntuple(ndims(src)) do d
    if d in dims
      Colon()
    else
      0
    end
  end
  map_array_preserve_shape!(f!, tgt, src, dimtypes;rev=rev)
end

@generated map_array_preserve_shape!{T,U,V,N}(f!::Function, tgt::AbstractArray{T,N}, src::AbstractArray{U,N}, dims::V;rev=false) = begin
  dimtypes = dims.types
  # slice_ndims is N if all dims are numbers, i.e., if applying f to each element. tgt will be map(f, src). f::U->T, except that f is inplace.
  # slice_ndims is 0 if applying f to the entire array. i.e. tgt will be f(src). f::AbsractArray{U,N}->AbstractArray{T,N}, except that f is inplace.
  slice_ndims = foldl((acc,x)->acc + (x==Int), 0, dimtypes)
  slice_indices = Int[map(it->it[1], filter(it->it[2]==Int, enumerate(dimtypes)))...]
  tgt_slice_exp = if slice_ndims == N
    :(tgt[coords...])
  else
    :(reverse_if_required(rev, slice(tgt, coords...)))
  end
  src_slice_exp = if slice_ndims == N
    :(src[coords...]) # no need to reverse.
  else
    :(reverse_if_required(rev, slice(src, coords...)))
  end
  apply_f_exp = if slice_ndims == N
    quote
      $tgt_slice_exp = f!($src_slice_exp)
    end
  else
    quote
      f!($tgt_slice_exp, $src_slice_exp)
    end
  end
  quote
    coords = Array(Any, $N)
    # assume that the types are all the same.
    @nloops $slice_ndims i j->1:size(src,$slice_indices[j]) begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      $apply_f_exp
    end
    tgt
  end
end


reverse_if_required(rev::Bool, arr::AbstractArray) = if rev
  ranges = ntuple(ndims(arr)) do d
    size(arr,d):-1:1
  end
  slice(arr, ranges...)
else
  arr
end

check_ldict(::LDict) = true
check_ldict(_) = false

"""

`keys(::DictArray)`

Return the field name vector of the input `DictArray`, which are the keys of the underlying `LDict`.

##### Examples

```julia
julia> keys(darr(a=[1,2,3], b=[:x,:y,:z]))
2-element Array{Symbol,1}:
 :a
 :b
```

"""
Base.keys(arr::DictArray) = keys(peel(arr))

"""

`values(::DictArray)`

Return the vector of field arrays of the input `DictArray`, which are the values of the underlying `LDict`.

##### Examples

```julia
julia> values(darr(a=[1,2,3], b=[:x,:y,:z]))
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}},1}:
 [Nullable(1),Nullable(2),Nullable(3)]   
 [Nullable(:x),Nullable(:y),Nullable(:z)]
```

"""
Base.values(arr::DictArray) = values(peel(arr))

# to avoid ambiguity with conventional use of reverse, specifically prohobit the integer argument.
Base.reverse(arr::DictArray, dummy::Integer) = error("not yet implemented.")
Base.reverse(arr::DictArray) = reverse(arr, [1])
# any iterable dims can be an argument.

"""

`reverse(arr::DictArray, dims)`

Reverse a `DictArray` `arr` using an iterable variable `dims`.

##### Arguments

* `arr` is an input `DictArray`.
* `dims` is an iterable variable of `Int`s.

##### Return

A `DictArray` whose elements along any directions belonging to `dims` are reversed.

##### Examples

```julia
julia> t = darr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1 x |2 y |3 z 
4 u |5 v |6 w 


julia> reverse(t, [1])
2 x 3 DictArray

a b |a b |a b 
----+----+----
4 u |5 v |6 w 
1 x |2 y |3 z 


julia> reverse(t, 1:2)
2 x 3 DictArray

a b |a b |a b 
----+----+----
6 w |5 v |4 u 
3 z |2 y |1 x 
```

"""
Base.reverse(arr::DictArray, dims) = begin
  coords = ntuple(ndims(arr)) do d
    if d in dims
      size(arr, d):-1:1
    else
      Colon()
    end
  end
  getindex(arr, coords...)
end

"""

`flipdim(arr::DictArray, dims...)`

Flip a `DictArray` `arr` using an iterable variable `dims`. The same method as `reverse(arr::DictArray, dims)`.

##### Arguments

* `arr` is an input `DictArray`.
* `dims` is an iterable variable of `Int`s.

##### Return

A `DictArray` whose elements along any directions belonging to `dims` are fliped.

##### Examples

```julia
julia> t = darr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1 x |2 y |3 z 
4 u |5 v |6 w 


julia> flipdim(t, 1)
2 x 3 DictArray

a b |a b |a b 
----+----+----
4 u |5 v |6 w 
1 x |2 y |3 z 


julia> flipdim(t, 1, 2)
2 x 3 DictArray

a b |a b |a b 
----+----+----
6 w |5 v |4 u 
3 z |2 y |1 x 
```

"""
Base.flipdim(arr::DictArray, dims::Integer...) = reverse(arr, dims)

"""

`fill(ldict::LDict, dims...)`

Fill a `DictArray` with `ldict`.

##### Return
A new `DictArray` whose elements are `ldict` and whose dimensions are `dims...`.

"""
Base.fill(ldict::LDict, dims::Integer...) = DictArray(mapvalues(v->fill(apply_nullable(v), dims...), ldict))
Base.fill(ldict::LDict, dims::Tuple{Vararg{Int}}) = fill(ldict, dims...)

"""

`reorder(arr::DictArray, ks...)`

Reorder the field names so that the first few field names are `ks`.

##### Return
A new `DictArray` whose fields are shuffled from `arr` so that the first few field names are `ks`.

"""
function reorder end

reorder(arr::DictArray, ks...) = DictArray(reorder(arr.data, ks...))

"""

`rename(arr::DictArray, ks...)`

Rename the field names so that the first few field names are `ks`.

##### Return
A new `DictArray` whose first few field names are `ks`.

"""
function rename end

rename{K}(arr::DictArray{K}, ks::K...) = DictArray(rename(arr.data, ks...))


"""

`@darr(...)`

Create a `DictArray`. The arguments `...` can be one of the following:

##### Arguments

* `k=>v` creates a field using an array `v` with field name `k`. `k` can be an arbitrary type. If the element type of `v` is not `Nullable`, each element will be wrapped by `Nullable`. If `NA` is provided as an element, it is translated as `Nullable{T}()` for an appropriate type `T`.
* `k=v` creates a field using an array `v` with field name `:k`.
* There can be at most one non pair type argument, which will be converted into a `DictArray` and other pair arguments will update it.

##### Examples

```julia
julia> t = @darr(a=[1 2;NA 4;5 NA],b=["abc" NA;1 2;:m "xyz"],:c=>[NA 1.5;:sym 'a';"X" "Y"])
3 x 2 DictArray

a b   c   |a b   c   
----------+----------
1 abc     |2     1.5 
  1   sym |4 2   a   
5 m   X   |  xyz Y   


julia> @darr(t, c=[1 2;3 4;5 6], "d"=>map(Nullable, [1 2;3 4;5 6]))
3 x 2 DictArray

a b   c d |a b   c d 
----------+----------
1 abc 1 1 |2     2 2 
  1   3 3 |4 2   4 4 
5 m   5 5 |  xyz 6 6 
```

"""
macro darr(args...)
  data_pairs = Any[]
  template = Nullable()
  for arg in args
    if :head in fieldnames(arg) && (arg.head == :kw || arg.head == :(=>))
      key = arg.head==:kw ? quote_symbol(arg.args[1]) : arg.args[1]
      value = arg.args[2]
      push!(data_pairs, quote
        $key => @nalift($(esc(value)))
      end)
    elseif :head in fieldnames(arg) && (arg.head == :vect || arg.head == :dict)
      throw(ArgumentError("an array/dictionary expression is not allowed."))
    elseif :head in fieldnames(arg) && arg.head == :call && arg.args[1] == :Dict
      throw(ArgumentError("an array/dictionary expression is not allowed."))
    elseif template.isnull
      template = Nullable(arg)
    else
      throw(ArgumentError("not a key=value type argument or an array argument $arg, or two or more base DictArrays are provided."))
    end
  end
  dataexp = if template.isnull && isempty(data_pairs)
    throw(ArgumentError("neither a base DictArray or a fieldname=>array pair provided."))
  elseif isempty(data_pairs)
    nothing
  else
    Expr(:call, :darr, Expr(:..., Expr(:vect, data_pairs...)))
  end
  if template.isnull
    dataexp
  else
    Expr(:call, :update_darr, esc(template.value), dataexp)
  end
end

"""

`darr(...)`

Create a `DictArray`. The arguments `...` can be one of the following:

##### Arguments

* `k=>v` creates a field using an array `v` with field name `k`. `k` can be an arbitrary type. If the element type of `v` is not `Nullable`, each element will be wrapped by `Nullable`. If you want to manually provide a `Nullable` array with `Nullable{T}()` elements in it, the macro version `@darr` may be more convenient to use. Note that this type of argument precedes the keyword type argument in the return `DictArray`, as shown in Examples below.
* `k=v` creates a field using an array `v` with field name `:k`.
* There can be at most one non pair type argument, which will be converted into a `DictArray` and other pair arguments will update it.
Especially, if the non pair type argument is an array of `LDict`, it will be converted into a `DictArray`.

##### Examples

```julia
julia> t = darr(a=[1 2;3 4;5 6],b=["abc" 'a';1 2;:m "xyz"],:c=>[1.0 1.5;:sym 'a';"X" "Y"])
3 x 2 DictArray

c   a b   |c   a b   
----------+----------
1.0 1 abc |1.5 2 a   
sym 3 1   |a   4 2   
X   5 m   |Y   6 xyz 


julia> darr(t, c=[1 2;3 4;5 6], :d=>map(Nullable, [1 2;3 4;5 6]))
3 x 2 DictArray

c a b   d |c a b   d 
----------+----------
1 1 abc 1 |2 2 a   2 
3 3 1   3 |4 4 2   4 
5 5 m   5 |6 6 xyz 6 

julia> darr(Any[LDict(:a => Nullable(1),:b => Nullable{Int}()),LDict(:a => Nullable(3),:b => Nullable(4))])
2 DictArray

a b 
----
1   
3 4 
```

"""
function darr end

darr_inner(kwargs...) = begin
  common_array_size = Nullable()
  for (k,v) in kwargs
    if isa(v, AbstractArray)
      if common_array_size.isnull
        common_array_size = Nullable(size(v))
      elseif common_array_size.value != size(v)
        throw(ArgumentError("the result sizes for different fields are inconsistent: $(string([k=>size(v) for (k,v) in kwargs]))"))
      end
    end
  end
  if common_array_size.isnull
    throw(ArgumentError("at least one argument has to be an array."))
  end
  arraylifted_kwargs = Any[k=>isa(v, AbstractArray) ? v : fill(v, common_array_size.value) for (k,v) in kwargs]
  nalifted_kwargs = Any[k=>nalift(v) for (k,v) in arraylifted_kwargs]
  DictArray(nalifted_kwargs...)
end

darr(arr::AbstractArray) = convert(DictArray, nalift(arr))
darr(arr::DictArray, pairs...; kwargs...) = update_darr(arr, darr(pairs...; kwargs...)) #isempty(kwargs) ? arr : darr(arr, kwargs...)
darr(arr::DictArray) = arr
darr(args...;kwargs...) = darr_inner(args..., kwargs...)

# an internal function to update the base DictArray using data.
update_darr(base, data) = update_darr(convert(DictArray, base), data)
update_darr(base::DictArray, data) = begin
  if data == nothing
    base
  else
    darr(merge(base.data, data.data)...)
  end
end

