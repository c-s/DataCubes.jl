module TestNA

using FactCheck
using DataCubes
using DataCubes: AbstractArrayWrapper, FloatNAArray, simplify_array, wrap_array, naop_plus

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
  @fact (t=@larr(a=[1 2 3;4 5 6], b=[4 5 6;7 8 9]);dcube.setna!(t.data.data[:a],2,2);dcube.setna!(t,2,1);t) --> @larr(a=[1 2 3;NA NA 6], b=[4 5 6;NA 8 9])
  @fact simplify_array(nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
  @fact DataCubes.simplify_floatarray(nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
  @fact sort(nalift([5.0,3.0,4.0])) --> nalift([3.0,4.0,5.0])
  @fact sort!(@nalift([5.0,3.0,4.0])) --> nalift([3.0,4.0,5.0])
  @fact DataCubes.wrap_array(vcat(FloatNAArray(1.0*[1 2 3]),FloatNAArray(1.0*[4 5 6]))) --> DataCubes.wrap_array(FloatNAArray([1 2 3;4 5 6]*1.0))
  @fact DataCubes.wrap_array(hcat(FloatNAArray(1.0*[1 2 3]),FloatNAArray(1.0*[4 5 6]))) --> DataCubes.wrap_array(FloatNAArray([1 2 3 4 5 6]*1.0))
  @fact DataCubes.simplify_floatarray(Nullable{Float64}[]) --> isempty
  @fact typeof(DataCubes.simplify_floatarray(Nullable{Float64}[])) --> DataCubes.FloatNAArray{Float64,1,Array{Float64,1}}
  @fact nalift(FloatNAArray([1.0 2.0 NaN])) --> @nalift([1.0 2.0 NA])
  @fact (t=@nalift([1.0 NA 3]);DataCubes.setna!(t);t) --> nalift(fill(Nullable{Any}(),1,3))
  #@fact (t=@nalift([1.0 NA 3]);DataCubes.setna!(t);typeof(t)) --> DataCubes.AbstractArrayWrapper{Nullable,2,Array{Nullable,2}} # in v0.5, it is promoted to FloatNAArray.
  @fact (t=@nalift([1.0 2.0 3.0]);DataCubes.setna!(t);t) --> nalift(fill(NaN,1,3))
  @fact (t=enumeration([:a,:b,:a]);DataCubes.setna!(t);wrap_array(t)) --> wrap_array(fill(Nullable{Symbol}(),3))
  @fact (t=enumeration([:a,:b,:a]);DataCubes.setna!(t,1);wrap_array(t)) --> wrap_array(@enumeration([NA,:b,:a],[:a,:b]))
  @fact (t=enumeration([:a,:b,:a]);DataCubes.setna!(t);typeof(t)) --> EnumerationArray{Symbol,1,DataCubes.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}
  @fact (t=enumeration([:a,:b,:a]);fill!(t,0);wrap_array(t)) --> wrap_array(fill(Nullable{Symbol}(),3))
  @fact (t=enumeration([:a,:b,:a]);fill!(t,Nullable(:c));wrap_array(t)) --> wrap_array(fill(Nullable{Symbol}(),3))
  @fact (t=enumeration([:a,:b,:a]);fill!(t,Nullable{Symbol}());wrap_array(t)) --> wrap_array(fill(Nullable{Symbol}(),3))
  @fact (t=@nalift([1.0 2.0 3.0]);fill!(t,NaN);t) --> @nalift([NA NA NA])
  @fact (t=@nalift([1.0 2.0 3.0]);fill!(t,Nullable{Float64}());t) --> @nalift([NA NA NA])
  @fact (t=@nalift([1.0 2.0 3.0]);fill!(t,Nullable(5.0));t) --> @nalift([5.0 5.0 5.0])
  @fact igna(Nullable{Int}(), 3) --> 3
  @fact igna(Nullable(1), 3) --> 1
  @fact igna(Nullable(1.0), 3.0) --> 1.0
  @fact igna(Array{Nullable{Int}}(0)) --> Array{Int}(0)
  @fact igna(Array{Nullable{Int}}(0),1) --> Array{Int}(0)
  @fact_throws igna(@nalift([1,2,NA]))
  #@fact_throws igna(@nalift([1,2.0,NA])) # does not throw anymore in v0.5, because it is promoted to FloatNAArray.
  @fact igna(@nalift([1 3 NA]), 1) --> [1 3 1]
  @fact igna(@nalift([1 3.0 NA]), 1.0) --> [1 3.0 1] # it is now promoted to FloatNAArray in v0.5.
  #@fact igna(@nalift([1 3.0 NA]), 1) --> [1 3.0 1]
  @fact igna(Array{Nullable}(0), 1) --> Array{Nullable}(0)
  @fact igna(@nalift([1 3 5]), 1) --> [1 3 5]
  @fact igna(@nalift([1.0 3.0 NA]), 1.0) --> [1.0 3.0 1.0]
  @fact igna(@nalift([1.0 3.0 NA]))[3] --> isnan
  @fact igna(@nalift([1.0 3.0 5.0]), 1.0) --> [1.0 3.0 5.0]
  @fact igna([Nullable(1.0) Nullable(3.0) Nullable{Float64}()])[3] --> isnan
  @fact igna([Nullable(1.0) Nullable(3.0) Nullable(5.0)], 1.0) --> [1.0 3.0 5.0]
  @fact igna([Nullable(1.0) Nullable(3.0) Nullable{Float64}()], 1.0) --> [1.0 3.0 1.0]
  @fact isna(Nullable{Int}()) --> true
  @fact isna(Nullable(1)) --> false
  @fact isna(Nullable(1.0)) --> false
  @fact isna(@nalift([1 3 NA])) --> [false false true]
  @fact isna(@nalift([1 3 NA]), 2:3) --> [false false true][2:3]
  @fact isna(@nalift([1 3 5])) --> [false false false]
  @fact isna(@nalift([1.0 3.0 NA])) --> [false false true]
  @fact isna(@nalift([1.0 3.0 5.0])) --> [false false false]
  @fact isna(@nalift([1.0 3.0 5 NA])) --> [false false false true]
  @fact isna(@enumeration([:a :b NA;:d NA :f])) --> [false false true;false true false]
  @fact isna(@enumeration([:a :b NA;:d NA :f]), 1:2, 3) --> [false false true;false true false][1:2, 3]
  @fact isna([Nullable{Float64}() Nullable(1.0)]) --> [true false]
  @fact ignabool(nalift([true, false])) --> [true, false]
  @fact ignabool(Nullable{Bool}()) --> false
  @fact ignabool(Nullable(true)) --> true
  @fact ignabool(Nullable(false)) --> false
  @fact ignabool([Nullable(true), Nullable{Bool}()]) --> [true, false]
  @fact ignabool([Nullable(true)]) --> [true]
  @fact ignabool([Nullable(false)]) --> [false]
  @fact ignabool(true) --> true
  @fact ignabool(false) --> false
  @fact @nalift([NA NA]) --> wrap_array([Nullable{Any}() Nullable{Any}()])
  @fact @nalift([NA,NA]) --> wrap_array([Nullable{Any}(),Nullable{Any}()])
  @fact @nalift([NA NA;NA NA]) --> wrap_array(reshape(fill(Nullable{Any}(),4),2,2))
  @fact @nalift([1,NA]) --> wrap_array([Nullable(1), Nullable{Int}()])
  @fact @nalift([1 NA]) --> wrap_array([Nullable(1)  Nullable{Int}()])
  @fact @nalift([1 NA;NA NA]) --> wrap_array([Nullable(1)  Nullable{Int}();Nullable{Int}() Nullable{Int}()])
  @fact map(x->x, nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
  @fact map((x,y)->naop_plus(x, y), nalift([1.0,2.0,3.0]), nalift([2.0,3.0,4.0])) --> nalift([3.0,5.0,7.0])
  #@fact nalift(DataCubes.simplify_array(Any[larr(a=[1,2,3]), darr(b=[:a,:b,:c])])) --> DataCubes.simplify_array(Any[larr(a=[1,2,3]), darr(b=[:a,:b,:c])])
  #@fact nalift(DataCubes.simplify_array(Any[darr(a=[1,2,3]), darr(b=[:a,:b,:c])])) --> DataCubes.simplify_array(Any[darr(a=[1,2,3]), darr(b=[:a,:b,:c])])
  #@fact nalift(DataCubes.simplify_array(Any[larr(a=[1,2,3]), larr(b=[:a,:b,:c])])) --> DataCubes.simplify_array(Any[larr(a=[1,2,3]), larr(b=[:a,:b,:c])])
  @fact nalift(nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
  @fact pickaxis(larr(a=[1,2,3]),1) == nalift([1,2,3]) --> false
  @fact nalift([1,2,3]) == pickaxis(larr(a=[1,2,3]),1) --> false

  context("FloatNAArray tests") do
    @fact map(identity, FloatNAArray(Array{Float64}(0))) --> Array{Nullable{Any}}(0)
    @fact nalift([1.0,2.0]) --> DataCubes.wrap_array(FloatNAArray([1.0,2.0]))
    @fact FloatNAArray([1.0,2.0,3.0])[1].value --> 1.0
    @fact FloatNAArray([1.0,2.0,3.0])[1:2].data --> [1.0,2.0]
    @fact wrap_array(DataCubes.simplify_floatarray(FloatNAArray([1.0 2.0]))) --> wrap_array(FloatNAArray([1.0 2.0]))
    @fact typeof(DataCubes.simplify_floatarray(FloatNAArray(Array{Float64}(0)))) --> FloatNAArray{Float64,1,Array{Float64,1}}
    @fact nalift(nalift([1.0,2.0,3.0])) --> nalift([1.0,2.0,3.0])
    @fact typeof(igna(nalift(Array{Float64}(0)))) --> DataCubes.AbstractArrayWrapper{Float64,1,Array{Float64,1}}
    @fact typeof(igna(nalift(Array{Float64}(0)),3.0)) --> DataCubes.AbstractArrayWrapper{Float64,1,Array{Float64,1}}
    @fact (arr=nalift([1.0,2.0,3.0]);arr[1]=0.0;arr) --> nalift([0.0,2.0,3.0])
    @fact (arr=nalift([1.0,2.0,3.0]);arr[1]=Nullable{Float64}();arr) --> @nalift([NA,2.0,3.0])
    @fact (arr=nalift([1.0,2.0,3.0]);arr[1:2]=nalift([0.0,-1.0]) ;arr) --> nalift([0.0,-1.0,3.0])
    @fact (arr=nalift([1.0,2.0,3.0]);arr[1:2]=Nullable(1.0) ;arr) --> nalift([1.0,1.0,3.0])
    @fact typeof(1.0*nalift([1 2])) --> AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}}
    #@fact sub(1.0*nalift([1 2 3;4 5 6]),1:2,1:1) --> nalift([1.0 4.0]')
    @fact view(1.0*nalift([1 2 3;4 5 6]),1:2,1) --> nalift([1.0,4.0])
    #@fact sub(1.0*nalift([1 2 3;4 5 6]),(1:2,1:1)) --> nalift([1.0 4.0]')
    @fact view(1.0*nalift([1 2 3;4 5 6]),(1:2,1)) --> nalift([1.0,4.0])
  end
end

end
