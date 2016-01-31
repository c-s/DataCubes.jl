__precompile__()

module DataCubes

import Formatting: sprintf1

# including files.
include("common.jl")
include("datatypes/ldict.jl")
include("datatypes/dict_array.jl")
include("datatypes/labeled_array.jl")
include("datatypes/enumeration_array.jl")
include("na/na.jl")
include("na/naarray_operators.jl")
include("util/select.jl")
include("util/join.jl")
include("util/sort.jl")
include("util/ungroup.jl")
include("util/array_util.jl")
include("util/mapslices_base.jl")
include("util/dataframe_interface.jl")
include("util/unique.jl")
include("util/union.jl")
include("util/intersect.jl")
include("util/setdiff.jl")
include("util/array_helper_functions.jl")

export LDict, DictArray, LabeledArray, EnumerationArray
export @select,
       @update,
       @darr,
       @larr,
       @nalift,
       @rap,
       @enumeration,
       enumeration,
       nalift,
       peel,
       pick,
       pickaxis,
       delete,
       selct,
       update,
       larr,
       darr,
       igna,
       ignabool,
       isna,
       ungroup,
       flds2axis,
       axis2flds,
       replace_axes,
       collapse_axes,
       dropna,
       mapna,
       mapvalues,
       leftjoin,
       innerjoin,
       reorder,
       rename,
       tensorprod,
       extract,
       discard,
       providenames,
       withdrawnames,
       msum, # moving sum
       mprod, # moving product
       mmean, # moving average
       mmedian, # moving median
       mminimum, # moving minimum
       mmaximum, # moving maximum
       mmiddle, # moving middle
       mquantile, # moving quantile
       nafill, # fill forward/backword na's.
       describe,
       shift,
       namerge

export dcube

module Tools
  using DataCubes
  items = [:AbstractArrayWrapper, :FloatNAArray, :simplify_array, :wrap_array, :type_array,
           :getindexpair,
           :getindexvalue,
           :gtake, :gdrop,
           :create_dict, :setna!,
           :dropnaiter, :enum_dropnaiter, :zip_dropnaiter,
           # some display setting functions.
           :set_showalongrow!!, :set_showsize!!, :set_showheight!!, :set_showwidth!!, :set_default_showsize!!,
           :set_dispalongrow!!, :set_dispsize!!, :set_dispheight!!, :set_dispwidth!!, :set_default_dispsize!!,
           :set_format_string!!]
  for item in items
    @eval begin
      $item = DataCubes.$item
      export $item
    end
  end
end

dcube = DataCubes.Tools

end
