module TestDataFrameInterface

using FactCheck
using MultidimensionalTables
import DataFrames: DataFrame
import RDatasets: dataset

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


  #using MultidimensionalTables;using DataFrames;using RDatasets
  context("RDatasets readability tests") do
    #for pd in zip(collect(values(peel(@select(@darr(RDatasets.datasets()), :Package, :Dataset))))...)
    #  d = @darr(dataset(map(x->x.value, pd)...))
    #  l = @larr(dataset(map(x->x.value, pd)...))
    #  nothing
    #end
    @fact (dataset("datasets", "iris");nothing) --> nothing
    @fact @darr(dataset("datasets", "iris")) --> convert(DictArray, dataset("datasets", "iris"))
    @fact @larr(dataset("datasets", "iris")) --> convert(LabeledArray, dataset("datasets", "iris"))

    @fact (dataset("boot", "neuro");nothing) --> nothing
    @fact @darr(dataset("boot", "neuro")) --> convert(DictArray, dataset("boot", "neuro"))
    @fact @larr(dataset("boot", "neuro")) --> convert(LabeledArray, dataset("boot", "neuro"))
  end
end

end
