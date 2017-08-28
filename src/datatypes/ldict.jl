import Base.==

"""

LDict is an ordered dictionary. It is assumed to be used in the field name => field mapping. In practice, the number of columns is not that long, and it is more efficient to implement LDict as 2 vectors, one for keys and one for values.

### Constructors

```julia
LDict{K,V}(dict::Associative{K, V}) # LDict from a dictionary dict. The result order is undetermined.
LDict{K,V}(dict::Associative{K, V}, ks) # LDict from a dictionary dict. ks is a vector of keys, and the keys in the result are ordered in that way. An error is thrown if one of ks is not found in dict.
LDict{K,V}(ks::Vector{K}, vs::Vector{V})
LDict(ps::Pair...)
LDict(ps::Tuple...)
```

"""
immutable LDict{K,V} <: Associative{K,V}
  keys::Vector{K}
  values::Vector{V}

  LDict{K,V}() where {K,V} = new(Vector{K}(), Vector{V}())
  LDict{K,V}(ks::Vector{K}, vs::Vector{V}) where {K,V} =
    if length(ks) == length(vs)
      new(ks, vs)
    else
      throw(ArgumentError("LDict: keys anvd values have different lengths. keys: ", ks, ", values: ", values))
    end
end

LDict(ks::Vector, vs::Vector) = begin
  try
    typed_keys = type_array(ks)
    typed_values = type_array(vs)
    LDict{eltype(typed_keys),eltype(typed_values)}(typed_keys, typed_values)
  catch e
    if isa(e, UndefRefError)
      LDict{eltype(ks), eltype(vs)}(ks, vs)
    else
      rethrow(e)
    end
  end
end

# sometimes checking types is too expensive. this version just creates an LDict without type checking.
create_ldict_nocheck() = LDict{Any,Any}()
create_ldict_nocheck(ks::Vector, vs::Vector) = LDict{eltype(ks), eltype(vs)}(ks, vs)
create_ldict_nocheck(ps::Pair...) = create_ldict_nocheck(type_array([x.first for x in ps]), type_array([x.second for x in ps]))
create_ldict_nocheck(ps::Tuple...) = create_ldict_nocheck(type_array([x[1] for x in ps]), type_array([x[2] for x in ps]))
create_ldict_nocheck(dict::Associative) = create_ldict_nocheck(collect(keys(dict)), collect(values(dict)))
create_ldict_nocheck{K,V}(dict::Associative{K,V}, ks::Vector{K}) = begin
  dict_keys = collect(keys(dict))
  dict_values = collect(values(dict))
  create_ldict_nocheck(ks, map(k->dict_values[findfirst(dict_keys, k)],ks))
end


LDict() = LDict{Any,Any}()
LDict(ps::Pair...) = LDict(type_array([x.first for x in ps]), type_array([x.second for x in ps]))
LDict(ps::Tuple...) = LDict(type_array([x[1] for x in ps]), type_array([x[2] for x in ps]))
LDict(dict::Associative) = LDict(collect(keys(dict)), collect(values(dict)))
LDict{K,V}(dict::Associative{K,V}, ks::Vector{K}) = begin
  dict_keys = collect(keys(dict))
  dict_values = collect(values(dict))
  LDict(ks, map(k->dict_values[findfirst(dict_keys, k)],ks))
end

# for iteration.
Base.start(::LDict) = 1
Base.next(ldict::LDict, state) = (Pair(ldict.keys[state], ldict.values[state]), state+1)
Base.done(ldict::LDict, s) = s > length(ldict)

Base.length(ldict::LDict) = length(ldict.keys)
Base.eltype{K, V}(::Type{LDict{K, V}}) = Pair{K, V}

"""

`merge(dict::LDict, ds...)`

Combine an `LDict` `dict` with `Associative` `ds`'s.
The subsequent elements in ds will either update the preceding one, or append the key-value pair.

##### Examples

```julia
julia> merge(LDict(:a=>3, :b=>5), Dict(:b=>"X", :c=>"Y"), LDict(:c=>'x', 'd'=>'y'))
DataCubes.LDict{Any,Any} with 4 entries:
  :a  => 3
  :b  => "X"
  :c  => 'x'
  'd' => 'y'
```

"""
Base.merge(dict::LDict, ds::Associative...) = begin
  keys = copy(dict.keys)
  values = copy(dict.values)
  keytype = eltype(keys)
  valuetype = eltype(values)
  for d in ds
    for (k,v) in d
      ind = findfirst(keys, k)
      if ind > 0
        if isa(v, valuetype)
          values[ind] = v
        else
          valuetype = promote_type(valuetype, typeof(v))
          newvalues = similar(values, valuetype, length(values))
          copy!(newvalues, values)
          values = newvalues
          values[ind] = v
        end
      else
        if isa(k, keytype)
          push!(keys, k)
        else
          keytype = promote_type(keytype, typeof(k))
          newkeys = similar(keys, keytype, length(keys)+1)
          copy!(newkeys, keys)
          keys = newkeys
          keys[end] = k
        end
        function final_try()
          valuetype = promote_type(valuetype, typeof(v))
          newvalues = similar(values, valuetype, length(values) + 1)
          copy!(newvalues, values)
          values = newvalues
          values[end] = v
        end
        if isa(v, valuetype)
          try
            push!(values, v)
          catch
            @show "probably a bug in `isa` function. Let's try to promote the common type."
            final_try()
          end
        else
          final_try()
        end
      end
    end
  end
  LDict(keys, values)
end


"""

`deletekeys(dict::LDict, keys...)`

Delete `keys` keys from `dict`. A missing key will be silently ignored.

```julia
julia> deletekeys(LDict(:a=>3, :b=>5, :c=>10), :a, :b, :x)
DataCubes.LDict{Symbol,Int64} with 1 entry:
  :c => 10
```

"""
deletekeys{K,V}(dict::LDict{K,V}, keys...) = begin
  dictkeys = dict.keys
  dictvalues = dict.values
  newkeys = K[]
  newvalues = V[]
  for (k,v) in dict
    ind = findfirst(keys, k)
    if ind==0
      push!(newkeys, k)
      push!(newvalues, v)
    end
  end
  LDict(newkeys, newvalues)
end

"""

`selectkeys(dict::LDict, keys...)`

Select `keys` keys from `dict`. A missing key will raise an error.

##### Examples

```julia
julia> selectkeys(LDict(:a=>3, :b=>5, :c=>10), :a, :b)
DataCubes.LDict{Symbol,Int64} with 2 entries:
  :a => 3
  :b => 5
```

"""
selectkeys{K,V}(dict::LDict{K,V}, keys...) = begin
  dictkeys = dict.keys
  dictvalues = dict.values
  LDict(collect(keys), [dictvalues[findfirst(dictkeys, k)] for k in keys])
end

# implement some basic functionalities for dictionaries.
Base.get{K,V}(ldict::LDict{K,V}, key::K, _) = begin
  intind = findfirst(ldict.keys, key)
  if intind <=0
    throw(BoundsError(ldict, key))
  else
    ldict.values[intind]::V
  end
end

Base.get!{K,V}(ldict::LDict{K,V}, key::K, value::V) = begin
  intind = findfirst(ldict.keys, key)
  if intind <=0
    push!(ldict.keys, key)
    push!(ldict.values, value)
    value::V
  else
    ldict.values[intind]::V
  end
end

Base.setindex!{K,V}(ldict::LDict{K,V}, value::V, key::K) = begin
  intind = findfirst(ldict.keys, key)
  if intind <=0
    push!(ldict.keys, key)
    push!(ldict.values, value)
    value
  else
    ldict.values[intind] = value
    value
  end
end

function ==(x::LDict, y::LDict)
  length(x) == length(y) &&
    wrap_array(x.keys) == wrap_array(y.keys) &&
    wrap_array(x.values) == wrap_array(y.values)
end
Base.isequal(x::LDict, y::LDict) = x==y
Base.haskey(ldict::LDict, k) = 0 < findfirst(ldict.keys, k)

isna{K,V<:AbstractArray}(ldict::LDict{K,V}) = reduce(&, map(isna, ldict.values))
isna{K,V}(ldict::LDict{K,V}) = all(map(isna, ldict.values))

Base.copy(ldict::LDict) = LDict(copy(ldict.keys), copy(ldict.values))
copy_arrayvalues(ldict::LDict) = LDict(copy(ldict.keys), map(copy, ldict.values))

# see array_util.jl for documentation.
mapvalues(f::Function, ldict::LDict) = try
  LDict(ldict.keys, map(f, ldict.values)) #[f(v) for v in ldict.values]) # for some reason, comprehension[] was much slower than map...
catch err
  # I found sometimes there is a type error, depending the order of execution.
  # Without knowing the reason precisely, I just put a try catch expression.
  # Hopefully, this will not impact the performance much.
  if isa(err, TypeError)
    buf = Array{Any}(length(ldict.values))
    map!(f, buf, ldict.values)
    LDict(ldict.keys, collect(simplify_array(buf)))
  else
    rethrow()
  end
end
Base.keys(ldict::LDict) = ldict.keys
Base.values(ldict::LDict) = ldict.values

"""

`reorder(ldict::LDict, ks...)`

Reorder the keys so that the first few keys are `ks`.

##### Examples

```julia
julia> reorder(LDict(:a=>1, :b=>2, :c=>3), :b, :c)
DataCubes.LDict{Symbol,Int64} with 3 entries:
  :b => 2
  :c => 3
  :a => 1
```

"""
reorder(ldict::LDict, ks...) = create_ldict_nocheck(ldict, [ks...;setdiff(ldict.keys, ks)])

"""

`rename(ldict::LDict, ks...)`

Renames the first few keys using `ks`.

##### Examples

```julia
julia> rename(LDict(:a=>1, :b=>2, :c=>3), :b, 'x')
DataCubes.LDict{Any,Int64} with 3 entries:
  :b  => 1
  'x' => 2
  :c  => 3
```

"""
rename(ldict::LDict, ks...) = create_ldict_nocheck([ks...;drop(ldict.keys, length(ks))...], ldict.values)

