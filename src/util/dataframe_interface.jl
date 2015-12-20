# a simple interface to convert to and from DataFrames.
# DataFrames directly corresponds to DictArray of dimension 1 with symbol field names.

import DataFrames: DataFrame, DataArray, PooledDataArray, Index

dataframe_to_dictarray(df::DataFrame) = begin
  colindex = df.colindex
  columns = df.columns
  newcolumns = map(columns) do column
    if isa(column, DataArray)
      simplify_array(create_naarray(column))
    elseif isa(column, PooledDataArray)
      convert(EnumerationArray, column)
    else
      simplify_array(nalift(column))
    end
  end
  lookup = colindex.lookup
  newpairs = map(colindex.names) do name
    name => newcolumns[lookup[name]]
  end
  DictArray(newpairs...)
end

create_naarray{T}(arr::DataArray{T}) = begin
  data = arr.data
  na = arr.na
  map(data, na) do elem, isna
    isna ? Nullable{T}() : Nullable(elem)
  end
end
create_dataarray{T}(arr::AbstractArray{Nullable{T}}) = begin
  isna_array0 = isna(arr)
  isna_array = if isa(isna_array0, BitArray)
    isna_array0
  else
    result = BitArray(size(isna_array0))
    copy!(result, isna_array0)
    result
  end
  value_array = Array{T}(size(arr))
  arbitrary_array = similar([],T,1)
  anyelem = if isdefined(arbitrary_array,1)
    arbitrary_array[1]
  else
    find_nonnull(arr)
  end
  if !isempty(value_array)
    map!(value_array, arr) do elem
      if elem.isnull
        anyelem
      else
        elem.value
      end
    end
  end
  DataArray(value_array, isna_array)
end

# promote to Nullable{Any} if the element type is just Nullable.
create_dataarray(arr::AbstractArray{Nullable}) = create_dataarray(convert(AbstractArray{Nullable{Any}}, arr))

find_nonnull(x::AbstractArray) = begin
  for elem in x
    if !elem.isnull
      return elem.value
    end
  end
end


dictarray_to_dataframe(arr::DictArray{TypeVar(:T),1}) = begin
  keys = [symbol(k) for k in arr.data.keys]
  colindex = Index(Dict(map(ik->ik[2]=>ik[1], enumerate(keys))), keys)
  columns = Any[create_dataarray(v) for v in arr.data.values]
  DataFrame(columns, colindex)
end

"""

`convert(::Type{DictArray}, df::DataFrame)` converts a `DataFrame` into `DictArray`.

"""
Base.convert(::Type{DictArray}, df::DataFrame) = dataframe_to_dictarray(df)

"""

`convert(::Type{LabeledArray}, df::DataFrame)` converts a `DataFrame` into `LabeledArray` simply by wrapping `convert(DictArray, df)` by `LabeledArray`.

"""
Base.convert(::Type{LabeledArray}, df::DataFrame) = LabeledArray(dataframe_to_dictarray(df))

"""

`convert(::Type{DataFrame}, arr::DictArray)` converts a `DictArray` into a `DataFrame`. If the dimensions of `arr` are greater than 1, `arr` is first flattend into 1 dimension using `collapse_axes`, and then converted into a `DataFrame`.

"""
Base.convert(::Type{DataFrame}, arr::DictArray) = dictarray_to_dataframe(collapse_axes(arr, 1, ndims(arr)))

"""

`convert(::Type{DataFrame}, arr::LabeledArray)` converts a `LabeledArray` into a `DataFrame` by first creating a `DictArray` by broadcasting all axes, and then convert that `DictArray` into a `DataFrame`.

"""
Base.convert(::Type{DataFrame}, arr::LabeledArray) = dictarray_to_dataframe((darr=selectfields(arr, allfieldnames(arr)...);collapse_axes(darr,1,ndims(darr))))

"""

`convert(::Type{EnumerationArray}, arr::PooledDataArray)` converts a `PooledDataArray` into an `EnumerationArray`.

"""
Base.convert(::Type{EnumerationArray}, arr::PooledDataArray) = EnumerationArray((arr.refs, arr.pool))
