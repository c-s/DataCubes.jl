## Getting Started

### Installation

To install ``MultidimensionalTables``, at the Julia REPL:

```julia
Pkg.add("MultidimensionalTables")
```


### Using the MultidimensionalTables package

To use ``MultidimensionalTables``,

```julia
using MultidimensionalTables
```

This will introduce the core functions into namespace.
A few helper functions have the form ``tbltool.*`` and they can be introduced into namespace as well by:

```julia
using MultidimensionalTables.Tools
```

Below, we assume you already executed ``using MultidimensionalTables``.

### Creating a multidimensional table

#### DictArray
A multidimensional table can be represented by either the [``DictArray``](/api/#type__dictarray.1) or [``LabeledArray``](/api/#type__labeledarray.1) data type.
A ``DictArray`` is an array of ordered dictionaries with the common keys, and represents a table with no speicial axis information.
A ``LabeledArray`` is a ``DictArray`` with an additional vector for each axis for their labels.
The macro ``@darr`` is used to create a ``DictArray``:

```julia
julia> d = @darr(c1=[1,1,2], c2=["x", "y", "z"])

3 DictArray

c1 c2 
------
1  x  
1  y  
2  z  
```

Note that this is a *one*-dimensional array. There are 3 elements in the array:
```julia
julia> for elem in d
         println(elem)
       end
MultidimensionalTables.LDict{Symbol,Nullable{T}}(:c1=>Nullable(1),:c2=>Nullable("x"))
MultidimensionalTables.LDict{Symbol,Nullable{T}}(:c1=>Nullable(1),:c2=>Nullable("y"))
MultidimensionalTables.LDict{Symbol,Nullable{T}}(:c1=>Nullable(2),:c2=>Nullable("z"))
```

``LDict`` is an ordered dictionary. That is, it is similar to ``Dict`` but keeps track of the order of the insertion of elements. Each element has two keys ``:c1`` and ``:c2``. Their values are all ``Nullable``: the macro ``@darr`` wraps values appropriately by ``Nullable`` if they are not wrapped already.
To choose an element, e.g. ``y`` in the ``DictArray`` ``d``, you can use ``d[2][:c2]``.
To choose one field, a function ``pick`` is provided:
```julia
julia> pick(d, :c1)
3-element MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},1,Array{Nullable{Int64},1}}:
 Nullable(1)
 Nullable(1)
 Nullable(2)
```

``pick`` has many types of methods, and the meaning is different depending on the situation.
For example, to get a ``DictArray`` with only ``c1`` field, use ``pick(d, [:c1])``.
An array access expression such as ``d[2,:c2]`` cannot be provided because the field name (``:c2``) can be actually any type. For example:

```julia
julia> d1 = @darr(:one=>[1,2,3], 2=>[:x,:y,:z], "three"=>['u','v','w'])
3 DictArray

one 2 three 
------------
1   x u     
2   y v     
3   z w     
```

#### LabeledArray

A ``LabeledArray`` adds axes information to a ``DictArray``.
A convenient way to create a ``LabeledArray`` by hand is using the macro ``@larr``.
For example,

```julia
julia> t = @larr(c1=[1 ,1 ,2], c2=["x", "y", "z"], axis1[k1=[10,11,12], k2=[:r1, :r2, :r3]])
3 LabeledArray

k1 k2 |c1 c2 
------+------
10 r1 |1  x  
11 r2 |1  y  
12 r3 |2  z  
```

Note the appearance of labels in the first column whose field names are ``k1`` and ``k2``.
You can also construct a ``LabeledArray`` from a ``DictArray`` and axes labels:

```julia
julia> d = @darr(c1=[1 ,1 ,2], c2=["x", "y", "z"])
3 DictArray

c1 c2 
------
1  x  
1  y  
2  z  


julia> t = @larr(d, axis1[k=[:r1, :r2, :r3]])
3 LabeledArray

k  |c1 c2 
---+------
r1 |1  x  
r2 |1  y  
r3 |2  z  
```

``peel(t)`` will return the underlying ``DictArray``, stripping off all axes information.
``pick(t, :c1)`` will return the field value array of ``c1``.

#### Multidimensional Tables

Both ``DictArray`` and ``LabeledArray`` can be multidimensional.
For example,

```julia
julia> m = @larr(c1=[1 2;3 4;5 6],
                 c2=['a' 'b';'b' 'a';'a' 'a'],
                 axis1[k1=["x","y","z"]],
                 axis2[r1=[:A,:B]])
3 x 2 LabeledArray

r1 |A     |B     
---+------+------
k1 |c1 c2 |c1 c2 
---+------+------
x  |1  a  |2  b  
y  |3  b  |4  a  
z  |5  a  |6  a  
```

You can choose elements in the array using usual array indexing expressions:

```julia
julia> m[2:3,2]
2 LabeledArray

k1 |c1 c2 
---+------
y  |4  a  
z  |6  a  
```

Many operations for multidimensional arrays are also applicable:

```julia
julia> transpose(m)
2 x 3 LabeledArray

k1 |x     |y     |z     
---+------+------+------
r1 |c1 c2 |c1 c2 |c1 c2 
---+------+------+------
A  |1  a  |3  b  |5  a  
B  |2  b  |4  a  |6  a  


julia> sub(m, 1:2, 1:2)
2 x 2 LabeledArray

r1 |A     |B     
---+------+------
k1 |c1 c2 |c1 c2 
---+------+------
x  |1  a  |2  b  
y  |3  b  |4  a  
```

Some operations take slightly differnt set of arguments. For example, to sort a ``LabeledArray`` ``m`` along the first axis using the field ``c2``:

```julia
julia> sort(m, 1, :c2)
3 x 2 LabeledArray

r1 |A     |B     
---+------+------
k1 |c1 c2 |c1 c2 
---+------+------
x  |1  a  |2  b  
z  |5  a  |6  a  
y  |3  b  |4  a  
```

### Manipulating LabeledArray

The macro ``@select`` uses a SQL-like syntax to transform one ``LabeledArray`` into another (or into a dictionary).
Let's use this ``LabeledArray`` ``m`` as an example:

```julia
julia> m = @larr(c1=[1 2;3 4;5 6],
                 c2=['a' 'b';'b' 'a';'a' 'a'],
                 c3=[10.0 NA;NA 12.0;20.0 20.0],
                 axis1[k1=["x","y","z"]],
                 axis2[r1=[:A,:B]])
3 x 2 LabeledArray

r1 |A          |B          
---+-----------+-----------
k1 |c1 c2 c3   |c1 c2 c3   
---+-----------+-----------
x  |1  a  10.0 |2  b       
y  |3  b       |4  a  12.0 
z  |5  a  20.0 |6  a  20.0 
```

To select only the fields ``c1`` and ``c2``,

```julia
julia> @select(m, :c1, :c2)
3 x 2 LabeledArray

r1 |A     |B     
---+------+------
k1 |c1 c2 |c1 c2 
---+------+------
x  |1  a  |2  b  
y  |3  b  |4  a  
z  |5  a  |6  a  
```

An example to create a new column from the existing one:

```julia
julia> @select(m, c=_c1 .* 2 .+ _c3)
3 x 2 LabeledArray

r1 |A    |B    
---+-----+-----
k1 |c    |c    
---+-----+-----
x  |12.0 |     
y  |     |20.0 
z  |30.0 |32.0 
```

``_c1`` refers to the ``c1`` field and ``.*`` does the component-wise multiplication.

To choose only relevant elements, use the ``where[...]`` expression,

```julia
julia> @select(m, :c1, :c2, where[_c2 .== 'b'])
2 x 2 LabeledArray

r1 |A     |B     
---+------+------
k1 |c1 c2 |c1 c2 
---+------+------
x  |      |2  b  
y  |3  b  |      
```

``where[...]`` can have many conditions inside ``...``, and they will be applied sequentially.
Multiple ``where[...]`` are also possible, and they will be simply concatenated.

To group the array elements by some fields, use the ``by[...]`` expression,

```julia
julia> @select(m,c1=sum(_c1), c3=sum(_c3), by[:c2])
2 LabeledArray

c2 |c1 c3   
---+--------
a  |16 62.0 
b  |5  0.0  
```

You can provide multiple fields to group by:

```julia
julia> @select(m,c1=sum(_c1), c3=mean(_c3), by[:c2,c4=_c1 .> 5])
3 LabeledArray

c2 c4    |c1 c3   
---------+--------
a  false |10 14.0 
a  true  |6  20.0 
b  false |5       
```

But it is also possible to group by the array in a multidimensional way:

```julia
julia> @select(m,c1=sum(_c1), c3=mean(_c3), by[:c2], by[c4=_c1 .> 5])
2 x 2 LabeledArray

c4 |false      |true      
---+-----------+----------
c2 |c1    c3   |c1   c3   
---+-----------+----------
a  |10    14.0 |6    20.0 
b  |5          |          
```

