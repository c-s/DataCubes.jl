using MultidimensionalTables

module T

using MultidimensionalTables
using DataFrames

lar = @larr(a=repmat(1:100,10000), b=rand(1000000))
#lar = @larr(a=repmat(1:1000,10000), b=rand(10000000))
df = DataFrame(lar)

@time r1 = @select(lar, by[:a], m=length(_))
@time r2 = by(df, :a) do df
  DataFrame(m=length(df))
end
@time r1 = @select(lar, by[:a], m=sum(_b))
@time r2 = by(df, :a) do df
  DataFrame(m=sum(df[:a]))
end

#@show(@allocated r1 = @select(lar, by[:a], m=length(_)))
#@show(@allocated r2 = by(df, :a) do df
#  DataFrame(m=length(df))
#end)
#@show(@allocated r1 = @select(lar, by[:a], m=sum(_b)))
#@show(@allocated r2 = by(df, :a) do df
#  DataFrame(m=sum(df[:a]))
#end)


end
