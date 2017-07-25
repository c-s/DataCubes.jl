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
const IS_JULIA_V05 = startswith(string(VERSION), "0.5") || startswith(string(VERSION), "0.6")


iosize_expr = if IS_JULIA_V05
  :(iosize_compat = Base.displaysize)
  #:(iosize_compat = Base.iosize)
else
  :(iosize_compat = Base.tty_size)
end

subarray_last_type = if IS_JULIA_V05
  :(const SUBARRAY_LAST_TYPE = true)
else
  :(const SUBARRAY_LAST_TYPE = 1)
end

eval(iosize_expr)
eval(subarray_last_type)

