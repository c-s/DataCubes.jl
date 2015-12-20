MultidimensionalTables.jl
=========================

[![Build Status](https://travis-ci.org/c-s/MultidimensionalTables.jl.svg?branch=master)](https://travis-ci.org/c-s/MultidimensionalTables.jl)

The **MultidimensionalTables** package provides several data types and tools to handle multidimensional tables.
Below, we give a brief description of the package. For more detail, please refer to [documentation](http://c-s.github.io/MultidimensionalTables.jl).


# Installation

At the Julia REPL, `Pkg.add("MultidimensionalTables")`.
The package requires [DataFrames](https://github.com/juliastats/dataframes.jl) to convert to and from `DataFrame`,
and [RDatasets](https://github.com/johnmyleswhite/RDatasets.jl) to run some tests.
The package itself is functionally stand alone.

# Getting Started

There are two important data types in **MultidimensionalTables**.

## DictArray

`DictArray` is a multidimensional array whose element type is an ordered dictionary with common keys.
The usual table

```julia
a b 
----
1 x 
2 y 
3 z 
```

can be thought of as a one dimensional array whose 3 elements are

```julia
[dict(:a=>1, :b=>:x), dict(:a=>2, :b=>:y), dict(:a=>3, :b=>:z)]
```

where `dict` stands for some type of ordered dictionary.
With this correspondence, it is straightforward to generalize the table into a multidimensional array.
In **MultidimensionalTables**, the function to create a `DictArray` is `darr`:

```julia
julia> d = darr(a=[1 2;3 4;5 6], b=[:x :y;:z :w;:u :v])
a b |a b 
----+----
1 x |2 y 
3 z |4 w 
5 u |6 v 

julia> d[1, 2]
MultidimensionalTables.All.LDict{Symbol,Nullable{T}} with 2 entries:
  :a => Nullable(2)
  :b => Nullable(:y)
```

Note that all elements in `DictArray` are `Nullable`.
`darr` is a helper function to create `DictArray`, which lifts each array elements to `Nullable`.

If you want to create an array with null value, use the macro `@darr`:

```julia
julia> @darr(a=[1,2,NA], b=['x',NA,'z'])
a b 
----
1 x 
2   
  z 
```

Internally, a `DictArray` is stored as an ordered dictionary of `Nullable` arrays, and the ordered dictionary is implemented as a key vector and a value vector.
Because a `DictArray` can be multidimensional, it will be misleading to call `a` and `b` above as column names.
We will call them field names, and refer to the corresponding arrays (`[1,2,NA]` and `['x',NA,'z']`) as field values.

Many of array related functions are implemented for `DictArray`. For example,

```julia
julia> d = @darr(a=[1 2 3;4 5 6], b=[11 12 13;14 15 16])
a  b |a  b |a  b 
-----+-----+-----
1 11 |2 12 |3 13 
4 14 |5 15 |6 16 

julia> size(d)
(2,3)

julia> transpose(d)

a  b |a  b 
-----+-----
1 11 |4 14 
2 12 |5 15 
3 13 |6 16 

julia> reshape(d, 1, 6)

a  b |a  b |a  b |a  b |a  b |a  b 
-----+-----+-----+-----+-----+-----
1 11 |4 14 |2 12 |5 15 |3 13 |6 16 

julia> mapslices(x->sum(x[:a]), d, [1])
3-element MultidimensionalTables.All.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(5)
 Nullable(7)
 Nullable(9)
```

## LabeledArray

`LabeledArray` is a multidimensional array consisting of base and axes.
A `LabeledArray` can be created using the `larr` function.
For example,

```julia
julia> larr(a=[1 2;3 4;5 6], b=[:x :y;:y :z;:z :x], axis1=darr(k=['x','y','z']), axis2=[:u, :v])

  |u   |v   
--+----+----
k |a b |a b 
--+----+----
x |1 x |2 y 
y |3 y |4 z 
z |5 z |6 x 
```

Here, the base part is a `DictArray` whose fields are `a` and `b`.
There are 2 axes. The first axis is another `DictArray` with a field `k`, and the other axis is a normal array `[:u, :v]`.

Similar to `DictArray`, there is a macro version, `@larr`, which enables to enter a null value manually more easily:

```julia
julia> @larr(a=[1 2;NA 4;5 6], b=[:x :y;:y :z;NA :x], axis1[k=['x','y',NA]], axis2[:u, NA])

  |u   |    
--+----+----
k |a b |a b 
--+----+----
x |1 x |2 y 
y |  y |4 z 
  |5   |6 x 
```

Note the slightly different way of specifying the axes: the macro version specifies axes by using the form `axisN[...]` for the `n`th axis, whereas the function version `axisN=[...]`.

Many array functions can be applied to `LabeledArray` with expected behavior:

```julia
julia> t = larr(a=[1 2;3 4;5 6], b=[:x :y;:y :z;:z :x], axis1=darr(k=['x','y','z']), axis2=[:u, :v])

  |u   |v   
--+----+----
k |a b |a b 
--+----+----
x |1 x |2 y 
y |3 y |4 z 
z |5 z |6 x 


julia> size(t)
(3,2)

julia> transpose(t)

k |x   |y   |z   
--+----+----+----
  |a b |a b |a b 
--+----+----+----
u |1 x |3 y |5 z 
v |2 y |4 z |6 x 


julia> reshape(t, 6)

k x1 |a b 
-----+----
x  u |1 x 
y  u |3 y 
z  u |5 z 
x  v |2 y 
y  v |4 z 
z  v |6 x 


julia> vcat(t, t)
  |u   |v   
--+----+----
k |a b |a b 
--+----+----
x |1 x |2 y 
y |3 y |4 z 
z |5 z |6 x 
x |1 x |2 y 
y |3 y |4 z 
z |5 z |6 x 
```


## Select from a LabeledArray

`@select` and `selct` selects and/or aggregates a `LabeledArray` and transforms it into another.
The function name is `selct` because what it does is not the same as what `Base.select` function does.

Here is an example usage of `@select`:

```julia
julia> t = larr(a=[1 2;3 4;5 6], b=[:x :y;:y :z;:z :x], axis1=darr(k=['x','y','z']), axis2=darr(r=[:u, :v]))

r |u   |v   
--+----+----
k |a b |a b 
--+----+----
x |1 x |2 y 
y |3 y |4 z 
z |5 z |6 x 


julia> @select(t, :b, :a)

r |u   |v   
--+----+----
k |b a |b a 
--+----+----
x |x 1 |y 2 
y |y 3 |z 4 
z |z 5 |x 6 


julia> @select(t, where[_b .== :x])

r |u   |v   
--+----+----
k |a b |a b 
--+----+----
x |1 x |    
z |    |6 x 


julia> @select(t, where[(_b .== :x) | (_b .== :y)], by[:b], count=length(_))

b |count 
--+------
x |    2 
y |    2 
```

In `@select`, `where[...]` chooses a portion of the `LabeledArray`.
An underscore `_` is treated as the array itself, and `_field` denotes the field `field` in the `LabeledArray`, when the field name is a symbol.
In general, a field name can be of arbitrary type, in which case, `_[field name]` can be used to choose that field.
A keyword `key=>value` creates a new field with name `key` and value defined by `value` just as in `by[...]`.
A field name itself creates the same field in the returned array.
Keyword/pair arguments determine how to aggregate the fields. In the last example, `count=length(_)` creates a field `count` whose value is the length of the selected values for each by-variable.
Multiple `where[...]` are allowed and they are simply concatenated.
Then the `by[...]` determines what variables to aggregate the table by:
A field name in `...` uses that field as the by-variable.
Keyword/pair arguments in `...` creates a new field and use those as by-variables.

`selct` is a function version of `@select`. It is similar but of course does not provide the underscore version of convenient way of creating a function.
Here are some examples:

```julia
julia> t = larr(a=reshape(1:50,10,5), b=repmat(1:10, 1, 5))

   | 1    | 2    | 3    | 4    | 5    
---+------+------+------+------+------
   | a  b | a  b | a  b | a  b | a  b 
---+------+------+------+------+------
 1 | 1  1 |11  1 |21  1 |31  1 |41  1 
 2 | 2  2 |12  2 |22  2 |32  2 |42  2 
 3 | 3  3 |13  3 |23  3 |33  3 |43  3 
 4 | 4  4 |14  4 |24  4 |34  4 |44  4 
 5 | 5  5 |15  5 |25  5 |35  5 |45  5 
 6 | 6  6 |16  6 |26  6 |36  6 |46  6 
 7 | 7  7 |17  7 |27  7 |37  7 |47  7 
 8 | 8  8 |18  8 |28  8 |38  8 |48  8 
 9 | 9  9 |19  9 |29  9 |39  9 |49  9 
10 |10 10 |20 10 |30 10 |40 10 |50 10 


julia> selct(t, :b)

   | 1 | 2 | 3 | 4 | 5 
---+---+---+---+---+---
   | b | b | b | b | b 
---+---+---+---+---+---
 1 | 1 | 1 | 1 | 1 | 1 
 2 | 2 | 2 | 2 | 2 | 2 
 3 | 3 | 3 | 3 | 3 | 3 
 4 | 4 | 4 | 4 | 4 | 4 
 5 | 5 | 5 | 5 | 5 | 5 
 6 | 6 | 6 | 6 | 6 | 6 
 7 | 7 | 7 | 7 | 7 | 7 
 8 | 8 | 8 | 8 | 8 | 8 
 9 | 9 | 9 | 9 | 9 | 9 
10 |10 |10 |10 |10 |10 


julia> selct(t, :b, where=[d -> d[:a] .> 25])

   | 1 | 2 | 3 
---+---+---+---
   | b | b | b 
---+---+---+---
 1 |   | 1 | 1 
 2 |   | 2 | 2 
 3 |   | 3 | 3 
 4 |   | 4 | 4 
 5 |   | 5 | 5 
 6 | 6 | 6 | 6 
 7 | 7 | 7 | 7 
 8 | 8 | 8 | 8 
 9 | 9 | 9 | 9 
10 |10 |10 |10 


julia> selct(t, sum_a = d -> sum(d[:a]), where=d -> d[:a] .> 25, by=:b)

 b |sum_a 
---+------
 1 |   72 
 2 |   74 
 3 |   76 
 4 |   78 
 5 |   80 
 6 |  108 
 7 |  111 
 8 |  114 
 9 |  117 
10 |  120 

julia> selct(t, sum_a = d -> sum(d[:a]), where=[d -> d[:a] .> 25], by=:b, by=:a])

 a |   26 |   27 |   28 |   29 |   30 |   31 |   32 |   33 |   34 |   35 |   36 |   37 ...
---+------+------+------+------+------+------+------+------+------+------+------+------
 b |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a |sum_a ...
---+------+------+------+------+------+------+------+------+------+------+------+------
 1 |      |      |      |      |      |   31 |      |      |      |      |      |      ...
 2 |      |      |      |      |      |      |   32 |      |      |      |      |      ...
 3 |      |      |      |      |      |      |      |   33 |      |      |      |      ...
 4 |      |      |      |      |      |      |      |      |   34 |      |      |      ...
 5 |      |      |      |      |      |      |      |      |      |   35 |      |      ...
 6 |   26 |      |      |      |      |      |      |      |      |      |   36 |      ...
 7 |      |   27 |      |      |      |      |      |      |      |      |      |   37 ...
 8 |      |      |   28 |      |      |      |      |      |      |      |      |      ...
 9 |      |      |      |   29 |      |      |      |      |      |      |      |      ...
10 |      |      |      |      |   30 |      |      |      |      |      |      |      ...
```

As the last example shows, it is possible to aggregate a table using multiple variables to create a multidimensional `LabeledArray`.

`update` and `@update` works similarly to `selct` and `@select` but starts from the original table, not from scratch, modifies it and returns a new `LabeledArray`.

## Join

`leftjoin` and `innerjoin` join two `LabeledArray`s.

```julia
julia> t1 = larr(a=[:k1,:k1,:k2,:k3,:k4],b=[1,2,3,4,5])

  | a b 
--+-----
1 |k1 1 
2 |k1 2 
3 |k2 3 
4 |k3 4 
5 |k4 5 


julia> t2 = @larr(axis1[a=[:k0,:k1,:k2,:k3]], axis2[r=[:m,:n]], c=[10 11;12 13;14 15;16 17])


 r | m | n 
---+---+---
 a | c | c 
---+---+---
k0 |10 |11 
k1 |12 |13 
k2 |14 |15 
k3 |16 |17 


julia> leftjoin(t1, t2, 1)

r | m      | n      
--+--------+--------
  | a b  c | a b  c 
--+--------+--------
1 |k1 1 12 |k1 1 13 
2 |k1 2 12 |k1 2 13 
3 |k2 3 14 |k2 3 15 
4 |k3 4 16 |k3 4 17 
5 |k4 5    |k4 5    


julia> innerjoin(t1, t2, 1)

r | m      | n      
--+--------+--------
  | a b  c | a b  c 
--+--------+--------
1 |k1 1 12 |k1 1 13 
2 |k1 2 12 |k1 2 13 
3 |k2 3 14 |k2 3 15 
4 |k3 4 16 |k3 4 17 
```

`leftjoin(t1, t2, 1)` left-joins `t1` and `t2` along the direction 1.
Since `ndims(t1) == 1` and `ndims(t2) == 2` and there is 1 dimension to join along,
the result `LabeledArray` is 1+2-1=2 dimensional.
`innerjoin` works similarly to `leftjoin` but only keeps the keys in `t1` that can be found in `t2`.


# Documentation

More detailed documentation is [available here](http://c-s.github.io/MultidimensionalTables.jl).

