module TestUngroup

using FactCheck
using MultidimensionalTables
using MultidimensionalTables: simplify_array

facts("Ungroup tests") do
  jaggedarr0 = simplify_array(nalift(reshape(Any[nalift([1,2,3]),nalift(["a","b","c"]),nalift([4,5,6,7,8]),nalift(["hello","hi","this","one","ten"]),[Nullable(9)],[Nullable("A")]], (2,3))))
  nonjaggedarr = nalift(reshape([1,2,3,4,5,6], (2,3)))
  @fact ungroup(jaggedarr0, jaggedarr0[1:1,:]) --> nalift(transpose(hcat(collect(1:9),["a","b","c","hello","hi","this","one","ten","A"])))
  @fact ungroup(jaggedarr0, 2) --> ungroup(jaggedarr0, jaggedarr0[1:1,:])
  @fact ungroup(nonjaggedarr, jaggedarr0[1:1,:]) --> nalift(transpose(hcat([1,1,1,3,3,3,3,3,5],[2,2,2,4,4,4,4,4,6])))
  @fact ungroup(transpose(jaggedarr0), transpose(jaggedarr0)[:,1]) --> transpose(ungroup(jaggedarr0, jaggedarr0[1:1,:]))
  @fact ungroup(transpose(nonjaggedarr), transpose(jaggedarr0)[:,1]) --> transpose(ungroup(nonjaggedarr, jaggedarr0[1:1,:]))
  @fact ungroup(map(Nullable, reshape(Any[[1,2,3],["a","b","c"],[4,5,6,7,8],["hello","hi","this","one","ten"],[9],["A"]], (2,3))), 2) --> nalift(transpose(hcat(collect(1:9),["a","b","c","hello","hi","this","one","ten","A"])))

  jaggedarr = nalift(reshape(nalift(Any[[1,2,3],[11,12,13],[4,5,6,7,8],[14,15,16,17,18],[9],[19]]), (2,3)))
  @fact ungroup(jaggedarr, jaggedarr[1:1,:]) --> nalift(transpose(hcat(collect(1:9),collect(11:19))))
  @fact ungroup(jaggedarr, 2) --> ungroup(jaggedarr, jaggedarr[1:1,:])
  @fact ungroup(nonjaggedarr, jaggedarr[1:1,:]) --> nalift(transpose(hcat([1,1,1,3,3,3,3,3,5],[2,2,2,4,4,4,4,4,6])))
  @fact ungroup(transpose(jaggedarr), transpose(jaggedarr)[:,1]) --> transpose(ungroup(jaggedarr, jaggedarr[1:1,:]))
  @fact ungroup(transpose(nonjaggedarr), transpose(jaggedarr)[:,1]) --> transpose(ungroup(nonjaggedarr, jaggedarr[1:1,:]))
  jagged_darr = DictArray(c1=jaggedarr)
  jagged_larr = LabeledArray(DictArray(c1=jaggedarr), axis1=@darr(k1=[1,2],k2=["a","b"]), axis2=@darr(r1=['x','y','z']))
  jagged_larr2 = LabeledArray(DictArray(c1=jaggedarr))
  @fact ungroup(jagged_darr, 2) --> @darr(c1=ungroup(jaggedarr, 2))
  @fact ungroup(jagged_larr, 2) --> @larr(r1=repmat(['x' 'x' 'x' 'y' 'y' 'y' 'y' 'y' 'z'],2),c1=pick(ungroup(jagged_darr,2),:c1),axis1[k1=[1,2],k2=["a","b"]])
  @fact ungroup(jagged_larr2, 2) --> LabeledArray(ungroup(jagged_larr2.data, 2))
  @fact ungroup(larr(fill(LDict(:a=>nalift([3,2,1])), 2, 3), axis1=11:12, axis2=darr(r=21:23)),1) --> larr(reshape(darr(x1=repmat([11,11,11,12,12,12],3),a=repmat([3,2,1],6)), 6,3), axis2=darr(r=[21,22,23]))
  @fact ungroup(larr(fill(LDict(:a=>nalift([3,2,1])), 2, 3), axis1=11:12, axis2=darr(r=21:23)),2) --> larr(reshape(larr(r=[[fill(x,6) for x in 21:23]...;], a=repeat([3,2,1],inner=[2],outer=[3])),2,9), axis1=11:12)
  context("simple combining multiple table tests") do
    d1 = darr(a=[1 2 3;4 5 6],b=['a' 'b' 'c';'d' 'e' 'f'])
    d2 = @darr(a=[10 11], b=['x' NA])
    combined1 = larr(Any[peel(d1), peel(d2)], axis1=[:set1, :set2])
    @fact ungroup(combined1, 1) --> @darr(x1=[fill(:set1,6);fill(:set2,2)],a=[1,4,2,5,3,6,10,11],b=['a','d','b','e','c','f','x',NA])
    combined2 = larr(darr(Any[peel(d1) peel(d2)]), axis2=darr(k=[:set1, :set2]))
    @fact ungroup(combined2, 2) --> reshape(@darr(k=[fill(:set1,6);fill(:set2,2)],a=[1,4,2,5,3,6,10,11],b=['a','d','b','e','c','f','x',NA]),1,8)
  end
end

end
