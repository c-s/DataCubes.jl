type ZeroElementException <: Exception end

#macro debug_stmt(x)
#  x
#end

macro debug_stmt(x)
end

# used to send some size information.
immutable TableSize{N}
  size::NTuple{N,Int}
end
TableSize(arr::AbstractArray) = TableSize(size(arr))

# some statements for compatibility.
const IS_JULIA_V06 = startswith(string(VERSION), "0.6")
