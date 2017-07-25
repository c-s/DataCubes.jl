# an ordering to be used in sorting DictArrays or Labeledarrays.
immutable AbstractArrayLT{N,O,F} <: Base.Ordering
  ords::O #NTuple{N,Base.Ordering}
  fields::F #NTuple{N,Vector}
end

AbstractArrayLT(arr::Union{DictArray,LabeledArray}, axis::Integer, field_names...; kwargs...) = begin
  kv = Dict(kwargs)
  ords = map(field_names) do field
    lt = get(kv, Symbol(field, "_lt"), isless)
    by = get(kv, Symbol(field, "_by"), identity)
    rev = get(kv, Symbol(field, "_rev"), false)
    order = get(kv, Symbol(field, "_ord"), Base.Forward)
    Base.Order.ord(lt, by, rev, order)
  end
  ndimsarr = ndims(arr)
  fields = map(field_names) do name
    #collect(selectfield(arr, name)[get(kv, Symbol(name, "_coords"), ntuple(d->d==axis ? Colon() : 1, ndimsarr))...])
    r = selectfield(arr, name)[get(kv, Symbol(name, "_coords"), ntuple(d->d==axis ? Colon() : 1, ndimsarr))...].a
    r
  end
  AbstractArrayLT{length(field_names),typeof(ords),typeof(fields)}(ords, fields)
end

@generated Base.Sort.lt{N}(ltobj::AbstractArrayLT{N}, x::Integer, y::Integer) = begin
  comparison(i) = quote
    atix = getindexvalue(ltobj.fields[$i], x)
    atiy = getindexvalue(ltobj.fields[$i], y)
    ord = ltobj.ords[$i]
    if base_lt_helper(ord, atix, atiy)
      return true
    elseif base_lt_helper(ord, atiy, atix)
      return false
    end
  end
  exprs = map(n->comparison(n), 1:N)
  Expr(:block, exprs..., :(return false))
end

# @inline macro actually enhanced the performance.
@inline base_lt_helper{O,X,Y}(ord::O, x::X, y::Y) = Base.lt(ord, x, y)
@inline base_lt_helper{O,F<:AbstractFloat}(ord::O, x::F, y::F) =
  (isnan(x) && !isnan(y)) || (!isnan(x) && !isnan(y) && Base.lt(ord, x, y))
@inline base_lt_helper{F<:AbstractFloat}(ord::Base.Order.ReverseOrdering, x::F, y::F) =
  (!isnan(x) && isnan(y)) || (!isnan(x) && !isnan(y) && Base.lt(ord, x, y))
@inline base_lt_helper{O,X,Y}(ord::O, x::Nullable{X}, y::Nullable{Y}) =
  (isnull(x) && !isnull(y)) || (!isnull(x) && !isnull(y) && Base.lt(ord, x.value, y.value))
@inline base_lt_helper{X,Y}(ord::Base.Order.ReverseOrdering, x::Nullable{X}, y::Nullable{Y}) =
  (!isnull(x) && isnull(y)) || (!isnull(x) && !isnull(y) && Base.lt(ord, x.value, y.value))

sortpermbase(arr::Union{DictArray, LabeledArray}, axis::Integer, algorithm, order::Base.Ordering) = begin
  sorted_indices = collect(1:size(arr, axis))
  sort!(sorted_indices, algorithm, order)
  permuted_coords = ntuple(ndims(arr)) do d
    if d == axis
      sorted_indices
    else
      Colon()
    end
  end
  permuted_coords
end
Base.sortperm(arr::Union{DictArray,LabeledArray}, axis::Integer, fields...; alg=Base.Sort.defalg(arr), kwargs...) = begin
  ordering = AbstractArrayLT(arr, axis, fields...;kwargs...)
  sortpermbase(arr, axis, alg, ordering)
end
sortbase(arr::Union{DictArray,LabeledArray}, axis::Integer, algorithm, order::Base.Ordering) =
  arr[sortpermbase(arr, axis, algorithm, order)...]

"""

`sort(arr, axis, fields... [; alg=..., ...])`

Sort a `DictArray` or `LabeledArray` along some axis.

##### Arguments

* `arr` : either a `DictArray` or a `LabeledArray`.
* `axis` : an axis direction integer to denote which direction to sort along. If omitted, axis=1.
* `fields...` : the names of fields to determine the order. The preceding ones have precedence over the later ones. Note only the components [1,...,1,:,1,...1], where : is placed at the axis position, will be used out of each field. If omitted, all fields will be used in their order for `DictArray` and the axis along the `axis` direction for `LabeledArray`.
* optionally, `alg=algorithm` determines the sorting algorithm. `fieldname_lt=ltfunc` sets the less-than function for the field fieldname, and similarly for `by`/`rev`/`ord`.

##### Examples

```julia
julia> t = larr(a=[3 3 2;7 5 3], b=[:b :a :c;:d :e :f], axis1=["X","Y"])
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |3 b |3 a |2 c 
Y |7 d |5 e |3 f 


julia> sort(t, 1, :a)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |3 b |3 a |2 c 
Y |7 d |5 e |3 f 


julia> sort(t, 2, :a)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |2 c |3 b |3 a 
Y |3 f |7 d |5 e 


julia> sort(t, 2, :a, :b)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |2 c |3 a |3 b 
Y |3 f |5 e |7 d 


julia> sort(t, 2, :a, :b, a_rev=true)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |3 a |3 b |2 c 
Y |5 e |7 d |3 f 
```

"""
Base.sort(arr::Union{DictArray,LabeledArray}, axis::Integer, fields...; alg=Base.Sort.defalg(arr), kwargs...) = begin
  ordering = AbstractArrayLT(arr, axis, fields...;kwargs...)
  sortbase(arr, axis, alg, ordering)
end
Base.sort(arr::DictArray, axis::Integer; alg=Base.Sort.defalg(arr), kwargs...) = sort(arr, axis, keys(arr)...; alg=alg, kwargs...)
Base.sort(arr::LabeledArray, axis::Integer; alg=Base.Sort.defalg(arr), kwargs...) = begin
  coords = sortperm(arr, axis; alg=alg, kwargs...)
  arr[coords...]
end
Base.sort(arr::Union{DictArray,LabeledArray}; alg=Base.Sort.defalg(arr), kwargs...) = sort(arr, 1; alg=alg, kwargs...)
Base.sortperm(arr::DictArray, axis::Integer; alg=Base.Sort.defalg(arr), kwargs...) = sortperm(arr, axis, keys(arr)...; alg=alg, kwargs...)
Base.sortperm(arr::LabeledArray, axis::Integer; alg=Base.Sort.defalg(arr), kwargs...) = begin
  axis_processed = sortperm_inner_convert_to_dictarray_if_necessary(pickaxis(arr,axis))
  ordering = AbstractArrayLT(axis_processed, 1, keys(axis_processed)...;kwargs...)
  axisorder = sortpermbase(axis_processed, 1, alg, ordering)[1]
  coords = ntuple(ndims(arr)) do d
    if d == axis
      axisorder
    else
      Colon()
    end
  end
  coords
end
Base.sortperm(arr::Union{DictArray,LabeledArray}; alg=Base.Sort.defalg(arr), kwargs...) = sortperm(arr, 1; alg=alg, kwargs...)
sortperm_inner_convert_to_dictarray_if_necessary(arr::DictArray) = arr
sortperm_inner_convert_to_dictarray_if_necessary(arr::AbstractArray) = create_dictarray_nocheck(create_ldict_nocheck(:dummy=>arr))
