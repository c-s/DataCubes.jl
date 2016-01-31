module TestSort

using FactCheck
using DataCubes

facts("Sort tests") do
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 1, :a) --> @darr(a=[3 3 1;5 5 3],b=[9 8 7;1 3 4])
  @fact sort(@darr(a=1.0*[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 1, :a) --> @darr(a=1.0*[3 3 1;5 5 3],b=[9 8 7;1 3 4])
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 2, :a) --> @darr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8])
  @fact sort(@darr(a=1.0*[5 5 3;3 3 1],b=[1 3 4;9 8 7]), 2, :a) --> @darr(a=1.0*[3 5 5;1 3 3],b=[4 1 3;7 9 8])
  @fact sort(@darr(a=[5 5 3;3 3 1],b=[3 1 4;8 9 7]), 2, :a,:b) --> @darr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8])
  @fact sort(@darr(a=[5 5 3;3 3 1],b=1.0*[3 1 4;8 9 7]), 2, :a,:b) --> @darr(a=[3 5 5;1 3 3],b=1.0*[4 1 3;7 9 8])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 1, :a) --> @larr(a=[3 3 1;5 5 3],b=[9 8 7;1 3 4],axis1[k=[:b,:a]],axis2[r=[:X,:Y,:Z]])
  @fact sort(@larr(a=[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a) --> @larr(a=[3 5 5;1 3 3],b=[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:X,:Y]])
  @fact sort(@larr(a=1.0*[5 5 3;3 3 1],b=[1 3 4;9 8 7],axis1[k=[:a,:b]],axis2[r=[:X,:Y,:Z]]), 2, :a) --> @larr(a=1.0*[3 5 5;1 3 3],b=[4 1 3;7 9 8],axis1[k=[:a,:b]],axis2[r=[:Z,:X,:Y]])
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
  @fact sort(@larr(a=[5 NA 3;3 3 1],b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b, a_rev=true) --> @larr(a=[5 3 NA;3 1 3],b=[3 4 1;8 7 9],axis1[k = [:a,:b]],axis2[r = [:X,:Z,:Y]])
  @fact sort(@larr(a=[5 NA 3;3 3 1],b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b, a_rev=true,b_rev=true) --> @larr(a=[5 3 NA;3 1 3],b=[3 4 1;8 7 9],axis1[k = [:a,:b]],axis2[r = [:X,:Z,:Y]])
  @fact sort(@larr(a=[5 NA 3;3 3 1],b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b) --> @larr(a=[NA 3 5;3 1 3],b=[1 4 3;9 7 8],axis1[k = [:a,:b]],axis2[r = [:Y,:Z,:X]])
  @fact sort(@larr(a=[5 NA 3;3 3 1],b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b, a_rev=true,b_rev=true) --> @larr(a=[5 3 NA;3 1 3],b=[3 4 1;8 7 9],axis1[k = [:a,:b]],axis2[r = [:X,:Z,:Y]])
  @fact sort(@larr(a=[5 NA 3;3 3 1],b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b) --> @larr(a=[NA 3 5;3 1 3],b=[1 4 3;9 7 8],axis1[k = [:a,:b]],axis2[r = [:Y,:Z,:X]])
  @fact sort(@larr(a=@enumeration([5 NA 3;3 3 1],[1,2,3,4,5]),b=[3 1 4;8 9 7],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b) --> @larr(a=[NA 3 5;3 1 3],b=[1 4 3;9 7 8],axis1[k = [:a,:b]],axis2[r = [:Y,:Z,:X]])
  @fact sort(@larr(a=@enumeration([5 NA 3;3 3 1],[1,2,3,4,5]),b=enumeration([3 1 4;8 9 7],[10,9,8,7,6,5,4,3,2,1]),axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b,b_rev=true) --> @larr(a=[NA 3 5;3 1 3],b=[1 4 3;9 7 8],axis1[k = [:a,:b]],axis2[r = [:Y,:Z,:X]])
  @fact sort(@larr(a=[5.0 NA 3.0;3.0 3.0 1.0],b=[3.0 1.0 4.0;8.0 9.0 7.0],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b, a_rev=true,b_rev=true) --> @larr(a=[5.0 3.0 NA;3.0 1.0 3.0],b=[3.0 4.0 1.0;8.0 7.0 9.0],axis1[k = [:a,:b]],axis2[r = [:X,:Z,:Y]])
  @fact sort(@larr(a=[5.0 NA 3.0;3.0 3.0 1.0],b=[3.0 1.0 4.0;8.0 9.0 7.0],axis1[k = [:a,:b]],axis2[r = [:X,:Y,:Z]]),2,:a,:b) --> @larr(a=[NA 3.0 5.0;3.0 1.0 3.0],b=[1.0 4.0 3.0;9.0 7.0 8.0],axis1[k = [:a,:b]],axis2[r = [:Y,:Z,:X]])
  @fact sort(larr(a=enumeration([1,7,4,3,5,3]),axis1=enumeration([1,12,13,14,15,16])),1,:a) --> larr(a=[1,7,4,3,3,5], axis1=[1,12,13,14,16,15])
  @fact sortperm(larr(a=enumeration([1,7,4,3,5,3]),axis1=enumeration([1,12,13,14,15,16])),1,:a) --> ([1,2,3,4,6,5],)
  @fact sortperm(larr(a=[1,7,4,3,5,3],axis1=enumeration([1,12,13,14,15,16])),1,:a) --> ([1,4,6,3,5,2],)
  for i in 1:100
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sort(t)==sort(t,1)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sort(t)==sort(t,1)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sort(t)==sort(t,1,:a,:b,:c)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sort(t,2)==sort(t,2,:a,:b,:c)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sort(t,2)==sort(t,2,:a,:b,:c)) --> true

    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=rand(0:1,3));sort(t)==sort(t,1)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=darr(k=rand(0:1,3)));sort(t)==sort(t,1)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=darr(k=rand(0:1,3)));sort(t)==sort(t,1,:k)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis2=darr(k=rand(0:1,5)));sort(t,2)==sort(t,2,:k)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis2=darr(k1=rand(0:1,5),k2=rand(0:1,5)));sort(t,2)==sort(t,2,:k1,:k2)) --> true

    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sortperm(t)==sortperm(t,1)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sortperm(t)==sortperm(t,1)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sortperm(t)==sortperm(t,1,:a,:b,:c)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sortperm(t,2)==sortperm(t,2,:a,:b,:c)) --> true
    @fact (t=darr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5));sortperm(t,2)==sortperm(t,2,:a,:b,:c)) --> true

    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=rand(0:1,3));sortperm(t)==sortperm(t,1)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=darr(k=rand(0:1,3)));sortperm(t)==sortperm(t,1)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis=darr(k=rand(0:1,3)));sortperm(t)==sortperm(t,1,:k)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis2=darr(k=rand(0:1,5)));sortperm(t,2)==sortperm(t,2,:k)) --> true
    @fact (t=larr(a=rand(0:1,3,5),b=rand(0:1,3,5),c=rand(0:1,3,5),axis2=darr(k1=rand(0:1,5),k2=rand(0:1,5)));sortperm(t,2)==sortperm(t,2,:k1,:k2)) --> true
  end
end

end
