using Distributions
using MultidimensionalTables

module T

using MultidimensionalTables
using DataFrames

println("test 1")

begin
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
end

println("test 2")
for n in [10_000_000, 100_000_000][1:2]
  for m in [100, 10_000, 1_000_000][1:1]
    d = darr(x=sample(1:m, n, replace=true), y=rand(n))
    dm = darr(x=sample(1:m, m))
    @show @time @select(d, where[_x .>= 10], where[_x .< 20])
    @show @time @select(d, where[_x .>= Nullable(10)], where[_x .< Nullable(20)])
  end
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
