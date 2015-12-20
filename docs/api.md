# MultidimensionalTables

## Exported

---

<a id="function__axis2flds.1" class="lexicon_definition"></a>
#### MultidimensionalTables.axis2flds [¶](#function__axis2flds.1)

`axis2flds(arr::LabeledArray (; name_collapse_function=..., default_axis_value=nothing)`

Collapse a dimension of a [`LabeledArray`](#type__labeledarray.1), making the axis along that direction as field names.

##### Arguments

* `larr` : a LabeledArray.
* `name_collapse_function` (optional keyword) : a function to combine the axis label and the column name. By default, it concatenates the names with '_' inserted in between.
* `default_axis_value` (optional keyword) : a default value to be used when an axis element is null. If `nothing` (by default), an exception will raise.

##### Examples

```julia
julia> t = larr(reshape(1:10,5,2), axis1=darr(k=['a','b','c','d','e']), axis2=darr(r1=[:M,:N],r2=["A","A"]))
5 x 2 LabeledArray

r1 |M |N  
r2 |A |A  
---+--+---
k  |  |   
---+--+---
a  |1 |6  
b  |2 |7  
c  |3 |8  
d  |4 |9  
e  |5 |10 


julia> axis2flds(t)
5 LabeledArray

k |M_A N_A 
--+--------
a |1   6   
b |2   7   
c |3   8   
d |4   9   
e |5   10  


julia> axis2flds(t, name_collapse_function=x->join(x, "*"))
5 LabeledArray

k |M*A N*A 
--+--------
a |1   6   
b |2   7   
c |3   8   
d |4   9   
e |5   10  


julia> m = @larr(reshape(1:10,5,2), axis1[k=['a','b','c','d','e']], axis2[:M,NA])
5 x 2 LabeledArray

  |M |   
--+--+---
k |  |   
--+--+---
a |1 |6  
b |2 |7  
c |3 |8  
d |4 |9  
e |5 |10 


julia> axis2flds(m, default_axis_value="N/A")
5 LabeledArray

k |M N/A 
--+------
a |1 6   
b |2 7   
c |3 8   
d |4 9   
e |5 10  
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:614](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L614)

---

<a id="function__collapse_axes.1" class="lexicon_definition"></a>
#### MultidimensionalTables.collapse_axes [¶](#function__collapse_axes.1)

`collapse_axes(arr::AbstractArray, front_dim::Integer, back_end::Integer)`

Collapse front_dim to back_dim dimensions into one.

##### Arguments

* `arr` : an array
* `front_dims` : the starting direction to collapse.
* `back_dims` : the end direction to collapse.

The result is an array whose elements along front_dims to back_dims are all flattened into one dimension.
If `arr` is a LabeledArray, all the labels along the flattened direction are combined together.

##### Examples

```julia
julia> collapse_axes(darr(a=reshape(1:40, 2,4,5), b=reshape(11:50, 2,4,5)), 1, 2)
8 x 5 DictArray

a b  |a  b  |a  b  |a  b  |a  b  
-----+------+------+------+------
1 11 |9  19 |17 27 |25 35 |33 43 
2 12 |10 20 |18 28 |26 36 |34 44 
3 13 |11 21 |19 29 |27 37 |35 45 
4 14 |12 22 |20 30 |28 38 |36 46 
5 15 |13 23 |21 31 |29 39 |37 47 
6 16 |14 24 |22 32 |30 40 |38 48 
7 17 |15 25 |23 33 |31 41 |39 49 
8 18 |16 26 |24 34 |32 42 |40 50 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:203](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L203)

---

<a id="function__darr.1" class="lexicon_definition"></a>
#### MultidimensionalTables.darr [¶](#function__darr.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1288](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1288)

---

<a id="function__delete.1" class="lexicon_definition"></a>
#### MultidimensionalTables.delete [¶](#function__delete.1)

Delete keys or fields from `LDict`, `DictArray`, or `LabeledArray`.

* `delete(dict::LDict, keys...)` deletes the keys `keys` from `dict` and returns a new `LDict`.
* `delete(arr::DictArray, fieldnames...)` deletes the fields for `fieldnames` from `arr` and returns a new `DictArray`.
* `delete(arr::LabeledArray, fieldnames...)` deletes the fields for `fieldnames` from `arr`, either from the base or axes, and returns a new `LabeledArray`.

##### Examples

```julia
julia> delete(LDict(:a=>1, :b=>2, :c=>3), :a, :c)
MultidimensionalTables.LDict{Symbol,Int64} with 1 entry:
  :b => 2

julia> delete(darr(a=[1,2,3], b=[:m,:n,:p]), :b)
3 DictArray

a 
--
1 
2 
3 


julia> t = larr(a=[1 2;3 4;5 6], b=[:x :y;:z :u;:v :w], axis1=darr(k=["X","Y","Z"]), axis2=[:A,:B])
3 x 2 LabeledArray

  |A   |B   
--+----+----
k |a b |a b 
--+----+----
X |1 x |2 y 
Y |3 z |4 u 
Z |5 v |6 w 


julia> delete(t, :k, :b)
3 x 2 LabeledArray

  |A |B 
--+--+--
  |a |a 
--+--+--
1 |1 |2 
2 |3 |4 
3 |5 |6 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:979](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L979)

---

<a id="function__describe.1" class="lexicon_definition"></a>
#### MultidimensionalTables.describe [¶](#function__describe.1)

`describe(arr)`

Generate a `LabeledArray` showing the overall statistics of the input.
If the input is a `Nullable` array, its summary statistics is calculated and the return value is of type `LDict`.
If the input is a `DictArray`, the summary is calculated for each field and the result is a `DictArray`.
If the input is a `LabeledArray`, `describe` returns the summary of its base.

##### Examples

```julia
julia> describe(@nalift([1,2,3,4,NA]))
MultidimensionalTables.LDict{Symbol,Any} with 10 entries:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:1312](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L1312)

---

<a id="function__discard.1" class="lexicon_definition"></a>
#### MultidimensionalTables.discard [¶](#function__discard.1)

`discard(arr, ns...)`

Discard a block of array discarding all elements specified by `ns`..., using labels for `LabeledArray`s, indices for other types of arrays or `LDict`s.

##### Arguments

* `arr`: an `AbstractArray` or `LDict`.
* `ns...`: each element in `ns` chooses specific elements along that direction. The element can be
  * `Colon()` (`:`): the entire range will be removed and the return value will be empty.
  * a label or array of labels along that direction to discard.
  * a boolean array of the same size as the axis along that direction to denote which position to discard.
  * a function that takes the axis along that direction and generates either an array of integers or a boolean array for the deleted positions.

##### Return

An array or `LDict` of the same type as `arr`, which is selected based on `ns`.... All indices will be chosen for the rest of the directions not specified in `ns`.... If any label is missing or the integer range is out of bound, it will be ignored.

##### Examples

```julia
julia> t = larr(a=map(x->'a'+x,reshape(0:14,5,3)), b=reshape(1:15,5,3), axis1=[:X,:Y,:Z,:U,:V], axis2=darr(r1=[:A,:A,:B],r2=[:m,:n,:n]))
5 x 3 LabeledArray

r1 |A   |A    |B    
r2 |m   |n    |n    
---+----+-----+-----
   |a b |a b  |a b  
---+----+-----+-----
X  |a 1 |f 6  |k 11 
Y  |b 2 |g 7  |l 12 
Z  |c 3 |h 8  |m 13 
U  |d 4 |i 9  |n 14 
V  |e 5 |j 10 |o 15 


julia> discard(t, [:X,:V,:W], map(Nullable,(:A,:m)))
3 x 2 LabeledArray

r1 |A   |B    
r2 |n   |n    
---+----+-----
   |a b |a b  
---+----+-----
Y  |g 7 |l 12 
Z  |h 8 |m 13 
U  |i 9 |n 14 


julia> discard(t, [:X,:V,:W], darr(r1=[:A,:B],r2=[:m,:m]))
3 x 2 LabeledArray

r1 |A   |B    
r2 |n   |n    
---+----+-----
   |a b |a b  
---+----+-----
Y  |g 7 |l 12 
Z  |h 8 |m 13 
U  |i 9 |n 14 


julia> discard(t, [], d->d[:r1] .== :A)
5 x 1 LabeledArray

r1 |B    
r2 |n    
---+-----
   |a b  
---+-----
X  |k 11 
Y  |l 12 
Z  |m 13 
U  |n 14 
V  |o 15 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1611](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1611)

---

<a id="function__dropna.1" class="lexicon_definition"></a>
#### MultidimensionalTables.dropna [¶](#function__dropna.1)

Remove any `NA` entries. If all elements are `NA` along some slice, that slice will be removed and the array size will shrink.

##### Examples

```julia
julia> t = @darr(a=[1 2 NA;NA 5 NA], b=[NA :n NA;:x NA NA])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1   |2 n |    
  x |5   |    


julia> dropna(t)
2 x 2 DictArray

a b |a b 
----+----
1   |2 n 
  x |5   


julia> m = @larr(a=[1 2 NA;NA 5 NA], b=[NA :n NA;:x NA NA], axis1[:M,:N])
d2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
M |1   |2 n |    
N |  x |5   |    


julia> dropna(m)
2 x 2 LabeledArray

  |1   |2   
--+----+----
  |a b |a b 
--+----+----
M |1   |2 n 
N |  x |5   
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1067](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1067)

---

<a id="function__enumeration.1" class="lexicon_definition"></a>
#### MultidimensionalTables.enumeration [¶](#function__enumeration.1)

`enumeration(arr [, poolorder])`

Create an `EnumerationArray`.

##### Arguments

* `arr`: an input array of `Nullable` element type. It is assumed that there are only a few possible values in `arr` and each value is converted into an integer when creating an `EnumerationArray`.
* `poolorder`: a vector to fix some of the integer values in the mapping from the values in `arr` to integers. If there are `n` elements in `poolorder`, those `n` elements in `arr` will be assigned 1...`n` when creating an `EnumerationArray`. All the others are assigned integers in order of their appearance.

##### Examples

```julia
julia> enumeration([:A,:A,:B,:B,:C])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)
 Nullable(:A)
 Nullable(:B)
 Nullable(:B)
 Nullable(:C)

julia> enumeration([:A,:A,:B,:B,:C]).pool
3-element Array{Symbol,1}:
 :A
 :B
 :C

julia> enumeration([:A,:A,:B,:B,:C]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 1
 2
 2
 3

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)
 Nullable(:A)
 Nullable(:B)
 Nullable(:B)
 Nullable(:C)

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B]).pool
3-element Array{Symbol,1}:
 :C
 :B
 :A

julia> enumeration([:A,:A,:B,:B,:C], [:C,:B]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 3
 3
 2
 2
 1
```



*source:*
[MultidimensionalTables/src/datatypes/enumeration_array.jl:178](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/enumeration_array.jl#L178)

---

<a id="function__extract.1" class="lexicon_definition"></a>
#### MultidimensionalTables.extract [¶](#function__extract.1)

`extract(arr, ns...)`

Extract a block of array using labels for `LabeledArray`s, indices for other types of arrays or `LDict`s.

##### Arguments

* `arr`: an `AbstractArray` or `LDict`.
* `ns...`: each element in `ns` chooses specific elements along that direction. The element can be
  * `Colon()` (`:`): the entire range.
  * a label along that direction. If the axis along the direction is `DictArray`, the label can be either an `LDict` for its element or a tuple to denote the values of `LDict`.
  * array of labels along that direction.
  * a boolean array of the same size as the axis along that direction to denote which position to choose.
  * a function that takes the axis along that direction and generates either an array of integers or a boolean array for the selected positions.

##### Return

An array or `LDict` of the same type as `arr`, which is selected based on `ns`.... All indices will be chosen for the rest of the directions not specified in `ns`.... If any label is missing or the integer range is out of bound, `NA` will be used for that element in the return value. If an element in `ns` is scalar, the dimension along that direction will be collapsed just as in `slice`.

##### Examples

```julia
julia> t = larr(a=map(x->'a'+x,reshape(0:14,5,3)), b=reshape(1:15,5,3), axis1=[:X,:Y,:Z,:U,:V], axis2=darr(r1=[:A,:A,:B],r2=[:m,:n,:n]))
5 x 3 LabeledArray

r1 |A   |A    |B    
r2 |m   |n    |n    
---+----+-----+-----
   |a b |a b  |a b  
---+----+-----+-----
X  |a 1 |f 6  |k 11 
Y  |b 2 |g 7  |l 12 
Z  |c 3 |h 8  |m 13 
U  |d 4 |i 9  |n 14 
V  |e 5 |j 10 |o 15 


julia> extract(t, [:X,:V,:W], map(Nullable,(:A,:m)))
3 LabeledArray

  |a b 
--+----
X |a 1 
V |e 5 
W |    


julia> extract(t, [:X,:V,:W], darr(r1=[:A,:B],r2=[:m,:m]))
3 x 2 LabeledArray

r1 |A   |B   
r2 |m   |m   
---+----+----
   |a b |a b 
---+----+----
X  |a 1 |    
V  |e 5 |    
W  |    |    


julia> extract(t, :, d->d[:r1] .== :A)
5 x 2 LabeledArray

r1 |A   |A    
r2 |m   |n    
---+----+-----
   |a b |a b  
---+----+-----
X  |a 1 |f 6  
Y  |b 2 |g 7  
Z  |c 3 |h 8  
U  |d 4 |i 9  
V  |e 5 |j 10 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1399](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1399)

---

<a id="function__flds2axis.1" class="lexicon_definition"></a>
#### MultidimensionalTables.flds2axis [¶](#function__flds2axis.1)

`flds2axis(arr::LabeledArray [; axisname=nothing, fieldname=nothing])`

Create another dimension using the field values of the data of a LabeledArray.

##### Arguments

* `arr` : a `LabeledArray`.
* `axisname` (optional) : the name of the new axis.
* `fieldname` (optional) : the name of the new field name. If not specified, the resulting `LabeledArray` will have a normal `AbstractArray` and not a `DictArray` as its data.

##### Returns

A new `LabeledArray` which has one higher dimensions than the input `arr`.
The field names become the elements of the new last axis, after wrapped by `Nullable`.
If `axisname` is provided, the new axis becomes a `DictArray` with that field name.
Otherwise, the new axis will be a normal array.
If `fieldname` is provided, the new data of the return `LabeledArray` is a `DictArray` with that field name.
Otherwise, the new data will be a normal array.

##### Examples

```julia
julia> t = larr(a=[1,2,3], b=[:x,:y,:z])
3 LabeledArray

  |a b 
--+----
1 |1 x 
2 |2 y 
3 |3 z 


julia> flds2axis(t, axisname=:newaxis, fieldname=:newfield)
3 x 2 LabeledArray

newaxis |a        |b        
--------+---------+---------
        |newfield |newfield 
--------+---------+---------
1       |1        |x        
2       |2        |y        
3       |3        |z        
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:509](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L509)

---

<a id="function__igna.1" class="lexicon_definition"></a>
#### MultidimensionalTables.igna [¶](#function__igna.1)

`igna(arr [, nareplace])`

Ignore null elements from `arr`.
Null elements will be replaced by `nareplace`, if provided.
If not, the behavior is implementation specific: depending on the array type, it may give some default value or raise an error.
Most likely, a nullable element in an array of `Nullable{F}` element type for some `AbstractFloat` `F` can be replaced by a version of `NaN`.
But for other types, it may be better to raise an error.

* `igna(arr::AbstractArray{Nullable{T},N} [, na_replace])`: ignores null elements from `arr` and return an `AbstractArray{T,N}`. A null value is replaced by `na_replace` if provided. Otherwise, the result is implementation specific.

* `igna(ldict::LDict [, na_replace])` ignores null values from `ldict` and replace them with `na_replace` if provided. Otherwise, the result is implementation specific.

##### Examples

```julia
julia> igna(@nalift([1,2,NA,4,5]))
ERROR: MultidimensionalTables.NAElementException()
 in anonymous at /Users/changsoonpark/.julia/v0.4/MultidimensionalTables/src/na/na.jl:315
 in map_to! at abstractarray.jl:1289
 in map at abstractarray.jl:1311
 in igna at /Users/changsoonpark/.julia/v0.4/MultidimensionalTables/src/na/na.jl:313

julia> igna(@nalift([1.0,2.0,NA,4.0,5.0]))
5-element MultidimensionalTables.AbstractArrayWrapper{Float64,1,Array{Float64,1}}:
   1.0
   2.0
 NaN  
   4.0
   5.0

julia> igna(@nalift([1,2,NA,4,5]), 3)
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 2
 3
 4
 5

julia> igna(LDict(:a=>Nullable(3), :b=>Nullable{Int}()), 1)
MultidimensionalTables.LDict{Symbol,Int64} with 2 entries:
  :a => 3
  :b => 1
```



*source:*
[MultidimensionalTables/src/na/na.jl:483](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L483)

---

<a id="function__ignabool.1" class="lexicon_definition"></a>
#### MultidimensionalTables.ignabool [¶](#function__ignabool.1)

`ignabool(arr)`

Ignore the `Nullable` part of of either a `Nullable` array or a `Nullable` variable.
It is mainly used in the condition statement for @select or @update, where it assumes that only Nullable(true) chooses the element.  Nullable(false) or Nullable{T}() will be regarded as false.

* `ignabool(::AbstractArray{Nullable{Bool}}) returns an `AbstractArray{Bool}` where null and `Nullable(false)` elements are converted into `false` and `Nullable(true)` into `true`.
* `ignabool(::Nullable{Bool})` converts null and `Nullable(false)` elements into `false` and `Nullable(true)` into true.

##### Examples

```julia
julia> ignabool(Nullable{Bool}())
false

julia> ignabool(Nullable(true))
true

julia> ignabool(Nullable(false))
false

julia> ignabool(@nalift([true true NA;false NA true]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
  true   true  false
 false  false   true
```



*source:*
[MultidimensionalTables/src/na/na.jl:568](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L568)

---

<a id="function__innerjoin.1" class="lexicon_definition"></a>
#### MultidimensionalTables.innerjoin [¶](#function__innerjoin.1)

`innerjoin(base, src, join_axis...)`

Inner join an LabeledArray into another LabeledArray. `innerjoin` is different from `leftjoin` in that only elements in the left array that have the corresponding elements in the right array will be kept. Otherwise, the elements will be set to null. If the entire elements along some direction are null, they will be all removed in the output.
Note that the left array (base) can be multidimensional. The function creates a dictionary from the right array (`src`).

##### Arguments

* `base` : the left `LabeledArray`.
* `src` : the right `LabeledArray`.
* `join_axes...` can be one of the following forms:
    * integers for the directions in `src` along which to join.
    * a list of integer=>integer or integer=>vector of arrays, each array of the same shape as `base`.

Ultimately, `join_axes...` produces pairs of direction in `src` => vector of arrays, each of the shape of `base`. If the value in key=>value is an integer, the axis along that direction in `base` is taken, after broadcast. The field values are combined into a vector of arrays. If the right hand side is missing (i.e. just an integer), the field names in the axis along the integer direction are used to create an array for `base`.

##### Return

An inner joined `LabeledArray`. The join is performed as follows: Given an `i=>arr` form as an element in `join_axes`, the keys in `i`th direction in `src` are used as keys and `arr` are used the keys in the `base` side to inner join. The values will be the sliced subarrays for each value in the `join_axes`. Note that `join_axis...` chooses multiple axes for keys.
The output number of dimensions is `ndims(base) + ndims(src) - length(join_axes)`.
Note that when `join_axis` is empty, the result is the tensor product of `base` and `src` from `tensorprod`.

##### Examples

```julia
julia> b = larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z]))
2 x 3 LabeledArray

r |x |y |z 
--+--+--+--
  |k |k |k 
--+--+--+--
x |x |x |y 
u |z |u |v 


julia> s = larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6])
6 LabeledArray

k |b 
--+--
x |1 
y |2 
z |3 
m |4 
n |5 
p |6 


julia> innerjoin(b, s, 1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 2 
u |z 3 |u   |v   


julia> innerjoin(b, s, 1=>1)
1 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 1 


julia> innerjoin(b, s, 1=>Any[nalift([:o :x :x;:q :r :y])])
2 x 2 LabeledArray

r |y   |z   
--+----+----
  |k b |k b 
--+----+----
x |x 1 |y 1 
u |u   |v 2 
```



*source:*
[MultidimensionalTables/src/util/join.jl:288](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/join.jl#L288)

---

<a id="function__isna.1" class="lexicon_definition"></a>
#### MultidimensionalTables.isna [¶](#function__isna.1)

`isna(arr [, coords...])`

Checks `NA` for each element and produces an AbstractArray{Bool} of the same shape as `arr`.
If `coords...` are provided, `isna` checks `NA` at that position.

* If an input array is `AbstractArray{Nullable{T}}`, it checkes whether an element is null.
* If an input array is `DictArray`, it tests whether all values of the dictionary values for each element are null.
* If an input array is `LabeledArray`, it applies `isna` to the base of `arr`.

##### Examples

```julia
julia> t = @darr(a=[1 NA 3;4 5 NA], b=[NA NA :z;:u :v :w])
2 x 3 DictArray

a b |a b |a b 
----+----+----
1   |    |3 z 
4 u |5 v |  w 


julia> isna(t)
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false   true  false
 false  false  false

julia> isna(t, 2, 2:3)
1x2 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false  false

julia> isna(@larr(t, axis1[NA,:Y], axis2[NA,NA,"W"]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false   true  false
 false  false  false

julia> isna(@nalift([1 2 NA;NA 5 6]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Bool,2,Array{Bool,2}}:
 false  false   true
  true  false  false
```



*source:*
[MultidimensionalTables/src/na/na.jl:619](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L619)

---

<a id="function__larr.1" class="lexicon_definition"></a>
#### MultidimensionalTables.larr [¶](#function__larr.1)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1409](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1409)

---

<a id="function__leftjoin.1" class="lexicon_definition"></a>
#### MultidimensionalTables.leftjoin [¶](#function__leftjoin.1)

`leftjoin(base, src, join_axis...)`

Left join a `LabeledArray` into another `LabeledArray`.
Note that the left array (base) can be multidimensional. The function creates a dictionary from the right array (`src`).

##### Arguments

* `base` : the left `LabeledArray`.
* `src` : the right `LabeledArray`.
* `join_axes...` can be one of the following forms:
    * integers for the directions in `src` along which to join. In this case, the keys is the `base` side are found by matching the field names in the join directions in `src` with those in `base`.
    * a list of integer=>integer or integer=>vector of arrays, each of the same shape as `base`.

Ultimately, `join_axes...` produces pairs of direction in `src` => vector of arrays, each of the shape of `base`. If the value in key=>value is an integer, the axis along that direction in `base` is taken, after broadcast. The field values are combined into a vector of arrays. If the right hand side is missing (i.e. just an integer), the field names in the axis along the integer direction are used to create an array for `base`.

##### Return

A left joined `LabeledArray`. The join is performed as follows: Given an `i=>arr` form as an element in `join_axes`, the keys in `i`th direction in `src` are used as keys and `arr` are used the keys in the `base` side to left join. The values will be the sliced subarrays for each value in the `join_axes`. Note that `join_axis...` chooses multiple axes for keys.
The output number of dimensions is `ndims(base) + ndims(src) - length(join_axes)`.
Note that when `join_axis` is empty, the result is the tensor product of `base` and `src` from `tensorprod`.

##### Examples

```julia
julia> b = larr(k=[:x :x :y;:z :u :v], axis1=[:x,:y], axis2=darr(r=[:x, :y, :z]))
2 x 3 LabeledArray

r |x |y |z 
--+--+--+--
  |k |k |k 
--+--+--+--
x |x |x |y 
y |z |u |v 


julia> s = larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6])
6 LabeledArray

k |b 
--+--
x |1 
y |2 
z |3 
m |4 
n |5 
p |6 


julia> leftjoin(b, s, 1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 2 
y |z 3 |u   |v   


julia> leftjoin(b, s, 1=>1)
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 1 |y 1 
y |z 2 |u 2 |v 2 


julia> leftjoin(b, s, 1=>Any[nalift([:x :z :n;:y :m :p])])
2 x 3 LabeledArray

r |x   |y   |z   
--+----+----+----
  |k b |k b |k b 
--+----+----+----
x |x 1 |x 3 |y 5 
y |z 2 |u 4 |v 6 
```



*source:*
[MultidimensionalTables/src/util/join.jl:85](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/join.jl#L85)

---

<a id="function__mapna.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mapna [¶](#function__mapna.1)

`mapna(f::Function, args...)`

Apply `f` to the nullable arrays `args`. It works similarly as `map(f, args...)` but unwraps Nullable from `args`. If any of elements are Nullable, `f` is Nullable, too.

##### Arguments

* `f::Function`: a function to apply.
* `args`: nullable arrays.

##### Returns

A nullable array after applying `f` to elements of `args` for each index. `f` maps non-nullable value to either non-nullable or nullable one. If mapped to a non-nullable value, it will be wrapped by `Nullable` implicitly. If any element of `args` is `NA`, then the return value at that position will be `NA`, too.

##### Examples

```julia
julia> mapna((x,y)->x+y+1, @nalift([1 2 3;4 5 NA]), @nalift([NA 2 3;4 NA NA]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable{Int64}()  Nullable(5)        Nullable(7)      
 Nullable(9)        Nullable{Int64}()  Nullable{Int64}()

julia> mapna((x,y)->Nullable(x+y+1), @nalift([1 2 3;4 5 NA]), @nalift([NA 2 3;4 NA NA]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable{Int64}()  Nullable(5)        Nullable(7)      
 Nullable(9)        Nullable{Int64}()  Nullable{Int64}()
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1110](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1110)

---

<a id="function__mapvalues.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mapvalues [¶](#function__mapvalues.1)

`mapvalues(f::Function, x)`

Apply a function `f` to `x`, which can be of type `LDict`/`DictArray`/`LabeledArray`.

##### Returns

* If `x` is `LDict`, `f` is applied to each value and the result is again `LDict` with the same keys and the new values.
* If `x` is `DictArray`, `f` is applied to each field. The return value will be `DictArray` if the return value of `f` is also an `AbstractArray`. Otherwise, an `LDict` will be returned.
* If `x` is `LabeledArray`, `mapvalues(f, _)` is applied to the base of `x`. The return value will be `LabeledArray` with the same axes if the return value of `f` is also an `AbstractArray`. Otherwise, an `LDict` will be returned.

##### Examples

```julia
julia> mapvalues(x->x+1, LDict(:a=>1, :b=>2))
MultidimensionalTables.LDict{Symbol,Int64} with 2 entries:
  :a => 2
  :b => 3

julia> mapvalues(x->x .+ 1, darr(a=[1,2,3], b=[4,5,6]))
3 DictArray

a b 
----
2 5 
3 6 
4 7 


julia> mapvalues(x->x .+ 1, larr(a=[1,2,3], b=[4,5,6], axis1=[:m,:n,:p]))
3 LabeledArray

  |a b 
--+----
m |2 5 
n |3 6 
p |4 7 


julia> mapvalues(sum, darr(a=[1,2,3], b=[4,5,6]))
MultidimensionalTables.LDict{Symbol,Nullable{Int64}} with 2 entries:
  :a => Nullable(6)
  :b => Nullable(15)

julia> mapvalues(sum, larr(a=[1,2,3], b=[4,5,6], axis1=[:m,:n,:p]))
MultidimensionalTables.LDict{Symbol,Nullable{Int64}} with 2 entries:
  :a => Nullable(6)
  :b => Nullable(15)
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:706](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L706)

---

<a id="function__mmaximum.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mmaximum [¶](#function__mmaximum.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(11)
 Nullable(14)
 Nullable(14)
 Nullable(14)
 Nullable(17)

julia> mmaximum(@nalift([11,NA,12,11,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:979](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L979)

---

<a id="function__mmean.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mmean [¶](#function__mmean.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(10.0) 
 Nullable(10.5) 
 Nullable(11.0) 
 Nullable(11.75)
 Nullable(12.8) 

julia> mmean(@nalift([10,NA,12,14,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:811](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L811)

---

<a id="function__mmedian.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mmedian [¶](#function__mmedian.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(14.0)

julia> mmedian(@nalift([11,NA,12,11,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:1043](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L1043)

---

<a id="function__mmiddle.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mmiddle [¶](#function__mmiddle.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(12.5)
 Nullable(14.0)

julia> mmiddle(@nalift([11,NA,12,11,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:1108](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L1108)

---

<a id="function__mminimum.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mminimum [¶](#function__mminimum.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(15)
 Nullable(10)
 Nullable(10)
 Nullable(10)
 Nullable(10)

julia> mminimum(@nalift([15,NA,12,11,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:915](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L915)

---

<a id="function__mprod.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mprod [¶](#function__mprod.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)    
 Nullable(110)   
 Nullable(1320)  
 Nullable(18480) 
 Nullable(314160)

julia> mprod(@nalift([10,NA,12,14,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:727](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L727)

---

<a id="function__mquantile.1" class="lexicon_definition"></a>
#### MultidimensionalTables.mquantile [¶](#function__mquantile.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
 Nullable(11.0) 
 Nullable(11.75)
 Nullable(11.75)
 Nullable(11.75)
 Nullable(12.5) 

julia> mquantile(@nalift([11,NA,12,11,17]), 0.25)
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Float64},1,Array{Nullable{Float64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:1174](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L1174)

---

<a id="function__msum.1" class="lexicon_definition"></a>
#### MultidimensionalTables.msum [¶](#function__msum.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)
 Nullable(21)
 Nullable(33)
 Nullable(47)
 Nullable(64)

julia> msum(@nalift([10,NA,12,14,17]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:642](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L642)

---

<a id="function__nafill.1" class="lexicon_definition"></a>
#### MultidimensionalTables.nafill [¶](#function__nafill.1)

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
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable{Int64}()
 Nullable{Int64}()  Nullable(4)      
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t)
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable{Int64}()
 Nullable(1)  Nullable(4)      
 Nullable(1)  Nullable(4)      

julia> nafill(t,2)
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable(1)      
 Nullable{Int64}()  Nullable(4)      
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t,2,1)
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(1)
 Nullable(1)  Nullable(4)
 Nullable(1)  Nullable(4)

julia> nafill(t, rev=true)
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable(4)      
 Nullable{Int64}()  Nullable(4)      
 Nullable{Int64}()  Nullable{Int64}()

julia> nafill(t, window=2)
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)        Nullable{Int64}()
 Nullable(1)        Nullable(4)      
 Nullable{Int64}()  Nullable(4)      
```



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:491](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L491)

---

<a id="function__nalift.1" class="lexicon_definition"></a>
#### MultidimensionalTables.nalift [¶](#function__nalift.1)

`nalift(arr)`

Lift each element in an array `arr` to `Nullable` if it is not already so.
Unlike `@nalift`, it does not perform lifting recursively.
It returns `arr` itself when applied to a `DictArray`/`LabeledArray`.

##### Examples

```julia
julia> nalift(Any[[1,2,3],[4,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},1,Array{Nullable{Array{Int64,1}},1}}:
 Nullable([1,2,3])
 Nullable([4,5])  

julia> nalift([1,2,3])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(2)
 Nullable(3)

julia> nalift(Any[[1,2,3],[4,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},1,Array{Nullable{Array{Int64,1}},1}}:
 Nullable([1,2,3])
 Nullable([4,5])  

julia> nalift(darr(a=[1 2;3 4;5 6], b=[:x :y;:z :w;:u :v]))
3 x 2 DictArray

a b |a b 
----+----
1 x |2 y 
3 z |4 w 
5 u |6 v 
```



*source:*
[MultidimensionalTables/src/na/na.jl:224](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L224)

---

<a id="function__namerge.1" class="lexicon_definition"></a>
#### MultidimensionalTables.namerge [¶](#function__namerge.1)

`namerge(xs...)`

Combine `Nullable` arrays and `Nullable` elements, having the later arguments override the preceding ones if the new element is not null.

##### Arguments

`xs...` consists of either a `AbstractArrayWrapper` with `Nullable` element type, or a `Nullable` variable. If an element is neither `AbstractArray` or `Nullable`, it will be wrapped by `Nullable`.

##### Return

* When there is no argument, an error will raise.
* If there is only one argument, that argument will be returned.
* If there are two arguments and if the two are not `AbstractArray`, the second argument will be returned only if it is not null. Otherwise, the first argument will be returned.
* If there are two arguments, and the two are `Nullable` arrays, the element at each position will be the one from the first argument if the second argument element is null. Otherwise, the element from the second argument will be used. If any argument is not `AbstractArray`, it will be promoted to a `Nullable` array.

##### Examples

```julia

julia> namerge(10, @nalift([1 2 NA;4 NA NA]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)   Nullable(10)
 Nullable(4)  Nullable(10)  Nullable(10)

julia> namerge(@nalift([1 2 NA;4 NA NA]), 10)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(10)  Nullable(10)  Nullable(10)
 Nullable(10)  Nullable(10)  Nullable(10)

julia> namerge(10, @nalift([1 2 NA;4 NA NA]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)   Nullable(10)
 Nullable(4)  Nullable(10)  Nullable(10)

julia> namerge(@nalift([1 2 NA;4 NA NA]), @nalift([11 NA NA;14 15 NA]))
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(11)  Nullable(2)   Nullable{Int64}()
 Nullable(14)  Nullable(15)  Nullable{Int64}()

```



*source:*
[MultidimensionalTables/src/util/array_util.jl:2162](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L2162)

---

<a id="function__peel.1" class="lexicon_definition"></a>
#### MultidimensionalTables.peel [¶](#function__peel.1)

Peel off a variable to see its underlying data.

* `peel(arr::DictArray)`: returns an `LDict` consisting of field name => field values array pairs.

* `peel(arr::LabeledArray)`: returns the underlying data, which can be a `DictArray` but can also be any `AbstractArray`.

##### Examples

```julia
julia> peel(darr(a=[1,2,3], b=[:m,:n,:p]))
MultidimensionalTables.LDict{Symbol,MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}}} with 2 entries:
  :a => [Nullable(1),Nullable(2),Nullable(3)]
  :b => [Nullable(:m),Nullable(:n),Nullable(:p)]

julia> peel(larr(a=[1,2,3], b=[:m,:n,:p], axis1=["X","Y","Z"]))
3 DictArray

a b 
----
1 m 
2 n 
3 p 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:763](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L763)

---

<a id="function__pick.1" class="lexicon_definition"></a>
#### MultidimensionalTables.pick [¶](#function__pick.1)

Pick fields from a `DictArray` or a `LabeledArray`.

* `pick(arr::DictArray, fieldname)`: returns the field value array corresponding to `fieldname`.
* `pick(arr::DictArray, fieldnames::AbstractArray)`: returns a `DictArray` whose field names are `fieldnames`.
* `pick(arr::DictArray, fieldnames::Tuple)`: returns a vector of field value arrays corresponding to `fieldnames`.
* `pick(arr::DictArray, fieldnames::...)` if there are more than 1 field name in `fieldnames`: returns a vector of field value arrays corresponding to the `fieldnames`.
* `pick(arr::LabeledArray, fieldname)`: returns the field value array corresponding to `fieldname`. If `fieldname` corresponds to a field in an axis, the field value array is broadcast appropriately.
* `pick(arr::LabeledArray, fieldnames::AbstractArray)`: returns a `DictArray` whose field names are `fieldnames`.
* `pick(arr::LabeledArray, fieldnames::Tuple)`: returns a vector of field value arrays corresponding to `fieldnames`.
* `pick(arr::LabeledArray, fieldnames::...)` if there are more than 1 field name in `fieldnames`: returns a vector of field value arrays corresponding to the `fieldnames`.

##### Examples

```julia
julia> pick(darr(a=[1,2,3], b=[:m,:n,:p]), :a)
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(2)
 Nullable(3)

julia> pick(darr(a=[1,2,3], b=[:m,:n,:p]), (:a,))
1-element Array{MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}},1}:
 [Nullable(1),Nullable(2),Nullable(3)]

julia> pick(darr(a=[1,2,3], b=[:m,:n,:p]), :a, :b)
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}},1}:
 [Nullable(1),Nullable(2),Nullable(3)]   
 [Nullable(:m),Nullable(:n),Nullable(:p)]

julia> pick(darr(a=[1,2,3], b=[:m,:n,:p]), (:a, :b))
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}},1}:
 [Nullable(1),Nullable(2),Nullable(3)]   
 [Nullable(:m),Nullable(:n),Nullable(:p)]

julia> t = larr(a=[1 2;3 4;5 6], b=[:x :y;:z :u;:v :w], axis1=darr(k=["X","Y","Z"]), axis2=[:A,:B])
3 x 2 LabeledArray

  |A   |B   
--+----+----
k |a b |a b 
--+----+----
X |1 x |2 y 
Y |3 z |4 u 
Z |5 v |6 w 


julia> pick(t, :a)
pic3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)
 Nullable(3)  Nullable(4)
 Nullable(5)  Nullable(6)

julia> pick(t, :a, :k)
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,N,A<:AbstractArray{T,N}},1}:
 3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)
 Nullable(3)  Nullable(4)
 Nullable(5)  Nullable(6)                                                                                                                                                                                                                                                     
 3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{ASCIIString},2,MultidimensionalTables.BroadcastAxis{Nullable{ASCIIString},2,MultidimensionalTables.AbstractArrayWrapper{Nullable{ASCIIString},1,Array{Nullable{ASCIIString},1}},MultidimensionalTables.DictArray{Symbol,2,MultidimensionalTables.AbstractArrayWrapper{T,2,A<:AbstractArray{T,N}},Nullable{T}}}}:
 Nullable("X")  Nullable("X")
 Nullable("Y")  Nullable("Y")
 Nullable("Z")  Nullable("Z")

julia> pick(t, (:a, :k))
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,N,A<:AbstractArray{T,N}},1}:
 3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)
 Nullable(3)  Nullable(4)
 Nullable(5)  Nullable(6)                                                                                                                                                                                                                                                     
 3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{ASCIIString},2,MultidimensionalTables.BroadcastAxis{Nullable{ASCIIString},2,MultidimensionalTables.AbstractArrayWrapper{Nullable{ASCIIString},1,Array{Nullable{ASCIIString},1}},MultidimensionalTables.DictArray{Symbol,2,MultidimensionalTables.AbstractArrayWrapper{T,2,A<:AbstractArray{T,N}},Nullable{T}}}}:
 Nullable("X")  Nullable("X")
 Nullable("Y")  Nullable("Y")
 Nullable("Z")  Nullable("Z")

julia> pick(t, [:a, :k])
3 x 2 DictArray

a k |a k 
----+----
1 X |2 X 
3 Y |4 Y 
5 Z |6 Z 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:855](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L855)

---

<a id="function__pickaxis.1" class="lexicon_definition"></a>
#### MultidimensionalTables.pickaxis [¶](#function__pickaxis.1)

Pick axes from a `LabeledArray`.

* `pickaxis(arr::LabeledArray)` picks a tuple of axes of `arr`.
* `pickaxis(arr::LabeledArray, index::Integer)` picks the axis along the `index` direction.
* `pickaxis(arr::LabeledArray, index::Integer, fields...)` picks the fields `fields` from the `index`th axis in `arr`. It is the same as `pick(pickaxis(arr, index), fields...)`.

##### Examples

```julia
julia> t = larr(a=[1 2;3 4;5 6], b=[:x :y;:z :u;:v :w], axis1=darr(k=["X","Y","Z"]), axis2=[:A,:B])
3 x 2 LabeledArray

  |A   |B   
--+----+----
k |a b |a b 
--+----+----
X |1 x |2 y 
Y |3 z |4 u 
Z |5 v |6 w 


julia> pickaxis(t)
(3 DictArray

k 
--
X 
Y 
Z 
,[Nullable(:A),Nullable(:B)])

julia> pickaxis(t, 1)
3 DictArray

k 
--
X 
Y 
Z 


julia> pickaxis(t, 1, :k)
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{ASCIIString},1,Array{Nullable{ASCIIString},1}}:
 Nullable("X")
 Nullable("Y")
 Nullable("Z")
```


*source:*
[MultidimensionalTables/src/util/array_util.jl:923](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L923)

---

<a id="function__providenames.1" class="lexicon_definition"></a>
#### MultidimensionalTables.providenames [¶](#function__providenames.1)

`providenames(arr::LabeledArray, create_fieldname::Funcion)`

Add generic field names for fields without field names in a `LabeledArray`.
This makes the data and all the axes components `DictArray`s.
This is useful when you want to apply `selct`/`update`/`leftjoin`/`innerjoin` whose interface is friendlier to `DictArray`s than general `AbstractArray`s.
The reverse operation, removing generic field names, is done by `withdrawnames`.
An optional argument `create_fieldname` is a function that gives a symbol that will be used as a new field name given an integer index.
By default, it generates `:xN` for an index integer `N`.

##### Examples

```julia
julia> t = larr([1 2 3;4 5 6], axis1=[:X,:Y], axis2=darr(k=["A","B","C"]))
2 x 3 LabeledArray

k |A |B |C 
--+--+--+--
  |  |  |  
--+--+--+--
X |1 |2 |3 
Y |4 |5 |6 


julia> providenames(t)
2 x 3 LabeledArray

k  |A  |B  |C  
---+---+---+---
x2 |x1 |x1 |x1 
---+---+---+---
X  |1  |2  |3  
Y  |4  |5  |6  
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1996](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1996)

---

<a id="function__rename.1" class="lexicon_definition"></a>
#### MultidimensionalTables.rename [¶](#function__rename.1)

##### Description

renames the fields such that the first field names are `names`.
The rest field names remain the same.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1230](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1230)

---

<a id="function__reorder.1" class="lexicon_definition"></a>
#### MultidimensionalTables.reorder [¶](#function__reorder.1)

##### Description

reorders the fields such that the first field names are `names`.
The rest field names are placed sequentially after that.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1220](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1220)

---

<a id="function__replace_axes.1" class="lexicon_definition"></a>
#### MultidimensionalTables.replace_axes [¶](#function__replace_axes.1)

##### Description
Replace axes with another fields.
The args are a list of pairs of the form (integer for the axis index) => new axes fields for this axis.
Only the first elements (`arr[:,...,:,1,:,...,:]`) will be taken. That is, if the underlying data array is 2 dimensional, and
you want to use the field `column1` as a new key for the 1st axis, `column1[:,1]` will be used as the new axis.
e.g. `replace_axes(labeled_array, 1=>[:c1,:c2], 3=>[:c3])`



*source:*
[MultidimensionalTables/src/util/array_util.jl:353](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L353)

---

<a id="function__selct.1" class="lexicon_definition"></a>
#### MultidimensionalTables.selct [¶](#function__selct.1)

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



*source:*
[MultidimensionalTables/src/util/select.jl:823](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L823)

---

<a id="function__shift.1" class="lexicon_definition"></a>
#### MultidimensionalTables.shift [¶](#function__shift.1)

`shift(arr, offsets... [; isbound=false])`

Parallel shift the input array `arr` so that the element at `[1,...,1]` in `arr` shows up at `[1,...,1]+offsets` in the return array.

##### Arguments

* `arr`: `AbstractArrayWrapper`/`LabeledArray`/`DictArray`, the input array. When applied to `DictArray`, `shift` is applied to each field. When applied to `LabeledArray`, `shift` is applied to the base.
* `offsets`: integers to denote the amount of offset for each direction. It is assumed that there is no shift in the missing direcitons.
* `isbound`: default `false`. If `true`, the index is floored and capped between 1 and the maximum possible index along that direction. If `false`, any out of bound index due to shifting results in a nullable element.

##### Examples

```julia
julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 1)
3x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 01)
3x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, 1)
3x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(5)        Nullable(6)        Nullable{Int64}()
 Nullable(8)        Nullable(9)        Nullable{Int64}()
 Nullable{Int64}()  Nullable{Int64}()  Nullable{Int64}()

julia> shift(nalift([1 2 3;4 5 6;7 8 9]), 1, -1)
3x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:1408](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L1408)

---

<a id="function__tensorprod.1" class="lexicon_definition"></a>
#### MultidimensionalTables.tensorprod [¶](#function__tensorprod.1)

`tensorprod(arrs...)`

Calculate the tensor product of `arrs`.

* `tensorprod(::AbstractArray...)` calculates the tensor product where the product operation creates a tuple of the input elements at each position, if every input element at that position is not `NA`. Otherwise, the result will be `NA`.
* `tensorprod(::DictArray...)` calculates the tensor product where the product operation creates a merged `LDict` of the input `LDict`s at each position.
* `tensorprod(::LabeledArray...)` calculates the tensor product of the bases of the inputs, which will be used as the base of the return `LabeledArray`. The axes of the return value will be appropriately extended version of the inputs.

##### Examples

```julia
julia> tensorprod(@nalift([1,2,NA]), @nalift([3,NA]))
3x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Tuple{Int64,Int64}},2,Array{Nullable{Tuple{Int64,Int64}},2}}:
 Nullable((1,3))                 Nullable{Tuple{Int64,Int64}}()
 Nullable((2,3))                 Nullable{Tuple{Int64,Int64}}()
 Nullable{Tuple{Int64,Int64}}()  Nullable{Tuple{Int64,Int64}}()

julia> tensorprod(@darr(a=[1,2,NA]), @darr(b=[3,NA]))
3 x 2 DictArray

a b |a b 
----+----
1 3 |1   
2 3 |2   
  3 |    


julia> tensorprod(@larr(a=[1,2,NA], axis1[:m,:n,:p]), @larr(b=[3,NA], axis1[:X,:Y]))
3 x 2 LabeledArray

  |X   |Y   
--+----+----
  |a b |a b 
--+----+----
m |1 3 |1   
n |2 3 |2   
p |  3 |    
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1198](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1198)

---

<a id="function__ungroup.1" class="lexicon_definition"></a>
#### MultidimensionalTables.ungroup [¶](#function__ungroup.1)

`ungroup(arr, ...)`

Ungroup array elements in an array into scalar elements along some direction.

##### Arguments

* `arr` : an array.
* `...` can be `axis`, `indices`, or `ref_field` : either an axis index along which to ungroup, a range tuple coordinates of the form `(i_1,...,i_k,:,i_{k+1},...,i_n)` for some integer i's, or the selected elements of `arr` after applying those types of tuples.

##### Return

An ungrouped array of the same type as `arr`. If `arr` is `LabeledArray`, the axis along the ungrouping direction will become a new field (a generic field name is provided if it was not a `DictArray` axis.

##### Examples

```julia
julia> t = larr(a=Any[[1,2,3],[4,5]], b=[:x,:x], c=Any[[11,12,13],[14,15]], axis1=[:X,:Y])
2 LabeledArray

  |a       b c          
--+---------------------
X |[1,2,3] x [11,12,13] 
Y |[4,5]   x [14,15]    


julia> ungroup(t, 1)
5 LabeledArray

  |x1 a b c  
--+----------
1 |X  1 x 11 
2 |X  2 x 12 
3 |X  3 x 13 
4 |Y  4 x 14 
5 |Y  5 x 15 


julia> ungroup(t, (:,1))
5 LabeledArray

  |x1 a b c  
--+----------
1 |X  1 x 11 
2 |X  2 x 12 
3 |X  3 x 13 
4 |Y  4 x 14 
5 |Y  5 x 15 


julia> m = nalift(reshape(Any[[1,2],[3,4],[5,6,7],[8,9,10]],2,2))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Array{Int64,1}},2,Array{Nullable{Array{Int64,1}},2}}:
 Nullable([1,2])  Nullable([5,6,7]) 
 Nullable([3,4])  Nullable([8,9,10])

julia> ungroup(m, 2)
2x5 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(5)  Nullable(6)  Nullable(7) 
 Nullable(3)  Nullable(4)  Nullable(8)  Nullable(9)  Nullable(10)
```



*source:*
[MultidimensionalTables/src/util/ungroup.jl:64](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/ungroup.jl#L64)

---

<a id="function__update.1" class="lexicon_definition"></a>
#### MultidimensionalTables.update [¶](#function__update.1)

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



*source:*
[MultidimensionalTables/src/util/select.jl:1042](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L1042)

---

<a id="function__withdrawnames.1" class="lexicon_definition"></a>
#### MultidimensionalTables.withdrawnames [¶](#function__withdrawnames.1)

`withdrawnames(arr::LabeledArray, check_fieldname::Function)`

Remove generic field names from a `LabeledArray` if possible.

##### Arguments
* `arr` is an input `LabeledArray`.
* `check_fieldname` is a function that returns whether an input field name is a generic name. By default, a field name is generic if it is a symbol of the form `:xN` for some integer `N`.

##### Return
If a field name in `LabeledArray` gives `true` when applied to `check_fieldname`, and the field name can be removed, it is removed in the return `LabeledArray`. A field name can be removed if it is a part of a `DictArray` with only one field.

##### Examples

```julia
julia> t = larr([1 2 3;4 5 6], axis1=[:X,:Y], axis2=darr(k=["A","B","C"]))
2 x 3 LabeledArray

k |A |B |C 
--+--+--+--
  |  |  |  
--+--+--+--
X |1 |2 |3 
Y |4 |5 |6 


julia> providenames(t)
2 x 3 LabeledArray

k  |A  |B  |C  
---+---+---+---
x2 |x1 |x1 |x1 
---+---+---+---
X  |1  |2  |3  
Y  |4  |5  |6  


julia> withdrawnames(providenames(t))
2 x 3 LabeledArray

k |A |B |C 
--+--+--+--
  |  |  |  
--+--+--+--
X |1 |2 |3 
Y |4 |5 |6 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:2068](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L2068)

---

<a id="method__rename.1" class="lexicon_definition"></a>
#### rename(arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  ks...) [¶](#method__rename.1)

`rename(arr::LabeledArray, ks...)`

Rename the field names of the base of `arr` so that the first few field names are `ks`.

##### Return
A new `LabeledArray` whose first few field names of the base of `arr` are `ks`.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1256](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1256)

---

<a id="method__rename.2" class="lexicon_definition"></a>
#### rename(ldict::MultidimensionalTables.LDict{K, V},  ks...) [¶](#method__rename.2)

`rename(ldict::LDict, ks...)`

Renames the first few keys using `ks`.

##### Examples

```julia
julia> rename(LDict(:a=>1, :b=>2, :c=>3), :b, 'x')
MultidimensionalTables.LDict{Any,Int64} with 3 entries:
  :b  => 1
  'x' => 2
  :c  => 3
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:300](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L300)

---

<a id="method__reorder.1" class="lexicon_definition"></a>
#### reorder(arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  ks...) [¶](#method__reorder.1)

`reorder(arr::LabeledArray, ks...)`

Reorder the field names of the base of `arr` so that the first few field names are `ks`.
The base of `arr` is expected to be a `DictArray`.

##### Return
A new `LabeledArray` whose base fields are shuffled from `arr` so that the first few field names are `ks`.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1244](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1244)

---

<a id="method__reorder.2" class="lexicon_definition"></a>
#### reorder(ldict::MultidimensionalTables.LDict{K, V},  ks...) [¶](#method__reorder.2)

`reorder(ldict::LDict, ks...)`

Reorder the keys so that the first few keys are `ks`.

##### Examples

```julia
julia> reorder(LDict(:a=>1, :b=>2, :c=>3), :b, :c)
MultidimensionalTables.LDict{Symbol,Int64} with 3 entries:
  :b => 2
  :c => 3
  :a => 1
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:281](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L281)

---

<a id="method__replace_axes.1" class="lexicon_definition"></a>
#### replace_axes(arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  args...) [¶](#method__replace_axes.1)
#### `replace_axes(arr::LabeledArray, args...)`

##### Arguments
* `arr`: an input `LabeledArray`. Note the data part of `arr` and the axis to replace need to be `DictArray`s.
* `args...`: arguments in `args` are of the form `i=>[f1,f2,...]` for some integer `i` and field names `f*`.

##### Returns
For each `i=>[f1,f2,...]` in `args`, the `i`th axis is replaced by the fields `f1`, `f2`, ....
Only the first elements will be taken. For example, if the underlying data array is 2 dimensional, and if you want to use some field for the 1st axis, `[:,1]` components will be used.
The original axis becomes the data part of `LabeledArray` after properly broadcast.
If the field name array is null for an argument in `args` (`i=>[]`), the corresponding axis will be `DefaultAxis`.

##### Examples

```julia
julia> t = larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=darr(k=[:x,:y]), axis2=["A","B","C"])
2 x 3 LabeledArray

  |A   |B   |C   
--+----+----+----
k |a b |a b |a b 
--+----+----+----
x |1 a |2 b |3 c 
y |4 d |5 e |6 f 


julia> replace_axes(t, 1=>[:a])
2 x 3 LabeledArray

  |A   |B   |C   
--+----+----+----
a |b k |b k |b k 
--+----+----+----
1 |a x |b x |c x 
4 |d y |e y |f y 


julia> replace_axes(t, 1=>[:a, :b])
2 x 3 LabeledArray

    |A |B |C 
----+--+--+--
a b |k |k |k 
----+--+--+--
1 a |x |x |x 
4 d |y |y |y 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:407](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L407)

---

<a id="type__dictarray.1" class="lexicon_definition"></a>
#### MultidimensionalTables.DictArray{K, N, VS, SV} [¶](#type__dictarray.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:31](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L31)

---

<a id="type__enumerationarray.1" class="lexicon_definition"></a>
#### MultidimensionalTables.EnumerationArray{T, N, V, R<:Integer} [¶](#type__enumerationarray.1)

An array type to store elements that have only a few choices.
That is, it is a pooled array.
Use `enumeration` to create an `EnumerationArray`.



*source:*
[MultidimensionalTables/src/datatypes/enumeration_array.jl:8](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/enumeration_array.jl#L8)

---

<a id="type__ldict.1" class="lexicon_definition"></a>
#### MultidimensionalTables.LDict{K, V} [¶](#type__ldict.1)

LDict is an ordered dictionary. It is assumed to be used in the field name => field mapping. In practice, the number of columns is not that long, and it is more efficient to implement LDict as 2 vectors, one for keys and one for values.

### Constructors

```julia
LDict{K,V}(dict::Associative{K, V}) # LDict from a dictionary dict. The result order is undetermined.
LDict{K,V}(dict::Associative{K, V}, ks) # LDict from a dictionary dict. ks is a vector of keys, and the keys in the result are ordered in that way. An error is thrown if one of ks is not found in dict.
LDict{K,V}(ks::Vector{K}, vs::Vector{V})
LDict(ps::Pair...)
LDict(ps::Tuple...)
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:18](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L18)

---

<a id="type__labeledarray.1" class="lexicon_definition"></a>
#### MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN} [¶](#type__labeledarray.1)

A multidimensional array together with additional axes attached to it.
Each axis is a one dimensional array, possibly a `DictArray`.
Use the function `larr` or a macro version `@larr` to create `LabeledArray`s, rather than call the constructor directly.

A `LabeledArray` consists of one main array, which we call the *base* array, and an axis array for each direction.

##### Constructors
* `LabeledArray(arr, axes)` creates a `LabeledArray` from a *base* array `arr` and a tuple `axes` of one dimensional arrays for axes.
* `LabeledArray(arr; kwargs...)` creates a `LabeledArray` from a *base* array `arr` and a keyword argument of the form `axisN=V` for some integer `N` for the axis direction and a one dimensional array `V`.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:16](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L16)

---

<a id="macro___darr.1" class="lexicon_definition"></a>
#### @darr(args...) [¶](#macro___darr.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1209](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1209)

---

<a id="macro___enumeration.1" class="lexicon_definition"></a>
#### @enumeration(args...) [¶](#macro___enumeration.1)

`@enumeration(arr [, poolorder])`

Create an `EnumerationArray`. Similar to the `enumeration` function, but you can type in a null element using `NA`.

##### Arguments

* `arr`: an input array of `Nullable` element type. It is assumed that there are only a few possible values in `arr` and each value is converted into an integer when creating an `EnumerationArray`. `NA` is translated into a null element of appropriate type.
* `poolorder`: a vector to fix some of the integer values in the mapping from the values in `arr` to integers. If there are `n` elements in `poolorder`, those `n` elements in `arr` will be assigned 1...`n` when creating an `EnumerationArray`. All the others are assigned integers in order of their appearance.

##### Examples

```julia
julia> @enumeration([:A,:A,:B,NA,NA])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)      
 Nullable(:A)      
 Nullable(:B)      
 Nullable{Symbol}()
 Nullable{Symbol}()

julia> @enumeration([:A,:A,:B,NA,NA]).pool
2-element Array{Symbol,1}:
 :A
 :B

julia> @enumeration([:A,:A,:B,NA,NA]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 1
 1
 2
 0
 0

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A])
5-element MultidimensionalTables.EnumerationArray{Symbol,1,MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}:
 Nullable(:A)      
 Nullable(:A)      
 Nullable(:B)      
 Nullable{Symbol}()
 Nullable{Symbol}()

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A]).pool
2-element Array{Symbol,1}:
 :B
 :A

julia> @enumeration([:A,:A,:B,NA,NA], [:B,:A]).elems
5-element MultidimensionalTables.AbstractArrayWrapper{Int64,1,Array{Int64,1}}:
 2
 2
 1
 0
 0
```



*source:*
[MultidimensionalTables/src/datatypes/enumeration_array.jl:247](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/enumeration_array.jl#L247)

---

<a id="macro___larr.1" class="lexicon_definition"></a>
#### @larr(args...) [¶](#macro___larr.1)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1299](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1299)

---

<a id="macro___nalift.1" class="lexicon_definition"></a>
#### @nalift(expr) [¶](#macro___nalift.1)

`@nalift(arr)`

Lift each element in an array `arr` to `Nullable` if it is not already so.
It is mainly used to translate a manually typed array expression such as `[1,2,3,NA,5]` into a `Nullable` array.
Unlike `nalift`, it performs lifting recursively.
It returns `arr` itself when applied to a `DictArray`/`LabeledArray`.

##### Examples

```julia
julia> @nalift([1,2,3])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(2)
 Nullable(3)

julia> @nalift([1,2,NA])
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)      
 Nullable(2)      
 Nullable{Int64}()

julia> @nalift(Any[[1,2,3],[NA,5]])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}},1,Array{Nullable{MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}},1}}:
 Nullable([Nullable(1),Nullable(2),Nullable(3)])
 Nullable([Nullable{Int64}(),Nullable(5)])      

julia> @nalift(larr(a=[1 2;3 4;5 6], b=[:x :y;:z :w;:u :v]))
3 x 2 LabeledArray

  |1   |2   
--+----+----
  |a b |a b 
--+----+----
1 |1 x |2 y 
2 |3 z |4 w 
3 |5 u |6 v 
```



*source:*
[MultidimensionalTables/src/na/na.jl:335](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L335)

---

<a id="macro___rap.1" class="lexicon_definition"></a>
#### @rap(args...) [¶](#macro___rap.1)

`@rap(args...)`

Apply right-to-left evaluation order to the arguments.
An argument having an underscore symbol except the last one is translated into the function `x`->(that expression replacing _ by `x`).

##### Examples

```julia
julia> @rap _+3 5
8

julia> @rap _*2 x->x+1 10
22

julia> @rap (_ .* 2) reverse @nalift [1,2,NA,4,5]
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(10)     
 Nullable(8)      
 Nullable{Int64}()
 Nullable(4)      
 Nullable(2)      
```


*source:*
[MultidimensionalTables/src/util/array_util.jl:282](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L282)

---

<a id="macro___select.1" class="lexicon_definition"></a>
#### @select(t, args...) [¶](#macro___select.1)

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



*source:*
[MultidimensionalTables/src/util/select.jl:734](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L734)

---

<a id="macro___update.1" class="lexicon_definition"></a>
#### @update(t, args...) [¶](#macro___update.1)

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



*source:*
[MultidimensionalTables/src/util/select.jl:943](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L943)

## Internal

---

<a id="function__create_dict.1" class="lexicon_definition"></a>
#### MultidimensionalTables.create_dict [¶](#function__create_dict.1)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1063](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1063)

---

<a id="function__gdrop.1" class="lexicon_definition"></a>
#### MultidimensionalTables.gdrop [¶](#function__gdrop.1)

`gdrop(arr, N1, N2, ...)`

Drop a block of an array. similar to `drop` in one dimensional case, but is slightly different and more general.
It can also be applied to an `LDict`.
It drops the first `N1` elements along direction 1, and similarly for other directions. Drops from rear if `N*` is negative.

##### Examples

```julia
julia> t = larr(a=rand(5,3), b=reshape(1:15,5,3), axis1=[:X,:Y,:Z,:U,:V])
5 x 3 LabeledArray

  |1                     |2                      |3                      
--+----------------------+-----------------------+-----------------------
  |a                   b |a                   b  |a                   b  
--+----------------------+-----------------------+-----------------------
X |0.27289790581491746 1 |0.8493197848353495  6  |0.8370920536703472  11 
Y |0.8424940964507834  2 |0.21518951524950136 7  |0.9290437789813346  12 
Z |0.9498541774517255  3 |0.942687447396005   8  |0.1341678643795654  13 
U |0.7356663426240728  4 |0.7662948222160162  9  |0.24109069576951692 14 
V |0.8716491751450759  5 |0.27472373001295436 10 |0.08909928028262804 15 


julia> gdrop(t, 3, 2)
2 x 1 LabeledArray

  |1                      
--+-----------------------
  |a                   b  
--+-----------------------
U |0.24109069576951692 14 
V |0.08909928028262804 15 


julia> gdrop(t, 5)
0 x 3 LabeledArray

 |1   |2   |3   
-+----+----+----
 |a b |a b |a b 


julia> gdrop(t, -3, -2)
2 x 1 LabeledArray

  |1                     
--+----------------------
  |a                   b 
--+----------------------
X |0.27289790581491746 1 
Y |0.8424940964507834  2 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1516](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1516)

---

<a id="function__gtake.1" class="lexicon_definition"></a>
#### MultidimensionalTables.gtake [¶](#function__gtake.1)

`gtake(arr, N1, N2, ...)`

Take a block of an array. similar to `take` in one dimensional case, but is slightly different and more general.
It can also be applied to an `LDict`.
It takes first `N1` elements along direction 1, and similarly for other directions. Repeats if the number of elements are less than `N*`. Picks from rear if `N*` is negative.

##### Examples

```julia
julia> t = larr(a=rand(5,3), b=reshape(1:15,5,3), axis1=[:X,:Y,:Z,:U,:V])
5 x 3 LabeledArray

  |1                     |2                      |3                      
--+----------------------+-----------------------+-----------------------
  |a                   b |a                   b  |a                   b  
--+----------------------+-----------------------+-----------------------
X |0.3219487839233375  1 |0.4863723989946185  6  |0.8784616074632225  11 
Y |0.04069063166302023 2 |0.06614308437642014 7  |0.31870618693881947 12 
Z |0.7855545407740521  3 |0.5208010912357377  8  |0.4421485355996708  13 
U |0.8134241459627629  4 |0.8256022894268482  9  |0.3127049127123851  14 
V |0.8536688845922342  5 |0.7263660648355621  10 |0.9315379228053462  15 


julia> gtake(t, 3, 2)
3 x 2 LabeledArray

  |1                     |2                     
--+----------------------+----------------------
  |a                   b |a                   b 
--+----------------------+----------------------
X |0.3219487839233375  1 |0.4863723989946185  6 
Y |0.04069063166302023 2 |0.06614308437642014 7 
Z |0.7855545407740521  3 |0.5208010912357377  8 


julia> gtake(t, 3, 4)
3 x 4 LabeledArray

  |1                     |2                     |3                      |4                     
--+----------------------+----------------------+-----------------------+----------------------
  |a                   b |a                   b |a                   b  |a                   b 
--+----------------------+----------------------+-----------------------+----------------------
X |0.3219487839233375  1 |0.4863723989946185  6 |0.8784616074632225  11 |0.3219487839233375  1 
Y |0.04069063166302023 2 |0.06614308437642014 7 |0.31870618693881947 12 |0.04069063166302023 2 
Z |0.7855545407740521  3 |0.5208010912357377  8 |0.4421485355996708  13 |0.7855545407740521  3 


julia> gtake(t, -2, -1)
2 x 1 LabeledArray

  |1                     
--+----------------------
  |a                  b  
--+----------------------
U |0.3127049127123851 14 
V |0.9315379228053462 15 
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:1303](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L1303)

---

<a id="function__selectfield.1" class="lexicon_definition"></a>
#### MultidimensionalTables.selectfield [¶](#function__selectfield.1)

`selectfield(t, fld, inds)` : select a field whose name is `fld` at cartesian coordinates `inds` in a LabeledArray `t`.
If `inds` is `nothing`, it chooses an entire `fld` from `t`.



*source:*
[MultidimensionalTables/src/util/select.jl:502](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L502)

---

<a id="function__setna.1" class="lexicon_definition"></a>
#### MultidimensionalTables.setna! [¶](#function__setna.1)

`setna!(arr, args...)`

Set the element of an array `arr` at `args` to `NA`.
If `args...` is omitted, all elements are set to `NA`.

* If `arr` is an array of element type `Nullable{T}`, `NA` means `Nullable{T}()`.
* If `arr` is a `DictArray`, `NA` means all fields at that position are `NA`.
* If `arr` is a `LabeledArray`, `NA` means the base of `arr` at that position is `NA`.

##### Examples

```julia
julia> setna!(@nalift([1,2,NA,4,5]))
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable{Int64}()

julia> setna!(@nalift([1,2,NA,4,5]), 2)
5-element Array{Nullable{Int64},1}:
 Nullable(1)      
 Nullable{Int64}()
 Nullable{Int64}()
 Nullable(4)      
 Nullable(5)      

julia> setna!(@darr(a=[1 2 NA;4 5 6], b=[:x :y :z;:u :v :w]), 1:2, 1)
2 x 3 DictArray

a b |a b |a b 
----+----+----
    |2 y |  z 
    |5 v |6 w 


julia> setna!(larr(a=[1 2 3;4 5 6], b=[:x :y :z;:u :v :w], axis1=[:X,:Y]), 1, 2:3)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 x |    |    
Y |4 u |5 v |6 w 
```



*source:*
[MultidimensionalTables/src/na/na.jl:414](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L414)

---

<a id="function__type_array.1" class="lexicon_definition"></a>
#### MultidimensionalTables.type_array [¶](#function__type_array.1)

`type_array(arr)`

`type_array` finds the most constraining type of the elements of an array `arr`, and converts the array element type.
Sometimes, an array is given type `Array{Any}`, even though the components are all Float64, for example.
`type_array` will convert the type into the most constraining one.

##### Arguments
* `arr::AbstractArray`: an abstract array whose element type will be constrained by `type_array`.

##### Returns
An array with the same elements as in `arr`, but the element type has been constrained just enough to contain all elements.

##### Examples

```julia
julia> type_array(Any[1, 3.0, 2])
3-element Array{Float64,1}:
 1.0
 3.0
 2.0

julia> type_array(Any[1, 3.0, 'x'])
3-element Array{Any,1}:
 1   
 3.0 
  'x'
```



*source:*
[MultidimensionalTables/src/util/array_util.jl:34](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_util.jl#L34)

---

<a id="function__diff.1" class="lexicon_definition"></a>
#### diff [¶](#function__diff.1)

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
5-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:574](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L574)

---

<a id="method__allfieldnames.1" class="lexicon_definition"></a>
#### allfieldnames(arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__allfieldnames.1)

`allfieldnames(::DictArray)`

Return all field names in the input `DictArray`, which are just the keys in the underlying `LDict`.

##### Examples

```julia
julia> allfieldnames(darr(a=reshape(1:6,3,2),b=rand(3,2)))
2-element Array{Symbol,1}:
 :a
 :b
```



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:535](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L535)

---

<a id="method__allfieldnames.2" class="lexicon_definition"></a>
#### allfieldnames(table::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}) [¶](#method__allfieldnames.2)

returns all field names for LabeledArray or DictArray. Returns an empty array for other types of arrays.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:754](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L754)

---

<a id="method__cat.1" class="lexicon_definition"></a>
#### cat(catdim::Integer,  arr1::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  arrs::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}...) [¶](#method__cat.1)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:804](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L804)

---

<a id="method__cat.2" class="lexicon_definition"></a>
#### cat(catdim::Integer,  arrs::MultidimensionalTables.DictArray{K, N, VS, SV}...) [¶](#method__cat.2)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:613](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L613)

---

<a id="method__convert.1" class="lexicon_definition"></a>
#### convert(::Type{DataFrames.DataFrame},  arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__convert.1)

`convert(::Type{DataFrame}, arr::DictArray)` converts a `DictArray` into a `DataFrame`. If the dimensions of `arr` are greater than 1, `arr` is first flattend into 1 dimension using `collapse_axes`, and then converted into a `DataFrame`.



*source:*
[MultidimensionalTables/src/util/dataframe_interface.jl:96](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/dataframe_interface.jl#L96)

---

<a id="method__convert.2" class="lexicon_definition"></a>
#### convert(::Type{DataFrames.DataFrame},  arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}) [¶](#method__convert.2)

`convert(::Type{DataFrame}, arr::LabeledArray)` converts a `LabeledArray` into a `DataFrame` by first creating a `DictArray` by broadcasting all axes, and then convert that `DictArray` into a `DataFrame`.



*source:*
[MultidimensionalTables/src/util/dataframe_interface.jl:102](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/dataframe_interface.jl#L102)

---

<a id="method__convert.3" class="lexicon_definition"></a>
#### convert(::Type{MultidimensionalTables.DictArray{K, N, VS, SV}},  df::DataFrames.DataFrame) [¶](#method__convert.3)

`convert(::Type{DictArray}, df::DataFrame)` converts a `DataFrame` into `DictArray`.



*source:*
[MultidimensionalTables/src/util/dataframe_interface.jl:84](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/dataframe_interface.jl#L84)

---

<a id="method__convert.4" class="lexicon_definition"></a>
#### convert(::Type{MultidimensionalTables.EnumerationArray{T, N, V, R<:Integer}},  arr::DataArrays.PooledDataArray{T, R<:Integer, N}) [¶](#method__convert.4)

`convert(::Type{EnumerationArray}, arr::PooledDataArray)` converts a `PooledDataArray` into an `EnumerationArray`.



*source:*
[MultidimensionalTables/src/util/dataframe_interface.jl:108](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/dataframe_interface.jl#L108)

---

<a id="method__convert.5" class="lexicon_definition"></a>
#### convert(::Type{MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}},  df::DataFrames.DataFrame) [¶](#method__convert.5)

`convert(::Type{LabeledArray}, df::DataFrame)` converts a `DataFrame` into `LabeledArray` simply by wrapping `convert(DictArray, df)` by `LabeledArray`.



*source:*
[MultidimensionalTables/src/util/dataframe_interface.jl:90](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/dataframe_interface.jl#L90)

---

<a id="method__deletekeys.1" class="lexicon_definition"></a>
#### deletekeys{K, V}(dict::MultidimensionalTables.LDict{K, V},  keys...) [¶](#method__deletekeys.1)

`deletekeys(dict::LDict, keys...)`

Delete `keys` keys from `dict`. A missing key will be silently ignored.

```julia
julia> deletekeys(LDict(:a=>3, :b=>5, :c=>10), :a, :b, :x)
MultidimensionalTables.LDict{Symbol,Int64} with 1 entry:
  :c => 10
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:155](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L155)

---

<a id="method__dropnaiter.1" class="lexicon_definition"></a>
#### dropnaiter{T, N}(arr::AbstractArray{Nullable{T}, N}) [¶](#method__dropnaiter.1)

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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:24](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L24)

---

<a id="method__enum_dropnaiter.1" class="lexicon_definition"></a>
#### enum_dropnaiter{T, N}(arr::AbstractArray{Nullable{T}, N}) [¶](#method__enum_dropnaiter.1)

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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:44](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L44)

---

<a id="method__fill.1" class="lexicon_definition"></a>
#### fill(ldict::MultidimensionalTables.LDict{K, V},  dims::Integer...) [¶](#method__fill.1)

`fill(ldict::LDict, dims...)`

Fill a `DictArray` with `ldict`.

##### Return
A new `DictArray` whose elements are `ldict` and whose dimensions are `dims...`.



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1141](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1141)

---

<a id="method__flipdim.1" class="lexicon_definition"></a>
#### flipdim(arr::MultidimensionalTables.DictArray{K, N, VS, SV},  dims::Integer...) [¶](#method__flipdim.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1129](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1129)

---

<a id="method__getindexvalue.1" class="lexicon_definition"></a>
#### getindexvalue(arr::AbstractArray{T, N},  args...) [¶](#method__getindexvalue.1)

`getindexvalue(arr::AbstractArray, args...)`

Return `arr[args...]`.



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:190](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L190)

---

<a id="method__getindexvalue.2" class="lexicon_definition"></a>
#### getindexvalue(arr::MultidimensionalTables.DictArray{K, N, VS, SV},  args...) [¶](#method__getindexvalue.2)

`getindexvalue(arr::DictArray, args...)`

Return the value tuple of `arr` at index `args`.



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:180](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L180)

---

<a id="method__intersect.1" class="lexicon_definition"></a>
#### intersect(dim::Integer,  arr0::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  arr_rest::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}...) [¶](#method__intersect.1)

`intersect(dim, arrs...)`

Take intersection of arrays of type `LabeledArray`/`DictArray`/`AbstractArrayWrapper`. The order is preserved.

##### Arguments

* `dim` : direction along which to intersect.
* `arrs...` : arrays to intersect.

##### Examples

```julia
julia> intersect(1, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
1x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)

julia> intersect(2, nalift([1 2 3;4 5 6]), nalift([1 2 3;5 5 6]))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(2)  Nullable(3)
 Nullable(5)  Nullable(6)

julia> intersect(1, darr(a=[:x,:y,:z]), darr(a=[:x,:x,:y]), darr(a=[:y,:y,:y]))
1 DictArray

a 
--
y 


julia> intersect(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:X,:Y]))
1 x 3 LabeledArray

  |1 |2 |3 
--+--+--+--
  |a |a |a 
--+--+--+--
X |1 |2 |3 


julia> intersect(1, larr(a=[1 2 3;4 5 6], axis1=[:X,:Y]), larr(a=[1 2 3;4 3 2], axis1=[:Z,:Y]))
0 x 3 LabeledArray

 |1 |2 |3 
-+--+--+--
 |a |a |a 
```



*source:*
[MultidimensionalTables/src/util/intersect.jl:53](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/intersect.jl#L53)

---

<a id="method__keys.1" class="lexicon_definition"></a>
#### keys(arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__keys.1)

`keys(::DictArray)`

Return the field name vector of the input `DictArray`, which are the keys of the underlying `LDict`.

##### Examples

```julia
julia> keys(darr(a=[1,2,3], b=[:x,:y,:z]))
2-element Array{Symbol,1}:
 :a
 :b
```



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1001](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1001)

---

<a id="method__map.1" class="lexicon_definition"></a>
#### map(f::Function,  arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__map.1)

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


*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:719](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L719)

---

<a id="method__mapslices.1" class="lexicon_definition"></a>
#### mapslices(f::Function,  arr::MultidimensionalTables.DictArray{K, N, VS, SV},  dims::AbstractArray{T, 1}) [¶](#method__mapslices.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:797](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L797)

---

<a id="method__merge.1" class="lexicon_definition"></a>
#### merge(arr1::MultidimensionalTables.DictArray{K, N, VS, SV},  args...) [¶](#method__merge.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:338](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L338)

---

<a id="method__merge.2" class="lexicon_definition"></a>
#### merge(arr1::MultidimensionalTables.DictArray{K, N, VS, SV},  arr2::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__merge.2)

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


*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:317](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L317)

---

<a id="method__merge.3" class="lexicon_definition"></a>
#### merge(arr1::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  args::MultidimensionalTables.DictArray{K, N, VS, SV}...) [¶](#method__merge.3)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1530](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1530)

---

<a id="method__merge.4" class="lexicon_definition"></a>
#### merge(arr1::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  arr2::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}) [¶](#method__merge.4)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1504](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1504)

---

<a id="method__merge.5" class="lexicon_definition"></a>
#### merge(dict::MultidimensionalTables.LDict{K, V},  ds::Associative{K, V}...) [¶](#method__merge.5)

`merge(dict::LDict, ds...)`

Combine an `LDict` `dict` with `Associative` `ds`'s.
The subsequent elements in ds will either update the preceding one, or append the key-value pair.

##### Examples

```julia
julia> merge(LDict(:a=>3, :b=>5), Dict(:b=>"X", :c=>"Y"), LDict(:c=>'x', 'd'=>'y'))
MultidimensionalTables.LDict{Any,Any} with 4 entries:
  :a  => 3
  :b  => "X"
  :c  => 'x'
  'd' => 'y'
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:98](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L98)

---

<a id="method__reducedim.1" class="lexicon_definition"></a>
#### reducedim(f::Function,  arr::MultidimensionalTables.DictArray{K, N, VS, SV},  dims,  initial) [¶](#method__reducedim.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:747](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L747)

---

<a id="method__repeat.1" class="lexicon_definition"></a>
#### repeat(arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__repeat.1)

`repeat(arr::DictArray [; inner=..., outer=...])`

Apply `repeat` field by field to the `DictArray` `arr`.



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:640](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L640)

---

<a id="method__replace_expr.1" class="lexicon_definition"></a>
#### replace_expr(expr) [¶](#method__replace_expr.1)

`replace_expr(expr)`

Create a function expression from a domain expression.

##### Expressions
Below t' is an object such that t'[k] for a field name k gives the corresponding array
for the field k in the table t at the coordinates selected so far.

* `_k` : translates to `t'[k]`. The field name `k` should be a symbol.
* `__k` : translates to `igna(t')[k]`. It ignores the null elements. The null elements are replaced with arbitrary values, so make sure there is no null value in the array if you want to use it. The field name `k` should be a symbol.
* `_!k` : translates to `isna(t')[k]`. It gives a boolean array to denote whether an element is null. The field name `k` should be a symbol.
* `_` : translates to `t'` if none of the above is applicable. It is useful when the field name is not a symbol.



*source:*
[MultidimensionalTables/src/util/select.jl:1118](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L1118)

---

<a id="method__reshape.1" class="lexicon_definition"></a>
#### reshape(arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  dims::Int64...) [¶](#method__reshape.1)

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



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:1177](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L1177)

---

<a id="method__reverse.1" class="lexicon_definition"></a>
#### reverse(arr::MultidimensionalTables.DictArray{K, N, VS, SV},  dims) [¶](#method__reverse.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1072](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1072)

---

<a id="method__sel.1" class="lexicon_definition"></a>
#### sel(func,  t) [¶](#method__sel.1)

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



*source:*
[MultidimensionalTables/src/util/select.jl:597](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L597)

---

<a id="method__selectfunc.1" class="lexicon_definition"></a>
#### selectfunc{N}(t::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  c,  b,  a) [¶](#method__selectfunc.1)

`selectfunc(t::LabeledArray, c, b, a)`

main select function. This function is internal and is meant to be used via `selct`.
`selectfunc` takes a table `t`, condition `c`, aggreagtion by rule `b`, aggregate function `a`.

* t : a LabeledArray
* c : an array of functions `(t, inds)` -> boolean array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* b : an array of arrays of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* c : an array of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.



*source:*
[MultidimensionalTables/src/util/select.jl:34](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L34)

---

<a id="method__selectkeys.1" class="lexicon_definition"></a>
#### selectkeys{K, V}(dict::MultidimensionalTables.LDict{K, V},  keys...) [¶](#method__selectkeys.1)

`selectkeys(dict::LDict, keys...)`

Select `keys` keys from `dict`. A missing key will raise an error.

##### Examples

```julia
julia> selectkeys(LDict(:a=>3, :b=>5, :c=>10), :a, :b)
MultidimensionalTables.LDict{Symbol,Int64} with 2 entries:
  :a => 3
  :b => 5
```



*source:*
[MultidimensionalTables/src/datatypes/ldict.jl:186](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/ldict.jl#L186)

---

<a id="method__show.1" class="lexicon_definition"></a>
#### show{N}(io::IO,  arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__show.1)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:376](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L376)

---

<a id="method__show.2" class="lexicon_definition"></a>
#### show{N}(io::IO,  arr::MultidimensionalTables.DictArray{K, N, VS, SV},  indent) [¶](#method__show.2)

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



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:376](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L376)

---

<a id="method__show.3" class="lexicon_definition"></a>
#### show{N}(io::IO,  table::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN}) [¶](#method__show.3)

`show(io::IO, table::LabeledArray [, indent=0; height=..., width=...])`

Show a LabeledArray.

##### Arguments

* `height` and `width`(optional, default set by show_size()): sets the maximum height and width to draw, beyond which the table will be cut.
* `alongrow`(optional, default set by `set_dispalongrow!!`. `tru` by default): if `true`, the fields in the array will be displayed along the row in each cell. Otherwise, they will be stacked on top of each other.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:244](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L244)

---

<a id="method__show.4" class="lexicon_definition"></a>
#### show{N}(io::IO,  table::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  indent) [¶](#method__show.4)

`show(io::IO, table::LabeledArray [, indent=0; height=..., width=...])`

Show a LabeledArray.

##### Arguments

* `height` and `width`(optional, default set by show_size()): sets the maximum height and width to draw, beyond which the table will be cut.
* `alongrow`(optional, default set by `set_dispalongrow!!`. `tru` by default): if `true`, the fields in the array will be displayed along the row in each cell. Otherwise, they will be stacked on top of each other.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:244](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L244)

---

<a id="method__sort.1" class="lexicon_definition"></a>
#### sort(arr::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  axis::Integer,  fields...) [¶](#method__sort.1)

`sort(arr, axis fields... [; alg=..., ...])`

Sort a `DictArray` or `LabeledArray` along some axis.

##### Arguments

* `arr` : either a `DictArray` or a `LabeledArray`.
* `axis` : an axis direction integer to denote which direction to sort along.
* `fields...` : the names of fields to determine the order. The preceding ones have precedence over the later ones. Note only the components [1,...,1,:,1,...1], where : is placed at the axis position, will be used out of each field.
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



*source:*
[MultidimensionalTables/src/util/sort.jl:132](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/sort.jl#L132)

---

<a id="method__unique.1" class="lexicon_definition"></a>
#### unique{T}(arr::MultidimensionalTables.AbstractArrayWrapper{Nullable{T}, N, A<:AbstractArray{T, N}}) [¶](#method__unique.1)

`unique(arr, dims...)`

Return unique elements of an array `arr` of type `LabeledArray`/`DictArray`/`Nullable AbstractArrayWrapper`.

##### Arguments

* `arr` : an array
* `dims...` : either an integer or, if an array is a DictArray or a LabeledArray, a list of integers. It specifies the directions along which to traverse. Any duplicate elements will be replaced by Nullable{T}(). If all components along some direction are missing, those components will be removed and the whole array size will shrink.
If `dims...` is missing, unique elements along the whole directions will be found. It is equivalent to `unique(arr, 1, 2, ..., ndims(arr))`.
Note that it compares each slice spanned by directions orthogonal to `dims...`.

##### Examples

```julia
julia> unique(nalift([1 2 3;3 4 1]))
2x2 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)
 Nullable(3)  Nullable(4)

julia> unique(nalift([1 2 3;3 4 1]), 1)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(3)  Nullable(4)  Nullable(1)

julia> unique(nalift([1 2 3;3 4 1]), 2)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(3)  Nullable(4)  Nullable(1)

julia> unique(nalift([1 2 3;1 2 3;4 5 6]), 1)
2x3 MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}}:
 Nullable(1)  Nullable(2)  Nullable(3)
 Nullable(4)  Nullable(5)  Nullable(6)

julia> t = darr(a=[1 2 1;1 5 1;1 2 1], b=[:a :b :a;:a :c :a;:a :b :a])
3 x 3 DictArray

a b |a b |a b 
----+----+----
1 a |2 b |1 a 
1 a |5 c |1 a 
1 a |2 b |1 a 


julia> unique(t, 1)
2 x 3 DictArray

a b |a b |a b 
----+----+----
1 a |2 b |1 a 
1 a |5 c |1 a 


julia> unique(t, 2)
3 x 2 DictArray

a b |a b 
----+----
1 a |2 b 
1 a |5 c 
1 a |2 b 


julia> m = larr(a=[1 2 1;1 5 1;1 2 1], b=[:a :b :a;:a :c :a;:a :b :a], axis1=["X","Y","Z"])
3 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 a |2 b |1 a 
Y |1 a |5 c |1 a 
Z |1 a |2 b |1 a 


julia> unique(m, 1)
2 x 3 LabeledArray

  |1   |2   |3   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
X |1 a |2 b |1 a 
Y |1 a |5 c |1 a 


julia> unique(m, 2)
3 x 2 LabeledArray

  |1   |2   
--+----+----
  |a b |a b 
--+----+----
X |1 a |2 b 
Y |1 a |5 c 
Z |1 a |2 b 
```



*source:*
[MultidimensionalTables/src/util/unique.jl:102](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/unique.jl#L102)

---

<a id="method__updatefunc.1" class="lexicon_definition"></a>
#### updatefunc{N}(t::MultidimensionalTables.LabeledArray{T, N, AXES<:Tuple, TN},  c,  b,  a) [¶](#method__updatefunc.1)

`updatefunc(t::LabeledArray, c, b, a)`

main update function. This function is internal and is meant to be used via `update`.
`updatefunc` takes a table `t`, condition `c`, aggreagtion by rule `b`, aggregate function `a`.

* `t` : a LabeledArray
* `c` : an array of functions `(t, inds)` -> boolean array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* `b` : an array of arrays of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.
* `c` : an array of pairs of field name => function `(t, inds)` -> array. `t` is a LabeledArray and inds is either `nothing` to choose the entire `t` or an array of Cartesian indices.



*source:*
[MultidimensionalTables/src/util/select.jl:111](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/select.jl#L111)

---

<a id="method__values.1" class="lexicon_definition"></a>
#### values(arr::MultidimensionalTables.DictArray{K, N, VS, SV}) [¶](#method__values.1)

`values(::DictArray)`

Return the vector of field arrays of the input `DictArray`, which are the values of the underlying `LDict`.

##### Examples

```julia
julia> values(darr(a=[1,2,3], b=[:x,:y,:z]))
2-element Array{MultidimensionalTables.AbstractArrayWrapper{T,1,A<:AbstractArray{T,N}},1}:
 [Nullable(1),Nullable(2),Nullable(3)]   
 [Nullable(:x),Nullable(:y),Nullable(:z)]
```



*source:*
[MultidimensionalTables/src/datatypes/dict_array.jl:1019](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/dict_array.jl#L1019)

---

<a id="method__wrap_array.1" class="lexicon_definition"></a>
#### wrap_array(arr::MultidimensionalTables.AbstractArrayWrapper{T, N, A<:AbstractArray{T, N}}) [¶](#method__wrap_array.1)

`wrap_array(arr)`

Wrap an array by `AbstractArrayWrapper` if it is not `DictArray` or `labeledArray`, and not already `AbstractArrayWrapper`.



*source:*
[MultidimensionalTables/src/na/naarray_operators.jl:11](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/naarray_operators.jl#L11)

---

<a id="method__zip_dropnaiter.1" class="lexicon_definition"></a>
#### zip_dropnaiter{N}(arrs::MultidimensionalTables.AbstractArrayWrapper{T, N, A<:AbstractArray{T, N}}...) [¶](#method__zip_dropnaiter.1)

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



*source:*
[MultidimensionalTables/src/util/array_helper_functions.jl:132](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/util/array_helper_functions.jl#L132)

---

<a id="type__abstractarraywrapper.1" class="lexicon_definition"></a>
#### MultidimensionalTables.AbstractArrayWrapper{T, N, A<:AbstractArray{T, N}} [¶](#type__abstractarraywrapper.1)

A thin wrapper around AbstractArray. The reason to introduce this wrapper is to redefine
the dotted operators such as .+, .-. Those operators will be mapped to arrays, elementwise just as before,
but, if each element is null, those operators will be applied to the one inside the Nullable.
For example,

```julia
julia> AbstractArrayWrapper([Nullable(1), Nullable(2)]) .+ AbstractArrayWrapper([Nullable{Int}(), Nullable(3)])
2-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable{Int64}()
 Nullable(5)      
```

Note that this means lifting those dotted operators via the list(AbstractArray) and maybe(Nullable) functors.

It is possible to redefine those operators for AbstractArray, but concerning about compatibility, it may be
best to introduce a new wrapper class for that.



*source:*
[MultidimensionalTables/src/na/na.jl:25](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/na/na.jl#L25)

---

<a id="type__defaultaxis.1" class="lexicon_definition"></a>
#### MultidimensionalTables.DefaultAxis [¶](#type__defaultaxis.1)

Default axis used when no axis is specified for a `LabeledArray`.
It behaves mostly as an array `[Nullable(1), Nullable(2), ...]`.
However, one notable exception is when using `@select`/`selct`/`extract`/`discard`/`getindex`/etc to choose, set or drop specific elements of a `LabeledArray`.
In this case, the result array of reduced size will again have a `DefaultAxis` of an appropriate size.



*source:*
[MultidimensionalTables/src/datatypes/labeled_array.jl:47](https://github.com/c-s/MultidimensionalTables.jl/tree/dd5467139cc1cbf5258d8a0a9b0857773e12afd7/src/datatypes/labeled_array.jl#L47)

