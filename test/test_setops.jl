module TestSetOprations

using FactCheck
using MultidimensionalTables

facts("Set Operations tests") do
  context("unique test") do
    @fact unique(nalift([1 1 2 1;1 2 4 1;1 1 2 1]),1,2) --> @nalift [1 NA NA;NA 2 4]
    @fact unique(nalift([1 1 2 1;1 2 4 1;1 1 2 1]),2,1) --> @nalift [1 2;NA 4]
    @fact unique(nalift([1 1 2 1;1 2 4 1;1 1 2 1]),1) --> @nalift [1 1 2 1;1 2 4 1]
    @fact unique(nalift([1 1 2 1;1 2 4 1;1 1 2 1]),2) --> @nalift [1 1 2;1 2 4;1 1 2]
    @fact unique(@darr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),1,2) --> @darr(a=[1 NA NA;NA 2 4])
    @fact unique(@darr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),2,1) --> @darr(a=[1 2;NA 4])
    @fact unique(@darr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),1) --> @darr(a=[1 1 2 1;1 2 4 1])
    @fact unique(@darr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),2) --> @darr(a=[1 1 2;1 2 4;1 1 2])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),1,2) --> @larr(a=[1 NA NA;NA 2 4])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),2,1) --> @larr(a=[1 2;NA 4])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),1) --> @larr(a=[1 1 2 1;1 2 4 1])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1]),2) --> @larr(a=[1 1 2;1 2 4;1 1 2])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1],axis1[k=[:a,:b,:c]]),1,2) --> @larr(a=[1 NA NA;NA 2 4],axis1[k=[:a,:b]])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1],axis1[k=[:a,:b,:c]]),2,1) --> @larr(a=[1 2;NA 4],axis1[k=[:a,:b]])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1],axis1[k=[:a,:b,:c]]),1) --> @larr(a=[1 1 2 1;1 2 4 1],axis1[k=[:a,:b]])
    @fact unique(@larr(a=[1 1 2 1;1 2 4 1;1 1 2 1],axis1[k=[:a,:b,:c]]),2) --> @larr(a=[1 1 2;1 2 4;1 1 2],axis1[k=[:a,:b,:c]])
  end
  context("union test") do
    @fact union(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[:sym1 :sym2 :sym3])) --> @larr(a=[1 2 3;4 5 6;:sym1 :sym2 :sym3])
    @fact union(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2 3])) --> @larr(a=[1 2 3;4 5 6])
    @fact union(2, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2;4 7])) --> @larr(a=[1 2 3 2;4 5 6 7])
    @fact union(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 7],b=[11 12;14 15])) --> @larr(a=[1 2 3 2;4 5 6 7], b=[11 12 13 12;14 15 16 15])
    @fact union(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 5],b=[11 12;14 15])) --> @larr(a=[1 2 3;4 5 6], b=[11 12 13;14 15 16])
    @fact union(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r5,:r2]])) --> @larr(a=[1 2 3 1 2;4 5 6 4 6],b=[11 12 13 11 12;14 15 16 14 15],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3,:r5,:r2]])
    @fact union(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r1,:r2]])) --> @larr(a=[1 2 3 2;4 5 6 6],b=[11 12 13 12;14 15 16 15],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3,:r2]])

    @fact union(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[:sym1 :sym2 :sym3])) --> @darr(a=[1 2 3;4 5 6;:sym1 :sym2 :sym3])
    @fact union(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2 3])) --> @darr(a=[1 2 3;4 5 6])
    @fact union(2, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2;4 7])) --> @darr(a=[1 2 3 2;4 5 6 7])
    @fact union(2, @darr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @darr(a=[1 2;4 7],b=[11 12;14 15])) --> @darr(a=[1 2 3 2;4 5 6 7], b=[11 12 13 12;14 15 16 15])
    @fact union(1, @nalift([1 2 3;4 5 6]), @nalift([:sym1 :sym2 :sym3])) --> @nalift([1 2 3;4 5 6;:sym1 :sym2 :sym3])
    @fact union(1, @nalift([1 2 3;4 5 6]), @nalift([1 2 3])) --> @nalift([1 2 3;4 5 6])
    @fact union(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 7])) --> @nalift([1 2 3 2;4 5 6 7])
    @fact union(2, @nalift([1 2 3;4 5 6]), @nalift([11 12;14 15])) --> @nalift([1 2 3 11 12;4 5 6 14 15])
    @fact union(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 5])) --> @nalift([1 2 3;4 5 6])
  end
  context("intersect test") do
    @fact intersect(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[:sym1 :sym2 :sym3])) --> isempty
    @fact intersect(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2 3])) --> @larr(a=[1 2 3])
    @fact intersect(2, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2;4 7])) --> @larr(a=[1 4]')
    @fact intersect(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 7],b=[11 12;14 15])) --> @larr(a=[1 4]',b=[11 14]')
    @fact intersect(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 5],b=[11 12;14 15])) --> @larr(a=[1 2;4 5],b=[11 12;14 15])
    @fact intersect(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r5,:r2]])) --> isempty
    @fact intersect(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r1,:r2]])) --> @larr(a=[1 4]',b=[11 14]',axis1[k=['a','b']],axis2[r=[:r1]])

    @fact intersect(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[:sym1 :sym2 :sym3])) --> isempty
    @fact intersect(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2 3])) --> @darr(a=[1 2 3])
    @fact intersect(2, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2;4 7])) --> @darr(a=[1 4]')
    @fact intersect(2, @darr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @darr(a=[1 2;4 7],b=[11 12;14 15])) --> @darr(a=[1 4]', b=[11 14]')
    @fact intersect(1, @nalift([1 2 3;4 5 6]), @nalift([:sym1 :sym2 :sym3])) --> isempty
    @fact intersect(1, @nalift([1 2 3;4 5 6]), @nalift([1 2 3])) --> @nalift([1 2 3])
    @fact intersect(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 7])) --> @nalift([1 4]')
    @fact intersect(2, @nalift([1 2 3;4 5 6]), @nalift([11 12;14 15])) --> isempty
    @fact intersect(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 5])) --> @nalift([1 2;4 5])
  end
  context("setdiff test") do
    @fact setdiff(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[:sym1 :sym2 :sym3])) --> setdiff(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[:sym1 :sym2 :sym3]))
    @fact setdiff(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2 3;4 5 6])) --> isempty
    @fact setdiff(1, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2 3])) --> @larr(a=[4 5 6])
    @fact setdiff(2, @larr(a=[1 2 3;4 5 6]), @larr(a=[1 2;4 7])) --> @larr(a=[2 3;5 6])
    @fact setdiff(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 7],b=[11 12;14 15])) --> @larr(a=[2 3;5 6],b=[12 13;15 16])
    @fact setdiff(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @larr(a=[1 2;4 5],b=[11 12;14 15])) --> @larr(a=[3 6]',b=[13 16]')
    @fact setdiff(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r5,:r2]])) --> @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]])
    @fact setdiff(2, @larr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16],axis1[k=['a','b']],axis2[r=[:r1,:r2,:r3]]), @larr(a=[1 2;4 6],b=[11 12;14 15],axis1[k=['a','b']],axis2[r=[:r1,:r2]])) --> @larr(a=[2 3;5 6],b=[12 13;15 16],axis1[k=['a','b']],axis2[r=[:r2,:r3]])

    @fact setdiff(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[:sym1 :sym2 :sym3])) --> @darr(a=[1 2 3;4 5 6])
    @fact setdiff(1, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2 3])) --> @darr(a=[4 5 6])
    @fact setdiff(2, @darr(a=[1 2 3;4 5 6]), @darr(a=[1 2;4 7])) --> @darr(a=[2 3;5 6])
    @fact setdiff(2, @darr(a=[1 2 3;4 5 6],b=[11 12 13;14 15 16]), @darr(a=[1 2;4 7],b=[11 12;14 15])) --> @darr(a=[2 3;5 6],b=[12 13;15 16])
    @fact setdiff(1, @nalift([1 2 3;4 5 6]), @nalift([:sym1 :sym2 :sym3])) --> @nalift([1 2 3;4 5 6])
    @fact setdiff(1, @nalift([1 2 3;4 5 6]), @nalift([1 2 3])) --> @nalift([4 5 6])
    @fact setdiff(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 7])) --> @nalift([2 3;5 6])
    @fact setdiff(2, @nalift([1 2 3;4 5 6]), @nalift([11 12;14 15])) --> @nalift([1 2 3;4 5 6])
    @fact setdiff(2, @nalift([1 2 3;4 5 6]), @nalift([1 2;4 5])) --> @nalift([3 6]')
  end
end

end
