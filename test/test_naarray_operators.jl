module TestNAArrayOperators

using FactCheck
using MultidimensionalTables
using MultidimensionalTables.AbstractArrayWrapper

facts("NAArrayOperators tests") do
  context("AbstractArrayWrapper tests") do
    @fact 1 .+ AbstractArrayWrapper(nalift([1,2,3])) --> AbstractArrayWrapper(nalift([2,3,4]))
    @fact AbstractArrayWrapper(nalift([1,2,3])) .- 1 --> AbstractArrayWrapper(nalift([0,1,2]))
    @fact AbstractArrayWrapper(nalift([1,2,3])) .*
            AbstractArrayWrapper(nalift([5.0,6.0,7.0])) --> AbstractArrayWrapper(nalift([5.0,12.0,21.0]))
    @fact map(x->Nullable(x.value*2), AbstractArrayWrapper(nalift([1,2,3]))) --> AbstractArrayWrapper(nalift([2,4,6]))
    @fact (x=AbstractArrayWrapper([5,1,3,2,4]);sort!(x);x) --> AbstractArrayWrapper([1,2,3,4,5])
    @fact sort(AbstractArrayWrapper([5 1 3 2 4]),2) --> AbstractArrayWrapper([1 2 3 4 5])
    @fact sort(AbstractArrayWrapper([5,1,3,2,4])) --> AbstractArrayWrapper([1,2,3,4,5])
    @fact map((x,y)->MultidimensionalTables.naop_plus(x,y), nalift([1,2,3,4,5]), @nalift([1,2,NA,4,5])) --> @nalift([2,4,NA,8,10])
  end
end

end
