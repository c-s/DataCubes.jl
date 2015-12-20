## Introduction to the MultidimensionalTables package

The MultidimensionalTables package provides several new data types and associated functions/macros, to deal with multidimensional tables. The package has the following notable features:

* It includes data types `DictArray` and `LabeledArray` that can describe multimensional tables.
* Extensive number of functions/macros are available to process common type of table manipulations and they can cover multidimensional tables as well.
* Each element in any field of a multidimensional table is `Nullable`. So there is no type instability when you access an element: a non `NA`(i.e. null) value will be represented by `Nullable(value)` and a `NA` value by `Nullable{T}()` for some `T`.

### DictArray

Conceptually, `DictArray` is an array of ordered dictionaries with identical keys. For example, a table with two columns `col1=[10, 11]` and `col2=[:sym1, :sym2]` can be considered as a one-dimensional array of length 2, whose elements are `[LDict(:col1=>10, :col2=>:sym1), LDict(:col1=>11, :col2=>:sym2)]` where `LDict` represents a kind of ordered dictionary, which will be described in detail later. This is a conceptual level description, and the methods in the packages utilizes as much as possible the fact that each ordered dictionary is from a set of arrays. One advantage of describing a table in terms of a one-dimensional array of ordered dictionaries is that it is straightforward to generalize this to multidimensional arrays. For example, `@darr` is a macro in the package to create a `DictArray` like this:

```julia
julia> using MultidimensionalTables

julia> d = @darr(A=[1 2 3;4 5 6], B=['a' 'b' 'a';'a' 'a' 'b'])
2 x 3 DictArray

A B |A B |A B 
----+----+----
1 a |2 b |3 a 
4 a |5 a |6 b 
```

Here, the `DictArray` `d` has two fields `A` and `B` and each is a two-dimensional array. A component of `d` is an ordered dictionary:

```julia
julia> d[1, 2]
MultidimensionalTables.LDict{Symbol,Nullable{T}} with 2 entries:
  :A => Nullable(2)
  :B => Nullable('b')
```

Note that each value is `Nullable`: It is typical for a value to be `NA` during an array transformation, and it makes more sense to make any values in the elements of a `DictArray` to be `Nullable`.
Note also that we use the term *fields* and not *column* to denote the two dimensional arrays represented by `A` and `B` above. The reason is, in multidimensional situations, they are not *columns* anymore.

### LabeledArray

A `LabeledArray` is a `DictArray` or usual array with labels attached to each axis. The labels for each axis is an array: It can be a normal array, or a `DictArray`. For example, `@larr` is a macro in the package to create a `LabeledArray`:

```julia
julia> using MultidimensionalTables

julia> l = @larr(A=[1 2 3;4 5 6],
                       B=['a' 'b' 'a';'a' 'a' 'b'],
                       axis1[a1=[:row1, :row2]],
                       axis2[a2=["X", "Y", "Z"]])
2 x 3 LabeledArray

a2   |X   |Y   |Z   
-----+----+----+----
a1   |A B |A B |A B 
-----+----+----+----
row1 |1 a |2 b |3 a 
row2 |4 a |5 a |6 b 
```

The `LabeledArray` along with `DictArray` are the main data types that represent multidimensional tables.


### @select

The macro `@select` transforms a `LabeledArray` into another `LabeledArray`. This macro is similar to the `select` statement in SQL. As an example:

```julia
julia> using MultidimensionalTables

julia> l = @larr(A=[1 2 3;4 5 6],
                 B=['a' 'b' 'a';'a' 'a' 'b'],
                 axis1[axis1=[:row1, :row2]],
                 axis2[axis2=["col1", "col2", "col3"]])
2 x 3 LabeledArray

axis2 |col1   |col2   |col3   
------+-------+-------+-------
axis1 |A    B |A    B |A    B 
------+-------+-------+-------
row1  |1    a |2    b |3    a 
row2  |4    a |5    a |6    b 


julia> @select(l, S=sum(_A), by[:B], where[_A .< 5])
2 LabeledArray

B |S 
--+--
a |8 
b |2 
```

This `@select` macro chooses all elements in the `LabeledArray` `l` where the `A` field is less than 5, and sum the `A` field values after grouping by the `B` field value.
