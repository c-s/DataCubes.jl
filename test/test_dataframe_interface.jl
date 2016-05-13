module TestDataFrameInterface

using FactCheck
using DataCubes
import DataFrames: DataFrame
import RDatasets: datasets, dataset

facts("DataFrameInterface tests") do
  @fact DictArray(DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])) -->
    @darr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10))
  @fact DataFrame(@darr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10))) -->
    DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])
  @fact LabeledArray(DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])) -->
    @larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10))
  @fact DataFrame(@larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10))) -->
    DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])

  @fact DataFrame(@darr(A=reshape(collect(1:10),2,5), B=reshape(repmat(["x","y"],5),2,5), C=reshape(fill(:sym,10),2,5))) -->
    DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])
  @fact DataFrame(@larr(A=reshape(collect(1:10),2,5), B=reshape(repmat(["x","y"],5),2,5), C=reshape(fill(:sym,10),2,5))) -->
    DataFrame(Any[collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:A,:B,:C])
  @fact DataFrame(@larr(A=reshape(collect(1:10),2,5), B=reshape(repmat(["x","y"],5),2,5), C=reshape(fill(:sym,10),2,5), axis1[k1=[:a,:b],k2=[10,11]])) -->
    DataFrame(Any[repmat([:a,:b],5),repmat(10:11,5),collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:k1,:k2,:A,:B,:C])
  @fact DataFrame(@larr(A=reshape(collect(1:10),2,5), B=reshape(repmat(["x","y"],5),2,5), C=reshape(fill(:sym,10),2,5), axis1[k1=[:a,:b],k2=[10,11]], axis2[r=['A',3,"5",:x,1.0]])) -->
    DataFrame(Any[repmat([:a,:b],5),repmat(10:11,5),repeat(['A',3,"5",:x,1.0],inner=[2]),collect(1:10), repmat(["x","y"], 5), fill(:sym,10)], [:k1,:k2,:r,:A,:B,:C])
    @fact DataCubes.wrap_array(DataFrame(@larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10)))) --> DataFrame(@larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10)))
    @fact DataCubes.type_array(DataFrame(@larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10)))) --> DataFrame(@larr(A=collect(1:10), B=repmat(["x","y"],5), C=fill(:sym,10)))

  context("RDatasets readability tests") do
    #for pd in zip(collect(values(peel(@select(@darr(datasets()), :Package, :Dataset))))...)
    #  d = @darr(dataset(map(x->x.value, pd)...))
    #  l = @larr(dataset(map(x->x.value, pd)...))
    #  nothing
    #end
    iris = dataset("datasets", "iris")
    @fact @darr(iris) --> convert(DictArray, iris)
    @fact @larr(iris) --> convert(LabeledArray, iris)

    neuro = dataset("boot", "neuro")
    @fact @darr(neuro) --> convert(DictArray, neuro)
    @fact @larr(neuro) --> convert(LabeledArray, neuro)
  end
end

end
