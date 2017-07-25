module TestLDict

using FactCheck
using DataCubes

facts("LDict tests") do
  context("constructor tests") do
    d1 = LDict(Dict(:a=>1, :c=>3, :b=>2), [:c, :b, :a])
    d2 = LDict([:c, :b, :a], [3, 2, 1])
    d3 = LDict(:c=>3, :b=>2, :a=>1)
    d4 = LDict((:c,3), (:b,2), (:a,1))
    @fact d1 --> d2
    @fact d2 --> d3
    @fact d3 --> d4
    @fact_throws LDict([:a,:b,:c], [1,2])
    @fact DataCubes.create_ldict_nocheck() --> isempty
    @fact DataCubes.create_ldict_nocheck((:a,3),(:b,2)) --> LDict(:a=>3,:b=>2)
    @fact DataCubes.create_ldict_nocheck(Dict(:a=>3,:b=>2)) --> Dict(:a=>3,:b=>2)
    @fact LDict(Dict(:a=>3,:b=>2)) --> Dict(:a=>3,:b=>2)
    @fact eltype(LDict(:a=>3,:b=>2)) --> Pair{Symbol,Int}
    @fact keys(LDict(:a=>3,:b=>2)) --> [:a,:b]
    @fact values(LDict(:a=>3,:b=>2)) --> [3,2]
    @fact_throws LDict(:a=>3,:b=>'a')[:x]
    d5 = LDict(:a=>3, :b=>'a')
    @fact get!(d5, :a, 1.0) --> 3
    @fact get!(d5, :c, 1.0) --> 1.0
  end
  context("method tests") do
    @fact merge(LDict(:a=>1, :b=>2, :c=>3), LDict(:a=>10, :d=>15)) -->
      LDict(:a=>10, :b=>2, :c=>3, :d=>15)
    @fact merge(LDict(:a=>1, :b=>2, :c=>3), LDict(:a=>10, :d=>"15")) -->
      LDict(:a=>10, :b=>2, :c=>3, :d=>"15")
    @fact delete(LDict(:a=>[10,11,12], 10=>3, :c=>5.0, :d=>1), :a, 10) -->
      LDict(:c=>5.0, :d=>1)
    @fact pick(LDict(:a=>[10,11,12], 10=>3, :c=>5.0, :d=>1), [:d, :c]) -->
      LDict(:d=>1, :c=>5.0)
  end
end

end
