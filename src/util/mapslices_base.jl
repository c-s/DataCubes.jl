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
  if !isa(result,AbstractArray) || isempty(result)
    result
  else
    peeloff_zero_array_if_necessary(result)
  end
end

peeloff_zero_array_if_necessary(x) = x
peeloff_zero_array_if_necessary{T}(arr::AbstractArray{T,0}) = arr[1]
peeloff_zero_array_if_necessary{K}(arr::DictArray{K,0}) = mapvalues(x->x[1], peel(arr))
peeloff_zero_array_if_necessary{T}(arr::LabeledArray{T,0}) = peeloff_zero_array_if_necessary(peel(arr))

mapslices_lambda_acc_int(acc, x) = acc + (x==Int)
mapslices_lambda_first(it) = it[1]
mapslices_lambda_second_int(it) = it[2] == Int
mapslices_lambda_colon(d) = Colon()
mapslices_lambda_one(d) = 1
mapslices_lambda_axis_tuple_func(testres, ressize, ndimstestres) = d -> begin
  if d<=ndimstestres
    pickaxis(testres, d)
  else
    DefaultAxis(ressize[d-ndimstestres])
  end
end

@generated mapslices_darr_larr_inner{V,N,T}(f::Function, arr::AbstractArray{V,N}, dims::T) = begin
  dimtypes = dims.types
  slice_ndims = foldl(mapslices_lambda_acc_int, 0, dimtypes)
  slice_indices = Int[map(mapslices_lambda_first, Iterators.filter(mapslices_lambda_second_int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(view(arr, coords...))
  end
  quote
    if isempty(arr)
      if $slice_ndims == 0
        return Nullable{Any}()
      else
        return similar(arr, Nullable{Any}, size(arr)[$slice_indices])
      end
    end
    sizearr = size(arr)
    coords = Array{Any}($N)
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
      large_result = LabeledArray(similar(peel(testres), (size(testres)...,ressize...)), ntuple(mapslices_lambda_axis_tuple_func(testres, ressize, ndimstestres), ndimstestres+length(ressize)))
      colons = ntuple(mapslices_lambda_colon, ndims(testres))
      ST = typeof(view(large_result, colons..., ntuple(mapslices_lambda_one, length(ressize))...))
      temp_result = similar(arr, ST, ressize)
      @nloops $slice_ndims i temp_result begin
        @nref($slice_ndims,temp_result,i) = view(large_result, colons..., @ntuple($slice_ndims,i)...)
      end
      # it's important to assign this mutable function's return to the same variable because of fallback.
      newresult = mapslices_darr_larr_inner_typed_wrapper!(temp_result, f, arr, dims, testres)
      if isnull(newresult)
        create_labeled_array_mapslices_inner(large_result, ndimstestres, arr, $slice_indices)
      else
        newresult.value
      end
    elseif reseltype<:AbstractArray
      ndimstestres = ndims(testres)
      large_result = similar(testres, (size(testres)...,ressize...))
      colons = ntuple(mapslices_lambda_colon, ndims(testres))
      ST = typeof(view(large_result, colons..., ntuple(mapslices_lambda_one, length(ressize))...))
      temp_result = similar(arr, ST, ressize)
      @nloops $slice_ndims i temp_result begin
        @nref($slice_ndims,temp_result,i) = view(large_result, colons..., @ntuple($slice_ndims,i)...)
      end
      # it's important to assign this mutable function's return to the same variable because of fallback.
      newresult = mapslices_darr_larr_inner_typed_wrapper!(temp_result, f, arr, dims, testres)
      if isnull(newresult)
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
      newresult = mapslices_darr_larr_inner_typed_wrapper!(res, f, arr, dims, testres)
      isnull(newresult) ? res : newresult.value
    end
    result
  end
end

mapslices_darr_larr_inner_typed_wrapper!{M,K,N,T,U<:AbstractArray,V}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::V) =
  mapslices_darr_larr_inner_typed!(result, f, arr, dims, testres)

@generated mapslices_darr_larr_inner_typed!{M,K,N,T,U<:AbstractArray,V}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::V) = begin
  dimtypes = dims.types
  slice_ndims = foldl(mapslices_lambda_acc_int, 0, dimtypes)
  slice_indices = Int[map(mapslices_lambda_first, Iterators.filter(mapslices_lambda_second_int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(view(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array{Any}($N)
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
        return Nullable(mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      #Haven't implemented the case when same_size==false yet.
      try
        copy_mapslice_helper!(@nref($slice_ndims, result, i), oneres)
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    Nullable()
  end
end

# TODO: VV and VVV should be actually the same, but what to do with VV=Nullable{Any} and VVV=Nullable?
mapslices_darr_larr_inner_typed_wrapper!{KK,VV,VVV,M,K,N,T}(result::AbstractArray{LDict{KK,VV},M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::LDict{KK,VVV}) =
  mapslices_darr_larr_inner_typed!(result, f, arr, dims, testres)

@generated mapslices_darr_larr_inner_typed!{KK,VV,VVV,M,K,N,T}(result::AbstractArray{LDict{KK,VV},M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::LDict{KK,VVV}) = begin
  dimtypes = dims.types
  slice_ndims = foldl(mapslices_lambda_acc_int, 0, dimtypes)
  slice_indices = Int[map(mapslices_lambda_first, Iterators.filter(mapslices_lambda_second_int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(view(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array{Any}($N)
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
      same_ldict &= (isnull(ldict_keys_sofar) || ldict_keys_sofar.value == oneres.keys)
      if same_ldict
        if isnull(ldict_keys_sofar)
          ldict_keys_sofar = Nullable(oneres.keys)
        end
      else
        fallback_result = similar(arr, typeof(testres), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      try
        @nref($slice_ndims, result, i) = oneres
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    Nullable()
  end
end

mapslices_darr_larr_inner_typed_wrapper!{U,M,K,N,T}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::U) =
  mapslices_darr_larr_inner_typed!(result, f, arr, dims, testres)

@generated mapslices_darr_larr_inner_typed!{U,M,K,N,T}(result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, testres::U) = begin
  dimtypes = dims.types
  slice_ndims = foldl(mapslices_lambda_acc_int, 0, dimtypes)
  slice_indices = Int[map(mapslices_lambda_first, Iterators.filter(mapslices_lambda_second_int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(view(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array{Any}($N)
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
      try
        @nref($slice_ndims, result, i) = oneres
      catch
        # if an exception occurs, just try once again with the fallback version.
        fallback_result = similar(arr, promote_type(typeof(oneres), typeof(testres)), sizearr[$slice_indices])
        return Nullable(mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts_so_far))
      end
      counts_so_far += 1
    end
    #@rap wrap_array nalift result
    Nullable()
  end
end

mapslices_darr_larr_inner_typed_fallback_wrapper!{V,U,M,K,N,T}(fallback_result::AbstractArray{V,M}, result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, counts_so_far::Int) =
  mapslices_darr_larr_inner_typed_fallback!(fallback_result, result, f, arr, dims, counts_so_far)

@generated mapslices_darr_larr_inner_typed_fallback!{V,U,M,K,N,T}(fallback_result::AbstractArray{V,M}, result::AbstractArray{U,M}, f::Function, arr::AbstractArray{K,N}, dims::T, counts_so_far::Int) = begin
  @debug_stmt @show "mapslices_darr_larr_inner_typed! exception occurs presumably due to type mismatch. a fallback version will run."
  dimtypes = dims.types
  slice_ndims = foldl(mapslices_lambda_acc_int, 0, dimtypes)
  slice_indices = Int[map(mapslices_lambda_first, Iterators.filter(mapslices_lambda_second_int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr[coords...])
  else
    :(view(arr, coords...))
  end
  quote
    sizearr = size(arr)
    coords = Array{Any}($N)
    counts = 0
    @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
      fill!(coords, Colon())
      @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
      oneslice = $slice_exp
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
        return mapslices_darr_larr_inner_typed_fallback_wrapper!(fallback_result, result, f, arr, dims, counts)
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
