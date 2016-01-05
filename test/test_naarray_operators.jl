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
    @fact @nalift([1,2,NA]) .> 1 --> @nalift([false, true, NA])
    @fact 1 .< @nalift([1,2,NA]) --> @nalift([false, true, NA])
    @fact @nalift([1,2,3,NA]) .< @nalift([NA,3,1,2]) --> @nalift([NA,true,false,NA])
    @fact @nalift([1.0,2.0,NA]) .- 1 --> @nalift([0.0,1.0,NA])
    @fact 1 .- @nalift([1.0,2.0,NA]) --> @nalift([0.0,-1.0,NA])
    @fact @nalift([1.0,2.0,NA]) .* @nalift([NA,2.0,3.0]) --> @nalift([NA,4.0,NA])
    @fact -@nalift([1.0,2.0,NA]) --> @nalift([-1.0,-2.0,NA])
    @fact ~@nalift([1,2,NA]) --> @nalift([~1,~2,NA])
    @fact AbstractArrayWrapper([1,2,3]) .> 1 --> AbstractArrayWrapper([false,true,true])
    @fact AbstractArrayWrapper([1,2,3]) .> 1.5 --> AbstractArrayWrapper([false,true,true])
    @fact 1 .< AbstractArrayWrapper([1,2,3]) --> AbstractArrayWrapper([false,true,true])
    @fact AbstractArrayWrapper([1,2,3]) .> Nullable(1) --> nalift([false,true,true])
    @fact AbstractArrayWrapper([1,2,3]) + 1.0 --> AbstractArrayWrapper([2.0,3.0,4.0])
    @fact AbstractArrayWrapper([1,2,3]) + Nullable(1.0) --> nalift([2.0,3.0,4.0])
    @fact Nullable(1) .< AbstractArrayWrapper([1,2,3]) --> nalift([false,true,true])
    @fact AbstractArrayWrapper([3.0,2.0,1.0]) .< AbstractArrayWrapper([1.0,2.0,3.0]) --> AbstractArrayWrapper([false,false,true])
    @fact AbstractArrayWrapper([3,2,1]) .< nalift([1,2,3]) --> nalift([false,false,true])
    @fact @nalift([3,NA,1]) .< AbstractArrayWrapper([1.0,2.0,3.0]) --> @nalift([false,NA,true])
    @fact nalift([3,2,1]) .< nalift([1.0,2.0,3.0]) --> nalift([false,false,true])
    @fact nalift([3,2,1]) + nalift([1.0,2.0,3.0]) --> nalift([4.0,4.0,4.0])
    @fact nalift([3,2,1]) + AbstractArrayWrapper([1.0,2.0,3.0]) --> nalift([4.0,4.0,4.0])
    @fact AbstractArrayWrapper([3,2,1]) + AbstractArrayWrapper([1.0,2.0,3.0]) --> AbstractArrayWrapper([4.0,4.0,4.0])
    @fact AbstractArrayWrapper([3,2,1]) + 5.0 --> AbstractArrayWrapper([8.0,7.0,6.0])
    @fact AbstractArrayWrapper([3,2,1]) + Nullable(5.0) --> nalift([8.0,7.0,6.0])
    @fact -AbstractArrayWrapper([3,2,1]) --> AbstractArrayWrapper([-3,-2,-1])
    @fact -AbstractArrayWrapper([3.0,2.0,1.0]) --> AbstractArrayWrapper([-3.0,-2.0,-1.0])
    @fact -nalift([3.0,2.0,1.0]) --> nalift([-3.0,-2.0,-1.0])
    @fact -darr(a=[3.0,2.0,1.0]) --> darr(a=[-3.0,-2.0,-1.0])
    @fact -larr(a=[3.0,2.0,1.0], axis1=[:x,:y,:z]) --> larr(a=[-3.0,-2.0,-1.0], axis1=[:x,:y,:z])
    @fact nalift([1.0,2.0,3.0]) + nalift([1,2,3]) --> nalift([2.0,4.0,6.0])
    @fact nalift([1.0,2.0,3.0]) + nalift([1.0,2.0,3.0]) --> nalift([2.0,4.0,6.0])
    @fact AbstractArrayWrapper(map(Nullable, [1.0,2.0,3.0])) + nalift([1.0,2.0,3.0]) --> nalift([2.0,4.0,6.0])
    @fact AbstractArrayWrapper(map(Nullable, [1.0,2.0,3.0])) + nalift([1,2,3]) --> nalift([2.0,4.0,6.0])
    @fact AbstractArrayWrapper(map(Nullable, [1.0,2.0,3.0])) + AbstractArrayWrapper([1,2,3]) --> nalift([2.0,4.0,6.0])
    @fact nalift([1.0,2.0,3.0]) + 1.0 --> nalift([2.0,3.0,4.0])
    @fact 1.0 + nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0])
    @fact nalift([1.0,2.0,3.0]) + 1 --> nalift([2.0,3.0,4.0])
    @fact 1 + nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0])
    @fact 1.0 + nalift([1,2,3]) --> nalift([2.0,3.0,4.0])
    @fact nalift([1,2,3]) + 1.0 --> nalift([2.0,3.0,4.0])
    @fact nalift([1.0,2.0,3.0]) + Nullable(1.0) --> nalift([2.0,3.0,4.0])
    @fact Nullable(1.0) + nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0])
    @fact nalift([1.0,2.0,3.0]) + Nullable(1) --> nalift([2.0,3.0,4.0])
    @fact Nullable(1) + nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0])
    @fact Nullable(1.0) + nalift([1,2,3]) --> nalift([2.0,3.0,4.0])
    @fact nalift([1,2,3]) + Nullable(1.0) --> nalift([2.0,3.0,4.0])
    @fact nalift([1.0,2.0,3.0]) * 1.0 --> nalift([2.0,3.0,4.0]) - 1
    @fact 1.0 * nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0]) - 1
    @fact nalift([1.0,2.0,3.0]) * 1 --> nalift([2.0,3.0,4.0]) - 1
    @fact 1 * nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0]) - 1
    @fact 1.0 * nalift([1,2,3]) --> nalift([2.0,3.0,4.0]) - 1
    @fact nalift([1,2,3]) * 1.0 --> nalift([2.0,3.0,4.0]) - 1
    @fact nalift([1.0,2.0,3.0]) * Nullable(1.0) --> nalift([2.0,3.0,4.0]) - 1
    @fact Nullable(1.0) * nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0]) - 1
    @fact nalift([1.0,2.0,3.0]) * Nullable(1) --> nalift([2.0,3.0,4.0]) - 1
    @fact Nullable(1) * nalift([1.0,2.0,3.0]) --> nalift([2.0,3.0,4.0]) - 1
    @fact Nullable(1.0) * nalift([1,2,3]) --> nalift([2.0,3.0,4.0]) - 1
    @fact nalift([1,2,3]) * Nullable(1.0) --> nalift([2.0,3.0,4.0]) - 1
  end
end

end
