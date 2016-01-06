import Base.==

"""

A multidimensional array together with additional axes attached to it.
Each axis is a one dimensional array, possibly a `DictArray`.
Use the function `larr` or a macro version `@larr` to create `LabeledArray`s, rather than call the constructor directly.

A `LabeledArray` consists of one main array, which we call the *base* array, and an axis array for each direction.

##### Constructors
* `LabeledArray(arr, axes)` creates a `LabeledArray` from a *base* array `arr` and a tuple `axes` of one dimensional arrays for axes.
* `LabeledArray(arr; kwargs...)` creates a `LabeledArray` from a *base* array `arr` and a keyword argument of the form `axisN=V` for some integer `N` for the axis direction and a one dimensional array `V`.

"""
immutable LabeledArray{T,N,AXES<:Tuple,TN} <: AbstractArray{T,N}
  data::TN
  axes::AXES

  LabeledArray(data::TN, axes::AXES) = begin
    if length(axes) != ndims(data)
      throw(ArgumentError("LabeledArray: the number of axes $(length(axes)) is not the same as the number of dimensions of data $(ndims(data))."))
    end
    if size(data) != map(length, axes)
      throw(ArgumentError("LabeledArray: the dimensions of data $(size(data)) do not match with the axes lengths $(map(length, axes))."))
    end
    for axis in axes
      if ndims(axis) != 1
        throw(ArgumentError("LabeledArray: axes should be 1 dimensional."))
      end
    end
    new(data, axes)
  end
end

(==)(arr1::LabeledArray, arr2::LabeledArray) = wrap_array(arr1.data)==wrap_array(arr2.data) && all(map(arr1.axes,arr2.axes) do x1,x2;wrap_array(x1)==wrap_array(x2) end)
Base.copy(arr::LabeledArray) = LabeledArray(copy(arr.data), map(copy, arr.axes))

"""

Default axis used when no axis is specified for a `LabeledArray`.
It behaves mostly as an array `[Nullable(1), Nullable(2), ...]`.
However, one notable exception is when using `@select`/`selct`/`extract`/`discard`/`getindex`/etc to choose, set or drop specific elements of a `LabeledArray`.
In this case, the result array of reduced size will again have a `DefaultAxis` of an appropriate size.

"""
immutable DefaultAxis <: AbstractArray{Nullable{Int}, 1}
  counts::Int
end
Base.size(axis::DefaultAxis) = (axis.counts,)
Base.linearindexing(::Type{DefaultAxis}) = Base.LinearFast()
Base.getindex(axis::DefaultAxis, i::Int) = Nullable(i)
Base.getindex(axis::DefaultAxis, i...) = begin
  labeledarray_mapnullable_inner((1:axis.counts)[i...])
end
labeledarray_mapnullable_inner(i::Int) = Nullable(i)
labeledarray_mapnullable_inner(i::AbstractArray) = map(Nullable, i)

Base.start(::DefaultAxis) = 1
Base.next(arr::DefaultAxis, state) = (Nullable(state), state+1)
Base.done(arr::DefaultAxis, s) = s > arr.counts
Base.eltype(::Type{DefaultAxis}) = Nullable{Int}
Base.length(axis::DefaultAxis) = axis.counts
Base.ndims(::DefaultAxis) = 1
(==)(arr1::DefaultAxis, arr2::DefaultAxis) = arr1.counts == arr2.counts

LabeledArray{T,N,AXES<:Tuple}(data::AbstractArray{T,N}, axes::AXES) = begin
  LabeledArray{T,N,AXES,typeof(data)}(data, axes)
end
# don't know why this is necessary.
LabeledArray{K,N,VS,SV,AXES<:Tuple}(data::DictArray{K,N,VS,SV}, axes::AXES) = LabeledArray{LDict{K,SV},N,AXES,typeof(data)}(data, axes)
LabeledArray{T,N}(data::AbstractArray{T,N}; kwargs...) = begin
  axes = Any[DefaultAxis(x) for x in size(data)]
  for (k, v) in kwargs
    kstr = string(k)
    if startswith(kstr, "axis")
      axisindex = parse(Int, kstr[5:endof(kstr)])
      axes[axisindex] = v
    end
  end
  axestuple = (axes...)
  LabeledArray(data, axestuple)
end

# used to calculate the appropriate number of columns/rows when showing an LabeledArray or a DictArray.
arr_width(x::DictArray) = length(x.data)
arr_width(x::AbstractArray) = 1

# some functions to set the height and width of output LabeledArrays to console.
default_showsize = () -> ((height,width) = Base.tty_size();(height-20,width-6))

@doc """

`set_default_showsize!!()`

Set the show height and width limit function to be the default one.
The default version calculates the height and width based on the current console screen size.
This is used to set the print limits when showing a `DictArray` or a `LabeledArray`.

"""
set_default_showsize!!() = (global show_size;show_size = default_showsize)
show_size = default_showsize

@doc """

`setshowsize!!(height::Integer, width::Integer)`

Set the show height and width limits to be the constant `height` and `width`, respectively.
To get to the default behavior of adjusting to the current console screen size, use `set_default_showsize!!()`.

"""
setshowsize!!(height::Integer, width::Integer) = (global show_size;show_size = () -> (height, width))

@doc """

`set_showheight!!(height::Integer)`

Set the show height limit to the constant `height`.
To get to the default behavior of adjusting to the current console screen size, use `set_default_showsize!!()`.

"""
set_showheight!!(height::Integer) = (origwidth=show_size()[2];global show_size;show_size = () -> (height, origwidth))

@doc """

`set_showwidth!!(width::Integer)`

Set the show width limit to the constant `width`.
To get to the default behavior of adjusting to the current console screen size, use `set_default_showsize!!()`.

"""
set_showwidth!!(width::Integer) = (origheight=show_size()[1];global show_size;show_size = () -> (origheight, width))
toshow_alongrow = true

@doc """

`set_showalongrow!!(alongrow::Bool)`

Determine how to show the fields of a `DictArray`.
By default (`alongrow` is `true`), the fields are shown from left to right.
If `alongrow=false`, the fields are shown from top to bottom.

##### Examples

```julia
julia> set_showalongrow!!(true)
true

julia> darr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1 x |2 y |3 z 
4 u |5 v |6 w 


julia> set_showalongrow!!(false)
false

julia> darr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w])
2 x 3 DictArray

a |1 2 3 
b |x y z 
--+------
a |4 5 6 
b |u v w 
```

"""
set_showalongrow!!(alongrow::Bool) = (global toshow_alongrow; toshow_alongrow = alongrow)

# some functions to set the height and width of output LabeledArrays to html.
default_dispsize = () -> (80,30)

@doc """

`set_default_dispsize!!()`

Set the display height and width limit function to be the default one.
This is used to set the display limits when displaying a `DictArray` or a `LabeledArray`.

"""
set_default_dispsize!!() = (global show_size;show_size = default_dispsize)
dispsize = default_dispsize

@doc """

`setdispsize!!(height::Integer, width::Integer)`

Set the display height and width limits to be the constant `height` and `width`, respectively.
To get to the default behavior, use `set_default_dispsize!!()`.

"""
setdispsize!!(height::Integer, width::Integer) = (global dispsize;dispsize = () -> (height, width))

@doc """

`set_dispheight!!(height::Integer)`

Set the display height limit to the constant `height`.
To get to the default behavior, use `set_default_dispsize!!()`.

"""
set_dispheight!!(height::Integer) = (origwidth=dispsize()[2];global dispsize;dispsize = () -> (height, origwidth))

@doc """

`set_dispwidth!!(width::Integer)`

Set the display width limit to the constant `width`.
To get to the default behavior, use `set_default_dispsize!!()`.

"""
set_dispwidth!!(width::Integer) = (origheight=dispsize()[1];global dispsize;dispsize = () -> (origheight, width))
todisp_alongrow = true

@doc """

`set_dispalongrow!!(alongrow::Bool)`

Determine how to display the fields of a `DictArray`.
By default (`alongrow` is `true`), the fields are displayed from left to right.
If `alongrow=false`, the fields are displayed from top to bottom.
See `set_showalongrow!!` to see an analogous example when showing a `DictArray`.

"""
set_dispalongrow!!(alongrow::Bool) = (global todisp_alongrow; todisp_alongrow = alongrow)

"""

`show(io::IO, table::LabeledArray [, indent=0; height=..., width=...])`

Show a LabeledArray.

##### Arguments

* `height` and `width`(optional, default set by show_size()): sets the maximum height and width to draw, beyond which the table will be cut.
* `alongrow`(optional, default set by `set_dispalongrow!!`. `tru` by default): if `true`, the fields in the array will be displayed along the row in each cell. Otherwise, they will be stacked on top of each other.

"""
Base.show{N}(io::IO, table::LabeledArray{TypeVar(:T),N}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow::Bool=toshow_alongrow) = begin
  print(io, join(size(table), " x "))
  print(io, " LabeledArray")
  print(io, '\n')
  ndimstable = ndims(table)
  for index=1:last(size(table))
    axislabel = table.axes[end][index]
    coords = [fill(:,ndimstable-1);index]
    print(io, '\n')
    show_indent(io, indent)
    print(io, axislabel)
    print(io, ' ')
    print(io, '[')
    for i in 1:length(coords)-1
      print(io, ":,")
    end
    print(io, index)
    print(io, ']')
    print(io, '\n')
    show(io, getindex(table, coords...), indent+4; height=height, width=width, alongrow=alongrow)
  end
end

Base.show(io::IO, table::LabeledArray{TypeVar(:T),0}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow::Bool=toshow_alongrow) = begin
  println(io, "0 dimensional LabeledArray")
  show(io, table.data)
end

Base.show(io::IO, table::LabeledArray{TypeVar(:T),1}, indent=0; height::Int=show_size()[1], width::Int=show_size()[2], alongrow::Bool=toshow_alongrow) = begin
  print(io, join(size(table), " x "))
  print(io, " LabeledArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(table; height=height, width=width)
  else
    create_string_reprmat_alongcol(table; height=height, width=width)
  end
  show_string_matrix(io, result, height, width, indent, hlines, vlines)
end

# create a string version of the matrix, properly truncated.
# returns a tuple of (string matrix, locations of horizontal lines, locations of vertical lines).
# location 10 of horizonal line means, e.g., there is a horizontal line to be inserted
# between the 9th and 10th rows.
create_string_reprmat_alongrow(table::LabeledArray{TypeVar(:T),1}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = table.data
  tableaxes1 = table.axes[1]
  nrows = min(show_height, size(table,1) + 1)
  nkeys = arr_width(tableaxes1)
  ncols = max(nkeys, min(show_width, nkeys + arr_width(tabledata)))
  result = fill("", nrows, ncols)
  if isa(tabledata, DictArray)
    result[1,nkeys+1:ncols] = map(string, tabledata.data.keys[1:ncols-nkeys])
    for i in nkeys+1:ncols
      result[2:nrows,i] = map(cell_to_string, tabledata.data.values[i-nkeys][1:nrows-1])
    end
  else
    result[2:nrows,nkeys+1] = map(cell_to_string, tabledata[1:nrows-1])
  end
  if isa(tableaxes1, DictArray)
    result[1,1:nkeys] = map(string, tableaxes1.data.keys)
    for i in 1:nkeys
      result[2:nrows,i] = map(cell_to_string, tableaxes1.data.values[i][1:nrows-1])
    end
  else
    result[2:nrows,1] = map(cell_to_string, tableaxes1[1:nrows-1])
  end
  (result, [2], [nkeys+1])
end

create_string_reprmat_alongcol(table::LabeledArray{TypeVar(:T),1}; height::Int=show_size()[1], width=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = table.data
  tableaxes1 = table.axes[1]
  widthtabledata = arr_width(tabledata)
  nrows = min(show_height, 1+widthtabledata*length(table))
  nkeys = arr_width(tableaxes1)
  ncols = max(nkeys, min(show_width, nkeys + 2))
  result = fill("", nrows, ncols)
  if isa(tabledata, DictArray)
    for i in 2:nrows
      result[i,nkeys+1] = string(tabledata.data.keys[1+(i-2) % widthtabledata]) #string(data.keys[i loop_key_index])
      result[i,nkeys+2] = cell_to_string(tabledata.data.values[1+(i-2) % widthtabledata][1+div(i-2,widthtabledata)])
    end
  else
    result[2:nrows,nkeys+1] = map(cell_to_string, tabledata[1:nrows-1])
  end
  # display axis 1.
  if isa(tableaxes1, DictArray)
    result[1,1:nkeys] = map(string, tableaxes1.data.keys)
    for i in 2:nrows
      for j in 1:nkeys
        if (i-2) % widthtabledata == 0
          result[i,j] = cell_to_string(tableaxes1.data.values[j][1+div(i-2,widthtabledata)])
        end
      end
    end
  else
    for i in 2:nrows
      result[i,1] = cell_to_string(tableaxes1[1+div(i-2,widthtabledata)])
    end
  end
  (result, collect(2+widthtabledata*(0:1+fld(nrows,widthtabledata))), [nkeys+1,nkeys+2])
end

Base.show(io::IO, table::LabeledArray{TypeVar(:T),2}, indent; height::Int=show_size()[1], width::Int=show_size()[2], alongrow=toshow_alongrow) = begin
  print(io, join(size(table), " x "))
  print(io, " LabeledArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(table; height=height, width=width)
  else
    create_string_reprmat_alongcol(table; height=height, width=width)
  end
  show_string_matrix(io, result, height, width, indent, hlines, vlines)
end


# create a string version of the matrix, properly truncated.
# returns a tuple of (string matrix, locations of horizontal lines, locations of vertical lines).
# location 10 of horizonal line means, e.g., there is a horizontal line to be inserted
# between the 9th and 10th rows.
create_string_reprmat_alongrow(table::LabeledArray{TypeVar(:T),2}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = table.data
  (tableheight,tablewidth) = size(tabledata)
  widthtabledata = arr_width(tabledata)
  tableaxes1 = table.axes[1]
  tableaxes2 = table.axes[2]
  widthtableaxes2 = arr_width(tableaxes2)
  nrows = min(show_height, tableheight + widthtableaxes2 + 1)
  nkeys = arr_width(tableaxes1)
  ncols = max(nkeys, min(show_width, nkeys + length(tableaxes2)*widthtabledata))
  result = fill("", nrows, ncols)
  # fill in axis2 above data columns.
  if isa(tableaxes2, DictArray)
    result[1:widthtableaxes2,nkeys] = map(string, tableaxes2.data.keys)
    for i in 1:min(show_height, widthtableaxes2)
      for j in 1:length(tableaxes2)
        ind = 1+nkeys+widthtabledata*(j-1)
        if ind <= ncols
          result[i,ind] = cell_to_string(tableaxes2.data.values[i][j])
        else
          break
        end
      end
    end
  else
    for i in 1:length(tableaxes2)
      ind = 1+nkeys+widthtabledata*(i-1)
      if ind <= ncols
        result[1,ind] = cell_to_string(tableaxes2[i])
      end
    end
  end
  # fill in the key columns.
  if isa(tabledata, DictArray)
    if widthtableaxes2+1 <= nrows
      for i in 1:length(tableaxes2)
        for j in 1:widthtabledata
          ind = nkeys+widthtabledata*(i-1)+j
          if ind>ncols break end
          result[widthtableaxes2+1,ind] = string(tabledata.data.keys[j])
        end
      end
      for i in widthtableaxes2+2:nrows
        for j in 1:length(tableaxes2)
          for k in 1:widthtabledata
            ind = nkeys+widthtabledata*(j-1)+k
            if ind>ncols break end
            result[i,ind] = cell_to_string(tabledata.data.values[k][i-widthtableaxes2-1,j])
          end
        end
      end
    end
  else
    result[widthtableaxes2+2:nrows,nkeys+1:ncols] = map(cell_to_string, tabledata[1:nrows-1-widthtableaxes2,1:ncols-nkeys])
  end
  if isa(tableaxes1, DictArray)
    result[widthtableaxes2+1,1:nkeys] = map(string, tableaxes1.data.keys)
    for i in 1:nkeys
      result[widthtableaxes2+2:nrows,i] = map(cell_to_string, tableaxes1.data.values[i][1:nrows-widthtableaxes2-1])
    end
  else
    result[widthtableaxes2+2:nrows,1] = map(cell_to_string, tableaxes1[1:nrows-1-widthtableaxes2])
  end
  (result, [widthtableaxes2+1,widthtableaxes2+2], map(x->nkeys+1+widthtabledata*(x-1), 1:ncols))
end

create_string_reprmat_alongcol(table::LabeledArray{TypeVar(:T),2}; height::Int=show_size()[1], width::Int=show_size()[2]) = begin
  show_height,show_width = (height, width)
  tabledata = table.data
  (tableheight,tablewidth) = size(tabledata)
  widthtabledata = arr_width(tabledata)
  tableaxes1 = table.axes[1]
  tableaxes2 = table.axes[2]
  widthtableaxes2 = arr_width(tableaxes2)
  nrows = min(show_height, widthtabledata*tableheight + widthtableaxes2)
  nkeys = arr_width(tableaxes1)
  ncols = max(nkeys, min(show_width, nkeys + length(tableaxes2)+1))
  result = fill("", nrows, ncols)
  # fill in axis2 above data columns.
  if isa(tableaxes2, DictArray)
    result[1:widthtableaxes2,nkeys+1] = map(string, tableaxes2.data.keys)
    for i in 1:min(show_height, widthtableaxes2)
      for j in 1:length(tableaxes2)
        ind = 1 + nkeys + j
        if ind <= ncols
          result[i,ind] = cell_to_string(tableaxes2.data.values[i][j])
        else
          break
        end
      end
    end
  else
    for i in 1:length(tableaxes2)
      ind = 1 + nkeys + i
      if ind <= ncols
        result[1,ind] = cell_to_string(tableaxes2[i])
      end
    end
  end
  # fill in the key columns.
  if isa(tabledata, DictArray)
    for j in widthtableaxes2+1:nrows
      result[j,nkeys+1] = string(tabledata.data.keys[1+(j-widthtableaxes2-1) % widthtabledata])
    end
    for i in widthtableaxes2+1:nrows
      for j in 1:length(tableaxes2)
        ind = nkeys + 1 + j
        if ind>ncols break end
        result[i,ind] = cell_to_string(tabledata.data.values[1+(i-widthtableaxes2-1) % widthtabledata][div(i-widthtableaxes2-1, widthtabledata)+1,j])
      end
    end
  else
    result[widthtableaxes2+1:nrows,nkeys+2:ncols] = map(cell_to_string, tabledata[1:nrows-widthtableaxes2,1:ncols-nkeys-1])
  end
  # fill in the axis 1 field names and values.
  if isa(tableaxes1, DictArray)
    result[widthtableaxes2,1:nkeys] = map(string, tableaxes1.data.keys)
    for i in 1:nkeys
      for j in widthtableaxes2+1:nrows
        if (j-widthtableaxes2-1) % widthtabledata == 0
          result[j,i] = cell_to_string(tableaxes1.data.values[i][1+div(j-1-widthtableaxes2, widthtabledata)])
        end
      end
    end
  else
    for j in widthtableaxes2+1:nrows
      if (j-widthtableaxes2-1) % widthtabledata == 0
        result[j,1] = cell_to_string(tableaxes1[1+div(j-1-widthtableaxes2, widthtabledata)])
      end
    end
  end
  (result, collect(widthtableaxes2+1+widthtabledata*(0:1+fld(nrows-1,widthtabledata))), [nkeys+1,nkeys+2])
end

show_indent(io::IO, indent) = print(io, repeat(" ", indent))

show_string_matrix(io::IO, m::Matrix, show_height, show_width, indent, hline_pos=[], vline_pos=[]) = begin
  # calculate maximum width for the displayed cells for each column.
  msize = size(m)
  max_widths = zeros(Int, msize[2])
  for j in 1:msize[1]
    for i in 1:msize[2]
      max_widths[i] = max(max_widths[i], length(m[j,i]))
    end
  end
  # calculate total width in character.
  max_i = 0
  nchar_sofar = indent
  istrunc = false
  for i in 1:length(max_widths)
    if nchar_sofar <= show_width
      nchar_sofar += max_widths[i] + (i in vline_pos ? 2 : 1)
      max_i +=1
    else
      istrunc = true
      break
    end
  end
  j_count = 0
  print(io, '\n')
  for j in 1:msize[1]
    if j in hline_pos
      show_indent(io, indent)
      running_nchars = indent
      for i in 1:max_i
        if i in vline_pos
          print(io, '+')
          running_nchars += 1
        end
        linelength = max(0, min(show_width-running_nchars, max_widths[i]+1))
        print(io, repeat("-", linelength))
        running_nchars += linelength
      end
      print(io, '\n')
      j_count += 1
    end
    show_indent(io, indent)
    running_nchars = indent
    for i in 1:max_i
      if i in vline_pos
        print(io, '|')
        running_nchars += 1
      end
      if max_widths[i] + running_nchars > show_width
        # it could be a unicode character.
        if running_nchars >= show_width-2
          print(io, "..")
          running_nchars += 2
        else
          for c in m[j,i]
            if running_nchars >= show_width-2
              print(io, "..")
              running_nchars += 2
              break
            end
            print(io, c)
            running_nchars += 1
          end
        end
        print(io, repeat(" ", max(0, show_width - running_nchars)))
        running_nchars += max(0, show_width - running_nchars)
      else
        print(io, rpad(m[j,i], max_widths[i]))
        running_nchars += max_widths[i]
      end
      print(io, ' ')
      running_nchars += 1
    end
    if istrunc print(io, "...") end
    print(io, '\n')
    j_count += 1
    if j_count > show_height
      show_indent(io, indent)
      for i in 1:max_i
        if i in vline_pos
          print(io, '|')
        end
        print(io, rpad(":", max_widths[i]))
        print(io, ' ')
      end
      print(io, '\n')
      break
    end
  end
end

Base.eachindex(arr::LabeledArray) = eachindex(arr.data)
Base.start(arr::LabeledArray) = begin
  iter = eachindex(arr.data)
  i = 1
  axes = map(arr.axes) do axis
    a = BroadcastAxis(axis, arr.data, i)
    i += 1
    a
  end
  (axes, iter, start(iter))
end
Base.next(arr::LabeledArray, state) = begin
  nextelem, nextstate = next(state[2], state[3])
  axesvalues = map(state[1]) do axis
    axis[nextelem]
  end
  nextvalue = arr[nextelem]
  (nextvalue, (state[1], state[2], nextstate))
end
Base.done(arr::LabeledArray, state) = done(state[2], state[3])
Base.linearindexing{T,N,AXES<:Tuple,TN}(::Type{LabeledArray{T,N,AXES,TN}}) = Base.LinearSlow()
Base.eltype{T,N,AXES<:Tuple,TN}(::Type{LabeledArray{T,N,AXES,TN}}) = T
Base.length(table::LabeledArray) = length(table.data)
Base.getindex(arr::LabeledArray, arg::Symbol) = selectfield(arr, arg)
Base.getindex(arr::LabeledArray, arg::Symbol, args::Symbol...) = [selectfield(arr, a) for a in [arg;args...]]
Base.getindex{N}(arr::LabeledArray, args::Tuple{N,Symbol}) = map(a->selectfield(arr, a), args)
Base.getindex(arr::LabeledArray, args::AbstractVector{Symbol}) = selectfields(arr, args...)
Base.getindex(arr::LabeledArray, indices::CartesianIndex) = getindex(arr, indices.I...)
Base.getindex(table::LabeledArray, indices...) = begin
  if is_scalar_indexing(indices)
    getindex_labeledarray_scalar_indexing(table, indices)
  else
    getindex_labeledarray_nonscalar_indexing(table, indices)
  end
end

getindex_labeledarray_scalar_indexing(table::LabeledArray, indices) = begin
  int_indices = Array(Int, ndims(table))
  loc_ind = 1
  # this is a hackish way to deal a CartesianIndex, but I don't know a better way yet...
  for index in indices
    if isa(index, Real)
      int_indices[loc_ind] = index
      loc_ind += 1
    elseif isa(index, CartesianIndex)
      for j = 1:length(index)
        int_indices[loc_ind+j-1] = index[j]
      end
      loc_ind += length(index)
    else
      error("this cannot happen. the index is ", index, " and we don't know how to handle it.")
    end
  end
  getindex(table, int_indices...)
end

getindex_labeledarray_nonscalar_indexing(table::LabeledArray, indices) = begin
  dataelem = getindex(table.data, indices...)
  zippedindices = zip(table.axes, indices)
  filtered_zippedindices = [filter(elem->!isa(elem[2], Real), zip(table.axes, indices))...]
  axeselem = [axis_index(axis,index) for (axis, index) in zippedindices]
  ndimstable = ndims(table)
  v04ndims = ndimstable
  for i in ndimstable:-1:1
    if !isa(axeselem[i], Real)
      v04ndims = i
      break
    end
  end
  if ndims(dataelem) == v04ndims
    # this is the expected behavior for v0.4:
    LabeledArray(dataelem, (axeselem[1:v04ndims]...))
  else
    # this is the expected behavior for v0.5, if one direction before the last non integer index is an integer index.
    LabeledArray(dataelem, ([axis_index(axis, index) for (axis, index) in filtered_zippedindices]...))
  end
end

axis_index(axis, index) = axis[index]
axis_sub(axis, index) = sub(axis, index)
axis_slice(axis, index) = slice(axis, index)

axis_index(axis::DefaultAxis, i::Int) = i
axis_index(axis::DefaultAxis, ::Colon) = axis
axis_index(axis::DefaultAxis, index::AbstractArray{Bool}) = DefaultAxis(length(find(index)))
axis_index(axis::DefaultAxis, index) = DefaultAxis(length(index))
axis_sub(axis::DefaultAxis, index) = axis_index(axis, index)
axis_slice(axis::DefaultAxis, index) = axis_index(axis, index)

Base.getindex(table::LabeledArray, indices::Int) =
  getindex_inner(table, ind2sub(table, indices))
Base.getindex(table::LabeledArray, indices::Int...) =
  getindex_inner(table, indices)
getindex_inner{N}(table::LabeledArray, indices::NTuple{N,Int}) = getindex(table.data, indices...)


# returns nested pairs axis1 => (axis2 => ... => (axisN => value)).
getindexpair(table::LabeledArray, indices::Int) =
  getindexpair_inner(table, ind2sub(table, indices))
getindexpair(table::LabeledArray, indices::Int...) =
  getindexpair_inner(table, indices)
getindexpair_inner{N}(table::LabeledArray{TypeVar(:T),N}, indices::NTuple{N,Int}) = begin
  tableaxes = table.axes
  foldr((x,acc)->Pair(x,acc),
        getindex(table.data, indices...),
        [x[y] for (x,y) in zip(tableaxes,indices)])
end

Base.size{N}(table::LabeledArray{TypeVar(:T),N}) = size(table.data)::NTuple{N,Int}
Base.transpose(table::LabeledArray{TypeVar(:T),2}) = LabeledArray(transpose(table.data), (table.axes[2],table.axes[1]))
Base.permutedims(table::LabeledArray, perms) = begin
  lenaxes = length(table.axes)
  if length(perms) != lenaxes
    throw(ArgumentError("LabeledArray permutedims: the number of axes is not the same as the length of the permutations."))
  end
  newdata = permutedims(table.data, perms)
  newaxes = cell(lenaxes)
  for i=1:lenaxes
    newaxes[i] = table.axes[perms[i]]
  end
  LabeledArray(newdata,(newaxes...))
end
Base.setindex!(table::LabeledArray, v, args...) = setindex!(table.data, v, args...)
Base.Multimedia.writemime(io::IO, ::MIME"text/plain", table::LabeledArray) = show(io, table)
Base.sub(table::LabeledArray, indices::Union{Colon, Int64, AbstractArray{TypeVar(:T),1}}...) = begin
  dataelem = sub(table.data, indices...)
  axeselem = [axis_sub(axis, isa(index,Int) ? (index:index) : index) for (axis, index) in zip(table.axes,indices)]
  newN = ndims(dataelem)
  LabeledArray(dataelem, (axeselem[1:newN]...))
end
Base.slice(table::LabeledArray, indices::Union{Colon, Int64, AbstractArray{TypeVar(:T),1}}...) = begin
  dataelem = slice(table.data, indices...)
  axeselem = [axis_slice(axis, index) for (axis, index) in [filter(elem->!isa(elem[2], Real), zip(table.axes, indices))...]]
  newN = ndims(dataelem)
  LabeledArray(dataelem, (axeselem[1:newN]...))
end

# select the field with name from table. If the name belongs to an axis,
# the axis array is broadcast to the full matrix shape.
selectfield(table::LabeledArray, name) = begin
  if isa(table.data, DictArray) && name in table.data.data.keys
    return selectfield(table.data, name)
  end
  counter = 1
  for axis in table.axes
    if isa(axis, DictArray) && name in axis.data.keys
      return AbstractArrayWrapper(BroadcastAxis(selectfield(axis, name), table.data, counter))
    end
    counter += 1
  end
  throw(ArgumentError(string("cannot find field ", name, " in the data or axes.")))
end
selectfields(arr::LabeledArray, fields...) = DictArray(LDict(map(n->n=>selectfield(arr,n), fields)...))

# broadcast an axis so that they can be treated as an N dimensional array for LabeledArray{T,N}.
immutable BroadcastAxis{T,N,V,W} <: AbstractArray{T,N}
  axis::V #AbstractArray{T,1}
  base::W #AbstractArray{TypeVar(:U),N}
  index::Int
end
(==)(arr1::BroadcastAxis, arr2::BroadcastAxis) =
  arr1.index==arr2.index && size(arr1.base)==size(arr2.base) && arr1.axis==arr2.axis
BroadcastAxis{T,N}(axis::AbstractArray{T,1}, base::AbstractArray{TypeVar(:U),N}, index::Int) = BroadcastAxis{T,N,typeof(axis),typeof(base)}(axis, base, index)
BroadcastAxis(axis::DictArray, base::AbstractArray, index::Int) = create_dictarray_nocheck(mapvalues(v->BroadcastAxis(v, base, index), peel(axis)))
Base.size(axis::BroadcastAxis) = size(axis.base)
Base.linearindexing(::Type{BroadcastAxis}) = Base.LinearSlow()
Base.getindex(axis::BroadcastAxis, arg::CartesianIndex) = getindex(axis.axis, arg[axis.index])
Base.getindex(axis::BroadcastAxis, args...) = begin
  newaxis = getindex(axis.axis, args[axis.index])
  if isa(newaxis, AbstractArray)
    newbase = sub(axis.base, args...)
    BroadcastAxis(newaxis, newbase, axis.index)
  else
    # this is definitely not one point. it is one coord along the axis index, but ranges along some other directions.
    # I cannot think of an alternative. Let's do a copy.
    fill(newaxis, size(sub(axis.base, args...)))
  end
end
Base.getindex(axis::BroadcastAxis, index::Int...) = getindex(axis.axis, index[axis.index])
Base.getindex(axis::BroadcastAxis, index::Int) = begin
  getindex(axis.axis, ind2sub(axis.base, index)[axis.index])
end

"""

returns all field names for LabeledArray or DictArray. Returns an empty array for other types of arrays.

"""
allfieldnames(table::LabeledArray) = simplify_array(unique(vcat(vcat(map(allfieldnames, table.axes)...),allfieldnames(table.data))))
allfieldnames(table::AbstractArray) = Array(Any, 0)
cell_to_string(cell::Nullable) = cell.isnull ? "" : string(cell.value)
cell_to_string{K,T}(cell::LDict{K,Nullable{T}}) = string(cell)
cell_to_string(cell::AbstractArray) = string(map(x->string(cell_to_string(x)," "), cell)...)

isna(arr::LabeledArray) = isna(peel(arr))
isna(arr::LabeledArray, indices...) = isna(peel(arr), indices...)

"""

`cat(catdim::Integer, arrs::LabeledArray...)`

Concatenate `LabeledArray`s `arrs` along the `catdim` direction.
The base of each element of `arrs` are concatenated and become the new base of the return `LabeledArray`.
The axes of each of `arrs` not along the `catdim` direction should be identical. Otherwise, there will be an error.
The axis along the `catdim` direction will be the concatenation of the axis of each of `arrs` along that direction.

```julia
julia> t1 = larr(a=[1 2 3;4 5 6], axis1=[:x,:y], axis2=["A","B","C"])
t2 x 3 LabeledArray

  |  |A B C 
--+--+------
x |a |1 2 3 
--+--+------
y |a |4 5 6 


julia> t2 = larr(a=[11 12 13;14 15 16], axis1=[:x,:y], axis2=["D","E","F"])
2 x 3 LabeledArray

  |  |D  E  F  
--+--+---------
x |a |11 12 13 
--+--+---------
y |a |14 15 16 


julia> cat(2, t1, t2)
2 x 6 LabeledArray

  |  |A B C D  E  F  
--+--+---------------
x |a |1 2 3 11 12 13 
--+--+---------------
y |a |4 5 6 14 15 16 
```

"""
Base.cat(catdim::Integer, arr1::LabeledArray, arrs::LabeledArray...) = begin
  if isempty(arrs)
    return arr1
  end
  newdata = cat(catdim, arr1.data, map(x->x.data, arrs)...)
  arrlist = Any[arr1,arrs...]
  newaxes = cell(max(map(ndims, arrlist)...))
  for arr in arrlist
    for i in 1:length(arr.axes)
      if i != catdim && isdefined(newaxes, i) && arr.axes[i] != newaxes[i]
        throw(ArgumentError("array dimensions in the arguments for cat do not match."))
      else
        newaxes[i] = arr.axes[i]
      end
    end
  end
  newaxes[catdim] = if all(arr->ndims(arr)<catdim || isa(arr.axes[catdim], DefaultAxis), arrlist) #isa(newaxes[catdim], DefaultAxis)
    DefaultAxis(sum(map(arr->ndims(arr)<catdim ? 1 : length(arr.axes[catdim]), arrlist)))
  else
    maxsizearr = arrlist[indmax(map(ndims, arrlist))]
    null_oneelem_array = create_naelem_array(maxsizearr.axes[catdim])
    cat(1, map(arr->ndims(arr)<catdim ? null_oneelem_array : arr.axes[catdim], arrlist)...)
  end
  LabeledArray(newdata, (newaxes...))
end

create_naelem_array(arr::DictArray) = darr(mapvalues(arr.data) do v
  eltype(v)[Nullable{eltype(eltype(v))}()]
end...)
create_naelem_array(arr::AbstractArray) = eltype(arr)[Nullable{eltype(eltype(arr))}()]

Base.vcat(arr1::LabeledArray, arrs::LabeledArray...) = cat(1, arr1, arrs...)
Base.hcat(arr1::LabeledArray, arrs::LabeledArray...) = cat(2, arr1, arrs...)

Base.repeat(arr::LabeledArray; inner::Array{Int}=ones(Int,ndims(arr)), outer::Array{Int}=ones(Int,ndims(arr))) = begin
  newdata = repeat(arr.data, inner=inner, outer=outer)
  newaxes = ntuple(ndims(arr)) do d
    repeat(arr.axes[d], inner=collect(inner[d]), outer=collect(outer[d]))
  end
  additional_axes = map(n->DefaultAxis(n), size(newdata)[length(newaxes)+1:end])
  LabeledArray(newdata, (newaxes..., additional_axes...))
end

Base.Multimedia.writemime{N}(io::IO,
                             ::MIME"text/html",
                             table::LabeledArray{TypeVar(:T),N};
                             height::Int=dispsize()[1],
                             width::Int=dispsize()[2],
                             alongrow::Bool=todisp_alongrow) = begin
  ndimstable = ndims(table)
  print(io, join(size(table), " x "))
  print(io, " LabeledArray")
  print(io, '\n')
  print(io, "<ul>")
  for index=1:last(size(table))
    axislabel = table.axes[end][index]
    coords = [fill(:,ndimstable-1);index]
    print(io, "<li>")
    print(io, axislabel)
    print(io, ' ')
    print(io, '[')
    for i in 1:length(coords)-1
      print(io, ":,")
    end
    print(io, index)
    print(io, ']')
    print(io, '\n')
    Base.Multimedia.writemime(io, MIME("text/html"), getindex(table, coords...); height=height, width=width, alongrow=alongrow)
    print(io, "</li>")
  end
  print(io, "</ul>")
end

Base.Multimedia.writemime(io::IO, ::MIME"text/html", table::LabeledArray{TypeVar(:T),0}; height::Int=dispsize()[1], width::Int=dispsize()[2], alongrow::Bool=todisp_alongrow) = begin
  print(io, "0 dimensional LabeledArray")
end


Base.Multimedia.writemime(io::IO, ::MIME"text/html", table::Union{LabeledArray{TypeVar(:T),1},LabeledArray{TypeVar(:T),2}}; height::Int=dispsize()[1], width::Int=dispsize()[2], alongrow::Bool=todisp_alongrow) = begin
  print(io, join(size(table), " x "))
  print(io, " LabeledArray")
  print(io, '\n')
  (result, hlines, vlines) = if alongrow
    create_string_reprmat_alongrow(table; height=height, width=width)
  else
    create_string_reprmat_alongcol(table; height=height, width=width)
  end
  print_string_reprmat_to_html_table(io, result, height, width, hlines, vlines)
end

# an internal function to convert a string represented matrix into an html table string printed into an output io).
print_string_reprmat_to_html_table{T<:AbstractString}(io::IO, strrep::AbstractArray{T,2}, height, width, hlines=[], vlines=[]) = begin
  buffer = 1
  print(io, """<table border="0" style="border:none; width:100%; border-collapse:collapse">""")
  for row in 1:size(strrep,1)
    if row > height-buffer
      print(io, """<tr style="border:0">""")
      for col in 1:size(strrep,2)
        if col > width-buffer
          break
        end
        print(io, """<td style="border:1px solid #000; border-width:0 0 0 0">:</td>""")
      end
      print(io, "</tr>")
      break
    end
    print(io, """<tr style="border:0">""")
    for col in 1:size(strrep,2)
      if col > width-buffer
        print(io, """<td style="border:1px solid #000; border-width:0 0 0 0"></td>""")
        break
      end
      ishline = row in hlines
      isvline = col in vlines
      if ishline && isvline
        print(io, """<td style="border:1px solid #ccc;border-width:1px 0px 0px 1px">""")
      end
      if ishline && !isvline
        print(io, """<td style="border:1px solid #ccc;border-width:1px 0px 0px 0px">""")
      end
      if !ishline && isvline
        print(io, """<td style="border:1px solid #ccc;border-width:0px 0px 0px 1px">""")
      end
      if !ishline && !isvline
        print(io, """<td style="border:1px solid #ccc;border-width:0px 0px 0px 0px">""")
      end
      print(io, strrep[row, col])
      print(io, "</td>")
    end
    print(io, "</tr>")
   end
  print(io, """</table>""")
end

Base.convert(::Type{DictArray}, larr::LabeledArray) = selectfields(larr, allfieldnames(larr)...)
Base.convert(::Type{LabeledArray}, larr::LabeledArray) = larr

Base.map(f::Function, arr::LabeledArray) = mapslices(f, arr, [])
Base.reducedim(f::Function, arr::LabeledArray, dims, initial) = begin
  mapslices(arr, dims) do slice
    reduce(f, initial, slice)
  end
end
Base.mapslices(f::Function, arr::LabeledArray, dims::AbstractVector) = begin
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
  newdata = if ndims(result) == 0
    isa(result, DictArray) ? mapvalues(x->x[1], result) : result[1]
  else
    result
  end
  newaxes = arr.axes[filter(i->!(i in dims),1:ndims(arr))]
  if length(dims) == ndims(arr)
    newdata
  else
    LabeledArray(newdata, newaxes)
  end
end

@generated mapslices_inner{T,N,AXES,TN,D}(f::Function, arr::LabeledArray{T,N,AXES,TN}, dims::D) = begin
  dimtypes = dims.types
  slice_ndims = foldl((acc,x)->acc + (x==Int), 0, dimtypes)
  slice_indices = Int[map(it->it[1], filter(it->it[2]==Int, enumerate(dimtypes)))...]
  slice_exp = if slice_ndims == N
    :(arr.data[coords...])
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
    testres = f(testslice)
    reseltype = typeof(testres)
    result = Array(reseltype, sizearr[$slice_indices]...)

    if reseltype <: LDict
      ldict_keys_sofar = testres.keys
      same_ldict::Bool = true
      @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
        fill!(coords, Colon())
        @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
        oneslice = $slice_exp
        oneres = f(oneslice)
        if same_ldict
          same_ldict &= (ldict_keys_sofar == oneres.keys)
        end
        @nref($slice_ndims, result, i) = oneres
      end
      if same_ldict
        valuetypes = [typeof(v) for v in testres.values]
        valuevects = map(valuetypes) do vtype
          similar(result, vtype)
        end
        valuevectslen = length(valuevects)
        @nloops $slice_ndims i result begin
          for j in 1:valuevectslen
            valuevectsj = valuevects[j]
            @nref($slice_ndims,valuevectsj,i) = @nref($slice_ndims,result,i).values[j]
          end
        end
        DictArray(testres.keys, map(wrap_array, valuevects))
      else
        result
      end
    else
      @nloops $slice_ndims i j->1:sizearr[$slice_indices[j]] begin
        fill!(coords, Colon())
        @nexprs $slice_ndims j->(coords[$slice_indices[j]] = i_j)
        oneslice = $slice_exp #slice(arr, coords...)
        oneres = f(oneslice)
        @nref($slice_ndims, result, i) = oneres
      end
      wrap_array(nalift(result))
    end
  end
end

recursive_pair_types{K1,K2,V}(::Type{Pair{K1,Pair{K2,V}}}) = DataType[K1, recursive_pair_types(Pair{K2,V})...]
recursive_pair_types{K,V}(::Type{Pair{K,V}}) = DataType[K, V]

"""

`create_dict(::LabeledArray)`

Create a nested `Dict` from a `LabeledArray`.

##### Examples

```julia
julia> t = larr(a=[1 2;3 4], axis1=[:x,:y], axis2=["A","B"])
2 x 2 LabeledArray

  |  |A B 
--+--+----
x |a |1 2 
--+--+----
y |a |3 4 


julia> create_dict(t)
Dict{Nullable{Symbol},Dict{Nullable{ASCIIString},MultidimensionalTables.LDict{Symbol,Nullable{Int64}}}} with 2 entries:
  Nullable(:y) => Dict(Nullable("B")=>MultidimensionalTables.LDict(:a=>Nullable(4)),Nullable("A")=>MultidimensionalTables.LDict(:a=>Nullable(3)))
  Nullable(:x) => Dict(Nullable("B")=>MultidimensionalTables.LDict(:a=>Nullable(2)),Nullable("A")=>MultidimensionalTables.LDict(:a=>Nullable(1)))
```

"""
function create_dict end

create_dict{T,N,AXES<:Tuple,TN}(arr::LabeledArray{T,N,AXES,TN}) = begin
  kvtype = foldr((x,acc)->Pair{x,acc}, T, map(eltype, arr.axes))
  typevec = recursive_pair_types(kvtype)
  result = foldr((x,acc)->Dict{x,acc}, typevec)()
  for i in eachindex(arr)
    if !isna(arr, i)
      insert_dict!(typevec, result, getindexpair(arr, i))
    end
  end
  result
end

insert_dict!{K,KK,DV,PV}(typevec, d::Dict{K,Dict{KK,DV}}, elem::Pair{K,PV}) = begin
  k = elem.first
  v = elem.second
  if !haskey(d, k)
    d[k] = Dict{KK,DV}()
  end
  insert_dict!(typevec[2:end], d[k], v)
end
insert_dict!{K,V}(typevec, d::Dict{K,V}, elem::Pair{K,V}) = begin
  k = elem.first
  v = elem.second
  d[k] = v
end

# to avoid ambiguity with conventional use of reverse, specifically prohobit the integer argument.
Base.reverse(arr::LabeledArray, dummy::Int) = error("not yet implemented.")
Base.reverse(arr::LabeledArray) = Base.reverse(arr, [1])
# any iterable dims can be an argument.
Base.reverse(arr::LabeledArray, dims) = begin
  coords = ntuple(ndims(arr)) do d
    if d in dims
      size(arr, d):-1:1
    else
      Colon()
    end
  end
  getindex(arr, coords...)
end
Base.flipdim(arr::LabeledArray, dims::Int...) = reverse(arr, dims)

Base.reshape(arr::LabeledArray, dims::Tuple{Vararg{Int}}) = reshape(arr, dims...)

"""

`reshape(arr::LabeledArray, dims...)`

Reshape `arr` into different sizes, if there is no ambiguity.
This means you can collapse several contiguous directions into one direction,
in which case all axes belonging to collapsing direction will be concatenated.
For other case, sometimes it is possible to disambiguate the axis position.
But in general, the result is either an error or an undetermined result
as long as the axis positions are concerned.

##### Examples

```julia
julia> t = larr(a=[1 2 3;4 5 6], axis1=[:x,:y], axis2=["A","B","C"])
2 x 3 LabeledArray

  |A |B |C 
--+--+--+--
  |a |a |a 
--+--+--+--
x |1 |2 |3 
y |4 |5 |6 


1 x 6 LabeledArray

x1 |x |y |x |y |x |y 
x2 |A |A |B |B |C |C 
---+--+--+--+--+--+--
   |a |a |a |a |a |a 
---+--+--+--+--+--+--
1  |1 |4 |2 |5 |3 |6 


julia> reshape(t, 6, 1)
6 x 1 LabeledArray

      |1 
------+--
x1 x2 |a 
------+--
x  A  |1 
y  A  |4 
x  B  |2 
y  B  |5 
x  C  |3 
y  C  |6 


julia> reshape(t, 6)
6 LabeledArray

x1 x2 |a 
------+--
x  A  |1 
y  A  |4 
x  B  |2 
y  B  |5 
x  C  |3 
y  C  |6 


julia> reshape(t, 3,2)
ERROR: ArgumentError: dims (3,2) are inconsistent.
```

"""
Base.reshape(arr::LabeledArray, dims::Int...) = begin
  newdata = reshape(arr.data, dims...)
  arraxes = arr.axes
  srcdims = [1;cumprod(collect(size(arr)))]
  tgtdims = [1;cumprod(collect(dims))]
  newaxes = Any[DefaultAxis(d) for d in dims]

  tracker = []
  for d in 1:length(arr.axes)
    if !isa(arraxes[d], DefaultAxis)
      startdims = srcdims[d]
      enddims = srcdims[d+1]
      # find where startdims, enddims lie in the tgtdims.
      for p in 1:length(dims)
        tgtdim = tgtdims[p]
        ntgtdim = tgtdims[p+1]
        if tgtdim<=startdims && ntgtdim>=enddims
          inner_dims = divrem(startdims, tgtdim)
          outer_dims = divrem(ntgtdim, enddims)
          if inner_dims[2] != 0 || outer_dims[2] != 0
            throw(ArgumentError("dims $(dims) are inconsistent."))
          end
          axistoadd = repeat(arraxes[d], inner=collect(inner_dims[1]), outer=collect(outer_dims[1]))
          if isa(newaxes[p], DefaultAxis)
            newaxes[p] = axistoadd
          else
            newaxes[p] = DictArray(merge(map(x->isa(x,DictArray) ? x.data : LDict(create_additional_fieldname(arr,tracker)=>x), (newaxes[p], axistoadd))...))
          end
        end
      end
    end
  end
  LabeledArray(newdata, (newaxes...))
end

"""

##### Description

reorders the fields such that the first field names are `names`.
The rest field names are placed sequentially after that.

"""
function reorder end

"""

##### Description

renames the fields such that the first field names are `names`.
The rest field names remain the same.

"""
function rename end


"""

`reorder(arr::LabeledArray, ks...)`

Reorder the field names of the base of `arr` so that the first few field names are `ks`.
The base of `arr` is expected to be a `DictArray`.

##### Return
A new `LabeledArray` whose base fields are shuffled from `arr` so that the first few field names are `ks`.

"""
reorder(arr::LabeledArray, ks...) = LabeledArray(reorder(arr.data, ks...), arr.axes)

"""

`rename(arr::LabeledArray, ks...)`

Rename the field names of the base of `arr` so that the first few field names are `ks`.

##### Return
A new `LabeledArray` whose first few field names of the base of `arr` are `ks`.

"""
rename(arr::LabeledArray, ks...) = LabeledArray(rename(arr.data, ks...), arr.axes)

"""

`@larr(...)`

Create a `LabeledArray`. The arguments `...` can be one of the following:

##### Arguments

* `k=>v` creates a field using array `v` with field name `k` for the base of the return `LabeledArray`. `k` can be an arbitrary type. If the element type of `v` is not `Nullable`, each element will be wrapped by `Nullable`. If `NA` is provided as an element, it is translated as `Nullable{T}()` for an appropriate type `T`.
* `k=v` creates a field using array `v` of the base with field name `:k`.
* There can be at most one non pair type argument, which will be converted into a `LabeledArray` and other pair arguments will update it.
* `axisN[...]` for some integer `N`: this creates an axis along the `N`th direction. If `...` are either keywords or pairs, those are used to create a `DictArray`. Otherwise, an array will be created using `...`.

##### Examples

```julia
julia> t = @larr(a=[1 NA;3 4;NA NA],:b=>[1.0 1.5;:sym 'a';"X" "Y"],c=1,axis1[:U,NA,:W],axis2[r=['m','n']])
3 x 2 LabeledArray

r |m       |n       
--+--------+--------
  |a b   c |a b   c 
--+--------+--------
U |1 1.0 1 |  1.5 1 
  |3 sym 1 |4 a   1 
W |  X   1 |  Y   1 


julia> @larr(t, c=[NA NA;3 4;5 6], :d=>:X, axis1[k=["g","h","i"]])
3 x 2 LabeledArray

r |m         |n         
--+----------+----------
k |a b   c d |a b   c d 
--+----------+----------
g |1 1.0   X |  1.5   X 
h |3 sym 3 X |4 a   4 X 
i |  X   5 X |  Y   6 X 
```

"""
macro larr(args...)
  data_pairs = Any[]
  axes_pairs = Any[]
  template = Nullable()
  for arg in args
    if :head in fieldnames(arg) && (arg.head == :kw || arg.head == :(=>))
      key = arg.head==:kw ? quote_symbol(arg.args[1]) : arg.args[1]
      value = arg.args[2]
      push!(data_pairs, quote
        $key => @nalift($(esc(value)))
      end)
    elseif :head in fieldnames(arg) && arg.head ==:ref && startswith(string(arg.args[1]), "axis") &&
           all(Bool[is_kw(a) for a in arg.args[2:end]])
      push!(axes_pairs, arg.args[1] => read_kws(arg.args[2:end]))
    elseif :head in fieldnames(arg) && arg.head == :ref && startswith(string(arg.args[1]), "axis") && length(arg.args) > 1
      if length(arg.args) != 2
        valueexpr = Expr(:vect, map(esc, arg.args[2:end])...)
        push!(axes_pairs, arg.args[1] => (verbatim_magic_symbol, quote
          @nalift($valueexpr)
        end))
        #throw(ArgumentError("if not a keyword/pair argument, the length has to be 1, consisting of an array for that axis."))
      else
        push!(axes_pairs, arg.args[1] => (verbatim_magic_symbol, quote
          @nalift($(esc(arg.args[2])))
        end))
      end
    elseif template.isnull #length(args) == 1
      template = Nullable(arg)
    else
      throw(ArgumentError("not a key=value type argument or an array argument $arg, or two or more base LabeledArrays are provided."))
    end
  end
  dataexp = if template.isnull && isempty(data_pairs)
    throw(ArgumentError("neither a base LabeledArray or a fieldname=>array pair provided."))
  elseif isempty(data_pairs)
    nothing
  else
    Expr(:call, :darr, Expr(:..., Expr(:vect, data_pairs...)))
  end
  axesexp = map(axes_pairs) do axispair
    axisname = axispair[1]
    axisvalue = axispair[2]
    axisexpr = if isa(axisvalue, Tuple) && length(axisvalue) == 2 && axisvalue[1] == verbatim_magic_symbol
      Expr(:kw, axisname, axisvalue[2])
    else
      Expr(:kw, axisname, Expr(:call, :darr, Expr(:..., Expr(:vect, axisvalue...))))
    end
  end
  if template.isnull
    Expr(:call, :larr, dataexp, axesexp...)
  else
    Expr(:call, :update_larr, quote @nalift($(esc(template.value))) end, dataexp, axesexp...)
  end
end

larr_inner(kwargs...) = begin
  data = []
  axes = []
  for (k,v) in kwargs
    if startswith(string(k), "axis")
      push!(axes, k=>nalift(v))
    else
      push!(data, k=>v)
    end
  end
  LabeledArray(darr(data...); axes...)
end

"""

`larr(...)`

Create a `LabeledArray`. The arguments `...` can be one of the following:

##### Arguments

* `k=>v` creates a field using array `v` with field name `k` for the underlying base `DictArray`. `k` can be an arbitrary type. If the element type of `v` is not `Nullable`, each element will be wrapped by `Nullable`. If you want to manually provide a `Nullable` array with `Nullable{T}()` elements in it, the macro version `@larr` may be more convenient to use. Note that this type of argument precedes the keyword type argument in the return `LabeledArray`, as shown in Examples below.
* `k=v` creates a field using an array `v` with field name `:k` for the underlying base `DictArray`.
* The keyword `axisN=v` for some integer `N` and an array `v` is treated specially. This will create the `N`th axis using the array `v`.
* There can be at most one non pair type argument, which will be converted into a `LabeledArray` and other pair arguments will update it.
Especially, if the non pair type argument is an array of `LDict`, it will be converted into a `DictArray`.

##### Examples

```julia
julia> t = larr(a=[1 2;3 4;5 6],:b=>[1.0 1.5;:sym 'a';"X" "Y"],c=1,axis1=[:U,:V,:W],axis2=darr(r=['m','n']))
3 x 2 LabeledArray

r |m       |n       
--+--------+--------
  |b   a c |b   a c 
--+--------+--------
U |1.0 1 1 |1.5 2 1 
V |sym 3 1 |a   4 1 
W |X   5 1 |Y   6 1 


julia> larr(t, c=[1 2;3 4;5 6], :d=>:X, axis1=darr(k=["g","h","i"]))
3 x 2 LabeledArray

r |m         |n         
--+----------+----------
k |b   a c d |b   a c d 
--+----------+----------
g |1.0 1 1 X |1.5 2 2 X 
h |sym 3 3 X |a   4 4 X 
i |X   5 5 X |Y   6 6 X 
```

"""
function larr end


larr0(arr::LabeledArray, kwargs...) = begin
  data = []
  newaxes = Any[arr.axes...]
  for (k,v) in kwargs
    kstr = string(k)
    if startswith(kstr, "axis")
      axisindex = parse(Int, kstr[5:endof(kstr)])
      newaxes[axisindex] = nalift(v)
    else
      push!(data, k=>nalift(v))
    end
  end
  LabeledArray(combine_data_inner(arr.data, LDict(data...)), (newaxes...))
end

combine_data_inner(arr1::DictArray, ldict::LDict) = darr(merge(arr1.data, ldict)...)
combine_data_inner(arr1::AbstractArray, ldict::LDict) = if isempty(ldict)
  arr1
else
  throw(ArgumentError("cannot combine an array of type $(typeof(arr1)) with a dict of type $(typeof(ldict))"))
end

larr(arr::AbstractArray) = convert(LabeledArray, nalift(arr))
larr(arr::AbstractArray, kwargs...) = larr(convert(LabeledArray, nalift(arr)), kwargs...)
larr(arr::AbstractArray, pairs...; kwargs...) = if isempty(kwargs) && isempty(pairs)
  convert(LabeledArray, nalift(arr))
else
  larr(convert(LabeledArray, nalift(arr)), pairs..., kwargs...)
end
larr(arr::LabeledArray, pairs...; kwargs...) = larr0(arr, pairs..., kwargs...)
larr(arr::LabeledArray) = arr
larr(args...; kwargs...) = larr_inner(args..., kwargs...)

Base.convert{K,V,N}(::Type{LabeledArray}, arr::LabeledArray{LDict{K,V},N}) = LabeledArray(convert_to_dictarray_if_possible(peel(arr)), arr.axes)
Base.convert{K,V,N}(::Type{LabeledArray}, arr::LabeledArray{Nullable{LDict{K,V}},N}) = LabeledArray(convert_to_dictarray_if_possible(peel(arr)), arr.axes)

# for some reason, this generic verion is gtakeed up instead of the LDict specialized versions.
Base.convert(::Type{LabeledArray}, arr::DictArray) = LabeledArray(arr)
Base.convert(::Type{LabeledArray}, arr::AbstractArray) = if eltype(arr) <: LDict
  LabeledArray(convert_to_dictarray_if_possible(arr))
elseif eltype(arr) <: Nullable && eltype(eltype(arr)) <: LDict
  LabeledArray(convert_to_dictarray_if_possible(arr))
else
  LabeledArray(arr)
end

update_larr(base, data; kwargs...) = update_larr(convert(LabeledArray, base), data;kwargs...)
update_larr(base::LabeledArray, data; kwargs...) = begin
  newdata = if data == nothing
    base.data
  else
    darr(merge(base.data.data, data.data)...)
  end
  newaxes = if isempty(kwargs)
    base.axes
  else
    axes = cell(length(base.axes))
    copy!(axes, base.axes)
    for (k,v) in kwargs
      kstr = string(k)
      if startswith(kstr, "axis")
        axisindex = parse(Int, kstr[5:endof(kstr)])
        axes[axisindex] = v
      end
    end
    axes
  end
  LabeledArray(newdata, (newaxes...))
end

"""

`merge(::LabeledArray, ::LabeledArray)`

Merge two `LabeledArrays`. The axes set of the two should be identical.
The bases are merged together and the common axes set is used.

##### Examples

```julia
julia> merge(larr(a=[1,2,3],b=[:x,:y,:z],axis1=[:a,:b,:c]),larr(c=[4,5,6],b=[:m,:n,:p],axis1=[:a,:b,:c]))
3 LabeledArray

  |a b c 
--+------
a |1 m 4 
b |2 n 5 
c |3 p 6 
```

"""
Base.merge(arr1::LabeledArray, arr2::LabeledArray) = begin
  @assert(pickaxis(arr1) == pickaxis(arr2))
  LabeledArray(merge(peel(arr1), peel(arr2)), pickaxis(arr1))
end

"""

`merge(::LabeledArray, ::DictArray...)`

Merge the base of the `LabeledArray` and the rest `DictArray`s.
Together with the axes set of the input `LabeledArray`, return a new `LabeledArray`.

##### Examples

```julia
julia> merge(larr(a=[1,2,3],b=[:x,:y,:z],axis1=[:a,:b,:c]),darr(c=[4,5,6],b=[:m,:n,:p]),darr(a=["X","Y","Z"]))
3 LabeledArray

  |a b c 
--+------
a |X m 4 
b |Y n 5 
c |Z p 6 
```

"""
Base.merge(arr1::LabeledArray, args::DictArray...) = LabeledArray(merge(peel(arr1), args...), pickaxis(arr1))
