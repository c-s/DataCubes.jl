module TestJoin

using FactCheck
using MultidimensionalTables
using DataFrames

facts("Join tests") do
  context("larr version tests") do
    lj_base_tbl = @larr(a=reshape(collect(1:20), 5,4), b=reshape(collect(101:120),5,4), axis1[k1=[1,2,3,4,5], k2=['a','a','b','c','d']], axis2[r1=[10,12,14,16]])
    lj_src_tbl = @larr(c=reshape(collect(51:56),3,2), axis1[k1=[5,3,1], k2=['d','a','a']], axis2[t1=["x","y"]])
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1) --> @larr(a=reshape(repmat(collect(1:20),2),5,4,2),b=reshape(repmat(collect(101:120),2),5,4,2),c=reshape(@nalift([53,NA,NA,NA,51,53,NA,NA,NA,51,53,NA,NA,NA,51,53,NA,NA,NA,51,56,NA,NA,NA,54,56,NA,NA,NA,54,56,NA,NA,NA,54,56,NA,NA,NA,54]),5,4,2),axis1[k1=collect(1:5),k2=['a','a','b','c','d']],axis2[r1=[10,12,14,16]],axis3[t1=["x","y"]])
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1) --> @larr(a=reshape(repmat([1,5,6,10,11,15,16,20],2),2,4,2),b=reshape(repmat([101,105,106,110,111,115,116,120],2),2,4,2),c=reshape([repmat([53,51],4);repmat([56,54],4)],2,4,2),axis1[k1=[1,5],k2=['a','d']],axis2[r1=[10,12,14,16]],axis3[t1=["x","y"]])
    @fact leftjoin(larr(a=[1,2,3]), larr(b=[2 3;0 1],axis1=[:x,:y])) --> larr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2),axis2=[:x,:y])
    @fact innerjoin(larr(a=[1,2,3]), larr(b=[2 3;0 1],axis1=[:x,:y])) --> larr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2),axis2=[:x,:y])
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,[:k1,:k2]))
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> leftjoin(lj_base_tbl, lj_src_tbl, 1)
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1=>1) --> leftjoin(lj_base_tbl, lj_src_tbl, 1)
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,[:k1,:k2]))
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> innerjoin(lj_base_tbl, lj_src_tbl, 1)
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1=>1) --> innerjoin(lj_base_tbl, lj_src_tbl, 1)
    @fact leftjoin(@larr(reshape(1:10,2,5),axis2[:a,:b,:c,:c,:d]), @larr(axis1[:a,:b,:c],[1,2,3]), 1=>2) --> @larr(x1=reshape(1:10,2,5), x2=[1 2 3 3 NA;1 2 3 3 NA], axis2[:a,:b,:c,:c,:d])
    @fact innerjoin(@larr("x"=>reshape(1:10,2,5),axis2[:a,:b,:c,:c,:d]), @larr(axis1[:a,:b,:c],[1,2,3]), 1=>2) --> larr("x"=>[1 3 5 7;2 4 6 8], x1=[1 2 3 3;1 2 3 3], axis2=[:a,:b,:c,:c])
    @fact leftjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1) --> @larr(k=[:x :x :y;:z :u :v], b=[1 1 2;3 NA NA], axis1[:x,:u], axis2[r=[:x,:y,:z]])
    @fact leftjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1=>1) --> @larr(k=[:x :x :y;:z :u :v], b=[1 1 1;NA NA NA], axis1[:x,:u], axis2[r=[:x,:y,:z]])
    @fact leftjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1=>Any[nalift([:o :x :x;:q :r :y])]) --> @larr(k=[:x :x :y;:z :u :v], b=[NA 1 1;NA NA 2], axis1[:x,:u], axis2[r=[:x,:y,:z]])
    @fact innerjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1) --> @larr(k=[:x :x :y;:z :u :v], b=[1 1 2;3 NA NA], axis1[:x,:u], axis2[r=[:x,:y,:z]])
    @fact innerjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1=>1) --> @larr(k=[:x :x :y], b=[1 1 1], axis1[[:x]], axis2[r=[:x,:y,:z]])
    @fact innerjoin(larr(k=[:x :x :y;:z :u :v], axis1=[:x,:u], axis2=darr(r=[:x, :y, :z])), larr(axis1=darr(k=[:x,:y,:z,:m,:n,:p]), b=[1,2,3,4,5,6]), 1=>Any[nalift([:o :x :x;:q :r :y])]) --> @larr(k=[:x :y;:u :v], b=[1 1;NA 2], axis1[:x,:u], axis2[r=[:y,:z]])
  end
  context("darr version tests") do
    lj_base_tbl = darr(a=reshape(collect(1:20), 5,4), b=reshape(collect(101:120),5,4), k1=repmat([1,2,3,4,5],1,4), k2=repmat(['a','a','b','c','d'],1,4), r1=repmat([10 12 14 16],5,1))
    lj_src_tbl = @larr(c=reshape(collect(51:56),3,2), axis1[k1=[5,3,1], k2=['d','a','a']], axis2[t1=["x","y"]])
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1) --> @larr(a=reshape(repmat(collect(1:20),2),5,4,2),
                                                         b=reshape(repmat(collect(101:120),2),5,4,2),
                                                         k1=reshape(repmat(1:5,8),5,4,2),
                                                         k2=reshape(repmat(['a','a','b','c','d'],8),5,4,2),
                                                         r1=reshape(repmat(reshape(repmat([10 12 14 16],5,1),20),2),5,4,2),
                                                         c=reshape(@nalift([53,NA,NA,NA,51,53,NA,NA,NA,51,53,NA,NA,NA,51,53,NA,NA,NA,51,56,NA,NA,NA,54,56,NA,NA,NA,54,56,NA,NA,NA,54,56,NA,NA,NA,54]),5,4,2),
                                                         axis3[t1=["x","y"]])
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1) --> @larr(a=reshape(repmat([1,5,6,10,11,15,16,20],2),2,4,2),
                                                          b=reshape(repmat([101,105,106,110,111,115,116,120],2),2,4,2),
                                                          k1=reshape(repmat([1,5],8),2,4,2),
                                                          k2=reshape(repmat(['a','d'],8),2,4,2),
                                                          r1=reshape(repmat([10,10,12,12,14,14,16,16],2),2,4,2),
                                                          c=reshape([repmat([53,51],4);repmat([56,54],4)],2,4,2),
                                                          axis3[t1=["x","y"]])
    @fact leftjoin(larr(a=[1,2,3]), larr(b=[2 3;0 1],axis1=[:x,:y])) --> larr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2),axis2=[:x,:y])
    @fact innerjoin(larr(a=[1,2,3]), larr(b=[2 3;0 1],axis1=[:x,:y])) --> larr(a=reshape(repmat([1,2,3],4),3,2,2),b=reshape([2,2,2,0,0,0,3,3,3,1,1,1],3,2,2),axis2=[:x,:y])
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,[:k1,:k2]))
    @fact leftjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> leftjoin(lj_base_tbl, lj_src_tbl, 1)
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,[:k1,:k2]))
    @fact innerjoin(lj_base_tbl, lj_src_tbl, 1=>pick(lj_base_tbl,:k1,:k2)) --> innerjoin(lj_base_tbl, lj_src_tbl, 1)
  end
end

end
