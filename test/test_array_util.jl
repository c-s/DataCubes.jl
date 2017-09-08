module TestArrayUtil

using FactCheck
using DataCubes
using DataCubes: AbstractArrayWrapper, FloatNAArray, simplify_array,
                     type_array, wrap_array, gtake, gdrop

facts("ArrayUtil tests") do
  context("type_array tests") do
    @fact type_array([1,2,3]) --> [1,2,3]
    @fact type_array(Any[1,2,3]) --> [1,2,3]
    @fact type_array(Any[1,2.0,3]) --> [1.0,2.0,3.0]
  end
  context("AbstractArrayWrapper tests") do
    @fact AbstractArrayWrapper(type_array([Nullable(1), Nullable(2.0)])) --> AbstractArrayWrapper([Nullable(1.0), Nullable(2.0)])
    @fact type_array(AbstractArrayWrapper(FloatNAArray([1.0,2.0,NaN]))) --> AbstractArrayWrapper(FloatNAArray([1.0,2.0,NaN]))
    @fact type_array(AbstractArrayWrapper(FloatNAArray([1.0,2.0,NaN]))) --> AbstractArrayWrapper([Nullable(1.0),Nullable(2.0),Nullable{Float64}()])
    @fact AbstractArrayWrapper(type_array(FloatNAArray([1.0,2.0,NaN]))) --> AbstractArrayWrapper([Nullable(1.0),Nullable(2.0),Nullable{Float64}()])
  end
  context("Array transformation tools tests") do
    @fact DataCubes.expand_dims([1 2 3], (2,), (3,)) --> reshape(repmat([1,1,2,2,3,3],3),(2,1,3,3))
    @fact DataCubes.expand_dims(@darr(a=[1 2 3]), (2,), (3,)) --> @darr(a=reshape(repmat([1,1,2,2,3,3],3),(2,1,3,3)))
    @fact DataCubes.expand_dims(@larr(a=[1 2 3],axis1[k=[:x]]), (DataCubes.DefaultAxis(2),), (DataCubes.DefaultAxis(3),)) --> @larr(a=reshape(repmat([1,1,2,2,3,3],3),(2,1,3,3)), axis2[k=[:x]])
    @fact collapse_axes(reshape(collect(1:100), 1,2,5,10), 2, 3) --> reshape(collect(1:100), 1,10,10)
    @fact collapse_axes(reshape(collect(1:100), 1,2,5,10), 2, 3) --> reshape(collect(1:100), 1,10,10)
    @fact collapse_axes(@darr(a=reshape(collect(1:100), 1,2,5,10)), 2, 3) --> @darr(a=reshape(collect(1:100), 1,10,10))
    @fact collapse_axes(@larr(a=reshape(collect(1:100), 1,2,5,10)), 2, 3) --> @larr(a=reshape(collect(1:100), 1,10,10))
    @fact collapse_axes(LabeledArray(DictArray(a=nalift(reshape(collect(1:100), 1,2,5,10))),
                                          axis1=DictArray(k1=nalift([:sym])),
                                          axis2=DictArray(r1=@nalift(["x","y"])),
                                          axis3=@nalift([100,99,98,97,96])), 1, 3) -->
          @larr(a=reshape(collect(1:100), 10,10),
                axis1[k1=fill(:sym, 10),r1=repmat(["x","y"],5),x1=[100,100,99,99,98,98,97,97,96,96]])
    @fact collapse_axes(LabeledArray(DictArray(a=nalift(reshape(collect(1:100), 1,2,5,10))),
                                          axis1=DictArray(1=>nalift([:sym])),
                                          axis2=DictArray(:x1=>@nalift(["x","y"])),
                                          axis3=@nalift([100,99,98,97,96]),
                                          axis4=nalift(collect(31:40))), 1, 4) -->
          @larr(a=collect(1:100),
                axis1[1=>fill(:sym, 100),:x1=>repmat(["x","y"],50),:x2=>repmat([100,100,99,99,98,98,97,97,96,96],10),:x3=>repeat(collect(31:40),inner=[10])])
    @fact (a=[1,2,3,4,5];collapse_axes(a) === a) --> true
    @fact (a=darr(a=[1,2,3,4,5]);collapse_axes(a) === a) --> true
    @fact (a=larr(a=[1,2,3,4,5],axis=[:a,:b,:c,:d,:e]);collapse_axes(a) === a) --> true
    @fact DataCubes.create_additional_fieldname(@larr(a=[1,2,3])) --> :x1
    @fact DataCubes.create_additional_fieldname(@larr(x1=[1,2,3])) --> :x2
    @fact DataCubes.create_additional_fieldname(@larr(x1=[1,2,3],x3=[:a,:b,:c])) --> :x2
    @fact DataCubes.create_additional_fieldname(@larr(x1=[1,2,3],axis1[x2=[:a,:b,:c]])) --> :x3
    @fact mapvalues(x->x+1,[3,2,1]) --> [4,3,2]
    @fact mapvalues(LDict(:a=>1,:b=>3,:c=>5)) do x;x*2 end --> LDict(:a=>2,:b=>6,:c=>10)
    @fact mapvalues(x->broadcast(+, x, 1), darr(a=[1,2,3], b=[4,5,6])) --> darr(a=[2,3,4], b=[5,6,7])
    @fact mapvalues(x->broadcast(+, x, 1), larr(a=[1,2,3], b=[4,5,6], axis1=[:m,:n,:p])) --> larr(a=[2,3,4], b=[5,6,7], axis1=[:m,:n,:p])
    @fact mapvalues(sum, darr(a=[1,2,3], b=[4,5,6])) --> LDict(:a=>Nullable(6), :b=>Nullable(15))
    @fact mapvalues(sum, larr(a=[1,2,3], b=[4,5,6], axis1=[:m,:n,:p])) --> LDict(:a=>Nullable(6), :b=>Nullable(15))
    @fact replace_axes(@larr(c1=[1 2 3;4 5 6],
                             c2=[:a :b :c;:d :e :f],
                             axis1[k1=["x","y"],k2=['a','b']],
                             axis2[r1=[10.0,11.0,12.0]]), 1=>[:c1,:k1], 2=>[:c2]) -->
          @larr(k2=['a' 'a' 'a';'b' 'b' 'b'],r1=[10.0 11.0 12.0;10.0 11.0 12.0],axis1[c1=[1,4],k1=["x","y"]],axis2[c2=[:a,:b,:c]])
    @fact replace_axes(@larr(c1=[1 2 3;4 5 6],
                             c2=[:a :b :c;:d :e :f],
                             axis1[k1=["x","y"],k2=['a','b']],
                             axis2[r1=[10.0,11.0,12.0]]), 1=>[:c1,:k1], 2=>[:c2,:k2]) -->
          @larr(r1=[10.0 11.0 12.0;10.0 11.0 12.0],axis1[c1=[1,4],k1=["x","y"]],axis2[c2=[:a,:b,:c],k2=['a','a','a']])
    @fact replace_axes(@larr(c1=[1 2 3;4 5 6],
                             c2=[:a :b :c;:d :e :f],
                             axis1[k1=["x","y"],k2=['a','b']],
                             axis2[r1=[10.0,11.0,12.0]]), [:c1,:k1], 2=>[:c2,:k2]) -->
          @larr(r1=[10.0 11.0 12.0;10.0 11.0 12.0],axis1[c1=[1,4],k1=["x","y"]],axis2[c2=[:a,:b,:c],k2=['a','a','a']])
    @fact replace_axes(@larr(c1=[1 2 3;4 5 6],
                             c2=[:a :b :c;:d :e :f],
                             axis1[k1=["x","y"],k2=['a','b']],
                             axis2[r1=[10.0,11.0,12.0]]), 1=>[:c1,:k1], [:c2,:k2]) -->
          @larr(r1=[10.0 11.0 12.0;10.0 11.0 12.0],axis1[c1=[1,4],k1=["x","y"]],axis2[c2=[:a,:b,:c],k2=['a','a','a']])
    @fact replace_axes(@larr(c1=[1 2 3;4 5 6],
                             c2=[:a :b :c;:d :e :f],
                             axis1[k1=["x","y"],k2=['a','b']],
                             axis2[r1=[10.0,11.0,12.0]]), [:c1,:k1], [:c2,:k2]) -->
          @larr(r1=[10.0 11.0 12.0;10.0 11.0 12.0],axis1[c1=[1,4],k1=["x","y"]],axis2[c2=[:a,:b,:c],k2=['a','a','a']])
    @fact replace_axes(larr('a'=>[1,2,3], b=[:x,:y,:z]), 1=>['a']) --> larr(b=[:x,:y,:z], axis1=darr('a'=>[1,2,3]))
    @fact replace_axes(larr('a'=>[1,2,3], b=[:x,:y,:z]), 1=>[:b]) --> larr(axis1=darr(b=[:x,:y,:z]), 'a'=>[1,2,3])
    @fact replace_axes(larr('a'=>[1,2,3], b=[:x,:y,:z]), 1=>'a') --> larr(b=[:x,:y,:z], axis1=darr('a'=>[1,2,3]))
    @fact replace_axes(larr('a'=>[1,2,3], b=[:x,:y,:z]), 1=>:b) --> larr(axis1=darr(b=[:x,:y,:z]), 'a'=>[1,2,3])
    @fact replace_axes(larr(a=[1 2;3 4;5 6], axis=[:x,:y,:z]),1=>[:a]) --> @larr(axis[a=[1,3,5]], x1=[:x :x;:y :y;:z :z])
    @fact replace_axes(larr(a=[1 2;3 4;5 6], axis=[:x,:y,:z]),1=>[]) --> @larr(a=[1 2;3 4;5 6], x1=[:x :x;:y :y;:z :z])
    @fact permutedims(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]])),(2,3,1))[:,:,1] -->
          LabeledArray(nalift([1 'a';2 'b';3 'c']), axis1=@darr(k=[100,200,300]), axis2=nalift([:X,:Y]))
    @fact permutedims(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]), axisname="newaxis"),(2,3,1))[:,:,1] -->
          LabeledArray(nalift([1 'a';2 'b';3 'c']), axis1=@darr(k=[100,200,300]), axis2=@darr("newaxis"=>[:X,:Y]))
    @fact permutedims(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]), fieldname="newfield"),(2,3,1))[:,:,1] -->
          LabeledArray(@darr("newfield"=>nalift([1 'a';2 'b';3 'c'])), axis1=@darr(k=[100,200,300]), axis2=nalift([:X,:Y]))
    @fact permutedims(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]), axisname="newaxis", fieldname="newfield"),(2,3,1))[:,:,1] -->
          LabeledArray(@darr("newfield"=>nalift([1 'a';2 'b';3 'c'])), axis1=@darr(k=[100,200,300]), axis2=@darr("newaxis"=>[:X,:Y]))
    @fact axis2flds(@larr(col=[1 2;3 4],axis1[k=[:a,:b]],axis2[r=[:x,:y]])) --> @larr(x_col=[1,3],:y_col=>[2,4],axis1[k=[:a,:b]])
    @fact axis2flds(@larr(col=[1 2;3 4],axis1[k=[:a,:b]],axis2[r=[:x,NA]]), default_axis_value=3) --> @larr(x_col=[1,3],Symbol("3_col")=>[2,4],axis1[k=[:a,:b]])
    @fact axis2flds(permutedims(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]),fieldname="newfield",axisname=:newaxis),(3,2,1))[:,:,1]) --> @larr(Symbol("100_newfield")=>[1,'a'],Symbol("200_newfield")=>[2,'b'],Symbol("300_newfield")=>[3,'c'], axis1[newaxis=[:X,:Y]])
    @fact axis2flds(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]),fieldname="newfield",axisname=:newaxis)) --> @larr(Symbol("X_newfield")=>[1 2 3],Symbol("Y_newfield")=>['a' 'b' 'c'], axis2[k=[100,200,300]])
    @fact axis2flds(flds2axis(@larr(X=[1 2 3],Y=['a' 'b' 'c'], axis2[k=[100,200,300]]),fieldname="newfield")) --> @larr(Symbol("X_newfield")=>[1 2 3],Symbol("Y_newfield")=>['a' 'b' 'c'], axis2[k=[100,200,300]])
    @fact flds2axis(@larr(a=[1,2,3,4,5],b=[:x,:y,:z,:v,:w],c=['a','b','c','d','e'])) --> LabeledArray(transpose(nalift([1 2 3 4 5;:x :y :z :v :w;'a' 'b' 'c' 'd' 'e'])), axis2=nalift([:a,:b,:c]))
    @fact axis2flds(flds2axis(@select(@larr(a=[1,2,3,4,5],b=[:x,:y,:z,:v,:w],c=['a','b','c','d','e']),:a))) --> @select(@larr(a=[1,2,3,4,5],b=[:x,:y,:z,:v,:w],c=['a','b','c','d','e']),:a)
    @fact axis2flds(larr(reshape(1:10,5,2), axis1=darr(k=['a','b','c','d','e']), axis2=darr(r1=[:M,:N],r2=["A","A"]))) --> larr(M_A=[1,2,3,4,5],N_A=[6,7,8,9,10], axis1=darr(k=['a','b','c','d','e']))
  end
  context("Misc functions tests") do
    rand_array = rand(10,5,30,20)
    @fact DataCubes.permutedims_if_necessary(rand_array,(1,2,3,4)) === rand_array --> true
    @fact DataCubes.permutedims_if_necessary(rand_array,(2,3,4,1)) == permutedims(rand_array,(2,3,4,1)) --> true
    @fact DataCubes.dropna(@larr(a=[1 2 NA;NA 3 NA],b=[10 11 NA;13 14 NA],axis1[k=['a','b']],axis2[r=[:x,:y,:z]])) --> @larr(a=[1 2;NA 3],b=[10 11;13 14],axis1[k=['a','b']],axis2[r=[:x,:y]])
    @fact DataCubes.dropna(@larr(a=[1 2 NA;NA 3 NA],b=[10 11 NA;13 14 NA])) --> @larr(a=[1 2;NA 3],b=[10 11;13 14])
    @fact DataCubes.dropna(@larr(a=[1 2 NA;NA 3 NA],b=[10 11 12;13 14 15])) --> @larr(a=[1 2 NA;NA 3 NA],b=[10 11 12;13 14 15])
    @fact DataCubes.dropna(@larr(a=[1 2 NA;NA 3 NA],b=[10 11 12;13 14 NA])) --> @larr(a=[1 2 NA;NA 3 NA],b=[10 11 12;13 14 NA])
    @fact DataCubes.dropna(@larr(a=[1 2 NA;NA 3 NA])) --> @larr(a=[1 2;NA 3])
    @fact DataCubes.dropna(@darr(a=[1 2 NA;NA 3 NA])) --> @darr(a=[1 2;NA 3])
    @fact DataCubes.dropna(@nalift([1 2 NA;NA 3 NA])) --> @nalift([1 2;NA 3])
    @fact sum(DataCubes.igna(DataCubes.reducedim((x,y)->DataCubes.naop_plus(x,y[:a]),@darr(a=reshape(1:5*5*2*3, 5,5,2,3),b=reshape(1:5*5*2*3, 5,5,2,3)),(1,2),Nullable(0.0)))) --> roughly(11325.0)
    @fact (@rap _.value (@rap sum peel _) reducedim((x,y)->DataCubes.naop_plus(x,y[:a]),@larr(a=reshape(1:5*5*2*3, 5,5,2,3),b=reshape(1:5*5*2*3, 5,5,2,3)),(1,2),Nullable(0.0))) --> roughly(11325.0)
    #@fact sum(DataCubes.igna(DataCubes.reducedim((x,y)->DataCubes.naop_plus(x,y.second.second.second.second[:a]),@larr(a=reshape(1:5*5*2*3, 5,5,2,3),b=reshape(1:5*5*2*3, 5,5,2,3)),(1,2),Nullable(0.0)))) --> roughly(11325.0)
    @fact (@rap sin cos sin 1) --> sin(cos(sin(1)))
    @fact (@rap sin(_) cos sin 1) --> sin(cos(sin(1)))
    @fact (@rap sin cos(_) sin 1) --> sin(cos(sin(1)))
    @fact (@rap sin cos(_) sin(_) 1) --> sin(cos(sin(1)))
    @fact (@rap _*8 _*2 3) --> 48
    #TODO ' seems to conflict with transpose in julia 0.6.
    #@fact (@rap sum sin' cos(_)' nalift([1,2,3])).value --> sum(map(sin, map(cos, [1,2,3])))
    @fact delete(@larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]])) --> @larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]])
    @fact delete(@larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]]), :a) --> @larr(b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]])
    @fact delete(@larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]]), :k2) --> @larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"]])
    @fact delete(@larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]]), :k1,:k2) --> @larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA])
    @fact delete(@larr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA], axis1[k1=["m","n"], k2=[:u,:u]]), :k1,:k2,:b) --> @larr(a=reshape(1:6,2,3))
    @fact delete(@darr(a=reshape(1:6,2,3), b=[:x NA :y;:z :w NA]), :a) --> @darr(b=[:x NA :y;:z :w NA])
    @fact delete([1,2,3,4,5]) --> [1,2,3,4,5]
    @fact delete(LDict('a'=>1,'b'=>3), 'a', 'b') --> isempty
    @fact mapna(x->x+1, @nalift([1,NA,NA])) --> @nalift([2,NA,NA])
    @fact mapna(x->x+1, @nalift([NA, NA,NA])) --> @nalift([NA,NA,NA])
    @fact mapna(x->repmat([:a],x), @nalift([NA, 3,NA])) --> wrap_array(Nullable{Array{Symbol,1}}[Nullable{Array{Symbol,1}}(),Nullable([:a,:a,:a]),Nullable{Array{Symbol,1}}()])
    @fact mapna((x,y)->x+y+1, @nalift([1,NA,NA]), @nalift([5,NA,2])) --> @nalift([7,NA,NA])
    @fact mapna((x,y)->"abc", @nalift([1,NA,NA]), @nalift([5,NA,2])) --> @nalift(["abc",NA,NA])
    @fact mapna((x,y)->Nullable("abc"), @nalift([1,NA,NA]), @nalift([5,NA,2])) --> @nalift(["abc",NA,NA])
    @fact eltype(mapna((x,y)->x+y+1, @nalift([1 2 3;4 5 NA]), @nalift([NA 2 3;4 NA NA]))[1,1]) --> Int64
    @fact eltype(mapna((x,y)->Nullable(x+y+1), @nalift([1 2 3;4 5 NA]), @nalift([NA 2 3;4 NA NA]))[1,1]) --> Int64
    @fact providenames(larr(1:10)) --> larr(x1=1:10, axis1=darr(x2=1:10))
    @fact providenames(larr(reshape(1:10,2,5), axis1=darr(k=[:x,:y]))) --> larr(x1=reshape(1:10,2,5), axis1=darr(k=[:x,:y]), axis2=darr(x2=1:5))
    @fact providenames(larr(a=reshape(1:10,2,5)), i->string("column",i)) --> larr(a=reshape(1:10,2,5), axis1=darr("column1"=>[1,2]), axis2=darr("column2"=>[1,2,3,4,5]))
    @fact withdrawnames(providenames(larr(1:10))) --> larr(1:10)
    @fact withdrawnames(providenames(larr(reshape(1:10,2,5), axis1=darr(k=[:x,:y])))) --> larr(reshape(1:10,2,5), axis1=darr(k=[:x,:y]))
    @fact withdrawnames(providenames(larr(a=reshape(1:10,2,5)), i->string("column",i)), name->isa(name, String) && startswith(name, "column")) --> larr(a=reshape(1:10,2,5))
  end
  context("darr/larr tests") do
    @fact @larr(@larr(a=[1,2,3]),b=[10,11,12], axis1[r=[:a,:b,"x"]]) --> @larr(a=[1,2,3],b=[10,11,12], axis1[r=[:a,:b,"x"]])
    @fact @larr(@larr(a=[1,2,3]), axis1[r=[:a,:b,"x"]]) --> @larr(a=[1,2,3], axis1[r=[:a,:b,"x"]])
    @fact @larr(@larr(a=[1,2,3]),b=[10,11,12]) --> @larr(a=[1,2,3],b=[10,11,12])
    @fact @larr(@larr(a=[1,2,3])) --> @larr(a=[1,2,3])
    @fact larr(a=[:a,:b,:c], axis1=[3,2,1]) --> @larr(a=[:a,:b,:c], axis1[[3,2,1]])
    @fact larr([:a,:b,:c], axis1=[3,2,1]) --> @larr([:a,:b,:c], axis1[[3,2,1]])
    @fact larr([1 2 3;4 5 6], :axis2=>["x","y","z"]) --> @larr([1 2 3;4 5 6], axis2[["x","y","z"]])
    @fact larr(@larr(a=[1,2,3], axis1[r=[:a,:b,:c]]), :axis1=>[3,2,1]) --> @larr(a=[1,2,3], axis1[[3,2,1]])
    @fact larr(@larr(a=[1,2,3], axis1[r=[:a,:b,:c]]), axis1=[3,2,1]) --> @larr(a=[1,2,3], axis1[[3,2,1]])
    @fact larr(larr(darr(darr(darr(a=[1,2,3]),b=[2,3,4])))) --> @larr(a=[1,2,3], b=[2,3,4])
    @fact darr(a=[1,2,3],b=[2,3,4]) --> @darr(a=[1,2,3], b=[2,3,4])
    @fact darr(darr(a=[1,2,3]),b=[2,3,4]) --> @darr(a=[1,2,3], b=[2,3,4])
    @fact darr(darr(darr(a=[1,2,3]),b=[2,3,4])) --> @darr(a=[1,2,3], b=[2,3,4])
    @fact darr(darr(larr(a=[1 2;3 4;5 6],axis1=darr(r=['x','y','z']))),:k=>[:m :n;:o :r;:x :y]) --> @darr(hcat(darr(r=['x','y','z']),darr(r=['x','y','z'])), :a=>[1 2;3 4;5 6], k=[:m :n;:o :r;:x :y])
    @fact larr(a=[1,2,3], b=10) --> larr(a=[1,2,3], b=[10,10,10])
    @fact darr(a=[1,2,3], b=10) --> darr(a=[1,2,3], b=[10,10,10])
    @fact tensorprod(larr(a=[1,2,3],axis1=['a','b','c']), larr(b=[2 3;0 1],axis1=[:x,:y])) --> larr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2),axis1=['a','b','c'],axis2=[:x,:y])
    @fact tensorprod(darr(a=[1,2,3]), darr(b=[2 3;0 1])) --> darr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2))
    @fact tensorprod(@nalift([1,NA,0]), nalift([1,0]), nalift([1,0])) --> reshape(@nalift([(1,1,1),NA,(0,1,1),(1,0,1),NA,(0,0,1),(1,1,0),NA,(0,1,0),(1,0,0),NA,(0,0,0)]),3,2,2)
    @fact_throws tensorprod()
    @fact mapvalues(namerge, 10, @larr(a=[3 5 NA;1 1 1]),@larr(a=[1 2 NA;4 NA 6])) --> @larr(a=[1 2 10;4 1 6])
  end
  context("enumeration array tests") do
    @fact wrap_array(EnumerationArray(nalift([:c,:b,:b,:a]), [:b,:c,:a])) --> wrap_array(enumeration([:c,:b,:b,:a], [:b,:c,:a]))
    @fact wrap_array(@enumeration(["x", NA, "y", NA], ["y", "x"])) --> wrap_array(EnumerationArray(([2,0,1,0], ["y","x"])))
    # temporarily suppressing two tests that give an error in v0.5.
    #@fact wrap_array(enumeration(enumeration([:a,:a,:c,:b],[:c,:b,:a]), [:a,:c,:b])) --> wrap_array(enumeration([:a,:a,:c,:b],[:c,:b,:a]))
    #@fact wrap_array(enumeration(enumeration([:a,:a,:c,:b],[:c,:b,:a]), [:a,:c])) --> wrap_array(enumeration([:a,:a,:c,:b],[:c,:b,:a]))
  end
  context("extract/discard tests") do
    @fact gtake(collapse_axes(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))), 2) --> larr(a=[1,4],b=['x','u'],axis1=darr(x1=[:m,:n],r=["A","A"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 2) --> larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))
    @fact gtake(collapse_axes(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))), 8) --> larr(a=[1,4,2,5,3,6,1,4],b=['x','u','y','v','z','w','x','u'],axis1=darr(x1=[:m,:n,:m,:n,:m,:n,:m,:n],r=["A","A","B","B","C","C","A","A"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 8) --> repeat(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])),outer=[4,1])
    @fact gtake(collapse_axes(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))), -8) --> larr(a=[3,6,1,4,2,5,3,6],b=['z','w','x','u','y','v','z','w'],axis1=darr(x1=[:m,:n,:m,:n,:m,:n,:m,:n],r=["C","C","A","A","B","B","C","C"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -8) --> repeat(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])),outer=[4,1])
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 1) --> larr(a=[1 2 3],b=['x' 'y' 'z'], axis1=[:m], axis2=darr(r=["A","B","C"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -1) --> larr(a=[4 5 6],b=['u' 'v' 'w'], axis1=[:n], axis2=darr(r=["A","B","C"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :, 1) --> larr(a=reshape([1 4],2,1),b=reshape(['x' 'u'],2,1), axis1=[:m,:n], axis2=darr(r=["A"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :, -1) --> larr(a=reshape([3 6],2,1),b=reshape(['z' 'w'],2,1), axis1=[:m,:n], axis2=darr(r=["C"]))
    @fact gtake(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -2) --> larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))
    @fact gtake(nalift([1 3 2 5 4]), :, 2:3) --> nalift([3 2])
    @fact gtake(nalift([1 3 2 5 4]), :, 2) --> nalift([1 3])
    @fact gtake(nalift([1 3 2 5 4]), :, -2) --> nalift([5 4])
    @fact gtake(LDict(:a=>3, :b=>3, :c=>2), 2) --> LDict(:a=>3, :b=>3)
    @fact gtake(LDict(:a=>3, :b=>3, :c=>2), -2) --> LDict(:b=>3, :c=>2)
    @fact_throws gtake(LDict(:a=>3, :b=>3, :c=>2), 4)
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :, darr(r=["X","A"])) --> @larr(a=[NA 1;NA 4],b=[NA 'x';NA 'u'], axis1[:m,:n], axis2[darr(r=["X","A"])])
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [:p,:m]) --> @larr(a=[NA NA NA;1 2 3],b=[NA NA NA;'x' 'y' 'z'], axis1[:p,:m], axis2[darr(r=["A","B","C"])])
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [:n, :o], darr(r=["X","A"])) --> @larr(a=[NA 4;NA NA],b=[NA 'u';NA NA], axis1[:n,:o], axis2[darr(r=["X","A"])])

    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :n, (Nullable("A"),)) --> LDict(:a=>Nullable(4), :b=>Nullable('u'))
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), Nullable(:m), LDict(:r=>Nullable("A"))) --> LDict(:a=>Nullable(1), :b=>Nullable('x'))
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), Nullable(:m), LDict(:r=>Nullable("X"))) --> LDict(:a=>Nullable{Int}(), :b=>Nullable{Char}())
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :m) --> larr(a=[1,2,3],b=['x','y','z'], axis1=darr(r=["A","B","C"]))
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :, LDict(:r=>Nullable("A"))) --> larr(a=[1,4], b=['x','u'], axis1=[:m,:n])
    @fact extract(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), :, (Nullable("A"),)) --> larr(a=[1,4], b=['x','u'], axis1=[:m,:n])

    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),1:2,nalift(1:3)) --> larr(a=[101 104 107;102 105 108], b=[1 4 7;2 5 8])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5),axis2=[:x,:y,:z,:u,:v]),2) --> larr(a=[102,105,108,111,114],b=[2,5,8,11,14],axis1=[:x,:y,:z,:u,:v])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),d->broadcast(>, wrap_array(d), 2)) --> larr(a=[103 106 109 112 115], b=[3 6 9 12 15])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),d->broadcast(>, wrap_array(d), 3)) --> isempty
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z])),d->broadcast(==, d[:k], :y)) --> larr(a=[102 105 108 111 114], b=[2 5 8 11 14], axis1=darr(k=[:y]))
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z])),d->broadcast(==, d[:k], :w)) --> isempty
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),:,d->broadcast(>, d, 8)) --> larr(a=[101 104;102 105;103 106],b=[1 4;2 5;3 6],axis1=darr(k=[:x,:y,:z]),axis2=[10,9])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),:,d->broadcast(>, d, 10)) --> isempty
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->1:1,d->2:3) --> larr(a=[104 107],b=[4 7],axis1=darr(k=[:x]),axis2=[9,8])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2:4,d->0:1) --> @larr(a=[NA 102;NA 103;NA NA],b=[NA 2;NA 3;NA NA],axis1[@darr(k=[:y,:z,NA])],axis2[@nalift([NA,10])])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2:4,d->1) --> @larr(a=[102,103,NA],b=[2,3,NA],axis1[@darr(k=[:y,:z,NA])])
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2,d->1) --> LDict(:a=>Nullable(102), :b=>Nullable(2))
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2,d->0) --> LDict(:a=>Nullable{Int}(), :b=>Nullable{Int}())
    @fact extract(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)), d->-1:1,d->[2,3]) --> @larr(a=[NA NA;NA NA;104 107],b=[NA NA;NA NA;4 7])
    @fact gtake(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable(5)),2) --> LDict(:a=>Nullable(1),:b=>Nullable(3))
    @fact gtake(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),2) --> LDict(:a=>Nullable(1),:b=>Nullable(3))
    @fact gtake(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),-2) --> LDict(:b=>Nullable(3),:c=>Nullable("x"))
    @fact gtake(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable(5)),-2) --> LDict(:b=>Nullable(3),:c=>Nullable(5))
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:c]) --> LDict(:a=>Nullable(1),:c=>Nullable("x"))
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:b]) --> LDict(:a=>Nullable(1),:b=>Nullable(3))
    @fact extract(LDict(:a=>Nullable(1.0),:b=>Nullable(3.0),:c=>Nullable(5.0)),[:a,:b]) --> LDict(:a=>Nullable(1.0),:b=>Nullable(3.0))
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:b,:d]) --> LDict(:a=>Nullable(1),:b=>Nullable(3),:d=>Nullable{Any}())
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable(5)),[:a,:b,:d]) --> LDict(:a=>Nullable(1),:b=>Nullable(3),:d=>Nullable{Int}())
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),:a).value --> 1
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),:x) --> isnull
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),d->broadcast(==, d, :a)) --> LDict(:a=>Nullable(1))
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),_->2:3) --> LDict(:b=>Nullable(3), :c=>Nullable("x"))
    @fact extract(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),_->2).value --> 3
    @fact extract(nalift(LDict(:a=>1,:b=>3)), :a).value --> 1
    @fact extract(nalift(LDict(:a=>1,:b=>3,:c=>5)), x->2).value --> 3
    @fact extract(nalift(LDict(:a=>1,:b=>3,:c=>5)), x->[2,3]) --> nalift(LDict(:b=>3,:c=>5))

    @fact extract(nalift(LDict(:a=>1,:b=>3,:c=>'x')), x->2).value --> 3
    @fact extract(nalift(LDict(:a=>1,:b=>3,:c=>'x')), x->[2,3]) --> nalift(LDict(:b=>3,:c=>'x'))
    @fact extract(nalift(LDict(:a=>1,:b=>3,:c=>'x')), x->[1,2]) --> nalift(LDict(:a=>1,:b=>3))
    @fact dcube.gdrop(nalift(LDict(:a=>1,:b=>3,:c=>5)),2) --> LDict(:c=>Nullable(5))
    @fact dcube.gdrop(nalift(LDict(:a=>1,:b=>3,:c=>5)),3) --> isempty
    @fact discard([7,5,3,1],1:2) --> nalift([3,1])
    @fact discard([7,5,3,1],x->[1,3]) --> nalift([5,1])

    @fact gdrop(collapse_axes(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))), 2) --> larr(a=[2,5,3,6],b=['y','v','z','w'],axis1=darr(x1=[:m,:n,:m,:n],r=["B","B","C","C"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 2) --> isempty
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 1) --> larr(a=[4 5 6],b=['u' 'v' 'w'], axis1=[:n], axis2=darr(r=["A","B","C"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -1) --> larr(a=[1 2 3],b=['x' 'y' 'z'], axis1=[:m], axis2=darr(r=["A","B","C"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [], 1) --> larr(a=[2 3;5 6],b=['y' 'z';'v' 'w'], axis1=[:m,:n], axis2=darr(r=["B","C"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [], -1) --> larr(a=[1 2;4 5],b=['x' 'y';'u' 'v'], axis1=[:m,:n], axis2=darr(r=["A","B"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), 8) --> isempty
    @fact gdrop(collapse_axes(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"]))), -2) --> larr(a=[1,4,2,5],b=['x','u','y','v'],axis1=darr(x1=[:m,:n,:m,:n],r=["A","A","B","B"]))
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -2) --> isempty
    @fact gdrop(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), -8) --> isempty
    @fact discard(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [], darr(r=["X","A"])) --> larr(a=[2 3;5 6],b=['y' 'z';'v' 'w'],axis1=[:m,:n],axis2=darr(r=["B","C"]))
    @fact discard(larr(a=[1 2 3;4 5 6],b=['x' 'y' 'z';'u' 'v' 'w'], axis1=[:m,:n], axis2=darr(r=["A","B","C"])), [:n, :o], darr(r=["X","A"])) --> larr(a=[2 3],b=['y' 'z'],axis1=[:m],axis2=darr(r=["B","C"]))
    @fact gdrop(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),2) --> LDict(:c=>Nullable("x"))
    @fact gdrop(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),-2) --> LDict(:a=>Nullable(1))
    @fact size(gdrop(larr(a=rand(5,3), b=reshape(1:15,5,3), axis1=[:X,:Y,:Z,:U,:V]),5)) --> (0,3)
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:c]) --> LDict(:b=>Nullable(3))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:b]) --> LDict(:c=>Nullable("x"))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),[:a,:b,:d]) --> LDict(:c=>Nullable("x"))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable(5)),[:a,:b,:d]) --> LDict(:c=>Nullable(5))
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),1:2,nalift(1:3)) --> larr(a=[112 115],b=[12 15])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5),axis2=[:x,:y,:z,:u,:v]),2) --> larr(a=[101 104 107 110 113;103 106 109 112 115],b=[1 4 7 10 13;3 6 9 12 15],axis2=[:x,:y,:z,:u,:v])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),d->broadcast(>, wrap_array(d), 2)) --> larr(a=[101 104 107 110 113;102 105 108 111 114],b=[1 4 7 10 13;2 5 8 11 14])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)),d->broadcast(>, wrap_array(d), 3)) --> larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5))
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z])),d->broadcast(==, d[:k], :y)) --> discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z])),(Nullable(:y),))
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z])),d->broadcast(==, d[:k], :w)) --> larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]))
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),[],d->broadcast(>, d, 8)) --> larr(a=reshape(107:115,3,3),b=reshape(7:15,3,3),axis1=darr(k=[:x,:y,:z]),axis2=[8,7,6])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),[],d->broadcast(>, d, 10)) --> larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->1:1,d->2:3) --> discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),LDict(:k=>Nullable(:x)),[8,9])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2:4,d->0:1) --> discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),darr(k=[:y,:z]), [100,10])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2:4,d->1:1) --> discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),darr(k=[:y,:z]), [100,10])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),d->2:4,d->1) --> discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5), axis1=darr(k=[:x,:y,:z]), axis2=[10,9,8,7,6]),darr(k=[:y,:z]), [100,10])
    @fact discard(larr(a=reshape(101:115,3,5),b=reshape(1:15,3,5)), d->-1:1,d->[2,3]) --> larr(a=[102 111 114;103 112 115],b=[2 11 14;3 12 15])
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),:a) --> LDict(:b=>Nullable(3), :c=>Nullable("x"))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),:x) --> LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x"))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),d->broadcast(==, d, :a)) --> LDict(:b=>Nullable(3), :c=>Nullable("x"))
    @fact discard(LDict(:a=>Nullable(1),:b=>Nullable(3),:c=>Nullable("x")),_->2:30) --> LDict(:a=>Nullable(1))
    @fact discard(larr(a=[1 2 3;4 5 6]), 1:1, 2:3) --> larr(a=[4]')

    @fact gdrop(nalift([1 3 2 5 4]), :, 2:3) --> isempty
    @fact gdrop(nalift([1 3 2 5 4]), [], 2:3) --> nalift([1 5 4])
    @fact gdrop(nalift([1 3 2 5 4]), [], 2) --> nalift([2 5 4])
    @fact gdrop(nalift([1 3 2 5 4]), [], -2) --> nalift([1 3 2])
    @fact gdrop(LDict(:a=>3, :b=>3, :c=>2), 2) --> LDict(:c=>2)
    @fact gdrop(LDict(:a=>3, :b=>3, :c=>2), -2) --> LDict(:a=>3)

    @fact namerge(@nalift([1,2,NA,4,NA]), @nalift([11,12,13,NA,NA])) --> @nalift([11,12,13,4,NA])
    @fact namerge(@nalift([1,2,NA,4,NA]), @nalift([11,12,13,NA,NA]), @nalift([NA,21,22,NA,25])) --> @nalift([11,21,22,4,25])
    @fact namerge(@nalift([1,2,NA,4,NA]), Nullable(3)) --> @nalift([3,3,3,3,3])
    @fact namerge(@nalift([1,2,NA,4,NA]), 3) --> @nalift([3,3,3,3,3])
    @fact namerge(@nalift([1,2,NA,4,NA]), Nullable{Int}()) --> @nalift([1,2,NA,4,NA])
    @fact namerge(Nullable(3), @nalift([1,2,NA,4,NA])) --> @nalift([1,2,3,4,3])
    @fact namerge(3, @nalift([1,2,NA,4,NA])) --> @nalift([1,2,3,4,3])
    @fact namerge(Nullable{Int}(), @nalift([1,2,NA,4,NA])) --> @nalift([1,2,NA,4,NA])
    @fact namerge(Nullable(1), Nullable{Int}()).value --> 1
    @fact namerge(1, Nullable{Int}()).value --> 1
    @fact namerge(Nullable{Int}(), Nullable(1)).value --> 1
    @fact namerge(Nullable{Int}(), 1).value --> 1
    @fact namerge(Nullable(1), Nullable(2)).value --> 2
    @fact namerge(1, 2).value --> 2
    @fact namerge(Nullable{Int}(), Nullable{Int}()) --> isnull
    @fact namerge(@nalift([1 2 NA;4 5 6])) --> @nalift([1 2 NA;4 5 6])
    @fact namerge(@nalift([1 2 NA;4 5 6])) --> @nalift([1 2 NA;4 5 6])
    @fact namerge(@larr([1 2 NA;4 5 6])) --> @larr([1 2 NA;4 5 6])
    @fact namerge(@larr([1 2 NA;4 5 6])) --> @larr([1 2 NA;4 5 6])
    @fact namerge(@darr(a=[1 2 NA;4 5 6])) --> @darr(a=[1 2 NA;4 5 6])
    @fact namerge(@darr(a=[1 2 NA;4 5 6])) --> @darr(a=[1 2 NA;4 5 6])
    @fact namerge(@larr(a=[1 2 NA;4 5 6],axis[:x,:y])) --> @larr(a=[1 2 NA;4 5 6],axis[:x,:y])
    @fact namerge(@larr(a=[1 2 NA;4 5 6],axis[:x,:y])) --> @larr(a=[1 2 NA;4 5 6],axis[:x,:y])
    @fact_throws namerge()
    @fact mapvalues(+, 1, darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0])) --> darr(a=[2 3;4 5],b=1.0*[2 3;4 5])
    @fact mapvalues(+, Nullable(1), darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0])) --> darr(a=[2 3;4 5],b=1.0*[2 3;4 5])
    @fact mapvalues(+, darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0]), 1) --> darr(a=[2 3;4 5],b=1.0*[2 3;4 5])
    @fact mapvalues(+, darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0]), Nullable(1)) --> darr(a=[2 3;4 5],b=1.0*[2 3;4 5])
    @fact mapvalues(+, darr(b=[11 12;13 14],a=[1 2;3 4]), darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0])) --> darr(b=1.0*[12 14;16 18],a=1.0*[2 4;6 8])
    @fact mapvalues(+, larr(b=[11 12;13 14],a=[1 2;3 4],axis1=[:x,:y]), darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0])) --> larr(b=1.0*[12 14;16 18],a=1.0*[2 4;6 8],axis1=[:x,:y])
    @fact mapvalues(+, larr(b=[11 12;13 14],a=[1 2;3 4],axis1=[:x,:y]), darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0]), 1) --> larr(b=1.0*[13 15;17 19],a=1.0*[3 5;7 9],axis1=[:x,:y])
    @fact mapvalues(+, larr(b=[11 12;13 14],a=[1 2;3 4],axis1=[:x,:y]), darr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0]), Nullable(1)) --> larr(b=1.0*[13 15;17 19],a=1.0*[3 5;7 9],axis1=[:x,:y])
    @fact mapvalues((x,y,z)->Nullable(1),1,larr(a=[1,2,3]),darr(a=[4,5,6])) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),1,darr(a=[1,2,3]),darr(a=[4,5,6])) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),darr(a=[1,2,3]),darr(a=[4,5,6]),2) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),darr(a=[4,5,6]),3,1) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),larr(a=[4,5,6]),2,1) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),larr(a=[4,5,6]),1,Nullable(3)) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),larr(a=[4,5,6]),1,Nullable(5)) --> nalift(LDict(:a=>1))
    @fact mapvalues((x,y,z)->Nullable(1),3,2,1).value --> 1
    @fact mapvalues(x->DataCubes.naop_plus(x,2), larr([1 2 3])) --> larr([3 4 5])
    @fact_throws mapvalues(+, larr(b=[11 12;13 14],a=[1 2;3 4],axis1=[:x,:y]), larr(a=[1 2;3 4],b=[1.0 2.0;3.0 4.0]))
    @fact (a=enumeration([:a,:b,:a]);push!(a, Nullable(:a));DataCubes.wrap_array(a)) --> DataCubes.wrap_array(enumeration([:a,:b,:a,:a]))
    @fact (a=enumeration([:a,:b,:a]);push!(a, Nullable{Symbol}());DataCubes.wrap_array(a)) --> DataCubes.wrap_array(@enumeration([:a,:b,:a,NA]))
    @fact (a=nalift([1.0,2.0,3.0]);push!(a, Nullable(5.0));a) --> nalift([1.0,2.0,3.0,5.0])
    @fact (a=nalift([1.0,2.0,3.0]);push!(a, Nullable{Float64}());a) --> @nalift([1.0,2.0,3.0,NA])
    @fact pick(darr(a=[1,2,3],b=[:x,:y,:z])[1], [:a]) --> LDict(:a=>Nullable(1))
    @fact pick(darr(a=[1,2,3],b=[:x,:y,:z])[1], :a).value --> 1
    @fact pick(darr(a=[1,2,3],b=[:x,:y,:z])[1], :a, :b) --> nalift([1,:x])
    @fact pick(darr(a=[1,2,3],b=[:x,:y,:z])[1], (:a,))[1].value --> 1
    @fact typeof(pick(darr(a=[1,2,3],b=[:x,:y,:z])[1], (:a,))) --> Array{Nullable{Int},1}
  end
end

end
