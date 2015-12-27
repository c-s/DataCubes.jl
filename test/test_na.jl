module TestNA

using FactCheck
using MultidimensionalTables
using MultidimensionalTables: AbstractArrayWrapper, FloatNAArray, simplify_array, wrap_array, naop_plus

facts("NA tests") do
  @fact AbstractArrayWrapper(nalift([1,2,3])) --> AbstractArrayWrapper([Nullable(1), Nullable(2), Nullable(3)])
  @fact map(AbstractArrayWrapper,Any[nalift([1 2 3]),nalift([4,5])]) --> map(AbstractArrayWrapper,Any[[Nullable(1) Nullable(2) Nullable(3)],[Nullable(4), Nullable(5)]])
  @fact AbstractArrayWrapper(simplify_array(nalift(Any[[1 2 3],[4,5]]))) --> AbstractArrayWrapper(simplify_array(Any[Nullable([1 2 3]), Nullable([4,5])]))
  @fact @nalift([1 2 3;4 NA 5]) --> AbstractArrayWrapper([Nullable(1) Nullable(2) Nullable(3);Nullable(4) Nullable{Int}() Nullable(5)])
  @fact @nalift(Any[[1 2 NA],[3,NA]]) --> nalift(map(AbstractArrayWrapper,Any[[Nullable(1) Nullable(2) Nullable{Int}()], [Nullable(3), Nullable{Int}()]]))
  @fact AbstractArrayWrapper([x for x in FloatNAArray([1.0,2.0,NaN])]) --> AbstractArrayWrapper([Nullable(1.0), Nullable(2.0), Nullable{Float64}()])
  @fact AbstractArrayWrapper(FloatNAArray(reverse([1.0,2.0,3.0]))) --> AbstractArrayWrapper(FloatNAArray([3.0,2.0,1.0]))
  @fact simplify_array(nalift([1,2,3])) --> AbstractArrayWrapper([Nullable(1),Nullable(2),Nullable(3)])
  @fact simplify_array(Any[Nullable(3.5), Nullable(2.0), Nullable{Float64}()]) --> AbstractArrayWrapper(FloatNAArray([3.5, 2.0, NaN]))
  @fact (t=@larr(a=[1 2 3;4 5 6], b=[4 5 6;7 8 9]);tbltool.setna!(t.data.data[:a],2,2);tbltool.setna!(t,2,1);t) --> @larr(a=[1 2 3;NA NA 6], b=[4 5 6;NA 8 9])
  @fact igna(Nullable{Int}(), 3) --> 3
  @fact igna(Nullable(1), 3) --> 1
  @fact ignabool(nalift([true, false])) --> [true, false]
  @fact ignabool(Nullable{Bool}()) --> false
  @fact ignabool(Nullable(true)) --> true
  @fact ignabool(Nullable(false)) --> false
  @fact ignabool([Nullable(true), Nullable{Bool}()]) --> [true, false]
  @fact ignabool([Nullable(true)]) --> [true]
  @fact ignabool([Nullable(false)]) --> [false]
  @fact @nalift([NA NA]) --> wrap_array([Nullable{Any}() Nullable{Any}()])
  @fact @nalift([NA,NA]) --> wrap_array([Nullable{Any}(),Nullable{Any}()])
  @fact @nalift([NA NA;NA NA]) --> wrap_array(reshape(fill(Nullable{Any}(),4),2,2))
  @fact @nalift([1,NA]) --> wrap_array([Nullable(1), Nullable{Int}()])
  @fact @nalift([1 NA]) --> wrap_array([Nullable(1)  Nullable{Int}()])
  @fact @nalift([1 NA;NA NA]) --> wrap_array([Nullable(1)  Nullable{Int}();Nullable{Int}() Nullable{Int}()])
  @fact map(x->x, nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
  @fact map((x,y)->naop_plus(x, y), nalift([1.0,2.0,3.0]), nalift([2.0,3.0,4.0])) --> nalift([3.0,5.0,7.0])
end

end
