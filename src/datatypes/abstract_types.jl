abstract type AbstractLabeledArray{T,N,AXES,TN} <: AbstractArray{T,N} end
abstract type AbstractDictArray{K,N,VS,SV} <: AbstractArray{LDict{K,SV},N} end
