module TestDictArray

using FactCheck
using DataCubes
using DataCubes.setna!

facts("DictArray tests") do
  context("constructor tests") do
    context("basic tests") do
      col1 = nalift(rand(10, 50))
      col2 = nalift(reshape(1:500, 10, 50))
      col3 = nalift(reshape(map(i->string("sym_",i), 1:500), 10, 50))
      col4 = nalift(hcat(rand(10,30), fill(:testsym, 10, 20)))
      d1 = DictArray(c1=col1, c2=col2, c3=col3, c4=col4)
      d2 = DictArray(LDict([:c3, :c4, :c1, :c2], Any[col3, col4, col1, col2]), [:c1, :c2, :c3, :c4])
      d3 = DictArray(:c1=>col1, :c2=>col2, :c3=>col3, :c4=>col4)
      d4 = DictArray((:c1,col1), (:c2,col2), (:c3,col3), (:c4,col4))
      @fact d1 --> d2
      @fact d2 --> d3
      @fact d3 --> d4
      @fact darr(Any[LDict(:a=>Nullable(1),:b=>Nullable{Int}()),LDict(:a=>Nullable(3),:b=>Nullable(4))]) --> @darr(a=[1,3], b=[NA,4])
      @fact convert(DictArray, [LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))]) --> @darr(a=[3,5],b=[NA,3])
      @fact convert(DictArray, nalift([LDict(:a=>Nullable(3),:b=>Nullable{Int}()), LDict(:a=>Nullable(5),:b=>Nullable(3))])) --> @darr(a=[3,5],b=[NA,3])
    end
    context("constructing DictArrays with null elements...") do
      col1 = nalift(rand(10, 50))
      setna!(col1, 5:10,1:30)
      col2 = nalift(reshape(1:500, 10, 50))
      setna!(col2, 1:7,40:45)
      col3 = nalift(reshape(map(i->string("str_",i), 1:500), 10, 50))
      setna!(col3, 2:10,1:20)
      col4 = nalift(hcat(rand(10,30), fill(:testsym, 10, 20)))
      setna!(col4, 5:10,30:40)
      d1 = DictArray(c1=col1, c2=col2, c3=col3, c4=col4)
      d2 = DictArray(LDict([:c3, :c4, :c1, :c2], Any[col3, col4, col1, col2]), [:c1, :c2, :c3, :c4])
      d3 = DictArray(:c1=>col1, :c2=>col2, :c3=>col3, :c4=>col4)
      d4 = DictArray((:c1,col1), (:c2,col2), (:c3,col3), (:c4,col4))
      @fact d1 --> d2
      @fact d2 --> d3
      @fact d3 --> d4
      @fact darr(darr(a=[1 2;3 4;5 6],b=["abc" 'a';1 2;:m "xyz"],:c=>[1.0 1.5;:sym 'a';"X" "Y"]), c=[1 2;3 4;5 6], :d=>map(Nullable, [1 2;3 4;5 6])) --> @darr(:c=>[1 2;3 4;5 6],:a=>[1 2;3 4;5 6],:b=>["abc" 'a';1 2;:m "xyz"],:d=>[1 2;3 4;5 6])
      @fact @darr(a=[1,2,3],b=1) --> darr(a=[1,2,3],b=[1,1,1])
    end
  end
  context("array related method tests") do
    d = DictArray(:a=>nalift(reshape(1:20, 5, 4)),
                  :b=>2.0*nalift(reshape(1:20, 5, 4)),
                  2=>nalift(fill(:sym, 5, 4)),
                  :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    @fact d[3,2] --> LDict(:a=>Nullable(8), :b=>Nullable(16.0), 2=>Nullable(:sym), :third=>Nullable("str_8"))
    @fact d[1:3,2] --> DictArray(:a=>nalift([6,7,8]),:b=>nalift([12.0,14.0,16.0]),2=>nalift([:sym,:sym,:sym]),:third=>nalift(["str_6","str_7","str_8"]))
    @fact d[2:2,2:4] --> DictArray(:a=>nalift([7 12 17]),:b=>nalift([14.0 24.0 34.0]),2=>nalift([:sym :sym :sym]),:third=>nalift(["str_7" "str_12" "str_17"]))
    @fact findfirst(d, LDict(:a=>Nullable(8), :b=>Nullable(16.0), 2=>Nullable(:sym), :third=>Nullable("str_8"))) --> 8
    @fact (setindex!(d,LDict(:a=>Nullable(108),:b=>Nullable(216.0),2=>Nullable(:newsym),:third=>Nullable("newstr_8")), 3, 2);d[3,2]) -->
      LDict(:a=>Nullable(108),:b=>Nullable(216.0),2=>Nullable(:newsym),:third=>Nullable("newstr_8"))
    @fact (setindex!(d,Dict(:a=>Nullable(105),:b=>Nullable(210.0),2=>Nullable(:newsym2),:third=>Nullable("newstr_8")), 3, 2);d[3,2]) -->
      LDict(:a=>Nullable(105),:b=>Nullable(210.0),2=>Nullable(:newsym2),:third=>Nullable("newstr_8"))
    @fact (setindex!(d,(Nullable(1008),Nullable(2016.0),Nullable(:newsym3),Nullable("newstr_80")), 3, 2);d[3,2]) -->
      LDict(:a=>Nullable(1008),:b=>Nullable(2016.0),2=>Nullable(:newsym3),:third=>Nullable("newstr_80"))
    @fact (setindex!(d,
                     DictArray(:a=>nalift(reshape(collect(100:108),3,3)),
                     :b=>nalift(2.0*reshape(collect(100:108),3,3)),
                     2=>nalift(fill(:newval,3,3)),
                     :third=>nalift(fill("newstr",3,3))),
                     2:4, 1:3);d[2,1]) -->
      LDict(:a=>Nullable(100),:b=>Nullable(200.0),2=>Nullable(:newval),:third=>Nullable("newstr"))
    @fact size(d) --> (5,4)
    #@fact eltype(d) --> LDict{Any}
    #@fact eltype(pick(d,[:a,:third])) --> LDict{Symbol}
    @fact pick(d,:a)[1,1].value --> 1
    @fact pick(d,:b)[1,1].value --> 2.0
    @fact pick(d,(:a,))[1][1,1].value --> 1
    @fact pick(d,(:b,))[1][1,1].value --> 2.0
    @fact peel(d)[:a][2,2].value --> 103
    @fact peel(d)[:b][2,2].value --> 206.0
    @fact pick(d, 2) --> peel(d)[2]
    @fact endof(d) --> length(d)
    @fact transpose(d) --> DictArray(mapvalues(transpose, d.data))
    @fact permutedims(d, (1,2)) --> DictArray(mapvalues(v->permutedims(v,(1,2)), d.data))
    @fact DictArray(a=nalift([1,2,3]),b=nalift([1.0,2.0,3.0])) == DictArray(a=nalift([1,2,3]),b=nalift([1.0,2.0,3.0])) --> true
    @fact copy(d) !== d --> true
    @fact size(cat(1, d, d)) --> ntuple(n->n==1 ? size(d,1)*2 : size(d,n), ndims(d))
    @fact size(cat(2, d, d)) --> ntuple(n->n==2 ? size(d,2)*2 : size(d,n), ndims(d))
    @fact size(vcat(d, d)) --> ntuple(n->n==1 ? size(d,1)*2 : size(d,n), ndims(d))
    @fact size(hcat(d, d)) --> ntuple(n->n==2 ? size(d,2)*2 : size(d,n), ndims(d))
    @fact size(repeat(d, inner=[5,2], outer=[3,4])) --> (size(d,1)*5*3, size(d,2)*2*4)
    @fact @darr(a=[1 2 3;4 5 6], 'x'=[:a :b :c;:x :y :z])[:a] --> nalift([1 2 3;4 5 6])
    @fact @darr(a=1.0*[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[:a,:b] --> Any[1.0*nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z])]
    @fact @darr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[[:a,:b]] --> @darr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])
    @fact @darr(a=[1 2 3;4 5 6], b=[:a :b :c;:x :y :z])[(:a,:b)] --> (nalift([1 2 3;4 5 6]), nalift([:a :b :c;:x :y :z]))
  end
  context("additional method tests") do
    d1 = darr(:a=>nalift(reshape(1:20, 5, 4)),
              2=>nalift(fill(:sym, 5, 4)),
              :third=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    d2 = darr(:x=>nalift(reshape(1:20, 5, 4)),
              :third=>nalift(fill(:sym, 5, 4)),
              :z=>nalift(reshape(map(i->string("str_",i), 1:20), 5, 4)))
    @fact pick(merge(d1, d2), [:a,2]) --> pick(d1, [:a,2])
    @fact pick(merge(d1, d2), [:x,:third,:z]) --> pick(d2, [:x,:third,:z])
    @fact merge(d1, d2).data.keys --> Any[:a,2,:third,:x,:z]
    @fact delete(merge(d1, d2), :a,2,:third) --> pick(d2, [:x, :z])
    @fact pick(d1, [:a]) --> DictArray(a=pick(d1, :a))
    @fact mapslices(x->x,@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[]) --> @darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"])
    #@fact mapslices(x->x,@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> Any[@darr(a=[1,4], b=["a","d"]),@darr(a=[2,5], b=["b","e"]),@darr(a=[3,6],b=["c","f"])]
    @fact mapslices(x->x,@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> @darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"])
    @fact mapslices(x->x[1],@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> @darr(a=[1,2,3], b=["a","b","c"])
    @fact mapslices(x->x[1],@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[2]) --> @darr(a=[1,4], b=["a","d"])
    @fact mapslices(length,@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[1]) --> @rap @nalift [2,2,2]
    @fact mapslices(length,@darr(a=[1 2 3;4 5 6],b=["a" "b" "c";"d" "e" "f"]),[2]) --> @rap @nalift [3,3]
    @fact mapslices(x->sum(map(x->x.value,peel(x)[:a])),@darr(a=[1,2,3]),[1]).value --> 6
    @fact mapslices(x->x,@larr(a=[1,2,3]),[1]) --> @larr(a=[1,2,3])
    @fact mapslices(x->x,@larr(a=[1,2,3]), [1]) --> mapslices(x->x,@larr(a=[1,2,3]), [])
    @fact mapslices(identity, @darr(a=[1 2 3;4 5 6]), []) --> @darr(a=[1 2 3;4 5 6])
    @fact mapslices(x->darr(b=x[:a]+10),darr(a=[10,9]),[1]) --> darr(b=[20,19])
    @fact mapslices(x->(x=x[:a].value;[x,x+1,x+10]),darr(a=[10,9]),[]) --> nalift([10 9;11 10;20 19])
    @fact mapslices(x->msum(x), darr(a=reshape(1:15,5,3), b=1.0*reshape(1:15,5,3)), [1]) --> @update(darr(a=[1 6 11;3 13 23;6 21 36;10 30 50;15 40 65]), b=1.0*_a)
    @fact mapslices(x->msum(x), darr(a=reshape(1:15,5,3), b=1.0*reshape(1:15,5,3)), [2]) --> update(darr(a=[1 2 3 4 5;7 9 11 13 15;18 21 24 27 30]), :b=>d->1.0*d[:a])

    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [1]) --> darr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2))
    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [1]) --> darr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2))
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2))
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O], axis1=[:m,:n,:p,:q]), darr(a=rand(3,5,2)), [1]) --> larr(l=reshape(repeat(collect(1:4),outer=[10]),4,5,2),p=reshape(repeat([:U,:V,:W,:O],outer=[10]),4,5,2),axis1=[:m,:n,:p,:q])
    @fact mapslices(x->[11,21,31,41], darr(a=rand(3,5,2)), [1]) --> reshape(repeat(nalift([11,21,31,41]),outer=[10]),4,5,2)

    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [2]) --> darr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2))
    @fact mapslices(x->darr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [2]) --> darr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2))
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O]), darr(a=rand(3,5,2)), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2))
    @fact mapslices(x->larr(:l=>[1,2,3,4],:p=>[:U,:V,:W,:O], axis1=[:m,:n,:p,:q]), darr(a=rand(3,5,2)), [2]) --> larr(l=reshape(repeat(collect(1:4),outer=[6]),4,3,2),p=reshape(repeat([:U,:V,:W,:O],outer=[6]),4,3,2),axis1=[:m,:n,:p,:q])
    @fact mapslices(x->[11,21,31,41], darr(a=rand(3,5,2)), [2]) --> reshape(repeat(nalift([11,21,31,41]),outer=[6]),4,3,2)
    @fact mapslices(x->x[:a][1,1].value==1 ? LDict(:a=>Nullable(1)) : LDict(:b=>nalift([1 2 3])), darr(a=[1 2 3;4 5 6]),[1]) --> nalift(DataCubes.simplify_array(Any[LDict(:a=>1), LDict(:b=>[1 2 3]), LDict(:b=>[1 2 3])]))
    @fact (i=0;mapslices(x->x[:a][1,1].value<=2 ? (i+=1;LDict(:a=>i)) : LDict(:b=>-1), darr(a=[1 2 3;4 5 6]),[1])) --> nalift(DataCubes.simplify_array(Any[LDict(:a=>1), LDict(:a=>2), LDict(:b=>-1)]))
    @fact (i=0;mapslices(x->x[:a][1,1].value<=2 ? (i+=1;LDict(:a=>i)) : LDict(:a=>-1), darr(a=[1 2 3;4 5 6]),[1])) --> darr(a=[1,2,-1])
    @fact mapslices(x->[1], darr(a=Int[]), [1])  --> isnull
    @fact size(mapslices(x->[1], darr(a=rand(0,5,3)), [2])) --> (0,3)

    @fact sub(darr(a=1.0*[1 2 3;4 5 6]),2:2,1:2) --> darr(a=1.0*[4 5])
    @fact slice(darr(a=1.0*[1 2 3;4 5 6]),2:2,1:2) --> darr(a=1.0*[4 5])
    @fact typeof(repeat(darr(a=1.0*[1 2 3;4 5 6]), inner=[2,1], outer=[1,3])) --> DataCubes.DictArray{Symbol,2,DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}},Nullable{Float64}}
    @fact reshape(darr(a=1.0*[1 3 5;2 4 6]), 1, 6) --> darr(a=1.0*[1 2 3 4 5 6])
    @fact typeof(reshape(darr(a=1.0*[1 3 5;2 4 6]), 1, 6)) --> DictArray{Symbol,2,DataCubes.AbstractArrayWrapper{Nullable{Float64},2,DataCubes.FloatNAArray{Float64,2,Array{Float64,2}}},Nullable{Float64}}
    @fact (1.0*nalift([1 2 3]))[CartesianIndex((1,2))].value --> 2.0
    @fact (a=1.0*nalift([1 2 3]);a[1,2]=5.0;a) --> 1.0*nalift([1 5 3])
    @fact (a=1.0*nalift([1 2 3]);a[2]=5.0;a) --> 1.0*nalift([1 5 3])
    @fact (a=1.0*nalift([1 2 3]);a[1:2]=[5.0 1.0];a) --> 1.0*nalift([5 1 3])
    @fact repeat(darr(a=1.0*[1 2;3 4]), inner=[2,1], outer=[1,3]) --> darr(a=1.0*[1 2 1 2 1 2;1 2 1 2 1 2;3 4 3 4 3 4;3 4 3 4 3 4])
    @fact repeat(darr(a=enumeration([1 2;3 4])), inner=[2,1], outer=[1,3]) --> darr(a=enumeration([1 2 1 2 1 2;1 2 1 2 1 2;3 4 3 4 3 4;3 4 3 4 3 4]))
    @fact repmat(darr(a=enumeration([1 2 3;4 5 6])), 2) --> darr(a=[1 2 3;4 5 6;1 2 3;4 5 6])
    @fact typeof(repmat(darr(a=enumeration([1 2;3 4])), 2, 2).data[:a]) --> DataCubes.AbstractArrayWrapper{Nullable{Int64},2,DataCubes.EnumerationArray{Int64,2,DataCubes.AbstractArrayWrapper{Int64,2,Array{Int64,2}},Int64}}
    @fact repmat(darr(a=enumeration([1 2;3 4])), 2, 2) --> darr(a=[1 2 1 2;3 4 3 4;1 2 1 2;3 4 3 4])
    @fact map(x->LDict(:c=>x[:a]), @darr(a=[1,2,3],b=[4,5,6])) --> @darr(c=[1,2,3])
    @fact map(x->x[:a], @darr(a=[1,2,3],b=[4,5,6])) --> nalift([1,2,3])
    @fact reverse(@darr(a=[1 2 3;4 5 6])) --> @darr(a=[4 5 6;1 2 3])
    @fact reverse(@darr(a=[1 2 3;4 5 6]),[1]) --> @darr(a=[4 5 6;1 2 3])
    @fact reverse(@darr(a=[1 2 3;4 5 6]),1:2) --> @darr(a=[6 5 4;3 2 1])
    @fact reverse(@darr(a=[1 2 3;4 5 6]),[2,1]) --> @darr(a=[6 5 4;3 2 1])
    @fact reverse(@darr(a=[1 2 3;4 5 6]),2:-1:1) --> @darr(a=[6 5 4;3 2 1])
    @fact flipdim(@darr(a=[1 2 3;4 5 6]), 1, 2) --> @darr(a=[6 5 4;3 2 1])
    @fact flipdim(@darr(a=[1 2 3;4 5 6]), 1) --> @darr(a=[4 5 6;1 2 3])
    @fact larr(darr(a=1:10), axis1=11:20) --> larr(larr(a=1:10), axis1=11:20)
    @fact larr(darr(a=1:10), axis1=11:20) --> larr(a=1:10, axis1=11:20)
    @fact fill(LDict('a'=>1, 'b'=>10), 10, 20) --> darr('a'=>fill(1,10,20), 'b'=>fill(10,10,20))
    @fact reshape(darr(a=[1 2 3;4 5 6],b=[10 11 12;13 14 15]), 3, 2) --> darr(a=[1 5;4 3;2 6],b=[10 14;13 12;11 15])
    @fact reducedim((x,y)->LDict(:a=>Nullable(x[:a].value+y[:a].value)), darr(a=[1 2 3;4 5 6]),[1],LDict(:a=>Nullable(0))) --> darr(a=[5,7,9])
    @fact reducedim((x,y)->x+y[:a].value, darr(a=[1 2 3;4 5 6]),[1],0) --> nalift([5,7,9])
    @fact reducedim((x,y)->x+y[:a].value, darr(a=[1 2 3;4 5 6]),[2],0) --> nalift([6,15])
    @fact reducedim((x,y)->x+y[:a].value, darr(a=[1 2 3;4 5 6]),[1,2],0).value --> 21
    @fact reorder(darr('x'=>1:10, 3=>11:20), 3) --> darr(3=>11:20, 'x'=>1:10)
    @fact reorder(darr(c1=1:10,c2=11:20),:c2,:c1) --> reorder(darr(c1=1:10,c2=11:20),:c2)
    @fact reorder(darr(c1=1:10,c2=11:20),:c2,:c1) --> darr(c2=11:20,c1=1:10)
    @fact rename(darr('x'=>1:10, 3=>11:20), 1) --> darr(1=>1:10, 3=>11:20)
    @fact rename(darr(c1=1:10,c2=11:20),:a,:b) --> darr(a=1:10,b=11:20)
    @fact cat(1, darr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), darr(b=['x' 'y' 'z'], d=[:m :n :p])) --> reshape(@darr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3)
    @fact cat(2, darr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), darr(b=['x','y'], d=[:m,:n])) --> reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f','x','y'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, darr(a=[1 2 3;4 5 6], b=['a' 'b' 'c';'d' 'e' 'f']), darr(b=[10,11], d=[:m,:n])) --> reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(1,darr(k=[1 2 3]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0;4.0 5.0 6.0])
    @fact cat(1,darr(k=[1.0 2.0 3.0]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0;4.0 5.0 6.0])
    @fact vcat(darr(k=[1.0 2.0 3.0]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0;4.0 5.0 6.0])
    @fact hcat(darr(k=[1.0 2.0 3.0]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0 4.0 5.0 6.0])
    @fact cat(1, darr(a=enumeration([1 2 3;4 5 6]), b=enumeration(['a' 'b' 'c';'d' 'e' 'f'],['x','y','z','a','b','c','d','e','f'])), darr(b=enumeration(['x' 'y' 'z'],['x','y','z','a','b','c','d','e','f']), d=[:m :n :p])) --> reshape(@darr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3)
    @fact vcat(darr(a=enumeration([1 2 3;4 5 6]), b=enumeration(['a' 'b' 'c';'d' 'e' 'f'],['x','y','z','a','b','c','d','e','f'])), darr(b=enumeration(['x' 'y' 'z'],['x','y','z','a','b','c','d','e','f']), d=[:m :n :p])) --> reshape(@darr(a=[1,4,NA,2,5,NA,3,6,NA],b=['a','d','x','b','e','y','c','f','z'],d=[NA,NA,:m,NA,NA,:n,NA,NA,:p]), 3, 3)
    @fact cat(2, darr(a=[1 2 3;4 5 6], b=enumeration(['a' 'b' 'c';'d' 'e' 'f'],['a','b','c','d','e','f'])), darr(b=enumeration(['a','b'],['a','b','c','d','e','f']), d=[:m,:n])) --> reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f','a','b'], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(2, darr(a=enumeration([1 2 3;4 5 6]), b=['a' 'b' 'c';'d' 'e' 'f']), darr(b=[10,11], d=[:m,:n])) --> reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact hcat(darr(a=enumeration([1 2 3;4 5 6]), b=['a' 'b' 'c';'d' 'e' 'f']), darr(b=[10,11], d=[:m,:n])) --> reshape(@darr(a=[1,4,2,5,3,6,NA,NA], b=['a','d','b','e','c','f',10,11], d=[NA,NA,NA,NA,NA,NA,:m,:n]), 2, 4)
    @fact cat(1,darr(k=[1 2 3]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0;4.0 5.0 6.0])
    @fact cat(1,darr(k=[1.0 2.0 3.0]),darr(k=[4.0 5.0 6.0])) --> darr(k=[1.0 2.0 3.0;4.0 5.0 6.0])
    @fact show(darr(a=rand(2))) --> nothing
    @fact show(darr(a=rand(2,3))) --> nothing
    @fact show(darr(a=rand(2,3,2))) --> nothing
    @fact show(darr(a=rand(2,3,2,2))) --> nothing

    context("show tests") do
      @fact show(darr(a=[])) --> nothing
      @fact show(darr(a=rand(2))) --> nothing
      @fact show(darr(a=rand(2,3))) --> nothing
      @fact show(darr(a=rand(2,3,2))) --> nothing
      @fact show(darr(a=rand(2,3,2,2))) --> nothing
      @fact show(darr(a=rand(2,3,2,2))) --> nothing
      @fact (dcube.set_showsize!!(5,5);show(darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_showheight!!(3);show(darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_showwidth!!(3);show(darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_default_showsize!!();nothing) --> nothing
      @fact (dcube.set_showalongrow!!(false);show(darr(a=rand(3),b=rand(3),c=fill(:X,3)))) --> nothing
      @fact (dcube.set_showalongrow!!(true);show(darr(a=rand(3),b=rand(3),c=fill(:X,3)))) --> nothing
      @fact (dcube.set_showalongrow!!(false);show(darr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_showalongrow!!(true);show(darr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_dispsize!!(5,5);writemime(STDOUT,MIME("text/html"),darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispheight!!(3);writemime(STDOUT,MIME("text/html"),darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispwidth!!(3);writemime(STDOUT,MIME("text/html"),darr(a=rand(10,10)))) --> nothing
      @fact (dcube.set_dispwidth!!(3);writemime(STDOUT,MIME("text/html"),darr(a=rand(2,3,4)))) --> nothing
      @fact (dcube.set_default_dispsize!!();nothing) --> nothing
      @fact (dcube.set_dispalongrow!!(false);writemime(STDOUT,MIME("text/html"),darr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
      @fact (dcube.set_dispalongrow!!(true);writemime(STDOUT,MIME("text/html"),darr(a=rand(3,5),b=rand(3,5),c=fill(:X,3,5)))) --> nothing
    end
  end
end

end
