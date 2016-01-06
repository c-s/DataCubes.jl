module TestSort

using FactCheck
using MultidimensionalTables

facts("Sort tests") do
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 1, :a) --> @darr(a=[3 3 1;5 5 3],b=[9 8 7;1 3 4])
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 2, :a) --> @darr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8])
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7]), 2, :a,:b) --> @darr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 1, :a) --> @larr(a=[3 3 1;5 5 3],b=[9 8 7;1 3 4],axis1[k=[:b,:a]],axis2[r=[:X,:Y,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a) --> @larr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:X,:Y]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b) --> @larr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:Y,:X]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b, a_rev=true) --> @larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:Y,:X,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b, a_rev=true, b_rev=true) --> @larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :b, b_coords=(1,:)) --> larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1=darr(k=[:a,:b]),axis2=darr(r=[:Y,:X,:Z]))
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :b, b_coords=(2,:)) --> larr(a=[3 5 5;1 3 3],b=[4 3 1;7 8 9],axis1=darr(k=[:a,:b]),axis2=darr(r=[:Z,:X,:Y]))

  @fact sort(@darr(a=[5.0 5.0 3.0;3.0 3.0 1.0],b=[1.0 3.0 4.0;9.0 8.0 7.0]), 1, :a) --> @darr(a=1.0*[3 3 1;5 5 3],b=1.0*[9 8 7;1 3 4])
  @fact sort(@darr(a=1.0*[5 5 3;3 3 1],b=1.0*[1 3 4;9 8 7]), 2, :a) --> @darr(a=1.0*[3 5 5;1 3 3],b=1.0*[4 1 3;7 9 8])
  @fact sort(@darr(a=1.0*[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7]), 2, :a,:b) --> @darr(a=1.0*[3 5 5;1 3 3],b=1.0*[4 1 3;7 9 8])
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=1.0*[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 1, :a) --> @larr(a=1.0*[3 3 1;5 5 3],b=1.0*[9 8 7;1 3 4],axis1[k=[:b,:a]],axis2[r=[:X,:Y,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=1.0*[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a) --> @larr(a=[3 5 5;1 3 3],b=1.0*[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:X,:Y]])
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b) --> @larr(a=1.0*[3 5 5;1 3 3],b=[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:Y,:X]])
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b, a_rev=true) --> @larr(a=1.0*[5 5 3;3 3 1],b=1.0*[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:Y,:X,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a,:b, a_rev=true, b_rev=true) --> @larr(a=[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]])
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :b, b_coords=(1,:)) --> larr(a=1.0*[5 5 3;3 3 1],b=1.0*[1 3 4;9 8 7],axis1=darr(k=[:a,:b]),axis2=darr(r=[:Y,:X,:Z]))
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=[3 1 4;8 9 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :b, b_coords=(2,:)) --> larr(a=1.0*[3 5 5;1 3 3],b=[4 3 1;7 8 9],axis1=darr(k=[:a,:b]),axis2=darr(r=[:Z,:X,:Y]))
end

end
