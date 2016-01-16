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
      # it's important to assign this mutable function's return to the same variable because of fallback.
      newresult = mapslices_darr_larr_inner_typed!(temp_result, f, arr, dims, testres)
      if newresult.isnull
        create_labeled_array_mapslices_inner(large_result, ndimstestres, arr, $slice_indices)
      else
        newresult.value
      end
    elseif reseltype<:AbstractArray
      ndimstestres = ndims(testres)
      large_result = similar(testres, (size(testres)...,ressize...))
      colons = ntuple(d->Colon(), ndims(testres))
      ST = typeof(slice(large_result, colons..., ntuple(d->1, length(ressize))...))
      temp_result = similar(arr, ST, ressize)
      @nloops $slice_ndims i temp_result begin
        @nref($slice_ndims,temp_result,i) = slice(large_result, colons..., @ntuple($slice_ndims,i)...)
      end
      # it's important to assign this mutable function's return to the same variable because of fallback.
      newresult = mapslices_darr_larr_inner_typed!(temp_result, f, arr, dims, testres)
      if newresult.isnull
        if isa(arr, LabeledArray)
          create_labeled_array_mapslices_inner(LabeledArray(large_result), ndimstestres, arr, $slice_indices)
        else
          large_result
        end
      else
        newresult.value
      end
    else
      res = similar_mapslices_inner(arr, testres, $slice_indices)
      newresult = mapslices_darr_larr_inner_typed!(res, f, arr, dims, testres)
      newresult.isnull ? res : newresult.value
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
    counts_so_far = 0
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
      #same_size &= size_sofar == size(oneres)
      if size_sofar != size(oneres)
        fallback_result = similar(arr, typeof(testres), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      #Haven't implemented the case when same_size==false yet.
      try
        copy_mapslice_helper!(@nref($slice_ndims, result, i), oneres)
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    Nullable()
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
    counts_so_far = 0
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
      same_ldict &= (ldict_keys_sofar.isnull || ldict_keys_sofar.value == oneres.keys)
      if same_ldict
        if ldict_keys_sofar.isnull
          ldict_keys_sofar = Nullable(oneres.keys)
        end
      else
        fallback_result = similar(arr, typeof(testres), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      try
        @nref($slice_ndims, result, i) = oneres
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    Nullable()
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
    counts_so_far = 0
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
      try
        @nref($slice_ndims, result, i) = oneres
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    #@rap wrap_array nalift result
    Nullable()
  end
end

@generated mapslices_darr_larr_inner_typed_fallback!{V,U,M,K,N,T}(fallback_result::AbstractArray{V,M}, result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, counts_so_far::Int) = begin
  @debug_stmt @show "mapslices_darr_larr_inner_typed! exception occurs presumably due to type mismatch. a fallback version will run."
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
    counts = 0
    @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      oneslice = $slice_exp #slice(arr, coords...)
      icoords = CartesianIndex(@ntuple($slice_ndims, i))
      try
        if counts < counts_so_far
          setindex_mapslices_inner!(fallback_result, @nref($slice_ndims, result, i), icoords)
          #@nref($slice_ndims, fallback_result, i) = @nref($slice_ndims, result, i)
        else
          setindex_mapslices_inner!(fallback_result, nalift(f(oneslice)), icoords)
        end
      catch
        # if an exception occurs, just try once again with the fallback version.
        @debug_stmt @show "mapslices_darr_larr_inner_typed! exception occurs presumably due to type mismatch. a fallback version will run."
        oneres = nalift(f(oneslice))
        if promote_type(typeof(oneres), V) == V
          rethrow()
        end
        fallback_result = similar(arr, promote_type(typeof(oneres), V), sizearr[$slice_indices])
        return mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts)
      end
      counts += 1
    end
    fallback_result
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

setindex_mapslices_inner!(fallback_result, reselem, coords) = (fallback_result[coords]=reselem)
setindex_mapslices_inner!{V<:AbstractArray}(fallback_result::AbstractArray{V}, reselem::AbstractArray, coords) = begin
  result = similar(fallback_result[1], size(reselem)) #similar(reselem, eltype(fallback_result))
  copy!(result, reselem)
  fallback_result[coords] = result
end
#@generated setindex_mapslices_inner!{V<:AbstractArray,N,T,M}(fallback_result::AbstractArray{V,N}, #reselem::AbstractArray{T,M}, coords) = quote #copy!(fallback_result[coords], reselem)
#  @nloops $M i reselem begin
#    fallback
