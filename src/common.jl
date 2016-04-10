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

iosize_expr = if startswith(string(VERSION), "0.5")
  :(iosize_compat = Base.displaysize)
  #:(iosize_compat = Base.iosize)
else
  :(iosize_compat = Base.tty_size)
end

eval(iosize_expr)

