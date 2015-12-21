module TestLabeledArray

using FactCheck
using MultidimensionalTables

facts("LabeledArray tests") do
  context("constructor tests") do
    col1 = nalift(rand(10, 50))
    col2 = nalift(reshape(1:500, 10, 50))
    col3 = nalift(reshape(map(i->string("sym_",i), 1:500), 10, 50))
    col4 = nalift(hcat(rand(10,30), fill(:testsym, 10, 20)))
    axis1c1 = DictArray(k1=nalift(collect(101:110)), k2=nalift(collect(201:210)))
    axis1c2 = nalift(map(i->string("a_",i), 1:50))
    d = DictArray(c1=col1, c2=col2, c3=col3, c4=col4)
    larr1 = LabeledArray(d, (axis1c1, axis1c2))
    larr2 = LabeledArray(d, axis1=axis1c1, axis2=axis1c2)
    @fact larr1 --> larr2
    @fact convert(LabeledArray, LabeledArray([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))],axis1=darr(k=[:x,:y]))) --> @larr(a=[3,5],b=[NA,3],axis1[darr(k=[:x,:y])])
    @fact convert(LabeledArray, LabeledArray(nalift([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]),axis1=darr(k=[:x,:y]))) --> @larr(a=[3,5],b=[NA,3],axis1[darr(k=[:x,:y])])
    @fact convert(LabeledArray, [LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]) --> @larr(a=[3,5],b=[NA,3])
    @fact convert(LabeledArray, nalift([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))])) --> @larr(a=[3,5],b=[NA,3])
    @fact @larr(a=[1,2,3],b=1,axis1[k=[:A,:B,:C]]) --> larr(a=[1,2,3],b=[1,1,1],axis1=darr(k=[:A,:B,:C]))
    @fact larr(@larr(a=[1,2,3],b=1,axis1[k=[:A,:B,:C]]), c=[:x,:y,:z], :d=>[1,2,3], axis1=darr(k=["X", "Y", "Z"])) --> larr(axis1=darr(k=["X","Y","Z"]), a=[1,2,3],b=[1,1,1],d=[1,2,3],c=[:x,:y,:z])
    @fact @larr(@larr(a=[1 NA;3 4;NA NA],:b=>[1.0 1.5;:sym 'a';"X" "Y"],c=1,axis1[:U,NA,:W],axis2[r=['m','n']]), c=[NA NA;3 4;5 6], :d=>:X, axis1[k=["g","h","i"]]) --> @larr(a=[1 NA;3 4;NA NA],b=[1.0 1.5;:sym 'a';"X" "Y"],c=[NA NA;3 4;5 6],d=reshape(fill(:X,6),3,2),axis2[r=['m','n']],axis1[k=["g","h","i"]])
  end
  context("array related method tests") do
    larr = LabeledArray(
      DictArray(:a=>nalift(reshape(1:20, 5, 4)),
                2=>nalift(fill(:sym, 5, 4)),
                :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4))),
          axis1=DictArray(k1=nalift(["a","a","b","b","b"]), k2=nalift(collect(101:105))),
          axis2=DictArray(r1=nalift([:alpha,:beta,:gamma,:delta])))
    @fact larr[3,2] --> LDict(:a=>Nullable(8), 2=>Nullable(:sym), :third=>Nullable("str_8"))
    @fact tbltool.getindexpair(larr,3,2).second.second --> LDict(:a=>Nullable(8), 2=>Nullable(:sym), :third=>Nullable("str_8"))
    @fact larr[1:3,2] --> LabeledArray(
                            DictArray(:a=>nalift([6,7,8]),
                                      2=>nalift([:sym,:sym,:sym]),
                                      :third=>nalift(["str_6","str_7","str_8"])),
                            axis1=DictArray(k1=nalift(["a","a","b"]), k2=nalift(collect(101:103))))
    @fact larr[2:2,2:4] --> LabeledArray(
                            DictArray(:a=>nalift([7 12 17]),
                                      2=>nalift([:sym :sym :sym]),
                                      :third=>nalift(["str_7" "str_12" "str_17"])),
                            axis1=DictArray(k1=nalift(["a"]), k2=nalift([102])),
                            axis2=DictArray(r1=nalift([:beta,:gamma,:delta])))
    @fact size(larr) --> (5,4)
    #@fact eltype(larr) --> LDict{Any}
    @fact pick(larr,:a)[1,1].value --> 1
    @fact pick(larr,(:a,))[1][1,1].value --> 1
    @fact endof(larr) --> length(larr)
    @fact transpose(larr) --> LabeledArray(DictArray(mapvalues(transpose, larr.data.data)),
                                           axis1=larr.axes[2],
                                           axis2=larr.axes[1])
    @fact permutedims(larr, (2,1)) --> transpose(larr)
    @fact LabeledArray(DictArray(a=nalift([1 2 3])), axes2=nalift([100,101,102])) ==
          LabeledArray(DictArray(a=nalift([1 2 3])), axes2=nalift([100,101,102])) --> true
    @fact copy(larr) !== larr --> true
    @fact size(cat(1, larr, larr)) --> ntuple(n->n==1 ? size(larr,1)*2 : size(larr,n), ndims(larr))
    @fact size(cat(2, larr, larr)) --> ntuple(n->n==2 ? size(larr,2)*2 : size(larr,n), ndims(larr))
    @fact size(repeat(larr, inner=[5,2], outer=[3,4])) --> (size(larr,1)*5*3, size(larr,2)*2*4)
    @fact @larr(a=[1 2 3;4 5 6], 'x'=[:a :b :c;:x :y :z])[:a] --> nalift([1 2 3;4 5 6])
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[:a,:b] --> Any[nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z])]
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[[:a,:b]] --> @darr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])
    @fact @larr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[(:a,:b)] --> (nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z]))
    @fact @larr(@larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[r=['a','b','c']]), axis1[[1,NA]],axis2[[3,NA,1]]) --> @larr(a=[1 2 3;4 5 6],axis1[1,NA],axis2[3,NA,1])
    @fact @larr(@larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[r=['a','b','c']]), axis2[[3,NA,1]]) --> @larr(a=[1 2 3;4 5 6],axis1[k=[:x,:y]],axis2[[3,NA,1]])
    @fact @larr([1 2 3;4 5 6]) --> LabeledArray(nalift([1 2 3;4 5 6]))
  end
  context("additional method tests") do
    d1 = larr(:a=>nalift(reshape(1:20, 5, 4)),
              2=>nalift(fill(:sym, 5, 4)),
              :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    d2 = larr(:x=>nalift(reshape(1:20, 5, 4)),
              :third=>nalift(fill(:sym, 5, 4)),
              :z=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    @fact pick(merge(d1, d2), [:a,2]) --> pick(d1, [:a,2])
    @fact pick(merge(d1, d2), [:x,:third,:z]) --> pick(d2, [:x,:third,:z])
    @fact keys(peel(merge(d1, d2))) --> Any[:a,2,:third,:x,:z]
    @fact delete(merge(d1, d2), :a,2,:third) --> pick(d2, [:x, :z])
    @fact pick(d1, [:a]) --> DictArray(a=pick(d1, :a))
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[1]) --> @larr(c=[2,2,2], axis1[r=[:m,:n,:p]])
    @fact mapslices(x->LDict(:c=>Nullable(length(x))),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"],axis1[k=[:x,:y]],axis2[r=[:m,:n,:p]]),[2]) --> @larr(c=[3,3], axis1[k=[:x,:y]])
    @fact mapslices(x->Nullable(length(x)),@larr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> LabeledArray(@nalift([2,2,2]), axes1=@nalift([1,2,3]))
    @fact size(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> (2,3)
    @fact mapslices(x->LDict(:c1=>MultidimensionalTables.naop_plus(x[:a],x[:b]),:c2=>Nullable(10)), @larr(a=[1 2 3;4 5 6],b=[1.0 2.0 3.0;4.0 5.0 6.0]), []) --> @larr(c1=[2.0 4.0 6.0;8.0 10.0 12.0], c2=@rap reshape(_,(2,3)) fill (10,6)...)
    #@fact typeof(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> Array{Pair{Nullable{Int64},Pair{Nullable{Int64},MultidimensionalTables.LDict{Symbol,Nullable{Int64}}}},2}
    @fact typeof(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> MultidimensionalTables.LabeledArray{MultidimensionalTables.LDict{Symbol,Nullable{Int64}},2,Tuple{MultidimensionalTables.DefaultAxis,MultidimensionalTables.DefaultAxis},MultidimensionalTables.DictArray{Symbol,2,MultidimensionalTables.AbstractArrayWrapper{Nullable{Int64},2,Array{Nullable{Int64},2}},Nullable{Int64}}}
    @fact eltype(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> MultidimensionalTables.LDict{Symbol,Nullable{Int64}}
    #@fact eltype(mapslices(identity, @larr(a=[1 2 3;4 5 6]), [])) --> Pair{Nullable{Int64},Pair{Nullable{Int64},MultidimensionalTables.LDict{Symbol,Nullable{Int64}}}}
    @fact mapslices(x -> x, @larr(a=[1 2 3;4 5 6]), []) --> @larr(a=[1 2 3;4 5 6])
    @fact map(x->LDict(:c=>x[:a]), @larr(a=[1,2,3],b=[4,5,6],axis1[[:x,:y,:z]])) --> @larr(c=[1,2,3],axis1[[:x,:y,:z]])
    @fact map(x->x[:a], @larr(a=[1,2,3],b=[4,5,6],axis1[[:x,:y,:z]])) --> @larr([1,2,3],axis1[[:x,:y,:z]])
    @fact tbltool.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(2)][LDict(:r=>Nullable(:z))][:a].value --> 6
    @fact collect(keys(tbltool.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)])) --> [LDict(:r=>Nullable(:x)), LDict(:r=>Nullable(:z))]
    @fact tbltool.create_dict(@larr(a=[1 NA NA;4 5 6],b=[NA NA 6; 7 8 9],axis2[r=[:x,:y,:z]]))[Nullable(1)][LDict(:r=>Nullable(:x))] --> LDict(:a=>Nullable(1), :b=>Nullable{Int}())
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[1]) --> @larr(a=[4 5 6;1 2 3],axis2[r=[:x,:y,:z]])
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2]) --> @larr(a=[3 2 1;6 5 4],axis2[r=[:z,:y,:x]])
    @fact reverse(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1:2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),2) --> @larr(a=[3 2 1;6 5 4],axis2[r=[:z,:y,:x]])
    @fact flipdim(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1,2) --> @larr(a=[6 5 4;3 2 1],axis2[r=[:z,:y,:x]])
    @fact reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),6) --> larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact reshape(larr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15],axis1=darr(k1=[:a,:b],k2=[100,101]),axis2=[:m,:n,:p]),1,6) --> @rap transpose reshape(_,6,1) larr(a=[1,4,2,5,3,6],b=[10,13,11,14,12,15], axis1=darr(k1=repmat([:a,:b],3),k2=repmat([100,101],3),x1=[:m,:m,:n,:n,:p,:p]))
    @fact reshape(larr([1 2 3;4 5 6],axis1=[10,11]),1,6) --> larr([1 4 2 5 3 6], axis2=repmat([10,11],3))
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1],0) --> larr([3 15 27 39;7 19 31 43;11 23 35 47])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1,2],0) --> larr([21,57,93,129])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4)),[1,2,3],0).value --> 300
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1],0) --> larr([3 15 27 39;7 19 31 43;11 23 35 47],axis2=[:x,:y,:z,:w])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1,2],0) --> larr([21,57,93,129],axis1=[:x,:y,:z,:w])
    @fact reducedim((x,y)->x+y[:a].value, larr(a=reshape(1:24,2,3,4),axis1=darr(k1=[:a,:b]),axis3=[:x,:y,:z,:w]),[1,2,3],0).value --> 300
    # runnability test when the result is empty.
    @fact size(@rap transpose @select((@rap transpose larr(r=rand(8,20), axis1=darr(a=rand(8),b=101:108))), :r=_r.*100, where[_r.>1])) --> (0,0)
    @fact reorder(larr('x'=>1:10, 3=>11:20, axis1=101:110), 3) --> larr(3=>11:20, 'x'=>1:10, axis1=101:110)
    @fact reorder(larr(c1=1:10,c2=11:20),:c2,:c1) --> reorder(larr(c1=1:10,c2=11:20),:c2)
    @fact reorder(larr(c1=1:10,c2=11:20),:c2,:c1) --> larr(c2=11:20,c1=1:10)
    @fact rename(larr('x'=>1:10, 3=>11:20, axis1=101:110), 1) --> larr(1=>1:10, 3=>11:20, axis1=101:110)
    @fact rename(larr(c1=1:10,c2=11:20),:a,:b) --> larr(a=1:10,b=11:20)
    @fact cat(1, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x' 'y' 'z'], d=[:m :n :p], axis1=[3])) --> larr(reshape(@larr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3), axis1=[:u,:v,3])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis1=[:u,:v]), larr(b=['x','y'], d=[:m,:n], axis1=[:u,:v])) --> larr(reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f','x','y'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[:u,:v])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), larr(b=[10,11], d=[:m,:n])) --> reshape(@larr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=darr(r=[:x,:y,:z])), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=@darr(r=[:x,:y,:z,NA]))
    # this will cause a NullException().
    #@fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'],axis1=[100,200]), larr(b=[10 11]', d=[:m :n]',axis1=[100,200],axis2=darr(r=[:k]))) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[100,200],axis2=[1,2,3,LDict(:r=>Nullable(:k))])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'],axis1=[100,200]), larr(b=[10 11]', d=[:m :n]',axis1=[100,200],axis2=[:k])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis1=[100,200],axis2=[1,2,3,:k])
    @fact cat(2, larr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f'], axis2=[:x,:y,:z]), larr(b=[10,11], d=[:m,:n])) --> larr(reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4), axis2=[Nullable(:x),Nullable(:y),Nullable(:z),Nullable{Symbol}()])
    @fact merge(larr(a=[1,2,3],b=[:x,:y,:z],axis1=[:a,:b,:c]),darr(c=[4,5,6],b=[:m,:n,:p]),darr(a=["X","Y","Z"])) --> larr(a=["X","Y","Z"],b=[:m,:n,:p],c=[4,5,6],axis1=[:a,:b,:c])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[2:-1:1,2] --> larr(a=[5,2])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[[2,1],2] --> larr(a=[5,2])
    @fact @larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]])[[2,1],2:3] --> larr(a=[5 6;2 3],axis2=darr(r=[:y,:z]))
    @fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2)
    @fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3) --> getindex(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2:3)
    @fact slice(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),[2,1],2) --> larr(a=[5,2])
    @fact slice(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=[2,3], axis1=darr(r=[:y,:z]))
    @fact sub(@larr(a=[1 2 3;4 5 6],axis2[r=[:x,:y,:z]]),1, 2:3) --> larr(a=[2 3], axis2=darr(r=[:y,:z]))
  end
end

end
