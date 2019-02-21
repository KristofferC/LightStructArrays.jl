# LightStructArrays

[![Build Status](https://travis-ci.org/KristofferC/LightStructArrays.jl.svg?branch=master)](https://travis-ci.org/KristofferC/LightStructArrays.jl)
[![codecov.io](http://codecov.io/github/KristofferC/LightStructArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/KristofferC/LightStructArrays.jl?branch=master)

Note: This package is a fork of https://github.com/piever/StructArrays.jl removing support for different data specific tasks thereby significantly
shortening the code, removing dependencies and reducing load time.

This package introduces the type `StructArray` which is an `AbstractArray` whose elements are `struct` (for example `NamedTuples`,  or `ComplexF64`, or a custom user defined `struct`). While a `StructArray` iterates `structs`, the layout is column based (meaning each field of the `struct` is stored in a seprate `Array`).

`Base.getproperty` or the dot syntax can be used to access columns, whereas rows can be accessed with `getindex`.

The package was largely inspired by the `Columns` type in [IndexedTables](https://github.com/JuliaComputing/IndexedTables.jl) which it now replaces.

## Example usage to store complex numbers

```julia
julia> using LightStructArrays, Random

julia> Random.seed!(4);

julia> s = StructArray{ComplexF64}((rand(2,2), rand(2,2)))
2×2 StructArray{Complex{Float64},2,NamedTuple{(:re, :im),Tuple{Array{Float64,2},Array{Float64,2}}}}:
 0.680079+0.625239im   0.92407+0.267358im
 0.874437+0.737254im  0.929336+0.804478im

julia> s[1, 1]
0.680079235935741 + 0.6252391193298537im

julia> s.re
2×2 Array{Float64,2}:
 0.680079  0.92407
 0.874437  0.929336

julia> fieldarrays(s) # obtain all field arrays as a named tuple
(re = [0.680079 0.92407; 0.874437 0.929336], im = [0.625239 0.267358; 0.737254 0.804478])
```

Note that the same approach can be used directly from an `Array` of complex numbers:

```julia
julia> StructArray([1+im, 3-2im])
2-element StructArray{Complex{Int64},1,NamedTuple{(:re, :im),Tuple{Array{Int64,1},Array{Int64,1}}}}:
 1 + 1im
 3 - 2im
```

### Collection and initialization

One can also create a `StructArrray` from an iterable of structs without creating an intermediate `Array`:

```julia
julia> StructArray(log(j+2.0*im) for j in 1:3)
3-element StructArray{Complex{Float64},1,NamedTuple{(:re, :im),Tuple{Array{Float64,1},Array{Float64,1}}}}:
 0.8047189562170501 + 1.1071487177940904im
 1.0397207708399179 + 0.7853981633974483im
 1.2824746787307684 + 0.5880026035475675im
```

Another option is to create an uninitialized `StructArray` and then fill it with data. Just like in normal arrays, this is done with the `undef` syntax:

```julia
julia> s = StructArray{ComplexF64}(undef, 2, 2)
2×2 StructArray{Complex{Float64},2,NamedTuple{(:re, :im),Tuple{Array{Float64,2},Array{Float64,2}}}}:
 6.91646e-310+6.91646e-310im  6.91646e-310+6.91646e-310im
 6.91646e-310+6.91646e-310im  6.91646e-310+6.91646e-310im

julia> rand!(s)
2×2 StructArray{Complex{Float64},2,NamedTuple{(:re, :im),Tuple{Array{Float64,2},Array{Float64,2}}}}:
  0.446415+0.671453im  0.0797964+0.675723im
 0.0340059+0.420472im   0.907252+0.808263im
```

### Using custom array types

StructArrays supports using custom array types. It is always possible to pass field arrays of a custom type. The "custom array of structs to struct of custom arrays" transformation will use the `similar` method of the custom array type. This can be useful when working on the GPU for example:

```julia
julia> using StructArrays, CuArrays

julia> a = CuArray(rand(Float32, 3));

julia> b = CuArray(rand(Float32, 3));

julia> StructArray{ComplexF32}((a, b))
3-element StructArray{Complex{Float32},1,NamedTuple{(:re, :im),Tuple{CuArray{Float32,1},CuArray{Float32,1}}}}:
 0.38701582f0 + 0.11897242f0im
   0.604787f0 + 0.50734913f0im
 0.08764398f0 + 0.0258466f0im5309567f0im

julia> c = CuArray(rand(ComplexF32, 3));

julia> StructArray(c)
3-element StructArray{Complex{Float32},1,NamedTuple{(:re, :im),Tuple{CuArray{Float32,1},CuArray{Float32,1}}}}:
   0.5544419f0 + 0.40554368f0im
    0.612093f0 + 0.41887426f0im
 0.051870108f0 + 0.95920694f0im
```

