module TestEnumerationArray

using FactCheck
using DataCubes

facts("EnumerationArray tests") do
  @fact EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"])).elems --> Int[1 0 2 2;0 2 1 3]
  @fact EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"]).elems --> Int[2 0 3 3;0 3 2 1]
  @fact EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]))[2,2].value --> "b"
  @fact EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"])[2,2].value --> "b"
  @fact dcube.wrap_array(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]))[1:3]) --> dcube.wrap_array(EnumerationArray(@nalift(["a",NA,NA])))
  @fact dcube.wrap_array(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"])[1:3]) --> dcube.wrap_array(EnumerationArray(@nalift(["a",NA,NA]), ["c","a","b"]))
  @fact size(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"])) --> (2, 4)
  @fact dcube.wrap_array(reshape(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"]), 4, 2)) --> dcube.wrap_array(transpose(EnumerationArray(@nalift(["a" NA  NA "b";"b" "a" "b" "c"]), ["c","a","b"])))
  @fact dcube.wrap_array(transpose(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"]))) --> dcube.wrap_array(EnumerationArray(@nalift(["a" NA;NA "b";"b" "a";"b" "c"])))
  @fact dcube.wrap_array(transpose(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"]))) --> dcube.wrap_array(permutedims(EnumerationArray(@nalift(["a" NA "b" "b";NA "b" "a" "c"]), ["c","a","b"]), (2,1)))
  @fact dcube.wrap_array(reverse(enumeration(["hello", "hello", "hi"]))) --> dcube.wrap_array(enumeration(["hi", "hello", "hello"]))
  @fact dcube.wrap_array((a=enumeration([:a,:b,:c]);a[2]=Nullable{Symbol}();a)) --> dcube.wrap_array(@enumeration([:a,NA,:c],[:a,:b,:c]))
  @fact dcube.wrap_array((a=enumeration([:x,:y]);copy!(a, enumeration([:m,:n]));a)) --> dcube.wrap_array(enumeration([:m,:n]))
  @fact_throws enumeration([1 2.0 NA])
  @fact_throws enumeration([1 2.0 NA],[2.0,1])
  @fact sort(enumeration([6,5,3,1,2,1])) --> nalift([6,5,3,1,1,2])
  @fact sort!(enumeration([6,5,3,1,2,1])) --> nalift([6,5,3,1,1,2])

  context("enumerations in labeled array tests") do
    arr = larr(
                :a=>enumeration(reshape(repeat(collect(1:4),inner=[1],outer=[5]),5,4)),
                :b=>2.0*nalift(reshape(1:20,5,4)),
                2=>enumeration(map(i->symbol(:sym,i), reshape(repeat(collect(1:4),inner=[1],outer=[5]),5,4))),
                :third=>enumeration(map(i->string(:str,i), reshape(repeat(collect(1:4),inner=[1],outer=[5]),5,4))),
          axis1=DictArray(k1=nalift(["a","a","b","b","b"]), k2=nalift(collect(101:105))),
          axis2=DictArray(r1=nalift([:alpha,:beta,:gamma,:delta])))
    @fact arr[3,2] --> LDict(:a=>Nullable(4), :b=>Nullable(16.0), 2=>Nullable(:sym4), :third=>Nullable("str4"))
    @fact dcube.getindexpair(arr,3,2).second.second --> LDict(:a=>Nullable(4), :b=>Nullable(16.0), 2=>Nullable(:sym4), :third=>Nullable("str4"))
    @fact arr[1:3,2] --> LabeledArray(
                            DictArray(:a=>nalift([2,3,4]),
                                      :b=>nalift([12.0,14.0,16.0]),
                                      2=>nalift([:sym2,:sym3,:sym4]),
                                      :third=>nalift(["str2","str3","str4"])),
                            axis1=DictArray(k1=nalift(["a","a","b"]), k2=nalift(collect(101:103))))
    @fact typeof(arr[1:3,2].data.data[:a]) --> DataCubes.AbstractArrayWrapper{Nullable{Int64},1,DataCubes.EnumerationArray{Int64,1,DataCubes.AbstractArrayWrapper{Int64,1,Array{Int64,1}},Int64}}
    @fact arr[2:2,2:4] --> LabeledArray(
                            DictArray(:a=>nalift([3 4 1]),
                                      :b=>nalift([14.0 24.0 34.0]),
                                      2=>nalift([:sym3 :sym4 :sym1]),
                                      :third=>nalift(["str3" "str4" "str1"])),
                            axis1=DictArray(k1=nalift(["a"]), k2=nalift([102])),
                            axis2=DictArray(r1=nalift([:beta,:gamma,:delta])))
    @fact size(arr) --> (5,4)
    #@fact eltype(arr) --> LDict{Any}
    @fact pick(arr,:a)[1,1].value --> 1
    @fact pick(arr,:b)[1,1].value --> 2.0
    @fact pick(arr,(:a,))[1][1,1].value --> 1
    @fact pick(arr,(:b,))[1][1,1].value --> 2.0
    @fact endof(arr) --> length(arr)
    @fact transpose(arr) --> LabeledArray(DictArray(mapvalues(transpose, arr.data.data)),
                                           axis1=arr.axes[2],
                                           axis2=arr.axes[1])
    @fact permutedims(arr, (2,1)) --> transpose(arr)
    @fact copy(arr) !== arr --> true
    @fact size(cat(1, arr, arr)) --> ntuple(n->n==1 ? size(arr,1)*2 : size(arr,n), ndims(arr))
    @fact size(cat(2, arr, arr)) --> ntuple(n->n==2 ? size(arr,2)*2 : size(arr,n), ndims(arr))
    @fact size(repeat(arr, inner=[5,2], outer=[3,4])) --> (size(arr,1)*5*3, size(arr,2)*2*4)

    d1 = larr(:a=>enumeration(reshape(1:20, 5, 4)),
              2=>enumeration(fill(:sym, 5, 4)),
              :third=>enumeration(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    d2 = larr(:x=>enumeration(reshape(1:20, 5, 4)),
              :third=>enumeration(fill(:sym, 5, 4)),
              :z=>enumeration(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    @fact pick(merge(d1, d2), [:a,2]) --> pick(d1, [:a,2])
    @fact pick(merge(d1, d2), [:x,:third,:z]) --> pick(d2, [:x,:third,:z])
    @fact keys(peel(merge(d1, d2))) --> Any[:a,2,:third,:x,:z]
    @fact delete(merge(d1, d2), :a,2,:third) --> pick(d2, [:x, :z])
    @fact pick(d1, [:a]) --> DictArray(a=pick(d1, :a))
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=enumeration([1 2 3;4 5 6]),b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[1]) --> @larr(c=[2,2,2], axis1[r=[:m,:n,:p]])
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=enumeration([1 2 3;4 5 6]),b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[2]) --> @larr(c=[3,3], axis1[k=[:x,:y]])
    @fact mapslices(x->Nullable(length(x)),@larr(a=enumeration([1 2 3;4 5 6]),b=["a" "b" "c";"d" "e" "f"]),[1]) --> LabeledArray(@nalift([2,2,2]), axes1=@nalift([1,2,3]))
    @fact size(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> (2,3)
    @fact mapslices(x->LDict(:c1=>DataCubes.naop_plus(x[:a],x[:b]),:c2=>Nullable(10)), @larr(a=enumeration([1 2 3;4 5 6]),b=[1.0 2.0 3.0;4.0 5.0 6.0]), []) --> @larr(c1=[2.0 4.0 6.0;8.0 10.0 12.0], c2=@rap reshape(_,(2,3)) fill (10,6)...)
    @fact mapslices(x -> x, @larr(a=enumeration([1 2 3;4 5 6])), []) --> @larr(a=[1 2 3;4 5 6])
    @fact map(x->x[:a], @larr(a=enumeration([1,2,3]),b=[4,5,6],axis1[[:x,:y,:z]])) --> @larr([1,2,3],axis1[[:x,:y,:z]])
    @fact dcube.create_dict(@larr(a=@enumeration([1 NA NA;4 5 6]),b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(2)][LDict(:r=>Nullable(:z))][:a].value --> 6
    @fact collect(keys(dcube.create_dict(@larr(a=@enumeration([1 NA NA;4 5 6]),b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)])) --> [LDict(:r=>Nullable(:x)), LDict(:r=>Nullable(:z))]
    @fact dcube.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)][LDict(:r=>Nullable(:x))] --> LDict(:a=>Nullable(1), :b=>Nullable{Int}())
    @fact reverse(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=enumeration([:x,:y,:z])]),[1]) --> @larr(a=[4 5 6;1 2 3],axis2[r=[:x,:y,:z]])
    @fact reverse(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),1:2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=[1 2 3;4 5 6],axis2[r=enumeration([:x,:y,:z])]),2) --> @larr(a=[3 2 1;6 5 4],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),1,2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact reshape(larr(a=enumeration([1 2 3;4 5 6]),b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),6) --> larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact reshape(larr(a=[1 2 3;4 5 6],b=enumeration([10 11 12;13 14 15]),axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),1,6) --> @rap transpose reshape(_,6,1) larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat(enumeration([:a,:b]),3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact reshape(larr([1 2 3;4 5 6],axis1=[10,11]),1,6) --> larr([1 4 2 5 3 6], axis2=repmat([10,11],3))
    @fact reducedim((x,y)->x+y[:a].value, larr(a=enumeration(reshape(1:24,2,3,4))),[1],0) --> @larr([3 15 27 39;7 19 31 43;11 23 35 47])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=enumeration(reshape(24:-1:1,2,3,4))),[1,2,3],0).value --> 300
    @fact reducedim((x,y)->x+y[:a].value, larr(a=enumeration(reshape(1:24,2,3,4)),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1,2,3],0).value --> 300
    # runnability test when the result is empty.
    @fact size(@rap transpose @select((@rap transpose larr(r=enumeration(rand(8,20)), axis1=darr(a=rand(8),b=101:108))), :r=_r.*100, where[_r.>1])) --> (0,0)
    @fact cat(1, larr(a=enumeration([1 2 3;4 5 6]), b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x' 'y' 'z'], d=[:m :n :p], axis1=[3])) --> larr(reshape(@larr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3), axis1=[:u,:v,3])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x','y'], d=[:m,:n], axis1=[:u,:v])) --> larr(reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f','x','y'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[:u,:v])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=enumeration(['a' 'b' 'c';'d' 'e' 'f'])), larr(b=[10,11], d=[:m,:n])) --> reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, larr(a=enumeration([1 2 3;4 5 6]), b=['a' 'b' 'c';'d' 'e' 'f'], axis2=darr(r=[:x,:y,:z])), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=@darr(r=[:x,:y,:z,NA]))
    @fact sub(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),[2,1],2) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2)
    @fact sub(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),[2,1],2:3) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3)
    @fact slice(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),[2,1],2) --> larr(a=[5,2])
    @fact slice(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=[2,3], axis1=darr(r=[:y,:z]))
    @fact sub(@larr(a=enumeration([1 2 3;4 5 6]),axis2[r=enumeration([:x,:y,:z])]),1, 2:3) --> larr(a=[2 3], axis2=darr(r=[:y,:z]))
    @fact endof(@enumeration([1,2,3,NA,5])) --> 5
    @fact nalift((a=enumeration([10,20,30,10,20]);a[1]=3;a)) --> nalift([30,20,30,10,20])
    @fact DataCubes.wrap_array((a=enumeration([1,2,3]);copy!(a, nalift([3,2,1]));a)) --> DataCubes.wrap_array(enumeration([3,2,1],[1,2,3]))
    @fact DataCubes.wrap_array((a=enumeration([1,2,3]);copy!(a, enumeration([3,2,1]));a)) --> DataCubes.wrap_array(enumeration([3,2,1]))
  end
end

end
