###################################################
# DataCubes.jl
# A general array library for Julia.
# https://github.com/c-s/DataCubes.jl.git
# MIT Licensed
###################################################

module TestDataCubes

using FactCheck

subtests = ["test_ldict.jl", "test_dict_array.jl", "test_labeled_array.jl",
            "test_na.jl", "test_naarray_operators.jl",
            "test_array_util.jl", "test_dataframe_interface.jl",
            "test_join.jl", "test_select.jl", "test_sort.jl", "test_ungroup.jl",
            "test_setops.jl", "test_array_helper_functions.jl",
            "test_enumeration_array.jl"][3:end]

FactCheck.onlystats(true)

for subtest in subtests
  include(subtest)
end

exitstatus()

end
