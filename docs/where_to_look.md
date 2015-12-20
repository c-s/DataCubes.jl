## Where To Look

### Create an array

* Create a nullable array
    * with `NA` (i.e. null) elements in it, mostly for manual typing: [`@nalift`](api/#macro___nalift.1).
    * without `NA`, typically just to lift non `Nullable` arrays: [`nalift`](api/#function__nalift.1).
* Create a multidimensional table: [`darr`](api/#function__darr.1), [`@darr`](api/#macro___darr.1)  to create a [`DictArray`](api/#type__dictarray.1). The latter if you want to convert `NA` into appropriate null elements when manually typing.
* Create an array with labels: [`larr`](api/#function__larr.1), [`@larr`](api/#macro___larr.1) to create a [`LabeledArray`](api/#type__labeledarray.1). The latter if you want to convert `NA` into appropriate null elements when manually typing.
* Create a nullable array where there are many duplications, i.e. create a pooled/enumeration array: [`enumeration`](api/#function__enumeration.1), [`@enumeration`](api/#macro___enumeration.1)

### Choose/Remove elements in an array

* Choose elements using index (normal way): index notation(`getindex`).
* Choose/Remove based on labels in [`LabeledArray`](api/#type__labeledarray.1): [`extract`](api/#function__extract.1), [`discard`](api/#function__discard.1).
* Choose the underlying *base* of [`LabeledArray`](api/#type__labeledarray.1): [`peel`](api/#function__peel.1)
* Choose the underlying ordered dictionary(`LDict`) of [`DictArray`](api/#type__dictarray.1): [`peel`](api/#function__peel.1)
* Choose field name(s) from [`DictArray`](api/#type__dictarray.1) or [`LabeledArray`](api/#type__labeledarray.1): [`pick`](api/#function__pick.1)
* Choose the axis or axes of [`LabeledArray`](api/#type__labeledarray.1): [`pickaxis`](api/#function__pickaxis.1)
* Remove fields in [`DictArray`](api/#type__dictarray.1)/[`LabeledArray`](api/#type__labeledarray.1) or keys in [`LDict`](api/#type__ldict.1): [`delete`](api/#function__delete.1)

### Select/Update tables in SQL style

* Create new fields and/or aggregating by some fields after choosing some elements based on given conditions: [`@select`](api/#macro___select.1), [`selct`](api/#function__selct.1)
* Update existing fields or append new fields and/or aggregating by some fields after choosing some elements based on given conditions: [`@update`](api/#macro___update.1), [`update`](api/#function__update.1)

### Join tables

* left join tables: [`leftjoin`](api/#function__leftjoin.1)
* inner join tables: [`innerjoin`](api/#function__innerjoin.1)

### Dealing with `NA` (null elements)

* Remove `Nullable`: [`igna`](api/#function__igna.1)
* Remove `Nullable` from a nullable boolean array, replacing null elements with `false`: [`ignabool`](api/#function__ignabool.1)

### Transform arrays

* Changing an array of arrays into an array, expanding the elements of array type along some direction: [`ungroup`](api/#function__ungroup.1)
* Make the fields to the last axis in [`LabeledArray`](api/#type__labeledarray.1): [`flds2axis`](api/#function__flds2axis.1)
* Make the last axis to fieldsi in [`LabeledArray`](api/#type__labeledarray.1): [`axis2flds`](api/#function__axis2flds.1)
* Replace the current axes along some directions with some fields [`LabeledArray`](api/#type__labeledarray.1): [`replace_axes`](api/#function__replace_axes.1)
* Flatten some of the middle dimensions in an array: [`collapse_axes`](api/#function__collapse_axes.1)
* Reordering fields: [`reorder`](api/#function__reorder.1)
* Renaming field names: [`rename`](api/#function__rename.1)
* Tensor product arrays: [`tensorprod`](api/#function__tensorprod.1)
* Providing/Withdrawing field names to [`LabeledArray`](api/#type__labeledarray.1) when some of its base or axes are not [`DictArray`](api/#type__labeledarray.1): [`providenames`](api/#function__providenames.1), [`withdrawnames`](api/#function__withdrawnames.1)

### Map arrays

* Map a function `f` element by element
    * if `f` is from non nullable value to nullable or non nullable value: [`mapna`](api/#function__mapna.1)
    * if `f` is from nullable value to nullable or non nullable value: [`map`](api/#method__map.1)
* Map or reduce slices of an array: [`mapslices`](api/#method__mapslices.1), [`reducedim`](api/#method__reducedim.1)
* Map values into another values keeping keys or field names the same: [`mapvalues`](api/#function__mapvalues.1)

### Calculate statistics

* Available statistical functions:
[`msum`](api/#function__msum.1),
[`mprod`](api/#function__mprod.1),
[`mmean`](api/#function__mmean.1),
[`mmedian`](api/#function__mmedian.1),
[`mminimum`](api/#function__mminimum.1),
[`mmaximum`](api/#function__mmaximum.1),
[`mmiddle`](api/#function__mmiddle.1),
[`mquantile`](api/#function__mquantile.1)

* Summarize fields in [`DictArray`](api/#type__dictarray.1): [`describe`](api/#function__describe.1)

* Fill `NA`s forward or backward: [`nafill`](api/#function__nafill.1)
* Shift arrays by some amount. Can be used, for example, to obtain previous or next month time series: [`shift`](api/#function__shift.1)

### Work with DataFrames

* convert to DataFrames: [`convert(::DataFrame, ::DictArray)`](api/#method__convert.1), [`convert(::DataFrame, ::LabeledArray)`](api/#method__convert.2)
* convert from DataFrames: [`convert(::DictArray, ::DataFrame)`](api/#method__convert.3), [`convert(::LabeledArray, ::DataFrame)`](api/#method__convert.5), [`convert(::EnumerationArray, ::DataFrame)`](api/#method__convert.4)

### Miscellaneous

* Remove all `NA` elements in an array, possibly reducing its size when some elements along some slice are all `NA`: [`dropna`](api/#function__dropna.1)
* Combining two arrays of the same shape. The second one updates the first one only when the element is not `NA`: [`namerge`](api/#function__namerge.1)
* Want to avoid excessive numbers of parentheses when applying several functions: [`@rap`](api/#macro___rap.1).
* Create a labels => base value nested dictionary from [`LabeledArray`](api/#type__labeledarray.1): [`tbltool.create_dict`](api/#function__create_dict.1)
* Set elements in an array to `NA`: [`tbltool.setna!`](api/#function__setna.1)
* Choose whether to display fields along row or column: `alongrow=true/false` option in [`show`](api/#method__show.1) for [`DictArray`](api/#type__dictarray.1) and [`show`](api/#method__show.3) for [`LabeledArray`](api/#type__labeledarray.1).
* Take some number of elements repeatedly along some direction in an array: [`tbltool.gtake`](api/#function__gtake.1).
* Drop some number of elements along some direction in an array: [`tbltool.gdrop`](api/#function__gdrop.1).
* Set show size when printing [`DictArray`](api/#type__dictarray.1) and [`LabeledArray`](api/#type__labeledarray.1) to console: `tbltool.set_showalongrow!!`,`tbltool.set_showheight!!`, `tbltool.set_showwidth!!`, `tbltool.set_default_showsize!!`
* Set display size for html output of [`DictArray`](api/#type__dictarray.1) and [`LabeledArray`](api/#type__labeledarray.1): `tbltool.set_dispalongrow!!`, `tbltool.set_dispheight!!`, `tbltool.set_dispwidth!!`, `tbltool.set_default_dispsize!!`
