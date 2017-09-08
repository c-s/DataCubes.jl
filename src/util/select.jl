# what I figured out for performance.
# send type information T to getindexvalue.
# use genearted @loops instead of arr[index...]

# each allocating a large size array.
# in create_by_array_inner
#  @time subarrays_buf = Array(NTuple{$N,Int}, length(indices))
# in getcondition
#  @time indices::Array{NTuple{$N,Int},1} = Array(NTuple{$N,Int}, length(t))
# in create_bymap_inner
#  @time indexvec::Vector{Int} = Array(Int, lenbyvec)

using Base.Cartesian

# used to test if @inbounds results in any substantial speed up.
#macro debuginbounds(x)
#  esc(x)
#  #:(@inbounds($(esc(x))))
#end

"""

`selectfunc(t::LabeledArray, c, b, a)`

main select function. This function is internal and is meant to be used via `selct`.
`selectfunc` takes a table `t`, condition `c`, aggreagtion by rule `b`, aggregate function `a`.

* t : a LabeledArray
* c : an array of functions `(t, inds)` -> boolean array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* b : an array of arrays of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* c : an array of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.

"""
selectfunc{T,N}(t::LabeledArray{T,N}, c, b, a) = begin
  nocond = isempty(c)
  noby = isempty(b)
  noagg = isempty(a)
  if nocond
    if noby
      if noagg
        t
      else
        if isa(t.data, DictArray)
          resa = [(k, onea(t,nothing)) for (k,onea) in a]
          if all(x->!isa(x[2], AbstractArray), resa)
            LDict(resa...)
          else
            LabeledArray(darr(resa...), t.axes)
          end
        else
          error("this should not happen: the data part of the LabeledArray is not a DictArray, but agg expression is provided.")
        end
      end
    else
      # nocond, yesby
      selected_cartesian_indices_all::Vector{NTuple{N,Int}} = getcondition(t, [(tbl, inds) -> inds])
      byvecs = [darr([(k, onebcomp(t, selected_cartesian_indices_all)) for (k,onebcomp) in oneb]...) for oneb in b]
      bymaps = [create_bymap(byvec) for byvec in byvecs]
      create_by_array(t, a, selected_cartesian_indices_all, byvecs, bymaps)
    end
  else
    # yescond
    selected_cartesian_indices::Vector{NTuple{N,Int}} = getcondition(t, c)
    if noby
      # results of a are not vectors.
      if !noagg && isa(t.data, DictArray)
        resa = [(k, onea(t,selected_cartesian_indices)) for (k,onea) in a]
        if all(x->!isa(x[2], AbstractArray), resa)
          return LDict(resa...)
        end
      end

      # yescond, noby
      aggvecs = if noagg
        if isa(t.data, DictArray)
          darr([(k, select_cartesian_elements_helper(onefld, selected_cartesian_indices)) for (k,onefld) in t.data.data]...)
          #above gives better result than below.
          #darr([(k, eltype(onefld)[onefld[i...] for i in selected_cartesian_indices]) for (k,onefld) in t.data.data]...)
        else
          tdata = t.data
          select_cartesian_elements_helper(tdata, selected_cartesian_indices)
          #above gives better result than below.
          #eltype(tdata)[tdata[i...] for i in selected_cartesian_indices]
        end
      else
        if isa(t.data, DictArray)
          darr([(k, onea(t, selected_cartesian_indices)) for (k,onea) in a]...)
        else
          error("The data part of the LabeledArray is not a DictArray, but agg expression is provided.")
        end
      end
      create_square_array(aggvecs, t, selected_cartesian_indices)
    else
      # yescond, yesby
      byvecs = [darr([(k, onebcomp(t, selected_cartesian_indices)) for (k,onebcomp) in oneb]...) for oneb in b]
      bymaps = [create_bymap(byvec) for byvec in byvecs]
      create_by_array(t, a, selected_cartesian_indices, byvecs, bymaps)
    end
  end
end

#select_cartesian_elements_helper{T,N}(fld::AbstractArray{T,N}, indices::Vector{NTuple{N,Int}}) = begin
#  result = Array(T, length(indices))
#  select_cartesian_elements_helper2(fld

@generated select_cartesian_elements_helper{T,N}(fld::AbstractArray{T,N}, indices::Vector{NTuple{N,Int}}) = quote
  result = Array{T}(length(indices))
  #result::T = similar(fld, length(indices))
  for i in eachindex(result)
    @inbounds index = indices[i]
    @inbounds result[i] = @nref $N fld d->index[d]
  end
  result
end

@generated select_cartesian_elements_helper{T<:AbstractFloat,N,A}(fld::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}},
                                                                indices::Vector{NTuple{N,Int}}) = quote
  result = Array{T}(length(indices))
  #result::T = similar(fld, length(indices))
  fldunderlying = fld.a.data
  for i in eachindex(result)
    @inbounds index = indices[i]
    @inbounds result[i] = @nref $N fldunderlying d->index[d]
  end
  AbstractArrayWrapper(FloatNAArray(result))
end


"""

`updatefunc(t::LabeledArray, c, b, a)`

main update function. This function is internal and is meant to be used via `update`.
`updatefunc` takes a table `t`, condition `c`, aggreagtion by rule `b`, aggregate function `a`.

* `t` : a LabeledArray
* `c` : an array of functions `(t, inds)` -> boolean array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* `b` : an array of arrays of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* `c` : an array of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.

"""
updatefunc{T,N}(t::LabeledArray{T,N}, c, b, a) = begin
  nocond = isempty(c)
  noby = isempty(b)
  noagg = isempty(a)
  if noagg
    t
  elseif nocond
    # agg but nocond noby
    if noby
      addres = map(a) do konea
        konea[1] => konea[2](t, nothing)
      end
      LabeledArray(merge(t.data, addres...), t.axes)
    else
      # nocond, yesby
      selected_cartesian_indices_all::Vector{NTuple{N,Int}} = getcondition(t, [(tbl, inds) -> inds])
      flattened_b = [b...;]
      byvec = darr([(k, onebcomp(t, selected_cartesian_indices_all)) for (k,onebcomp) in flattened_b]...)
      bymap = create_bymap(byvec, true)
      update_by_array(t, a, selected_cartesian_indices_all, byvec, bymap)
    end
  else
    # agg with cond
    selected_cartesian_indices::AbstractArray{NTuple{N,Int},1} = getcondition(t, c)
    if isempty(selected_cartesian_indices)
      return t
    end
    if noby
      result = copy(t.data.data)
      addres = map(a) do konea
        k = konea[1]
        onea = konea[2]
        aggvec = onea(t, selected_cartesian_indices)
        if haskey(result, k)
          resultk = copy(result[k])
          i = 1
          for coords in selected_cartesian_indices
            resultk[coords...] = aggvec[i]
            i += 1
          end
        else
          isaggvecarray = isa(aggvec, AbstractArray)
          resultk = if isaggvecarray
            similar(aggvec, size(t.data))
          else
            similar(t.data, typeof(aggvec), size(t.data))
          end
          setna!(resultk, :)
          i = 1
          if isaggvecarray
            for coords in selected_cartesian_indices
              resultk[coords...] = aggvec[i]
              i += 1
            end
          else
            for coords in selected_cartesian_indices
              resultk[coords...] = aggvec
              i += 1
            end
          end
        end
        k => resultk
      end
      LabeledArray(darr(merge(result, LDict(addres...))...), t.axes)
    else
      # yes agg, by, cond
      flattened_b = [b...;]
      byvec = darr([(k, onebcomp(t, selected_cartesian_indices)) for (k,onebcomp) in flattened_b]...)
      bymap = create_bymap(byvec, true)
      update_by_array(t, a, selected_cartesian_indices, byvec, bymap)
    end
  end
end

zero_func(_) = 0
# creates a by array for selectfunc.
create_by_array(t, a, indices, byvecs, bymaps) =
  create_by_array_inner(t, a, indices, byvecs, bymaps, Array{Int}(ntuple(zero_func, length(bymaps))...))

create_by_array_inner_private_first(x) = x[1]
create_by_array_inner_private_second(x) = x[2]
create_by_array_inner_private_len(x) = length(x[1][1])
create_by_array_inner_private_indexsubarrays(index_subarrays) = tp -> similar(index_subarrays, tp)
create_by_array_inner_private_comprehension1(t) = [(k, (t,r) -> selectfield(t,k,r)) for (k,_) in t.data.data]
create_by_array_inner_private_comprehension2(effa, results) = [(konea[1], result) for (konea, result) in zip(effa, results)]
# N is the original array dimensions.
# M is the byarray dimentions.
@generated create_by_array_inner{T,N,M}(t::AbstractArray{T,N}, a, indices::Vector{NTuple{N,Int}}, byvecs, bymaps, dummy::Array{Int,M}) = quote
  labels::Tuple = (map(create_by_array_inner_private_first, bymaps)...)
  # assumes there is at least one label for each axis.
  ressize::NTuple{$M,Int} = (map(create_by_array_inner_private_len, bymaps)...)
  indexvecs::NTuple{$M,Vector{Int}} = (map(create_by_array_inner_private_second, bymaps)...)
  indcountmat::Array{Int,$M} = fill(0, ressize)
  for i in eachindex(indices)
    @inbounds @nexprs $M j->(ids_j = indexvecs[j][i])
    @inbounds @nref($M,indcountmat,ids) += 1
  end
  subarrays_buf = Array{NTuple{$N,Int}}(length(indices))
  index_subarrays = similar(indcountmat, SubArray{NTuple{$N,Int},1,Array{NTuple{$N,Int},1},Tuple{UnitRange{Int}},SUBARRAY_LAST_TYPE})
  indsumsofar::Int = 0
  lenindcountmat::Int = length(indcountmat)
  for i in 1:lenindcountmat
    prevsum = indsumsofar
    @inbounds indsumsofar += indcountmat[i]
    @inbounds index_subarrays[i] = view(subarrays_buf, prevsum+1:indsumsofar)
  end
  # change the meaning of indcountmat, not to create another buffer.
  fill!(indcountmat, 0)
  counter::Int = 1
  for i in eachindex(indices)
    @inbounds @nexprs $M j->(ids_j = indexvecs[j][i])
    @inbounds current_count = @nref($M,indcountmat,ids) + 1
    @inbounds @nref($M,indcountmat,ids) = current_count
    @inbounds subarray = @nref($M, index_subarrays, ids)
    @inbounds subarray[current_count] = indices[i]
  end
  effa = if isempty(a)
    create_by_array_inner_private_comprehension1(t)
  else
    a
  end

  # There is a problem when an element in index_subarrays is empty. In that case, the type is not properly marked.
  # This is ultimately due to strange map function behavior. For example,
  #   map((x,y)->x==y, Int[], Int[])
  # is an Int array, not a boolean array (Granted that I couldn't see a better way, though).
  # So, comment out this:
  # DictArray(LDict([(k, map(r->lift_naelem(onea(t,r)), index_subarrays)) for (k, onea) in a]...))
  # and implement another method, by creating an empty array for each onea in a, and fill it up.
  # But first, we need to check the type of each element in each onea, which can be done by examining any
  # non zero length array results. We assume that all elements have the same type.
  restypes = map(create_by_array_inner_private_lambda1(index_subarrays, t), effa)
  # Now, let's create empty arrays to fill up results later.
  results = map(create_by_array_inner_private_indexsubarrays(index_subarrays), restypes)
  for (konea, result) in zip(effa, results)
    fill_byarrays!(result, konea[2], index_subarrays, t)
  end
  aggvecs = DictArray(LDict(create_by_array_inner_private_comprehension2(effa, results)...))
  newaxes = map(create_by_array_inner_private_lambda2, byvecs, labels)
  LabeledArray(aggvecs, (newaxes...))
end

create_by_array_inner_private_lambda1(index_subarrays, t) = konea -> begin
  onea = konea[2]
  for inds in index_subarrays
    # perhaps it is okay to just use one index.
    # but do not attempt it now.
    #return typeof(apply_nullable(onea(t,inds[1:1])))
    if !isempty(inds)
      return typeof(apply_nullable(onea(t,inds)))
    end
  end
  return Any
end

create_by_array_inner_private_lambda2(byvec, label) = DictArray(byvec.data.keys, collect(label))

@generated fill_byarrays!{T,M,V}(result::AbstractArray{Nullable{T},M}, onea, index_subarrays::AbstractArray{V,M}, t::LabeledArray) = quote
  @nloops $M i result begin
    inds = @nref($M,index_subarrays,i)
    value = if isempty(inds)
      Nullable{T}()
    else
      apply_nullable(onea(t, inds))
    end
    @nref($M,result,i) = value
  end
end

#bymap_coords_calculate_helper{T}(bymap::Dict{T,Int}, byvec, bytype::Type{T}, i::Int) = begin
#  v::T = getindexvalue(byvec,bytype,i)
#  bymap[v]::Int
#end

create_bymap(byvec::DictArray, skip_ordering::Bool=false) = begin
  # N 1 dimensional vectors to store the result axis labels.
  labelvecs = ntuple(length(byvec.data)) do d
    #elvaluetype(byvec.data.values[d])[]
    create_zero_byvec(byvec.data.values[d])
  end
  create_bymap_inner(byvec, labelvecs, Tuple{[elvaluetype(v) for v in byvec.data.values]...}, skip_ordering)
end

create_bymap_inner{T,L}(byvec::DictArray, labelvecs::L, ::Type{T}, skip_ordering::Bool) = if isa(byvec, DictArray)
  # resmap: (d dim tuple) for the key tuple => the coordiante in the result byarray.
  lenbyvec::Int = length(byvec)
  resmap = Dict{T,Int}()
  # well, this type annotation is necessary to enhance performance!
  # don't know why the type is not inferred stably.
  indexvec::Vector{Int} = Array{Int}(lenbyvec)
  counter = 1
  for i in 1:lenbyvec
    value::T = getindexvalue(byvec, T, i)
    # index is the index in the output byarray along some direction.
    # why is this more efficient than get! ?
    index::Int = if haskey(resmap, value)
      resmap[value]
    else
      push_labelvecs_inner!(labelvecs, value)
      tempcounter = counter
      counter += 1
      resmap[value] = tempcounter
      tempcounter
    end
    @inbounds indexvec[i] = index
  end
  # check to see if reordeingr indices is necessary.
  tosort_indices = Bool[method_exists(isless,(peel_nullabletype(eltype(x)),peel_nullabletype(eltype(x)))) for x in labelvecs]
  nochange_flag = skip_ordering || !any(tosort_indices)
  if nochange_flag
    labelvecs, indexvec
  else
    # reorder indices.
    toorder_labels = collect(zip(labelvecs[tosort_indices]...))
    neworder = sortperm(toorder_labels, lt=byarray_isless)
    len = length(toorder_labels)
    # well, this type annotation is necessary to enhance performance!
    # don't know why the type is not inferred correctly.
    inverse_order::Vector{Int} = Array{Int}(len)
    for i in eachindex(neworder)
      @inbounds inverse_order[neworder[i]] = i
    end
    for labelvec in labelvecs
      permute!(labelvec, neworder)
    end
    for i in eachindex(indexvec)
      @inbounds indexvec[i] = inverse_order[indexvec[i]]
    end
    labelvecs, indexvec
  end
else
  error("did not implelment yet.")
end

# TODO logically the below should be fine, and was fine til julia v0.5.
#@generated push_labelvecs_inner!{N}(labelvecs::NTuple{N}, value::NTuple{N}) = begin
@generated push_labelvecs_inner!(labelvecs::Tuple, value::Tuple) = begin
  N = length(value.types)
  exprs = Any[:(push!(labelvecs[$i], value[$i])) for i in 1:N]
  Expr(:block, exprs...)
end

peel_nullabletype{T}(::Type{Nullable{T}}) = T
peel_nullabletype{T}(::Type{T}) = T
peel_nullabletype(::Type{Nullable}) = Any

@inline byarray_isless(x, y) = isless(x, y)
@inline byarray_isless{T}(x::Nullable{T}, y::Nullable{T}) =
  (isnull(x) && !isnull(y)) || (!isnull(x) && !isnull(y) && isless(x.value, y.value))

@generated byarray_isless(x::Tuple, y::Tuple) = begin
  N = length(x.types)
  exprs = map(1:N) do n
    quote
      if byarray_isless(x[$n],y[$n])
        return true
      elseif byarray_isless(y[$n],x[$n])
        return false
      end
    end
  end
  Expr(:block, exprs..., :(return false))
end

create_square_array{T,N}(aggvec, t::AbstractArray{T,N}, inds::Vector{NTuple{N,Int}}) = begin
  sz::NTuple{N,Int} = size(t)
  boolvecs::NTuple{N,BitVector} = ntuple(d->falses(sz[d]), N)
  create_square_array_helper1!(boolvecs, inds)
  wherevecs::NTuple{N,Vector{Int}} = ntuple(d->find(boolvecs[d]), N)
  reversemapvec::NTuple{N,Vector{Int}} = map(boolvecs, wherevecs) do boolvec, wherevec
    v = Array{Int}(length(boolvec))
    @inbounds v[wherevec] = 1:length(wherevec)
    v
  end
  ressize = map(length, wherevecs)
  result = similar(aggvec, ressize)

  setna!(result)
  newinds = create_square_array_helper2(inds, reversemapvec)
  setcartesian!(result, aggvec, newinds)
  # result is the data field of the return value. Now work on the axes part.
  @inbounds newaxes = map((axis, wherevec) -> isa(axis, DefaultAxis) ? DefaultAxis(length(wherevec)) : axis[wherevec], t.axes, wherevecs)
  LabeledArray(result, (newaxes...))
end

@generated create_square_array_helper1!{N}(boolvecs::NTuple{N,BitVector}, inds::Vector{NTuple{N,Int}}) = quote
  for ind in inds
    @nexprs $N d->boolvecs[d][ind[d]] = true
  end
end

@generated create_square_array_helper2{N}(inds::AbstractVector{NTuple{N,Int}}, reversemapvec::NTuple{N,Vector{Int}}) = quote
  newinds = Array{NTuple{$N,Int}}(length(inds))
  for i in eachindex(newinds)
    tpl = @ntuple $N d->reversemapvec[d][inds[i][d]]
    @inbounds newinds[i] = tpl
  end
  newinds
end
# the current version of create_square_array_helper in julia 0.4.1 turns out to be definitely faster than below.
# map(ind->ntuple(d->reversemapvec[d][ind[d]], N), inds)

setcartesian!{N}(tgt::DictArray, src::DictArray, inds::AbstractArray{NTuple{N,Int},1}) = begin
  for (k, v) in src.data
    @inbounds onefield = tgt.data[k]
    setcartesian_inner!(inds, onefield, v)
  end
  tgt
end
setcartesian!{T,N}(tgt::AbstractArray{Nullable{T},N}, src::AbstractArray{Nullable{T},1}, inds::AbstractArray{NTuple{N,Int},1}) = begin
  setcartesian_inner!(inds, tgt, src)
  tgt
end


setcartesian_inner!{T,N}(inds::AbstractArray{NTuple{N,Int},1}, onefield::AbstractArray{T,N}, v::AbstractArray{T,1}) = begin
  for (ind,onev) in zip(inds,v)
    @inbounds onefield[ind...] = onev
  end
  # this hardly gains any.
  #for i in eachindex(inds)
  #  @inbounds onefield[inds[i]...] = v[i]
  #end
end

# A view of an array, to be used in selectfield below.
# It won't be too difficult to implement because we assume it is a one dimensional array,
# determined by a vector of cartesian indices.
immutable SubArrayView{T,N,A,I} <: AbstractVector{T}
  data::A
  indices::I
end

# a syb array view of an array to select a portion of a `LabeledArray` during `selct` or `update`.
SubArrayView{T,N}(data::AbstractArray{T,N}, indices::AbstractVector{NTuple{N,Int}}) = SubArrayView{T,N,typeof(data),typeof(indices)}(data, indices)
SubArrayView{T,N,A}(data::AbstractArrayWrapper{T,N,A}, indices::AbstractVector{NTuple{N,Int}}) = SubArrayView{T,N,A,typeof(indices)}(data.a, indices)
SubArrayView{T,N,A}(data::AbstractArrayWrapper{Nullable{T},N,FloatNAArray{T,N,A}}, indices::AbstractVector{NTuple{N,Int}}) = FloatNAArray(SubArrayView{T,N,A,typeof(indices)}(data.a.data, indices))
Base.getindex{T,N,A,I}(arr::SubArrayView{T,N,A,I}, arg::Int) = arr.data[arr.indices[arg]...]
# Let's make the array immutable at this stage.
#Base.setindex!{T,N}(arr::SubArrayView{T,N}, v::T, arg::Int) = setindex!(arr.data, v, arr.indices[arg]...)
Base.start(iter::SubArrayView) = 1
Base.next{T,N,A,I}(iter::SubArrayView{T,N,A,I}, state) = (iter.data[iter.indices[state]...], state+1)
Base.done(iter::SubArrayView, state) = state > length(iter.indices)
Base.size(arr::SubArrayView) = (length(arr.indices),)
Base.eltype{T,N,A,I}(::Type{SubArrayView{T,N,A,I}}) = T
Base.endof(arr::SubArrayView) = length(arr.indices)
Base.IndexStyle{T,N,A,I}(::Type{SubArrayView{T,N,A,I}}) = Base.IndexLinear()
Base.similar{T,N,A,I,U,M}(arr::SubArrayView{T,N,A,I}, ::Type{U}, dims::NTuple{M,Int}) = similar(arr.data, U, dims)
Base.similar{T,N,A,I,U}(arr::SubArrayView{T,N,A,I}, ::Type{U}, dims::Int...) = similar(arr.data, U, dims...)
# need this special case because the underlying arr.data is not of the same shape as the corresponding SubArrayView.
Base.similar{T,N,A,I,U}(arr::SubArrayView{T,N,A,I}, ::Type{U}) = similar(arr.data, U, size(arr))
view(arr::SubArrayView, args::Union{Colon,Int,AbstractVector}...) = SubArrayView(arr.data, view(arr.indices, args...))
view(arr::SubArrayView, args::Tuple{Vararg{Union{Colon,Int,AbstractVector}}}) = SubArrayView(arr.data, view(arr.indices, args...))
#getindexvalue{T}(arr::SubArrayView, ::Type{T}, arg::Int) = getindexvalue(arr.data, T, arr.indices[arg]...)
getindexvalue(arr::SubArrayView, arg::Int) = getindexvalue(arr.data, arr.indices[arg]...)


"""

`selectfield(t, fld, inds)` : select a field whose name is `fld` at cartesian coordinates `inds` in a LabeledArray `t`.
If `inds` is `nothing`, it chooses an entire `fld` from `t`.

"""
function selectfield end

selectfield(t::LabeledArray, fld, ::Void) = begin
  onefld = selectfield(t, fld)
  wrap_array(onefld)
end
selectfield(t::LabeledArray, fld, inds) = AbstractArrayWrapper(SubArrayView(selectfield(t,fld), inds))
selectfield{K,N}(t::LabeledArray, fld::AbstractArray{Nullable{K},N}, ::Void) = begin
  # use a slower version: find a field for each ind.
  @inbounds r=simplify_array([isnull(onefld) ? Nullable{Any}() : selectfield(t,onefld.value)[i] for (i,onefld) in enumerate(fld)])
  #TODO this does not work anymore in julia v0.6.
  #@inbounds r=simplify_array([isnull(onefld) ? Nullable{Any}() : selectfield(t,onefld.value)[i] for (i,onefld) in zip(eachindex(fld), fld)])
  reshape(r, size(fld))
end

selectfield{K,N}(t::LabeledArray, fld::AbstractVector{Nullable{K}}, inds::AbstractArray{NTuple{N,Int},1}) = begin
  if length(fld) != length(inds)
    throw(ArgumentError("key lengths do not match with indices length."))
  end
  # use a slower version: find a field for each ind.
  @inbounds r=simplify_array([isnull(onefld) ? Nullable{Any}() : selectfield(t,onefld.value)[i...] for (i,onefld) in zip(inds,fld)])
  r
end

getcondition_apply_where(t) = (inds, onec) -> onec(t, inds)

# create an array of cartesian indices of a LabeledArray that satisfies
# the conditions in c.
@generated getcondition{T,N}(t::LabeledArray{T,N}, c) = quote
  indices_array = Array{NTuple{$N,Int}}(length(t))

  index = 1

  @nloops $N i t begin
    tupleind::NTuple{$N,Int} = @ntuple $N i
    @inbounds indices_array[index] = tupleind
    index += 1
  end
  foldl(getcondition_apply_where(t), indices_array, c)
end

# larray -> indices -> field name -> element.
# Implementationwise, it is easier to do larray -> fieldname -> indices -> element.
# This and other *LazilySelectedLabeledArray class help to use the other mapping above.
immutable LazilySelectedLabeledArray{T,N,AXES<:Tuple,TN,I} #<: Associative
  larray::LabeledArray{T,N,AXES,TN}
  indices::I #::{Array{NTuple{N,Int}}
end

immutable IGNALazilySelectedLabeledArray{T,N,AXES<:Tuple,TN,I} #<: Associative
  larray::LabeledArray{T,N,AXES,TN}
  indices::I #::Array{NTuple{N,Int}}
end

immutable ISNALazilySelectedLabeledArray{T,N,AXES<:Tuple,TN,I} #<: Associative
  larray::LabeledArray{T,N,AXES,TN}
  indices::I #Array{NTuple{N,Int}}
end

Base.get{K}(d::LazilySelectedLabeledArray, k::AbstractArray{Nullable{K}}, _) = selectfield(d.larray, k, d.indices)
Base.get{K}(d::IGNALazilySelectedLabeledArray, k::AbstractArray{Nullable{K}}, _) = igna(selectfield(d.larray, k, d.indices))
Base.get{K}(d::ISNALazilySelectedLabeledArray, k::AbstractArray{Nullable{K}}, _) = isna(selectfield(d.larray, k, d.indices))
Base.get{K}(d::LazilySelectedLabeledArray, k::K, _) = selectfield(d.larray, k, d.indices)
Base.get{K}(d::IGNALazilySelectedLabeledArray, k::K, _) = igna(selectfield(d.larray, k, d.indices))
Base.get{K}(d::ISNALazilySelectedLabeledArray, k::K, _) = isna(selectfield(d.larray, k, d.indices))

# TODO: this is only introduced to suppress error when transitioning from julia 0.5 to 0.6.
Base.getindex{K}(d::LazilySelectedLabeledArray, k::K) = get(d, k, nothing)
Base.getindex{K}(d::IGNALazilySelectedLabeledArray, k::K) = get(d, k, nothing)
Base.getindex{K}(d::ISNALazilySelectedLabeledArray, k::K) = get(d, k, nothing)

Base.length{T,N,AXES<:Tuple,TN}(d::LazilySelectedLabeledArray{T,N,AXES,TN,Void}) = length(d.larray)
Base.length{T,N,AXES<:Tuple,TN,I}(d::LazilySelectedLabeledArray{T,N,AXES,TN,I}) = length(d.indices)
Base.length{T,N,AXES<:Tuple,TN}(d::IGNALazilySelectedLabeledArray{T,N,AXES,TN,Void}) = length(d.larray)
Base.length{T,N,AXES<:Tuple,TN,I}(d::IGNALazilySelectedLabeledArray{T,N,AXES,TN,I}) = length(d.indices)
Base.length{T,N,AXES<:Tuple,TN}(d::ISNALazilySelectedLabeledArray{T,N,AXES,TN,Void}) = length(d.larray)
Base.length{T,N,AXES<:Tuple,TN,I}(d::ISNALazilySelectedLabeledArray{T,N,AXES,TN,I}) = length(d.indices)
Base.size{T,N,AXES<:Tuple,TN}(d::LazilySelectedLabeledArray{T,N,AXES,TN,Void}) = size(d.larray)
Base.size{T,N,AXES<:Tuple,TN,I}(d::LazilySelectedLabeledArray{T,N,AXES,TN,I}) = size(d.indices)
Base.size{T,N,AXES<:Tuple,TN}(d::ISNALazilySelectedLabeledArray{T,N,AXES,TN,Void}) = size(d.larray)
Base.size{T,N,AXES<:Tuple,TN,I}(d::ISNALazilySelectedLabeledArray{T,N,AXES,TN,I}) = size(d.indices)
Base.size{T,N,AXES<:Tuple,TN}(d::IGNALazilySelectedLabeledArray{T,N,AXES,TN,Void}) = size(d.larray)
Base.size{T,N,AXES<:Tuple,TN,I}(d::IGNALazilySelectedLabeledArray{T,N,AXES,TN,I}) = size(d.indices)
Base.similar(d::LazilySelectedLabeledArray, element_type::Type, dim, dims...) = similar(d.larray, element_type, dim, dims...)
Base.similar(d::IGNALazilySelectedLabeledArray, element_type::Type, dim, dims...) = similar(d.larray, element_type, dim, dims...)
Base.similar(d::ISNALazilySelectedLabeledArray, element_type::Type, dim, dims...) = similar(d.larray, element_type, dim, dims...)

igna(d::LazilySelectedLabeledArray) = IGNALazilySelectedLabeledArray(d.larray, d.indices)
isna(d::LazilySelectedLabeledArray) = ISNALazilySelectedLabeledArray(d.larray, d.indices)

"""

`sel(func, t [; c=[], b=[], a=[]])`

an intermediate `select`/`update` function to connect `selectfunc`/`updatefunc` and `@select`(`selct`)/`@update`(`update`).

##### Arguments

Below `t'` is an object such that `t'[k]` for a field name `k` gives the corresponding array
for the field `k` in the table `t` at the coordinates selected so far.
* `func` : selectfunc or updatefunc.
* `t` : a LabeledArray.
* `c` : an array of conditions of type `t'` -> nullable boolean array.
* `b` : an array of arrays of pairs from field names to by functions specified as `t'` -> a nullable array.
* `a` : an array of pairs from field names to aggregate functions specified as `t'` -> a nullable array.

"""
sel(func, t; c=[], b=[], a=[]) = begin
  efft = isa(t, DictArray) ? LabeledArray(t) : t
  cfuncs = map(c) do onec
    if isa(onec, Function)
      (d, inds) -> begin
        @inbounds r = inds[ignabool(onec(LazilySelectedLabeledArray(efft, inds)))]
        r
      end
    else
      (d, inds) -> begin
        @inbounds r = inds[ignabool(selectfield(d, onec, inds))]
        r
      end
    end
  end
  bfuncs = map(b) do oneb
    map(oneb) do subb
      if !isa(subb, Pair) && !isa(subb, Tuple)
        subb => (d, inds) -> selectfield(d, subb, inds)
      elseif isa(subb[2], Function)
        subb[1] => (d, inds) -> subb[2](LazilySelectedLabeledArray(efft, inds))
      else
        subb[1] => (d, inds) -> selectfield(d, subb[2], inds)
      end
    end
  end
  afuncs = map(a) do onea
    if !isa(onea, Pair) && !isa(onea, Tuple)
      onea => (d, inds) -> selectfield(d, onea, inds)
    elseif isa(onea[2], Function)
      onea[1] => (d, inds) -> onea[2](LazilySelectedLabeledArray(efft, inds))
    else
      onea[1] => (d, inds) -> selectfield(d, onea[2], inds)
    end
  end
  if isa(t, DictArray)
    result = func(efft, cfuncs, bfuncs, afuncs)
    if isa(result, LabeledArray) && all(map(axis->isa(axis,DefaultAxis), result.axes))
      result.data
    else
      result
    end
  else
    func(efft, cfuncs, bfuncs, afuncs)
  end
end

"""

`@select(t, args...)`

Select macro transforms a `LabeledArray` or `DictArray` into another by choosing / grouping / aggregating.

##### Arguments

Below `t'` is an object such that `t'[k]` for a field name `k` gives the corresponding array
for the field `k` in the table `t` at the coordinates selected so far.

* `t` : a `LabeledArray` or `DictArray`.
* `args...` : each argument can be field names, fieldname=>(t'->nullable array function) pair, `by[...]` or `where[...]`. A fieldname=function can be used instead of the pair notation if the fieldname is a symbol. The first `by[...]` has an array of similar expressions and determines the 1st axis. The second `by[...]` similarly determines the 2nd axis. The output `LabeledArray` will have dimensions of the number of `by[...]` clauses, or the original dimensions if no `by[...]` is provided. `where[...]` has (`t'`->nullable boolean array) functions inside and chooses the appropriate portion of the original array. Multiple `where[...]` will simply be combined.

##### Function Specification

Note that a function (`t'`->nullable array) is expressed by some **expression** with variable names with underscores. The **expression** is converted into `t''->**expression**. Symbols with underscores are converted in the following way:

* `_k` : translates to `t'[k]`. The field name `k` should be a symbol.
* `_!k` : translates to `isna(t')[k]`. It gives a boolean array to denote whether an element is null. The field name `k` should be a symbol.
* `_` : translates to `t'` if none of the above is applicable. It is useful when the field name is not a symbol.

##### Return

A `LabeledArray` transformed by `args...` if `t` is a `LabeledArray`.
If `t` is `DictArray` and the transformed `LabeledArray` has `DefaultAxis` along each direction, the return value is also a `DictArray`. Otherwise it is a `LabeledArray`.

##### Examples

```julia
julia> t = @larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z])
10 LabeledArray

   |a  b c
---+-------
1  |1  1 x
2  |2  2 x
3  |3  3 x
4  |4    x
5  |5    y
6  |6    y
7  |7  1 y
8  |8  1 z
9  |9  2 z
10 |10 3 z


julia> @select(t, :a, :b=>_b .* 2)
10 LabeledArray

   |a  b
---+-----
1  |1  2
2  |2  4
3  |3  6
4  |4
5  |5
6  |6
7  |7  2
8  |8  2
9  |9  4
10 |10 6


julia> @select(t, :a, :b=>_b .* 2, where[_c .!= :z], where[_a .> 2])
5 LabeledArray

  |a b
--+----
1 |3 6
2 |4
3 |5
4 |6
5 |7 2


julia> @select(t, a=mean(_a), b=sum(_b .* 2), by[d=_b .* 2], by[:c])
4 x 3 LabeledArray

c |x     |y     |z
--+------+------+-------
d |a   b |a   b |a    b
--+------+------+-------
  |4.0 0 |5.5 0 |
2 |1.0 2 |7.0 2 |8.0  2
4 |2.0 4 |      |9.0  4
6 |3.0 6 |      |10.0 6
```

"""
macro select(t, args...)
  select_inner(:selectfunc, t, args...)
end


"""

`selct(t, agg... [; by=[...]..., where=[...]...])`

Select a `LabeledArray` or `DictArray` into another by choosing / grouping / aggregating.

##### Arguments

Below `t'` is an object such that `t'[k]` for a field name `k` gives the corresponding array
for the field `k` in the table `t` at the coordinates selected so far.

* `t` : a `LabeledArray` or `DictArray`.
* `agg...` : each argument can be field names, fieldname=>(t'->nullable array function) pair, `by[...]` or `where[...]`. A fieldname=function can be used instead of the pair notation if the fieldname is a symbol.
* `by=[...]`: the first `by=[...]` has an array of similar expressions and determines the 1st axis. The second `by=[...]` similarly determines the 2nd axis. The output `LabeledArray` will have dimensions of the number of `by[...]` clauses, or the original dimensions if no `by[...]` is provided.
* `where=[...]`: has (`t'`->nullable boolean array) functions inside and chooses the appropriate portion of the original array. Multiple `where=[...]` will simply be combined.

##### Return

A `LabeledArray` transformed by `args...` if `t` is a `LabeledArray`.
If `t` is `DictArray` and the transformed `LabeledArray` has `DefaultAxis` along each direction, the return value is also a `DictArray`. Otherwise it is a `LabeledArray`.

##### Examples

```julia
julia> t = @larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z])
10 LabeledArray

   |a  b c
---+-------
1  |1  1 x
2  |2  2 x
3  |3  3 x
4  |4    x
5  |5    y
6  |6    y
7  |7  1 y
8  |8  1 z
9  |9  2 z
10 |10 3 z


julia> selct(t, :a, :b=>d->d[:b] .* 2)
10 LabeledArray

   |a  b
---+-----
1  |1  2
2  |2  4
3  |3  6
4  |4
5  |5
6  |6
7  |7  2
8  |8  2
9  |9  4
10 |10 6


julia> selct(t, :a, :b=>d->d[:b] .* 2, where=[d->d[:c] .!= :z], where=[d->d[:a] .> 2])
5 LabeledArray

  |a b
--+----
1 |3 6
2 |4
3 |5
4 |6
5 |7 2


julia> selct(t, a=d->mean(d[:a]), b=d->sum(d[:b] .* 2), by=Any[:d=>d->d[:b] .* 2], by=[:c])
4 x 3 LabeledArray

c |x     |y     |z
--+------+------+-------
d |a   b |a   b |a    b
--+------+------+-------
  |4.0 0 |5.5 0 |
2 |1.0 2 |7.0 2 |8.0  2
4 |2.0 4 |      |9.0  4
6 |3.0 6 |      |10.0 6
```

"""
function selct end

selct(t::LabeledArray, args...; kwargs...) = selct_untyped(t, args...; kwargs...)
selct(t::DictArray, args...; kwargs...) = selct_untyped(t, args...; kwargs...)
selct_untyped(t, args...; kwargs...) = begin
  a = Any[args...]
  b = []
  c = []
  for (k,v) in kwargs
    if k == :by
      push!(b, isa(v, AbstractArray) ? v : [v])
    elseif k == :where
      push!(c, (isa(v, AbstractArray) ? v : [v])...)
    else
      push!(a, k=>v)
    end
  end
  sel(selectfunc, t; c=c, b=b, a=a)
end

"""

`@update(t, args...)`

Similar to `select` macro, but is used to update and create a new `LabeledArray` or `DictArray` from the original one.
The main difference from the `select` macro is that it keeps the original fields intact, unless
directed otherwise, whereas the `select` macro only chooses the fields that are explicitly specified.

##### Arguments
Below `t'` is an object such that `t'[k]` for a field name k gives the corresponding array
for the field `k` in the table `t` at the coordinates selected so far.

* `t` : a `LabeledArray` or `DictArray`.
* `args...` : each argument can be field names, fieldname=>(`t'`->nullable array function) pair or `where[...]`. A fieldname=function can be used instead of the pair notation if the fieldname is a symbol. `by[...]` has (`t'`->nullable array) as its elements and used as in grouping when updateing. Multiple `by[...]` are simply combined. `where[...]` has
(`t'`->nullable boolean array) functions inside and chooses the appropriate portion of the original array. Multiple `where[...]` will simply be combined.

##### Function Specification

Note that a function (`t'`->nullable array) is expressed by some **expression** with variable names with underscores. The **expression** is converted into `t''->**expression**. Symbols with underscores are converted in the following way:

* `_k` : translates to `t'[k]`. The field name `k` should be a symbol.
* `_!k` : translates to `isna(t')[k]`. It gives a boolean array to denote whether an element is null. The field name `k` should be a symbol.
* `_` : translates to `t'` if none of the above is applicable. It is useful when the field name is not a symbol.

##### Return

An updated array of the same type as `t`.

##### Examples

```julia
julia> t = @larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z])
10 LabeledArray

   |a  b c
---+-------
1  |1  1 x
2  |2  2 x
3  |3  3 x
4  |4    x
5  |5    y
6  |6    y
7  |7  1 y
8  |8  1 z
9  |9  2 z
10 |10 3 z


julia> @update(t, a=_a .+ 100, d=_a .* _b)
10 LabeledArray

   |a   b c d
---+-----------
1  |101 1 x 1
2  |102 2 x 4
3  |103 3 x 9
4  |104   x
5  |105   y
6  |106   y
7  |107 1 y 7
8  |108 1 z 8
9  |109 2 z 18
10 |110 3 z 30


julia> @update(t, a=_a .+ 100, d=_a .* _b, where[~isna(_b)])
10 LabeledArray

   |a   b c d
---+-----------
1  |101 1 x 1
2  |102 2 x 4
3  |103 3 x 9
4  |4     x
5  |5     y
6  |6     y
7  |107 1 y 7
8  |108 1 z 8
9  |109 2 z 18
10 |110 3 z 30


julia> @update(t, a=sum(_a), d=reverse(_a .* _b), where[~isna(_b)], by[:b])
10 LabeledArray

   |a  b c d
---+----------
1  |16 1 x 8
2  |11 2 x 18
3  |13 3 x 30
4  |4    x
5  |5    y
6  |6    y
7  |16 1 y 7
8  |16 1 z 1
9  |11 2 z 4
10 |13 3 z 9
```

"""
macro update(t, args...)
  select_inner(:updatefunc, t, args...)
end


"""

`update(t, agg... [; by=[...]..., where=[...]...])`

Similar to `selct`, but is used to update and create a new `LabeledArray` or `DictArray` from the original one.
The main difference from the `selct` function is that it keeps the original fields intact, unless
directed otherwise, whereas the `select` macro only chooses the fields that are explicitly specified.

##### Arguments

Below `t'` is an object such that `t'[k]` for a field name `k` gives the corresponding array
for the field `k` in the table `t` at the coordinates selected so far.

* `t` : a LabeledArray or `DictArray`.
* `agg...` : each argument can be field names, fieldname=>(t'->nullable array function) pair, `by[...]` or `where[...]`. A fieldname=function can be used instead of the pair notation if the fieldname is a symbol.
* `by=[...]`: `by[...]` has (`t'`->nullable array) as its elements and used as in grouping when updateing. Multiple `by[...]` are simply combined.
* `where=[...]`: has (`t'`->nullable boolean array) functions inside and chooses the appropriate portion of the original array. Multiple `where=[...]` will simply be combined.

##### Return

An updated array of the same type as `t`.

##### Examples

```julia
julia> t = @larr(a=1:10, b=[1,2,3,NA,NA,NA,1,1,2,3], c=[:x,:x,:x,:x,:y,:y,:y,:z,:z,:z])
10 LabeledArray

   |a  b c
---+-------
1  |1  1 x
2  |2  2 x
3  |3  3 x
4  |4    x
5  |5    y
6  |6    y
7  |7  1 y
8  |8  1 z
9  |9  2 z
10 |10 3 z


julia> update(t, a=d->d[:a] .+ 100, d=d->d[:a] .* d[:b])
10 LabeledArray

   |a   b c d
---+-----------
1  |101 1 x 1
2  |102 2 x 4
3  |103 3 x 9
4  |104   x
5  |105   y
6  |106   y
7  |107 1 y 7
8  |108 1 z 8
9  |109 2 z 18
10 |110 3 z 30


julia> update(t, a=d->d[:a] .+ 100, d=d->d[:a] .* d[:b], where=[d-> ~isna(d[:b])])
10 LabeledArray

   |a   b c d
---+-----------
1  |101 1 x 1
2  |102 2 x 4
3  |103 3 x 9
4  |4     x
5  |5     y
6  |6     y
7  |107 1 y 7
8  |108 1 z 8
9  |109 2 z 18
10 |110 3 z 30


julia> update(t, a=d->sum(d[:a]), d=d->reverse(d[:a] .* d[:b]), where=[d-> ~isna(d[:b])], by=[:b])
10 LabeledArray

   |a  b c d
---+----------
1  |16 1 x 8
2  |11 2 x 18
3  |13 3 x 30
4  |4    x
5  |5    y
6  |6    y
7  |16 1 y 7
8  |16 1 z 1
9  |11 2 z 4
10 |13 3 z 9
```

"""
function update end

update(t::LabeledArray, args...; kwargs...) = update_untyped(t, args...; kwargs...)
update(t::DictArray, args...; kwargs...) = update_untyped(t, args...; kwargs...)
update_untyped(t, args...; kwargs...) = begin
  a = Any[args...]
  b = []
  c = []
  for (k,v) in kwargs
    if k == :by
      push!(b, isa(v, AbstractArray) ? v : [v])
    elseif k == :where
      push!(c, (isa(v, AbstractArray) ? v : [v])...)
    else
      push!(a, k=>v)
    end
  end
  sel(updatefunc, t; c=c, b=b, a=a)
end

# a helper function to decipher expressions for the select and update macros.
select_inner(func, t, args...) = begin
  cexprs = Any[]
  bexprs = Any[]
  aexprs = Any[]
  for arg in args
    if :head in fieldnames(arg)
      if arg.head == :kw || arg.head == :(=>) || arg.head == :(=)
        push!(aexprs, replace_expr(arg))
      elseif arg.head == :call && arg.args[1] == :(=>)
        push!(aexprs, replace_expr(arg))
      elseif arg.head == :ref && arg.args[1] == :where
        push!(cexprs, map(replace_expr, arg.args[2:end])...)
      elseif arg.head == :ref && arg.args[1] == :by
        push!(bexprs, map(x -> replace_expr(lift_to_dict(x)), arg.args[2:end]))
      else
        # when arg is a quoted symbol.
        push!(aexprs, replace_expr(lift_to_dict(arg)))
      end
    else
      push!(aexprs, replace_expr(lift_to_dict(arg)))
    end
  end
  cexprvec = if isempty(cexprs); :([]) else Expr(:vect, cexprs...) end
  bexprvec = if isempty(bexprs); :([]) else Expr(:ref, :Any, map(v->Expr(:vect, v...), bexprs)...) end
  aexprvec = if isempty(aexprs); :([]) else Expr(:vect, aexprs...) end
  quote
    sel($func, $(esc(t)), c=$cexprvec, b=$bexprvec, a=$aexprvec)
  end
end

const verbatim_magic_symbol = Symbol("datacubes_verbatim__")

lift_to_dict(expr) = begin
  if :head in fieldnames(expr) &&
     (expr.head == :kw || expr.head == :(=>) || expr.head == :(=))
    expr
  elseif :head in fieldnames(expr) && expr.head == :call && expr.args[1] == :(=>)
    expr
  else
    Expr(:call, :(=>), expr, Expr(:ref, verbatim_magic_symbol, expr))
  end
end

"""

`replace_expr(expr)`

Create a function expression from a domain expression.

##### Expressions
Below t' is an object such that t'[k] for a field name k gives the corresponding array
for the field k in the table t at the coordinates selected so far.

* `_k` : translates to `t'[k]`. The field name `k` should be a symbol.
* `__k` : translates to `igna(t')[k]`. It ignores the null elements. The null elements are replaced with arbitrary values, so make sure there is no null value in the array if you want to use it. The field name `k` should be a symbol.
* `_!k` : translates to `isna(t')[k]`. It gives a boolean array to denote whether an element is null. The field name `k` should be a symbol.
* `_` : translates to `t'` if none of the above is applicable. It is useful when the field name is not a symbol.

"""
replace_expr(expr) = begin
  noescape_symbols = [:none, :LineNumberNode, :QuoteNode, :line, :quote]
  result = if :head in fieldnames(expr) && expr.head == :kw || expr.head == :(=>) || expr.head == :(=)
    # this is for a or b case.
    key = if expr.head == :(=) || expr.head == :kw; quote_symbol(expr.args[1]) else expr.args[1] end
    if :head in fieldnames(expr.args[2]) && expr.args[2].head == :ref && expr.args[2].args[1] == verbatim_magic_symbol
      Expr(:call, :(=>), esc(key), esc(expr.args[2].args[2]))
    else
      value = replace_expr_inner(expr.args[2], noescape_symbols...)
      Expr(:call, :(=>), esc(key), Expr(:(->), :d, Expr(:call, :nalift, value)))
    end
  elseif :head in fieldnames(expr) && expr.head == :call && expr.args[1] == :(=>)
    key = expr.args[2]
    if :head in fieldnames(expr.args[3]) && expr.args[3].head == :ref && expr.args[3].args[1] == verbatim_magic_symbol
      Expr(:call, :(=>), esc(key), esc(expr.args[3].args[2]))
    else
      value = replace_expr_inner(expr.args[3], noescape_symbols...)
      Expr(:call, :(=>), esc(key), Expr(:(->), :d, Expr(:call, :nalift, value)))
    end
  else
    # this is for c case.
    Expr(:(->), :d, replace_expr_inner(expr, noescape_symbols...))
  end
  result
end

replace_expr_inner(expr, noescape_symbols...) = begin
  strexpr = string(expr)
  if isa(expr, Symbol) && startswith(strexpr, "__")
    Expr(:ref, Expr(:call, :igna, :d), QuoteNode(Symbol(strexpr[3:endof(strexpr)])))
  elseif isa(expr, Symbol) && startswith(strexpr, "_!")
    Expr(:ref, Expr(:call, :isna, :d), QuoteNode(Symbol(strexpr[3:endof(strexpr)])))
  elseif isa(expr, Symbol) && strexpr == "_"
    :d
  elseif isa(expr, Symbol) && startswith(strexpr, '_')
    Expr(:ref, :d, QuoteNode(Symbol(strexpr[2:endof(strexpr)])))
  elseif :head in fieldnames(expr) && expr.head==:macrocall && expr.args[1] == Symbol("@rap")
    # if it is @rap, give precedence to it.
    replace_expr_inner(recursive_rap(expr.args[2:end]...), noescape_symbols...)
  elseif :head in fieldnames(expr) && expr.head==:kw
    Expr(:kw, expr.args[1], replace_expr_inner(expr.args[2], noescape_symbols...))
  elseif :head in fieldnames(expr) && expr.head==:ref && expr.args[1]==Symbol("__")
    Expr(:ref, Expr(:call, :igna, :d), esc(expr.args[2]))
  elseif :head in fieldnames(expr) && expr.head==:ref && expr.args[1]==Symbol("_!")
    Expr(:ref, Expr(:call, :isna, :d), esc(expr.args[2]))
  elseif :head in fieldnames(expr) && expr.head==:ref && expr.args[1]==:_
    #TODO need to fix this so that it works with an array of field names.
    Expr(:ref, replace_expr_inner(expr.args[1], noescape_symbols...), map(x->isa(x,QuoteNode) || (:head in fieldnames(x) && x.head==:quote) ? x : replace_expr_inner(x, noescape_symbols...), expr.args[2:end])...)
    #Expr(:ref, expr.args[1], map(x->isa(x, Symbol) ? QuoteNode(x) : replace_expr_inner(x), expr.args[2:end])...)
  elseif :head in fieldnames(expr) && expr.head == :(->)
    noescsymbs = get_function_arguments_exprs(expr.args[1])
    Expr(:(->), expr.args[1], replace_expr_inner(expr.args[2], noescsymbs..., noescape_symbols...))
  else
    if isa(expr, QuoteNode)
      expr
    elseif :head in fieldnames(expr) && expr.head in noescape_symbols
      expr
    elseif :args in fieldnames(expr)
      newargs = map(x->replace_expr_inner(x, noescape_symbols...), expr.args)
      expr.args = newargs
      expr
    elseif expr in noescape_symbols
      expr
    else
      esc(expr)
    end
  end
end

get_function_arguments_exprs(expr) = begin
  if :head in fieldnames(expr) && expr.head == :tuple
    expr.args
  else
    (expr,)
  end
end

# N is the original array dimensions.
update_by_array{T,N}(t::AbstractArray{T,N}, a, indices::Vector{NTuple{N,Int}}, byvec, bymap) = begin
  label = bymap[1]
  # assumes there is at least one label for each axis.
  reslen = length(bymap[1][1])
  indexvec::Vector{Int} = bymap[2]
  indcountvec::Vector{Int} = fill(0, reslen)
  for i in eachindex(indices)
    ids = indexvec[i]
    indcountvec[ids] += 1
  end
  subarrays_buf = Array{NTuple{N,Int}}(length(indices))
  index_subarrays = similar(indcountvec, SubArray{NTuple{N,Int},1,Array{NTuple{N,Int},1},Tuple{UnitRange{Int}},SUBARRAY_LAST_TYPE})
  indsumsofar::Int = 0
  lenindcountvec::Int = length(indcountvec)
  for i in 1:lenindcountvec
    prevsum = indsumsofar
    @inbounds indsumsofar += indcountvec[i]
    @inbounds index_subarrays[i] = view(subarrays_buf, prevsum+1:indsumsofar)
  end
  # change the meaning of indcountmat, not to create another buffer.
  fill!(indcountvec, 0)
  counter::Int = 1
  for i in eachindex(indices)
    ids = indexvec[i]
    current_count = indcountvec[ids] + 1
    indcountvec[ids] = current_count
    subarray = index_subarrays[ids]
    subarray[current_count] = indices[i]
  end
  result = copy(t.data.data)
  for (k,onea) in a
    trial_indices = index_subarrays[1]
    trial_aggvec = onea(t, trial_indices)
    result = create_field_for_update!(result, k, trial_aggvec)
    update_agg!(result, k, trial_aggvec, trial_indices)
    start_index = 2

    for i in start_index:length(index_subarrays)
      indices = index_subarrays[i]
    #for indices in index_subarrays
      aggvec = onea(t, indices)
      update_agg!(result, k, aggvec, indices)
    end
  end
  LabeledArray(DictArray(result), t.axes)
end

create_field_for_update!{T}(result::LDict, k, ::AbstractArray{Nullable{T}}) = begin
  k_in_result = haskey(result, k)
  repval = values(result)[1]
  if !k_in_result
    v = similar(repval, Nullable{T}, size(repval))
    setna!(v)
    merge(result, LDict(k=>v))
  elseif !isa(T, eltype(eltype(result[k])))
    v = similar(repval, Nullable{promote_type(T,eltype(eltype(result[k])))}, size(repval))
    copy!(v, result[k])
    merge(result, LDict(k=>v))
  else
    result
  end
end
create_field_for_update!{T}(result::LDict, k, ::Nullable{T}) = begin
  k_in_result = haskey(result, k)
  repval = values(result)[1]
  if !k_in_result
    v = similar(repval, Nullable{T}, size(repval))
    setna!(v)
    merge(result, LDict(k=>v))
  elseif !isa(T, eltype(eltype(result[k])))
    v = similar(repval, Nullable{promote_type(T,eltype(eltype(result[k])))}, size(repval))
    copy!(v, result[k])
    merge(result, LDict(k=>v))
  else
    result
  end
end
create_field_for_update!{T}(result::LDict, k, ::T) = create_field_for_update!(result, k, Nullable{Any})

update_agg!{N}(result::LDict, k, aggvec::AbstractVector, indices::AbstractVector{NTuple{N,Int}}) = begin
  @assert(length(aggvec) == length(indices))
  i = 1
  resultk = result[k]
  for coords in indices
    resultk[coords...] = aggvec[i]
    i += 1
  end
end

update_agg!{N}(result::LDict, k, aggnum, indices::AbstractVector{NTuple{N,Int}}) = update_agg!(result, k, Nullable(aggnum), indices)
update_agg!{N,V}(result::LDict, k, aggnum::Nullable{V}, indices::AbstractVector{NTuple{N,Int}}) = begin
  i = 1
  resultk = result[k]
  for coords in indices
    resultk[coords...] = aggnum
    i += 1
  end
end

create_zero_byvec{T}(arr::AbstractArray{T}) = T[]
create_zero_byvec(arr::AbstractArrayWrapper) = create_zero_byvec(arr.a)
create_zero_byvec{T,N,V,R}(arr::EnumerationArray{T,N,V,R}) = EnumerationArray((R[], arr.pool))
create_zero_byvec{T}(arr::FloatNAArray{T}) = FloatNAArray(T[])
create_zero_byvec(arr::SubArrayView) = create_zero_byvec(arr.data)
create_zero_byvec(arr::BroadcastAxis) = create_zero_byvec(arr.axis)
