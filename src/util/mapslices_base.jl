copy_mapslice_helper!(tgt::AbstractArray, src::LabeledArray) = copy!(tgt, peel(src))
copy_mapslice_helper!(tgt::AbstractArray, src::AbstractArray) = copy!(tgt, src)

mapslices_darr_larr(f::Function, arr::AbstractArray, dims::AbstractVector) = begin
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
  result = mapslices_darr_larr_inner(f, arr, dimtypes)
  @show result
  peeloff_zero_array_if_necessary(result)
end

peeloff_zero_array_if_necessary(x) = x
peeloff_zero_array_if_necessary(arr::AbstractArray{TypeVar(:T),0}) = arr[1]
peeloff_zero_array_if_necessary(arr::DictArray{TypeVar(:K),0}) = mapvalues(x->x[1], peel(arr))
peeloff_zero_array_if_necessary(arr::LabeledArray{TypeVar(:T),0}) = peeloff_zero_array_if_necessary(peel(arr))

@generated mapslices_darr_larr_inner{V,N,T}(f::Function, arr::AbstractArray{V,N}, dims::T) = begin
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
    testres = nalift(f(testslice))
    reseltype = typeof(testres)

    ressize = sizearr[$slice_indices]
    result = if reseltype<:LabeledArray
      ndimstestres = ndims(testres)
      large_result = LabeledArray(similar(peel(testres), (size(testres)...,ressize...)), ntuple(ndimstestres+length(ressize)) do d
        if d<=ndimstestres
          pickaxis(testres, d)
        else
          DefaultAxis(ressize[d-ndimstestres])
        end
      end)
      colons = ntuple(d->Colon(), ndims(testres))
      ST = typeof(slice(large_result, colons..., ntuple(d->1, length(ressize))...))
      temp_result = similar(arr, ST, ressize)
      @nloops $slice_ndims i temp_result begin
        @nref($slice_ndims,temp_result,i) = slice(large_result, colons..., @ntuple($slice_ndims,i)...)
      end
      mapslices_darr_larr_inner_typed!(temp_result, f, arr, dims, testres)
      create_labeled_array_mapslices_inner(large_result, ndimstestres, arr, $slice_indices)
    elseif reseltype<:AbstractArray
      ndimstestres = ndims(testres)
      large_result = similar(testres, (size(testres)...,ressize...))
      colons = ntuple(d->Colon(), ndims(testres))
      ST = typeof(slice(large_result, colons..., ntuple(d->1, length(ressize))...))
      temp_result = similar(arr, ST, ressize)
      @nloops $slice_ndims i temp_result begin
        @nref($slice_ndims,temp_result,i) = slice(large_result, colons..., @ntuple($slice_ndims,i)...)
      end
      mapslices_darr_larr_inner_typed!(temp_result, f, arr, dims, testres)
      if isa(arr, LabeledArray)
        create_labeled_array_mapslices_inner(LabeledArray(large_result), ndimstestres, arr, $slice_indices)
      else
        large_result
      end
    else
      res = similar_mapslices_inner(arr, testres, $slice_indices)
      mapslices_darr_larr_inner_typed!(res, f, arr, dims, testres)
      res
    end
    result
  end
end

@generated mapslices_darr_larr_inner_typed!{M,K,N,T,U<:AbstractArray,V}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::V) = begin
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
    #ldict_keys_sofar = Nullable{Vector{KK}}() #testres.keys
    size_sofar = size(testres)
    is_the_first = true
    same_size::Bool = true
    @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      oneslice = $slice_exp
      oneres = if is_the_first
        is_the_first = false
        testres
      else
        nalift(f(oneslice))
      end
      same_size &= size_sofar == size(oneres)
      #Haven't implemented the case when same_size==false yet.
      copy_mapslice_helper!(@nref($slice_ndims, result, i), oneres)
    end
    result
  end
end

@generated mapslices_darr_larr_inner_typed!{KK,VV,M,K,N,T}(result::AbstractArray{LDict{KK,VV},M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::LDict{KK,VV}) = begin
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
        nalift(f(oneslice))
      end
      if same_ldict
        same_ldict &= (ldict_keys_sofar.isnull || ldict_keys_sofar.value == oneres.keys)
        if ldict_keys_sofar.isnull
          ldict_keys_sofar = Nullable(oneres.keys)
        end
      end
      @nref($slice_ndims, result, i) = oneres
    end
    result
    #if same_ldict
    #  valuetypes = [typeof(v) for v in result[1].values]
    #  valuevects = map(valuetypes) do vtype
    #    similar(result, vtype)
    #  end
    #  valuevectslen = length(valuevects)
    #  for j in 1:valuevectslen
    #    try
    #      map!(r->r.values[j], valuevects[j], result)
    #    catch
    #      @show result
    #      @show typeof(result)
    #      @show eltype(result)
    #      @show valuevects
    #      @show valuetypes
    #      rethrow()
    #    end
    #  end
    #  DictArray(ldict_keys_sofar.value, map(wrap_array, valuevects))
    #else
    #  result
    #end
  end
end

@generated mapslices_darr_larr_inner_typed!{U,M,K,N,T}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::U) = begin
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
        nalift(f(oneslice))
      end
      @nref($slice_ndims, result, i) = oneres
    end
    @rap wrap_array nalift result
  end
end

similar_mapslices_inner(arr::AbstractArray, testres, slice_indices) = similar(arr, typeof(testres), size(arr)[slice_indices])
similar_mapslices_inner(arr::DictArray, testres::LDict, slice_indices) = begin
  ressize = size(arr)[slice_indices]
  i = 0
  @rap create_dictarray_nocheck mapvalues(testres) do r
    i += 1
    similar(arr, typeof(r), ressize)
  end
end
similar_mapslices_inner(arr::LabeledArray, testres, slice_indices) = begin
  newdata = similar_mapslices_inner(peel(arr), testres, slice_indices)
  newaxes = ntuple(length(slice_indices)) do d
    pickaxis(arr, slice_indices[d])
  end
  LabeledArray(newdata, newaxes)
end

create_labeled_array_mapslices_inner(large_result::LabeledArray, ndimstestres, arr::LabeledArray, slice_indices) = begin
  LabeledArray(peel(large_result), ntuple(ndims(large_result)) do d
    if d <= ndimstestres
      pickaxis(large_result, d)
    else
      pickaxis(arr, slice_indices[d-ndimstestres])
    end
  end)
end

create_labeled_array_mapslices_inner(large_result::LabeledArray, ndimstestres, arr::AbstractArray, slice_indices) = begin
  LabeledArray(peel(large_result), ntuple(ndims(large_result)) do d
    if d <= ndimstestres
      pickaxis(large_result, d)
    else
      DefaultAxis(size(large_result, d))
    end
  end)
end
create_labeled_array_mapslices_inner(large_result::AbstractArray, ndimstestres, arr::LabeledArray, slice_indices) = begin
  LabeledArray(large_result, ntuple(ndims(large_result)) do d
    if d <= ndimstestres
      DefaultAxis(size(large_result, d))
    else
      pickaxis(arr, slice_indices[d-ndimstestres])
    end
  end)
end
create_labeled_array_mapslices_inner(large_result::AbstractArray, ndimstestres, arr::AbstractArray, slice_indices) = large_result
