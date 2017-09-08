import Base: sum, prod, diff, mean, var, std, quantile, minimum, maximum, median, middle, cov, cor, cumprod, cumsum, cummin, cummax

import DataStructures

# define several helper functions such as sum or mean over nullable arrays (AbstractArrayWrapper{Nullable{T}}).

"""

`dropnaiter(arr)`

Generate an iterator from a nullable array `arr`, which iterates over only non-null elements.

##### Examples

```julia
julia> for x in dropnaiter(@nalift([1,2,NA,4,5]))
         println(x)
       end
1
2
4
5
```

"""
dropnaiter{T,N}(arr::AbstractArray{Nullable{T},N}) = NonNAIterator{T,N,typeof(arr)}(arr)

"""

`enum_dropnaiter(arr)`

Generate an iterator from a nullable array `arr`, which yields (index, elem) for an integer `index` for non-null element positions of `arr` and a non-null element `elem`.

##### Examples

```julia
julia> for x in enum_dropnaiter(@nalift([:A,:B,NA,NA,:C]))
         println(x)
       end
(1,:A)
(2,:B)
(5,:C)
```

"""
enum_dropnaiter{T,N}(arr::AbstractArray{Nullable{T},N}) = EnumerateNonNAIterator{T,N,typeof(arr)}(arr)

immutable NonNAIterator{T,N,A<:AbstractArray}
  array::A #AbstractArray{Nullable{T},N}
end
Base.eltype{T,N,A}(::Type{NonNAIterator{T,N,A}}) = T

Base.start(iter::NonNAIterator) = start(iter.array)
Base.next{T,N,U,A}(iter::NonNAIterator{T,N,A}, state::U) = begin
  (next_item::Nullable{T}, next_state::U) = next(iter.array, state)
  while isnull(next_item)
    (next_item, next_state) = next(iter.array, next_state)
  end
  (next_item.value, next_state)::Tuple{T,U}
  # recursion does not increase/decrease performance in some case.
  #if isnull(next_item)
  #  # I need to check if TCO is applied here.
  #  next(iter, next_state)::Tuple{T,U}
  #else
  #  (next_item.value, next_state)::Tuple{T,U}
  #end
end
Base.done{T,N,U,A}(iter::NonNAIterator{T,N,A}, state::U) = begin
  isdonenow::Bool = done(iter.array, state)
  if isdonenow
    true
  else
    (next_item, next_state) = next(iter.array, state)
    if isnull(next_item)
      done(iter, next_state)::Bool
    else
      false
    end
  end
end

immutable EnumerateNonNAIterator{T,N,A<:AbstractArray}
  array::A #::AbstractArray{Nullable{T},N}
end

Base.eltype{T,N,A}(::Type{EnumerateNonNAIterator{T,N,A}}) = Tuple{Int,T}
Base.start{T,N}(iter::EnumerateNonNAIterator{T,N}) = (1, start(iter.array))
Base.next{T,N}(iter::EnumerateNonNAIterator{T,N}, state) = begin
  (next_item, next_state) = next(iter.array, state[2])
  if isnull(next_item)
    next(iter, (state[1]+1, next_state)) #::Tuple{Tuple{Int,T},Tuple{Int,typeof(state)}}
  else
    ((state[1], next_item.value), (state[1]+1, next_state)) #::Tuple{Tuple{Int,T},Tuple{Int,typeof(state)}}
  end
end
Base.done{T,N}(iter::EnumerateNonNAIterator{T,N}, state) = begin
  isdonenow = done(iter.array, state[2])
  if isdonenow
    true
  else
    (next_item, next_state) = next(iter.array, state[2])
    if isnull(next_item)
      done(iter, (state[1]+1, next_state))::Bool
    else
      false
    end
  end
end

immutable ZipNonNAIterator{T,N,M,A}
  arrays::A
end


"""

`zip_dropnaiter(arrs...)`

Generate a zipped iterator from nullable arrays `arrs...`. If any element in `arrs...` is null, the iterator will skip it and move to the next element tuple.

##### Examples

```julia
julia> for x in zip_dropnaiter(@nalift([11,12,NA,NA,15]),
                               @nalift([:X,NA,:Z,NA,:V]),
                               @nalift([71,72,73,NA,75]))
         println(x)
       end
(11,:X,71)
(15,:V,75)
```

"""
zip_dropnaiter(arrs::AbstractArray...) = begin
  T = Tuple{map(x->eltype(eltype(x)), arrs)...}
  ZipNonNAIterator{T,length(arrs),length(arrs),typeof(arrs)}(arrs)
end
Base.eltype{T,N,M,A}(::Type{ZipNonNAIterator{T,N,M,A}}) = T
Base.start{T,N,M}(iter::ZipNonNAIterator{T,N,M}) = map(start, iter.arrays)
Base.next{T,N,M}(iter::ZipNonNAIterator{T,N,M}, state) = begin
  nexts = map(iter.arrays, state) do array,s; next(array,s) end
  for (n,s) in nexts
    if isnull(n)
      return next(iter, map(x->x[2],nexts))
    end
  end
  (map(x->x[1].value,nexts), map(x->x[2],nexts))
end
Base.done{T,N,M}(iter::ZipNonNAIterator{T,N,M}, state) = begin
  isdonenow = reduce(|, map(iter.arrays, state) do array,s; done(array,s) end)
  if isdonenow
    return true
  end
  nexts = map(iter.arrays, state) do array,s; next(array,s) end
  for (n,s) in nexts
    if isnull(n)
      return done(iter, map(x->x[2],nexts))::Bool
    end
  end
  return false
end

# for some reason, I cannot make dropnaiter type stable.
# for now, just use the plain for loop.
Base.sum{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,A}) = begin
  acc = zero(T)
  for x in arr
    if !isnull(x)
      acc += x.value
    end
  end
  Nullable(acc)
end
Base.sum{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
  arrdata = arr.a.data
  acc = zero(T)
  for x in arrdata
    if !isnan(x)
      acc += x
    end
  end
  Nullable(acc)
end

Base.prod{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,A}) = begin
  acc = one(T)
  for x in arr
    if !isnull(x)
      acc *= x.value
    end
  end
  Nullable(acc)
end
Base.prod{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
  arrdata = arr.a.data
  acc = one(T)
  for x in arrdata
    if !isnan(x)
      acc *= x
    end
  end
  Nullable(acc)
end

Base.mean{T}(arr::AbstractArrayWrapper{Nullable{T}}) = (iter=dropnaiter(arr);isempty(iter) ? Nullable{T}() : Nullable(mean(iter)))
Base.mean{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
  acc = zero(T)
  count = 0
  for elem in arr.a.data
    if !isnan(elem)
      count += 1
      acc += elem
    end
  end
  if count == 0
    Nullable{T}()
  else
    Nullable(acc / convert(T,count))
  end
end

Base.var{T}(arr::AbstractArrayWrapper{Nullable{T}}; corrected::Bool=true, mean=nothing) = begin
  iter = dropnaiter(arr)
  isempty(iter) ? Nullable{T}() : Nullable(var(iter; corrected=corrected, mean=mean))
end
Base.std{T}(arr::AbstractArrayWrapper{Nullable{T}}; corrected::Bool=true, mean=nothing) = begin
  iter = dropnaiter(arr)
  isempty(iter) ? Nullable{T}() : Nullable(std(iter; corrected=corrected, mean=mean))
end

# TODO need to optimize this without converting to another arrays first.
Base.cov{T,U}(arr1::AbstractArrayWrapper{Nullable{T},1}, arr2::AbstractArrayWrapper{Nullable{U},1}) = cov_base(arr1, arr2)
Base.cov{T,U}(arr1::AbstractArrayWrapper{Nullable{T},2}, arr2::AbstractArrayWrapper{Nullable{U},2}) = cov_base(arr1, arr2)
Base.cov{T,U}(arr1::AbstractArrayWrapper{Nullable{T}}, arr2::AbstractArrayWrapper{Nullable{U}}) = cov_base(arr1, arr2)
cov_base{T,U}(arr1::AbstractArrayWrapper{Nullable{T}}, arr2::AbstractArrayWrapper{Nullable{U}}) = begin
  zipped = zip_dropnaiter(arr1, arr2)
  v1 = Array{T}(length(arr1))
  v2 = Array{U}(length(arr2))
  n = 1
  for z in zipped
    v1[n] = z[1]
    v2[n] = z[2]
    n += 1
  end
  resize!(v1, n-1)
  resize!(v2, n-1)
  r = cov(v1, v2)
  if isnan(r)
    Nullable{typeof(r)}()
  else
    Nullable(r)
  end
end

# TODO need to optimize this without converting to another arrays first.
Base.cor{T,U}(arr1::AbstractArrayWrapper{Nullable{T},1}, arr2::AbstractArrayWrapper{Nullable{U},1}) = cor_base(arr1, arr2)
Base.cor{T,U}(arr1::AbstractArrayWrapper{Nullable{T},2}, arr2::AbstractArrayWrapper{Nullable{U},2}) = cor_base(arr1, arr2)
Base.cor{T,U}(arr1::AbstractArrayWrapper{Nullable{T}}, arr2::AbstractArrayWrapper{Nullable{U}}) = cor_base(arr1, arr2)
cor_base{T,U}(arr1::AbstractArrayWrapper{Nullable{T}}, arr2::AbstractArrayWrapper{Nullable{U}}) = begin
  zipped = zip_dropnaiter(arr1, arr2)
  v1 = Array{T}(length(arr1))
  v2 = Array{U}(length(arr2))
  n = 1
  for z in zipped
    v1[n] = z[1]
    v2[n] = z[2]
    n += 1
  end
  if n == 1
    # well, it's not really correct. If T and U are Int64, the result might be a Float64.
    Nullable{Base.return_types(/, (promote_type(T,U),Int))[1]}()
  else
    resize!(v1, n-1)
    resize!(v2, n-1)
    r = cor(v1, v2)
    if isnan(r)
      Nullable{typeof(r)}()
    else
      Nullable(cor(v1, v2))
    end
  end
end

Base.minimum{T}(arr::AbstractArrayWrapper{Nullable{T}}) = begin
  r=type_array(collect(dropnaiter(arr)))
  isempty(r) ? Nullable{T}() : Nullable(minimum(r))
end
#TODO NaN behavior changed from julia v0.5 to v0.6. Suppress this specialization for now.
#Base.minimum{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = (r=minimum(arr.a.data);isnan(r) ? Nullable{T}() : Nullable(r))

Base.maximum{T}(arr::AbstractArrayWrapper{Nullable{T}}) = begin
  r=type_array(collect(dropnaiter(arr)))
  isempty(r) ? Nullable{T}() : Nullable(maximum(r))
end
#TODO NaN behavior changed from julia v0.5 to v0.6. Suppress this specialization for now.
#Base.maximum{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = (r=maximum(arr.a.data);isnan(r) ? Nullable{T}() : Nullable(r))

Base.median{T}(arr::AbstractArrayWrapper{Nullable{T}}) = median_helper(typeof(one(T) / 2), arr)
median_helper{T,DIVTYPE}(::Type{DIVTYPE}, arr::AbstractArrayWrapper{Nullable{T}}) = begin
  r=collect_nonnas(arr)
  isempty(r) ? Nullable{DIVTYPE}() : Nullable(median(r))
end

collect_nonnas{T}(arr::AbstractArrayWrapper{Nullable{T}}) = type_array(collect(dropnaiter(arr)))
collect_nonnas{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = begin
  nonnas = similar(arr.a.data, T)
  count = 0
  for elem in arr.a.data
    if !isnan(elem)
      count += 1
      nonnas[count] = elem
    end
  end
  resize!(nonnas, count)
  nonnas
end

Base.middle{T}(arr::AbstractArrayWrapper{Nullable{T}}) = middle_helper(typeof(one(T) / 2), arr)
middle_helper{T,DIVTYPE}(::Type{DIVTYPE}, arr::AbstractArrayWrapper{Nullable{T}}) = begin
  r=type_array(collect(dropnaiter(arr)))
  isempty(r) ? Nullable{DIVTYPE}() : Nullable(middle(r))
end
#TODO NaN behavior changed from julia v0.5 to v0.6. Suppress this specialization for now.
#Base.middle{T<:AbstractFloat,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}) = (r=middle(arr.a.data);isnan(r) ? Nullable{T}() : Nullable(r))

Base.quantile{T}(arr::AbstractArrayWrapper{Nullable{T}}, q::AbstractVector) = quantile_helper(typeof(one(T) / 2), arr, q)
quantile_helper{T,DIVTYPE}(::Type{DIVTYPE}, arr::AbstractArrayWrapper{Nullable{T}}, q::AbstractVector) = begin
  r=collect_nonnas(arr)
  if isempty(r)
    Nullable{DIVTYPE}[]
  else
    map(Nullable, quantile(r, q))
  end
end
Base.quantile{T}(arr::AbstractArrayWrapper{Nullable{T}}, q::Number) = quantile_helper(typeof(one(T) / 2), arr, q)
quantile_helper{T,DIVTYPE}(::Type{DIVTYPE}, arr::AbstractArrayWrapper{Nullable{T}}, q::Number) = begin
  r=collect_nonnas(arr)
  if isempty(r)
    Nullable{DIVTYPE}()
  else
    Nullable(quantile(r, q))
  end
end

for op = [:sum, :prod, :mean, :var, :std, :median, :middle, :minimum, :maximum, :quantile]
  @eval begin
    $(op)(arr::DictArray) = mapvalues($(op), arr.data)
    $(op)(arr::LabeledArray) = $(op)(arr.data)
  end
end
Base.quantile(arr::DictArray, q::Number) = mapvalues(v->quantile(v, q), arr.data)
Base.quantile(arr::LabeledArray, q::Number) = quantile(arr.data, q)

for op = [:cov, :cor]
  op_base = Symbol(op, "_base")
  @eval begin
    $(op_base)(arr1::DictArray, arr2::DictArray) = begin
      axis1 = keys(arr1)
      axis2 = keys(arr2)
      # the covariance matrix should not be large.
      len1 = length(axis1)
      len2 = length(axis2)
      inds = reshape(collect(zip(repeat(collect(1:len1),inner=[1],outer=[len2]),
                                 repeat(collect(1:len2),inner=[len1],outer=[1]))),len1,len2)
      data = map(inds) do xy
        $(op)(arr1.data.values[xy[1]], arr2.data.values[xy[2]])
      end
      larr(data, axis1=axis1, axis2=axis2)
    end
    $(op_base)(arr1::LabeledArray, arr2::LabeledArray) = begin
      assert(arr1.axes == arr2.axes)
      $(op)(arr1.data, arr2.data)
    end
    $(op)(arr1::DictArray,arr2::DictArray) = $(op_base)(arr1, arr2)
    $(op){T,U}(arr1::DictArray{T,1},arr2::DictArray{U,1}) = $(op_base)(arr1, arr2)
    $(op){T,U}(arr1::DictArray{T,2},arr2::DictArray{U,2}) = $(op_base)(arr1, arr2)
    $(op){T}(arr::DictArray{T,1}) = $(op)(arr, arr)
    $(op){T}(arr::DictArray{T,2}) = $(op)(arr, arr)
    $(op)(arr::DictArray) = $(op)(arr, arr)
    $(op)(arr1::LabeledArray,arr2::LabeledArray) = $(op_base)(arr1, arr2)
    $(op){T,U}(arr1::LabeledArray{T,1},arr2::LabeledArray{U,1}) = $(op_base)(arr1, arr2)
    $(op){T,U}(arr1::LabeledArray{T,2},arr2::LabeledArray{U,2}) = $(op_base)(arr1, arr2)
    $(op){T}(arr::LabeledArray{T,1}) = $(op)(arr, arr)
    $(op){T}(arr::LabeledArray{T,2}) = $(op)(arr, arr)
    $(op)(arr::LabeledArray) = $(op)(arr, arr)
  end
end

for opspec in [:cumsum, :cumprod, :cummin, :cummax, :diff]
  @eval begin
    $(opspec){T}(arr::AbstractArrayWrapper{Nullable{T}};rev=false) = $(opspec)(arr, 1;rev=rev)
    $(opspec){T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}};rev=false) = $(opspec)(arr, 1;rev=rev)
    $(opspec)(arr::DictArray, dims::Integer...;rev=false) = DictArray(mapvalues(v->$(opspec)(v, dims...;rev=rev), arr.data))
    $(opspec)(arr::LabeledArray, dims::Integer...;rev=false) = LabeledArray($(opspec)(arr.data, dims...;rev=rev), arr.axes)
  end
end

for opspec in [:msum, :mprod, :mmean, :mminimum, :mmaximum, :mmedian, :mmiddle, :nafill]
  @eval begin
    $(opspec){T}(arr::AbstractArrayWrapper{Nullable{T}};rev=false,window=0) = $(opspec)(arr, 1;rev=rev,window=window)
    $(opspec){T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}};rev=false,window=0) = $(opspec)(arr, 1;rev=rev,window=window)
    $(opspec)(arr::DictArray, dims::Integer...;rev=false,window=0) = DictArray(mapvalues(v->$(opspec)(v, dims...;rev=rev,window=window), arr.data))
    $(opspec)(arr::LabeledArray, dims::Integer...;rev=false,window=0) = LabeledArray($(opspec)(arr.data, dims...;rev=rev,window=window), arr.axes)
  end
end

mquantile{T}(arr::AbstractArrayWrapper{Nullable{T}}, quantile::Number;rev=false,window=0) = mquantile(arr, quantile, 1; rev=rev,window=window)
mquantile{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, quantile::Number;rev=false,window=0) = mquantile(arr, quantile, 1; rev=rev,window=window)
mquantile(arr::DictArray, quantile::Number, dims::Integer...;rev=false,window=0) =
  DictArray(mapvalues(v->mquantile(v, quantile, dims...;rev=rev,window=window), arr.data))
mquantile(arr::LabeledArray, quantile::Number, dims::Integer...;rev=false,window=0) =
  LabeledArray(mquantile(arr.data, quantile, dims...;rev=rev,window=window), arr.axes)

Base.cumsum{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = zero(T)
    for i in eachindex(src)
      if !isnull(src[i])
        acc += src[i].value
      end
      tgt[i] = Nullable(acc)
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
Base.cumsum{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = zero(T)
    for i in eachindex(src)
      if !isnan(src[i])
        acc += src[i]
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

Base.cumprod{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = one(T)
    for i in eachindex(src)
      if !isnull(src[i])
        acc *= src[i].value
      end
      tgt[i] = Nullable(acc)
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
Base.cumprod{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                    dims::Integer...
                    ;rev=false) = begin
  function update!(tgt, src)
    acc = one(T)
    for i in eachindex(src)
      if !isnan(src[i])
        acc *= src[i]
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

Base.cummin{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = Nullable{T}()
    for i in eachindex(src)
      if !isnull(src[i])
        acc = isnull(acc) ? src[i] : Nullable(min(acc.value, src[i].value))
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
Base.cummin{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                   dims::Integer...
                   ;rev=false) = begin
  function update!(tgt, src)
    acc = convert(T, NaN)
    for i in eachindex(src)
      if !isnan(src[i])
        acc = isnan(acc) ? src[i] : min(acc, src[i])
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

Base.cummax{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = Nullable{T}()
    for i in eachindex(src)
      if !isnull(src[i])
        acc = isnull(acc) ? src[i] : Nullable(max(acc.value, src[i].value))
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
Base.cummax{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                   dims::Integer...
                   ;rev=false) = begin
  function update!(tgt, src)
    acc = convert(T, NaN)
    for i in eachindex(src)
      if !isnan(src[i])
        acc = isnan(acc) ? src[i] : max(acc, src[i])
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

cummiddle{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  DIVTYPE = typeof(one(T) / 2)
  function update!(tgt, src)
    accmin = Nullable{T}()
    accmax = Nullable{T}()
    for i in eachindex(src)
      if !isnull(src[i])
        accmin = isnull(accmin) ? src[i] : Nullable(min(accmin.value, src[i].value))
        accmax = isnull(accmax) ? src[i] : Nullable(max(accmax.value, src[i].value))
      end
      tgt[i] = (isnull(accmin) || isnull(accmax) ? Nullable{DIVTYPE}() : Nullable((accmin.value + accmax.value) / 2)) :: Nullable{DIVTYPE}
    end
  end
  result = similar(arr, Nullable{DIVTYPE})
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
cummiddle{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false) = begin
  DIVTYPE = typeof(one(T) / 2)
  function update!(tgt, src)
    accmin = convert(T, NaN)
    accmax = convert(T, NaN)
    for i in eachindex(src)
      if !isnan(src[i])
        accmin = isnan(accmin) ? src[i] : min(accmin, src[i])
        accmax = isnan(accmax) ? src[i] : max(accmax, src[i])
      end
      tgt[i] = isnan(accmin) || isnan(accmax) ? convert(DIVTYPE, NaN) : (accmin + accmax) / 2
    end
  end
  result = similar(arr, Nullable{DIVTYPE})
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

nafill0(arr::AbstractArrayWrapper, dims::Integer...;rev=false) = AbstractArrayWrapper(nafill0(arr.a, dims...; rev=rev))
nafill0{T}(arr::AbstractArray{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    lastelem = Nullable{T}()
    for i in eachindex(src)
      if !isnull(src[i])
        lastelem = src[i]
      end
      tgt[i] = lastelem
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result, arr, dims...;rev=rev)
  result
end
nafill0{T}(arr::FloatNAArray{T}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    lastelem = convert(T, NaN)
    for i in eachindex(src)
      if !isnan(src[i])
        lastelem = src[i]
      end
      tgt[i] = lastelem
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.data, arr.data, dims...;rev=rev)
  result
end

"""

`nafill(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Fill forward (backward if `rev=true`) `arr` using non-null values from the last `window` elements, or latest non-null value from the beginning if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `nafill` is applied to each field. When applied to `LabeledArray`, `nafill` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, the fill forward is performed along the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., the fill forward is taken along the leading dimension in `dims` first (i.e. `sum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, the backward filling is calculated instead, starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to fill forward. If `window=0`, `nafill` fills forward `arr` using all the elements so far. `NA` will be ignored.

##### Examples

```julia
julia> t = @nalift([1 NA;NA 4;NA NA])
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable{Int64}()
 Nullable{Int64}()  Nullable(4)
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t)
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable{Int64}()
 Nullable(1)  Nullable(4)
 Nullable(1)  Nullable(4)

julia> nafill(t,2)
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable(1)
 Nullable{Int64}()  Nullable(4)
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t,2,1)
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(1)
 Nullable(1)  Nullable(4)
 Nullable(1)  Nullable(4)

julia> nafill(t, rev=true)
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable(4)
 Nullable{Int64}()  Nullable(4)
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t, window=2)
3x2 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable{Int64}()
 Nullable(1)        Nullable(4)
 Nullable{Int64}()  Nullable(4)
```

"""
function nafill end

nafill(arr::AbstractArrayWrapper, dims::Integer...;rev=false, window=0) = AbstractArrayWrapper(nafill(arr.a, dims...; rev=rev, window=window))
nafill{T}(arr::AbstractArray{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return nafill0(arr, dims...;rev=rev)
  end
  function update!(tgt, src)
    lastelem = Nullable{T}()
    age = 0
    for i in eachindex(src)
      if isnull(src[i])
        age += 1
        if age >= window
          lastelem = Nullable{T}()
        end
      else
        lastelem = src[i]
        age = 0
      end
      tgt[i] = lastelem
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result, arr, dims...;rev=rev)
  result
end
nafill{T}(arr::FloatNAArray{T}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return nafill0(arr, dims...;rev=rev)
  end
  function update!(tgt, src)
    lastelem = convert(T, NaN)
    age = 0
    for i in eachindex(src)
      if isnan(src[i])
        age += 1
        if age >= window
          lastelem = convert(T, NaN)
        end
      else
        lastelem = src[i]
        age = 0
      end
      tgt[i] = lastelem
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.data, arr.data, dims...;rev=rev)
  result
end



"""

`diff(arr, dims... [; rev=false])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Take the difference between adjacent elements of `arr` along the directions belonging to the integers `dims`.
Note that `diff` applied to `AbstractArrayWrapper` (or to `LabeledArray` or `DictArray` by extension) will have the same shape as the original array. The first elements will be the first elements of the input array. This will ensure cumsum(diff(arr)) == diff(cumsum(arr)) == arr if there is no `Nullable` element.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `diff` is applied to each field. When applied to `LabeledArray`, `diff` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, difference is calculated along the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., difference is taken along the leading dimension in `dims` first (i.e. `sum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, difference is taken backward starting for the last elements. By default, `rev=false`.

##### Examples

```julia
julia> diff(@nalift([10,NA,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable(2)
 Nullable(3)

julia> diff(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a  b  |a  b  |a  b
------+------+------
11 10 |-2 2  |-2 2
3  -3 |3  -3 |3  -3


julia> diff(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2, rev=true)
2 x 3 DictArray

a  b  |a  b  |a  b
------+------+-----
-3 3  |-3 3  |-3 3
2  -2 |2  -2 |16 5


julia> diff(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2, rev=true)
2 x 3 LabeledArray

  |1     |2     |3
--+------+------+-----
  |a  b  |a  b  |a  b
--+------+------+-----
1 |-3 3  |-3 3  |-3 3
2 |2  -2 |2  -2 |16 5
```

"""
function diff end

Base.diff{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = Nullable(zero(T))
    for i in eachindex(src)
      tgt[i] = naop_minus(src[i], acc)
      acc = src[i]
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
Base.diff{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false) = begin
  function update!(tgt, src)
    acc = zero(T)
    for i in eachindex(src)
      tgt[i] = src[i] - acc
      acc = src[i]
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

"""

`msum(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving sum of `arr` using the last `window` elements, or cumulative sum if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `msum` is applied to each field. When applied to `LabeledArray`, `msum` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving sum is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving sum is taken along the leading dimension in `dims` first (i.e. `sum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving sum is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving sum. If `window=0`, `sum` calculates the cumulative sum. `NA` will be ignored.

##### Examples

```julia
julia> msum(@nalift([10,11,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable(21)
 Nullable(33)
 Nullable(47)
 Nullable(64)

julia> msum(@nalift([10,NA,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable(10)
 Nullable(22)
 Nullable(36)
 Nullable(53)

julia> msum(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a  b  |a  b  |a  b
------+------+------
11 10 |37 26 |65 40
25 17 |52 32 |81 45


julia> msum(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1     |2     |3
--+------+------+------
  |a  b  |a  b  |a  b
--+------+------+------
1 |81 45 |56 28 |29 13
2 |70 35 |44 19 |16 5
```

"""
function msum end

msum{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false,window=0) = begin
  if window == 0
    return cumsum(arr, dims...;rev=rev)
  end

  function update!(tgt, src)
    ringbuf = fill(zero(T), window)
    acc = zero(T)
    ringbuf_index = 1
    for i in eachindex(src)
      if isnull(src[i])
        acc -= ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = zero(T)
      else
        acc += src[i].value - ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = src[i].value
      end
      if ringbuf_index == window
        ringbuf_index = 1
      else
        ringbuf_index += 1
      end
      tgt[i] = Nullable(acc)
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
msum{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false,window=0) = begin
  if window == 0
    return cumsum(arr, dims...;rev=rev)
  end

  function update!(tgt, src)
    ringbuf = fill(zero(T), window)
    acc = zero(T)
    ringbuf_index = 1
    for i in eachindex(src)
      if isnan(src[i])
        acc -= ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = zero(T)
      else
        acc += src[i] - ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = src[i]
      end
      if ringbuf_index == window
        ringbuf_index = 1
      else
        ringbuf_index += 1
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end

"""

`mprod(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving product of `arr` using the last `window` elements, or cumulative product if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mprod` is applied to each field. When applied to `LabeledArray`, `mprod` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving product is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving product is taken along the leading dimension in `dims` first (i.e. `prod(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving product is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving product. If `window=0`, `prod` calculates the cumulative product. `NA` will be ignored.

##### Examples

```julia
julia> mprod(@nalift([10,11,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable(110)
 Nullable(1320)
 Nullable(18480)
 Nullable(314160)

julia> mprod(@nalift([10,NA,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable(10)
 Nullable(120)
 Nullable(1680)
 Nullable(28560)

julia> mprod(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a   b  |a     b    |a       b
-------+-----------+---------------
11  10 |1848  630  |360360  30240
154 70 |27720 3780 |5765760 151200


julia> mprod(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1              |2          |3
--+---------------+-----------+-------
  |a       b      |a     b    |a   b
--+---------------+-----------+-------
1 |5765760 151200 |37440 2160 |208 40
2 |524160  15120  |3120  240  |16  5
```

"""
function mprod end

mprod{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cumprod(arr, dims...;rev=rev)
  end
  function update!(tgt, src)
    ringbuf = fill(one(T), window)
    acc = one(T)
    ringbuf_index = 1
    for i in eachindex(src)
      if isnull(src[i])
        acc /= ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = one(T)
      else
        acc *= src[i].value / ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = src[i].value
      end
      if ringbuf_index == window
        ringbuf_index = 1
      else
        ringbuf_index += 1
      end
      tgt[i] = Nullable(acc)
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a, arr.a, dims...;rev=rev)
  result
end
mprod{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cumprod(arr, dims...;rev=rev)
  end
  function update!(tgt, src)
    ringbuf = fill(one(T), window)
    acc = one(T)
    ringbuf_index = 1
    for i in eachindex(src)
      if isnan(src[i])
        acc /= ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = one(T)
      else
        acc *= src[i] / ringbuf[ringbuf_index]
        ringbuf[ringbuf_index] = src[i]
      end
      if ringbuf_index == window
        ringbuf_index = 1
      else
        ringbuf_index += 1
      end
      tgt[i] = acc
    end
  end
  result = similar(arr)
  map_array_preserve_shape!(update!, result.a.data, arr.a.data, dims...;rev=rev)
  result
end


"""

`mmean(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving mean of `arr` using the last `window` elements, or cumulative mean if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mmean` is applied to each field. When applied to `LabeledArray`, `mmean` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving mean is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving mean is taken along the leading dimension in `dims` first (i.e. `mean(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving mean is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving mean. If `window=0`, `mean` calculates the cumulative mean. `NA` will be ignored.

##### Examples

```julia
julia> mmean(@nalift([10,11,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(10.0)
 Nullable(10.5)
 Nullable(11.0)
 Nullable(11.75)
 Nullable(12.8)

julia> mmean(@nalift([10,NA,12,14,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(10.0)
 Nullable(10.0)
 Nullable(11.0)
 Nullable(12.0)
 Nullable(13.25)

julia> mmean(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a    b    |a                  b                 |a    b
----------+-------------------------------------+---------
11.0 10.0 |12.333333333333334 8.666666666666666 |13.0 8.0
12.5 8.5  |13.0               8.0               |13.5 7.5


julia> mmean(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1        |2                                    |3
--+---------+-------------------------------------+---------
  |a    b   |a                  b                 |a    b
--+---------+-------------------------------------+---------
1 |13.5 7.5 |14.0               7.0               |14.5 6.5
2 |14.0 7.0 |14.666666666666666 6.333333333333333 |16.0 5.0
```

"""
function mmean end

mmean{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  if window == 0
    map_array_preserve_shape!((tgt,src)->cummean_update!(tgt,src), result.a, arr.a, dims...;rev=rev)
  else
    map_array_preserve_shape!((tgt,src)->mmean_update!(tgt,src,window), result.a, arr.a, dims...;rev=rev)
  end
  result
end
mmean{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, dims::Integer...;rev=false, window=0) = begin
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  if window == 0
    map_array_preserve_shape!((tgt,src)->cummean_update!(tgt,src), result.a.data, arr.a.data, dims...;rev=rev)
  else
    map_array_preserve_shape!((tgt,src)->mmean_update!(tgt,src,window), result.a.data, arr.a.data, dims...;rev=rev)
  end
  result
end

function mmean_update!{T,U}(tgt::AbstractArray{Nullable{T}}, src::AbstractArray{Nullable{U}}, window::Integer)
  ringbuf = fill(Nullable{U}(), window)
  acc = zero(U)
  num_non_nullable = 0
  ringbuf_index = 1
  for i in eachindex(src)
    srci = src[i]
    if !isnull(srci)
      num_non_nullable += 1
      acc += srci.value
    end
    if !isnull(ringbuf[ringbuf_index])
      num_non_nullable -= 1
      acc -= ringbuf[ringbuf_index].value
    end
    ringbuf[ringbuf_index] = srci
    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    tgt[i] = (num_non_nullable == 0 ? Nullable{T}() : Nullable(acc / num_non_nullable))::Nullable{T}
  end
end
function mmean_update!{T<:AbstractFloat,U<:AbstractFloat}(tgt::AbstractArray{T}, src::AbstractArray{U}, window::Integer)
  ringbuf = fill(convert(U,NaN), window)
  acc = zero(U)
  num_non_nullable = 0
  ringbuf_index = 1
  for i in eachindex(src)
    srci = src[i]
    if !isnan(srci)
      num_non_nullable += 1
      acc += srci
    end
    if !isnan(ringbuf[ringbuf_index])
      num_non_nullable -= 1
      acc -= ringbuf[ringbuf_index]
    end
    ringbuf[ringbuf_index] = srci
    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    tgt[i] = num_non_nullable == 0 ? convert(T,NaN) : acc / num_non_nullable
  end
end

function cummean_update!{T,U}(tgt::AbstractArray{Nullable{T}}, src::AbstractArray{Nullable{U}})
  acc = zero(U)
  num_non_nullable = 0
  for i in eachindex(src)
    srci = src[i]
    if !isnull(srci)
      num_non_nullable += 1
      acc += srci.value
    end
    tgt[i] = (num_non_nullable == 0 ? Nullable{T}() : Nullable(acc / num_non_nullable))::Nullable{T}
  end
end
function cummean_update!{T<:AbstractFloat,U<:AbstractFloat}(tgt::AbstractArray{T}, src::AbstractArray{U})
  acc = zero(U)
  num_non_nullable = 0
  for i in eachindex(src)
    srci = src[i]
    if !isnan(srci)
      num_non_nullable += 1
      acc += srci
    end
    tgt[i] = num_non_nullable == 0 ? convert(T,NaN) : acc / num_non_nullable
  end
end

"""

`mminimum(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving minimum of `arr` using the last `window` elements, or cumulative minimum if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mminimum` is applied to each field. When applied to `LabeledArray`, `mminimum` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving minimum is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving minimum is taken along the leading dimension in `dims` first (i.e. `minimum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving minimum is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving minimum. If `window=0`, `minimum` calculates the cumulative minimum. `NA` will be ignored.

##### Examples

```julia
julia> mminimum(@nalift([15,10,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(15)
 Nullable(10)
 Nullable(10)
 Nullable(10)
 Nullable(10)

julia> mminimum(@nalift([15,NA,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(15)
 Nullable(15)
 Nullable(12)
 Nullable(11)
 Nullable(11)

julia> mminimum(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a  b  |a  b |a  b
------+-----+-----
11 10 |11 7 |11 6
11 7  |11 6 |11 5


julia> mminimum(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1    |2    |3
--+-----+-----+-----
  |a  b |a  b |a  b
--+-----+-----+-----
1 |11 5 |12 5 |13 5
2 |12 5 |13 5 |16 5
```

"""
function mminimum end

mminimum{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cummin(arr, dims...;rev=rev)
  end
  result = similar(arr, Nullable{T})
  map_array_preserve_shape!((tgt,src) -> moving_update!(minimum, window, tgt, src), result, arr, dims...;rev=rev)
  result
end

"""

`mmaximum(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving maximum of `arr` using the last `window` elements, or cumulative maximum if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mmaximum` is applied to each field. When applied to `LabeledArray`, `mmaximum` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving maximum is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving maximum is taken along the leading dimension in `dims` first (i.e. `minimum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving maximum is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving maximum. If `window=0`, `maximum` calculates the cumulative maximum. `NA` will be ignored.

##### Examples

```julia
julia> mmaximum(@nalift([11,14,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(11)
 Nullable(14)
 Nullable(14)
 Nullable(14)
 Nullable(17)

julia> mmaximum(@nalift([11,NA,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(11)
 Nullable(11)
 Nullable(12)
 Nullable(12)
 Nullable(17)

julia> mmaximum(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a  b  |a  b  |a  b
------+------+------
11 10 |14 10 |15 10
14 10 |15 10 |16 10


julia> mmaximum(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1     |2    |3
--+------+-----+-----
  |a  b  |a  b |a  b
--+------+-----+-----
1 |16 10 |16 9 |16 8
2 |16 9  |16 8 |16 5
```

"""
function mmaximum end

mmaximum{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cummax(arr, dims...;rev=rev)
  end
  result = similar(arr, Nullable{T})
  map_array_preserve_shape!((tgt,src) -> moving_update!(maximum, window, tgt, src), result, arr, dims...;rev=rev)
  result
end

"""

`mmedian(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving median of `arr` using the last `window` elements, or cumulative median if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mmedian` is applied to each field. When applied to `LabeledArray`, `mmedian` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving median is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving median is taken along the leading dimension in `dims` first (i.e. `minimum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving median is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving median. If `window=0`, `median` calculates the cumulative median. `NA` will be ignored.

##### Examples

```julia
julia> mmedian(@nalift([11,14,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(14.0)

julia> mmedian(@nalift([11,NA,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(11.0)
 Nullable(11.5)
 Nullable(11.5)
 Nullable(12.0)

julia> mmedian(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a    b    |a    b   |a    b
----------+---------+---------
11.0 10.0 |12.5 8.5 |14.0 8.5
12.5 8.5  |14.0 8.5 |14.5 8.5


julia> mmedian(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1        |2        |3
--+---------+---------+---------
  |a    b   |a    b   |a    b
--+---------+---------+---------
1 |14.5 8.5 |14.5 8.0 |14.5 6.5
2 |14.5 8.0 |14.5 6.5 |16.0 5.0
```

"""
function mmedian end

mmedian{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cumquantile(arr, 0.5, dims...;rev=rev)
  end
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  map_array_preserve_shape!((tgt,src) -> moving_update!(median, window, tgt, src), result, arr, dims...;rev=rev)
  result
end

"""

`mmiddle(arr, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving middle of `arr` using the last `window` elements, or cumulative middle if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mmiddle` is applied to each field. When applied to `LabeledArray`, `mmiddle` is applied to the base.
* `dims`: by default `dims=(1,)`. That is, moving middle is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving middle is taken along the leading dimension in `dims` first (i.e. `minimum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving middle is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving middle. If `window=0`, `middle` calculates the cumulative middle. `NA` will be ignored.

##### Examples

```julia
julia> mmiddle(@nalift([11,14,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(14.0)

julia> mmiddle(@nalift([11,NA,12,11,17]))
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(11.0)
 Nullable(11.5)
 Nullable(11.5)
 Nullable(14.0)

julia> mmiddle(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 1, 2)
2 x 3 DictArray

a    b    |a    b   |a    b
----------+---------+---------
11.0 10.0 |12.5 8.5 |13.0 8.0
12.5 8.5  |13.0 8.0 |13.5 7.5


julia> mmiddle(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 2, 1, rev=true)
2 x 3 LabeledArray

  |1        |2        |3
--+---------+---------+---------
  |a    b   |a    b   |a    b
--+---------+---------+---------
1 |13.5 7.5 |14.0 7.0 |14.5 6.5
2 |14.0 7.0 |14.5 6.5 |16.0 5.0
```

"""
function mmiddle end

mmiddle{T}(arr::AbstractArrayWrapper{Nullable{T}}, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cummiddle(arr, dims...;rev=rev)
  end
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  map_array_preserve_shape!((tgt,src) -> moving_update!(middle, window, tgt, src), result, arr, dims...;rev=rev)
  result
end

"""

`mquantile(arr, quantile, dims... [; rev=false, window=0])` for `arr` of type `AbstractArrayWrapper`/`LabeledArray`/`DictArray`.

Calculate moving quantile of `arr` using the last `window` elements, or cumulative quantile if `window=0`.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `mquantile` is applied to each field. When applied to `LabeledArray`, `mquantile` is applied to the base.
* `quantile`: a number between 0 and 1 for the quantile to calculate.
* `dims`: by default `dims=(1,)`. That is, moving quantile is performed in the first direction. If `dims=(n1, n2,...)`, for each slice spanned along the directions `n1`, `n2`, ..., moving quantile is taken along the leading dimension in `dims` first (i.e. `minimum(dims)`), and then the next dimension, and so on.
* `rev`: If `rev=true`, moving quantile is calculated backward starting for the last elements. By default, `rev=false`.
* `window`: If `window>0`, only the last `window` elements, including the one in consideration, will be used to calculate moving quantile. If `window=0`, `quantile` calculates the cumulative quantile. `NA` will be ignored.

##### Examples

```julia
julia> mquantile(@nalift([11,14,12,11,17]), 0.25)
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(11.75)
 Nullable(11.75)
 Nullable(11.75)
 Nullable(12.5)

julia> mquantile(@nalift([11,NA,12,11,17]), 0.25)
5-element DataCubes.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(11.0)
 Nullable(11.25)
 Nullable(11.25)
 Nullable(11.5)

julia> mquantile(darr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 0.25, 1, 2)
2 x 3 DictArray

a     b    |a     b    |a     b
-----------+-----------+-----------
11.0  10.0 |11.75 7.75 |12.5  7.75
11.75 7.75 |12.5  7.75 |13.25 7.75


julia> mquantile(larr(a=[11 12 13;14 15 16], b=[10 9 8;7 6 5]), 0.25, 2, 1, rev=true)
2 x 3 LabeledArray

  |1          |2          |3
--+-----------+-----------+-----------
  |a     b    |a     b    |a     b
--+-----------+-----------+-----------
1 |13.75 7.25 |13.75 6.5  |13.75 5.75
2 |13.75 6.5  |13.75 5.75 |16.0  5.0
```

"""
function mquantile end

mquantile{T}(arr::AbstractArrayWrapper{Nullable{T}}, q::Number, dims::Integer...;rev=false, window=0) = begin
  if window == 0
    return cumquantile(arr, q, dims...;rev=rev)
  end
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  # we don't mind changing the input src. native quantile function was not fast enough.
  map_array_preserve_shape!((tgt,src) -> moving_update!(x->mquantile_quickselect!(DIVTYPE, x, q), window, tgt, src), result, arr, dims...;rev=rev)
  result
end

mquantile_quickselect!{T,R}(::Type{T}, arr::AbstractArray, p::R) =
  mquantile_quickselect_inner!(T, arr, 1,
                               length(arr),
                               one(R) + p * (length(arr)-1))
mquantile_quickselect_inner!{T,R}(::Type{T}, arr::AbstractArray, left::Int, right::Int, expected_position::R) = begin
  while true
    if left == right
      return convert(T, arr[left])
    elseif left == right - 1
      return convert(T, (expected_position - left) * arr[right] + (right - expected_position) * arr[left])
    else
      pivotindex = div(right + left, 2)
      pivotindex = mquantile_partition(arr, left, right, pivotindex)
      if expected_position == pivotindex
        return convert(T, arr[pivotindex])
      elseif expected_position < pivotindex
        right = pivotindex
      else
        left = pivotindex
      end
    end
  end
  error("this should not be reacheable.")
end
mquantile_partition(arr::AbstractArray, left::Int, right::Int, pivotindex::Int) = begin
  pivotvalue = arr[pivotindex]
  temp = arr[right]; arr[right] = arr[pivotindex]; arr[pivotindex] = temp
  storeindex = left
  for i in left:right-1
    if arr[i] < pivotvalue
      temp = arr[storeindex]; arr[storeindex] = arr[i]; arr[i] = temp
      storeindex += 1
    end
  end
  temp = arr[right]; arr[right] = arr[storeindex]; arr[storeindex] = temp
  return storeindex
end
moving_update!{T,U}(f::Function, window::Integer, tgt::AbstractArrayWrapper{Nullable{T}}, src::AbstractArrayWrapper{Nullable{U}}) = moving_update!(f, window, tgt.a, src.a)
moving_update!{T,U}(f::Function, window::Integer, tgt::AbstractArrayWrapper{Nullable{T}}, src::AbstractArray{Nullable{U}}) = moving_update!(f, window, tgt.a, src)
moving_update!{T,U}(f::Function, window::Integer, tgt::AbstractArrayWrapper{Nullable{T}}, src::FloatNAArray{U}) = moving_update!(f, window, tgt.a, src)
moving_update!{T,U}(f::Function, window::Integer, tgt::AbstractArray{Nullable{T}}, src::AbstractArrayWrapper{Nullable{U}}) = moving_update!(f, window, tgt, src.a)
moving_update!{T,U}(f::Function, window::Integer, tgt::FloatNAArray{T}, src::AbstractArrayWrapper{Nullable{U}}) = moving_update!(f, window, tgt, src.a)

# generic case.
function moving_update!{T,U}(f::Function,
                             window::Integer,
                             tgt::AbstractArray{Nullable{T}},
                             src::AbstractArray{Nullable{U}})
  ringbuf = Array{Nullable{U}}(window)
  projbuf = Array{U}(window)
  ringbuf_index = 1
  eff_size = 1
  for i in eachindex(src)
    ringbuf[ringbuf_index] = src[i]
    index = 0
    for j in 1:eff_size
      if !isnull(ringbuf[j])
        index += 1
        projbuf[index] = ringbuf[j].value
      end
    end
    tgt[i] = index==0 ? Nullable{T}() : Nullable(f(view(projbuf, 1:index)))

    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    eff_size = min(window, eff_size+1)
  end
end

# tgt, src are float arrays.
function moving_update!{T,U}(f::Function,
                             window::Integer,
                             tgt::FloatNAArray{T},
                             src::FloatNAArray{U})
  ringbuf = Array{U}(window)
  projbuf = Array{U}(window)
  ringbuf_index = 1
  eff_size = 1
  srcdata = src.data
  na = convert(T, NaN)
  for i in eachindex(srcdata)
    ringbuf[ringbuf_index] = srcdata[i]
    index = 0
    for j in 1:eff_size
      if !isnan(ringbuf[j])
        index += 1
        projbuf[index] = ringbuf[j]
      end
    end
    tgt[i] = index==0 ? na : f(view(projbuf, 1:index))

    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    eff_size = min(window, eff_size+1)
  end
end

# tgt is a float array.
function moving_update!{T,U}(f::Function,
                             window::Integer,
                             tgt::FloatNAArray{T},
                             src::AbstractArray{Nullable{U}})
  ringbuf = Array{Nullable{U}}(window)
  projbuf = Array{U}(window)
  ringbuf_index = 1
  eff_size = 1
  na = convert(T, NaN)
  for i in eachindex(src)
    ringbuf[ringbuf_index] = src[i]
    index = 0
    for j in 1:eff_size
      if !isnull(ringbuf[j])
        index += 1
        projbuf[index] = ringbuf[j].value
      end
    end
    tgt[i] = index==0 ? na : f(view(projbuf, 1:index))

    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    eff_size = min(window, eff_size+1)
  end
end

# src is a float array.
function moving_update!{T,U}(f::Function,
                             window::Integer,
                             tgt::AbstractArray{Nullable{T}},
                             src::FloatNAArray{U})
  ringbuf = Array{U}(window)
  projbuf = Array{U}(window)
  ringbuf_index = 1
  eff_size = 1
  srcdata = src.data
  for i in eachindex(srcdata)
    ringbuf[ringbuf_index] = srcdata[i]
    index = 0
    for j in 1:eff_size
      if !isnan(ringbuf[j])
        index += 1
        projbuf[index] = ringbuf[j]
      end
    end
    tgt[i] = index==0 ? Nullable{T}() : Nullable(f(view(projbuf, 1:index)))

    if ringbuf_index == window
      ringbuf_index = 1
    else
      ringbuf_index += 1
    end
    eff_size = min(window, eff_size+1)
  end
end

cumquantile{T}(arr::AbstractArrayWrapper{Nullable{T}}, q::Number, dims::Integer...;rev=false) = begin
  DIVTYPE = typeof(one(T) / 1)
  result = similar(arr, Nullable{DIVTYPE})
  map_array_preserve_shape!((tgt,src) -> cumquantile_update!(tgt, src, q), result, arr, dims...;rev=rev)
  result
end

cumquantile_update!{T,U,R}(tgt::AbstractArray{Nullable{T}}, src::AbstractArray{Nullable{U}}, q::R) = begin
  lowqueue = DataStructures.PriorityQueue{U,U,Base.Order.Ordering}(Base.Order.Reverse) # queue for smaller elements. Easy to get the maximum element.
  highqueue = DataStructures.PriorityQueue{U,U,Base.Order.Ordering}(Base.Order.Forward) # queue for larger elements. Easy to get the minimum element.

  dummy_index = 0
  for i in eachindex(src)
    srci = src[i]
    if !isnull(srci)
      dummy_index += 1
      if isempty(highqueue) || DataStructures.peek(highqueue)[2] < srci.value
        DataStructures.enqueue!(highqueue, dummy_index, srci.value)
      elseif isempty(lowqueue)
        DataStructures.enqueue!(lowqueue, dummy_index, srci.value)
      end
      # check the queues and shuffle elements if necessary.
      quantile_denom = length(lowqueue) + length(highqueue) - 1
      while q < (length(lowqueue)-1) / quantile_denom
        elem = DataStructures.peek(lowqueue)
        DataStructures.dequeue!(lowqueue)
        DataStructures.enqueue!(highqueue, elem...)
      end
      while q > length(lowqueue) / quantile_denom
        elem = DataStructures.peek(highqueue)
        DataStructures.dequeue!(highqueue)
        DataStructures.enqueue!(lowqueue, elem...)
      end
    end
    tgt[i] = if isempty(lowqueue)
      if isempty(highqueue)
        Nullable{T}()
      else
        Nullable(convert(T, DataStructures.peek(highqueue)[2]))
      end
    elseif isempty(highqueue)
      Nullable(convert(T, DataStructures.peek(lowqueue)[2]))
    else
      lowlen = length(lowqueue)
      highlen = length(highqueue)
      low_quantile = (lowlen - 1) / (lowlen + highlen - 1)
      high_quantile = lowlen / (lowlen + highlen - 1)
      lowpeek = DataStructures.peek(lowqueue)[2]
      highpeek = DataStructures.peek(highqueue)[2]
      Nullable((lowpeek + (q - low_quantile) * (highpeek - lowpeek) / (high_quantile - low_quantile))::T)
    end
  end
end

"""

`describe(arr)`

Generate a `LabeledArray` showing the overall statistics of the input.
If the input is a `Nullable` array, its summary statistics is calculated and the return value is of type `LDict`.
If the input is a `DictArray`, the summary is calculated for each field and the result is a `DictArray`.
If the input is a `LabeledArray`, `describe` returns the summary of its base.

##### Examples

```julia
julia> describe(@nalift([1,2,3,4,NA]))
DataCubes.LDict{Symbol,Any} with 10 entries:
  :min     => [Nullable(1)]
  :q1      => Nullable(1.75)
  :med     => Nullable(2.5)
  :q3      => Nullable(3.25)
  :max     => Nullable(4)
  :mean    => Nullable(2.5)
  :std     => Nullable(1.2909944487358056)
  :count   => Nullable(5)
  :nacount => Nullable(1)
  :naratio => Nullable(0.2)

julia> describe(@darr(a=[1,2,3,4,NA],b=[1,2,3,4,5]))
2 LabeledArray

  |min q1   med q3   max mean std                count nacount naratio
--+--------------------------------------------------------------------
a |1   1.75 2.5 3.25 4   2.5  1.2909944487358056 5     1       0.2
b |1   2.0  3.0 4.0  5   3.0  1.5811388300841898 5     0       0.0


julia> describe(@larr(a=[1,2,3,4,NA],b=[1,2,3,4,5],axis1[:m,:n,:p,:q,:r]))
2 LabeledArray

  |min q1   med q3   max mean std                count nacount naratio
--+--------------------------------------------------------------------
a |1   1.75 2.5 3.25 4   2.5  1.2909944487358056 5     1       0.2
b |1   2.0  3.0 4.0  5   3.0  1.5811388300841898 5     0       0.0
```

"""
function describe end

describe{T<:Nullable}(arr::AbstractArray{T}) = begin
  LDict(
    :min => try minimum(arr) catch Nullable{Float64}() end,
    :q1 => try quantile(arr, 0.25) catch Nullable{Float64}() end,
    :med => try quantile(arr, 0.5) catch Nullable{Float64}() end,
    :q3 => try quantile(arr, 0.75) catch Nullable{Float64}() end,
    :max => try maximum(arr) catch Nullable{Float64}() end,
    :mean => try mean(arr) catch Nullable{Float64}() end,
    :std => try std(arr) catch Nullable{Float64}() end,
    :count => Nullable(length(arr)),
    :nacount => Nullable(length(arr)-length(dropna(arr))),
    :naratio => Nullable((length(arr)-length(dropna(arr)))/length(arr)))
end


describe(arr::DictArray) = begin
  stat_func(v) = darr(
    :min => [try minimum(v) catch Nullable{Float64}() end],
    :q1 => try quantile(v, 0.25) catch Nullable{Float64}() end,
    :med => try quantile(v, 0.5) catch Nullable{Float64}() end,
    :q3 => try quantile(v, 0.75) catch Nullable{Float64}() end,
    :max => try maximum(v) catch Nullable{Float64}() end,
    :mean => try mean(v) catch Nullable{Float64}() end,
    :std => try std(v) catch Nullable{Float64}() end,
    :count => Nullable(length(v)),
    :nacount => Nullable(length(v)-length(dropna(v))),
    :naratio => Nullable((length(v)-length(dropna(v)))/length(v)))
  larr(cat(1, [stat_func(v) for (_,v) in peel(arr)]...), axis1=keys(arr))
end

describe(arr::LabeledArray) = describe(peel(arr))

"""

`shift(arr, offsets... [; isbound=false])`

Parallel shift the input array `arr` so that the element at `[1,...,1]` in `arr` shows up at `[1,...,1]+offsets` in the return array.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `shift` is applied to each field. When applied to `LabeledArray`, `shift` is applied to the base.
* `offsets`: integers to denote the amount of offset for each direction. It is assumed that there is no shift in the missing direcitons.
* `isbound`: default `false`. If `true`, the index is floored and capped between 1 and the maximum possible index along that direction. If `false`, any out of bound index due to shifting results in a nullable element.

##### Examples

```julia
julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 1)
3x3 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 01)
3x3 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 1)
3x3 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, -1)
3x3 DataCubes.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable{Int64}()  Nullable(4)        Nullable(5)
 Nullable{Int64}()  Nullable(7)        Nullable(8)
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(darr(a=[1 2 3;4 5 6;7 8 9]), 1, -1)
3 x 3 DictArray

a |a |a
--+--+--
  |4 |5
  |7 |8
  |  |


julia> shift(larr(a=[1 2 3;4 5 6;7 8 9], axis2=[:X,:Y,:Z]), 1, -1)
3 x 3 LabeledArray

  |X |Y |Z
--+--+--+--
  |a |a |a
--+--+--+--
1 |  |4 |5
2 |  |7 |8
3 |  |  |
```

"""
function shift end

@generated shift{T,N}(arr::AbstractArrayWrapper{Nullable{T},N}, offsets::NTuple{N,Int};isbound=false) = quote
  result = similar(arr)
  sizearr = size(arr)
  if isbound
    @nloops $N i arr d->j_d=max(1,min(sizearr[d],i_d+offsets[d])) begin
      @nref($N,result,i) = @nref($N,arr,j)
    end
  else
    @nloops $N i arr d->j_d=i_d+offsets[d] begin
      @nref($N,result,i) = if @nall($N, d->checkbounds(Bool, sizearr[d], j_d))
        @nref($N,arr,j)
      else
        Nullable{T}()
      end
    end
  end
  result
end

@generated shift{T,N,A}(arr::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, offsets::NTuple{N,Int};isbound=false) = quote
  arradata = arr.a.data
  result = similar(arradata)
  sizearr = size(arradata)
  indicesarr = indices(arradata)
  na = convert(T, NaN)
  if isbound
    @nloops $N i arradata d->j_d=max(1,min(sizearr[d],i_d+offsets[d])) begin
      @nref($N,result,i) = @nref($N,arradata,j)
    end
  else
    @nloops $N i arr d->j_d=i_d+offsets[d] begin
      @nref($N,result,i) = if @nall($N, d->checkbounds(Bool, indicesarr[d], j_d))
        @nref($N,arradata,j)
      else
        na
      end
    end
  end
  AbstractArrayWrapper(FloatNAArray(result))
end
shift{T}(arr::AbstractArrayWrapper{Nullable{T}}, offsets::Integer...;isbound=false) = begin
  lenoffsets = length(offsets)
  shift(arr, ntuple(d->lenoffsets<d ? 0:offsets[d], ndims(arr));isbound=isbound)
end
shift(arr::DictArray, offsets::Integer...;isbound=false) = DictArray(mapvalues(v->shift(v, offsets...;isbound=isbound), arr.data))
shift(arr::LabeledArray, offsets::Integer...;isbound=false) = LabeledArray(shift(arr.data, offsets...;isbound=isbound), arr.axes)

Base.iteratorsize(::ZipNonNAIterator) = Base.SizeUnknown()
Base.iteratorsize(::EnumerateNonNAIterator) = Base.SizeUnknown()
Base.iteratorsize(::NonNAIterator) = Base.SizeUnknown()
