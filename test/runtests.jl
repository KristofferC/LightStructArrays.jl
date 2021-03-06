using LightStructArrays
using Test

# write your own tests here
@testset "index" begin
    a, b = [1 2; 3 4], [4 5; 6 7]
    t = StructArray((a = a, b = b))
    @test (@inferred t[2,2]) == (a = 4, b = 7)
    @test (@inferred t[2,1:2]) == StructArray((a = [3, 4], b = [6, 7]))
    @test_throws BoundsError t[3,3]
    @test (@inferred view(t, 2, 1:2)) == StructArray((a = view(a, 2, 1:2), b = view(b, 2, 1:2)))
end

@testset "fieldarrays" begin
    t = StructArray(a = 1:10, b = rand(Bool, 10))
    @test LightStructArrays.propertynames(t) == (:a, :b)
    @test LightStructArrays.propertynames(LightStructArrays.fieldarrays(t)) == (:a, :b)
end

@testset "similar" begin
    t = StructArray(a = rand(10), b = rand(Bool, 10))
    s = similar(t)
    @test eltype(s) == NamedTuple{(:a, :b), Tuple{Float64, Bool}}
    @test size(s) == (10,)
    t = StructArray(a = rand(10, 2), b = rand(Bool, 10, 2))
    s = similar(t, 3, 5)
    @test eltype(s) == NamedTuple{(:a, :b), Tuple{Float64, Bool}}
    @test size(s) == (3, 5)
    s = similar(t, (3, 5))
    @test eltype(s) == NamedTuple{(:a, :b), Tuple{Float64, Bool}}
    @test size(s) == (3, 5)
end

@testset "empty" begin
    s = StructVector(a = [1, 2, 3], b = ["a", "b", "c"])
    empty!(s)
    @test isempty(s.a)
    @test isempty(s.b)
end

@testset "constructor from existing array" begin
    v = rand(ComplexF64, 5, 3)
    t = @inferred StructArray(v)
    @test size(t) == (5, 3)
    @test t[2,2] == v[2,2]
    t2 = convert(StructArray, v)::StructArray
    @test t2 == t
    t3 = StructArray(t)::StructArray
    @test t3 == t
end

@testset "tuple case" begin
    s = StructArray(([1], ["test"],))
    @test s[1] == (1, "test")
    @test Base.getproperty(s, 1) == [1]
    @test Base.getproperty(s, 2) == ["test"]
    t = StructArray{Tuple{Int, Float64}}([1], [1.2])
    @test t[1] == (1, 1.2)

    t[1] = (2, 3)
    @test t[1] == (2, 3.0)
    push!(t, (1, 2))
    @test getproperty(t, 1) == [2, 1]
    @test getproperty(t, 2) == [3.0, 2.0]
end

@testset "kwargs constructor" begin
    a = [1.2]
    b = [2.3]
    @test StructArray(a=a, b=b) == StructArray((a=a, b=b))
    @test StructArray{ComplexF64}(re=a, im=b) == StructArray{ComplexF64}(a, b)
    f1() = StructArray(a=[1.2], b=["test"])
    f2() = StructArray{Pair}(first=[1.2], second=["test"])
    t1 = @inferred f1()
    t2 = @inferred f2()
    @test t1 == StructArray((a=[1.2], b=["test"]))
    @test t2 == StructArray{Pair}([1.2], ["test"])
end

@testset "complex" begin
    a, b = [1 2; 3 4], [4 5; 6 7]
    t = StructArray{ComplexF64}(a, b)
    @test t[2,2] == ComplexF64(4, 7)
    @test t[2,1:2] == StructArray{ComplexF64}([3, 4], [6, 7])
    @test view(t, 2, 1:2) == StructArray{ComplexF64}(view(a, 2, 1:2), view(b, 2, 1:2))
end

@testset "copy" begin
    a, b = [1 2; 3 4], [4 5; 6 7]
    t = StructArray{ComplexF64}(a, b)
    t2 = @inferred copy(t)
    @test t2[1,1] == 1.0 + im*4.0
    t2[1,1] = 2.0 + im*4.0
    # Test we actually did a copy
    @test t[1,1] == 1.0 + im*4.0
end

@testset "undef initializer" begin
    t = @inferred StructArray{ComplexF64}(undef, 5, 5)
    @test eltype(t) == ComplexF64
    @test size(t) == (5,5)
    c = 2 + im
    t[1,1] = c
    @test t[1,1] == c
end

@testset "resize!" begin
    t = StructArray{Pair}([3, 5], ["a", "b"])
    resize!(t, 5)
    @test length(t) == 5
    p = 1 => "c"
    t[5] = p
    @test t[5] == p
end

@testset "concat" begin
    t = StructArray{Pair}([3, 5], ["a", "b"])
    push!(t, (2 => "c"))
    @test t == StructArray{Pair}([3, 5, 2], ["a", "b", "c"])
    append!(t, t)
    @test t == StructArray{Pair}([3, 5, 2, 3, 5, 2], ["a", "b", "c", "a", "b", "c"])
    t = StructArray{Pair}([3, 5], ["a", "b"])
    t2 = StructArray{Pair}([1, 6], ["a", "b"])
    @test cat(t, t2; dims=1)::StructArray == StructArray{Pair}([3, 5, 1, 6], ["a", "b", "a", "b"]) == vcat(t, t2)
    @test vcat(t, t2) isa StructArray
    @test cat(t, t2; dims=2)::StructArray == StructArray{Pair}([3 1; 5 6], ["a" "a"; "b" "b"]) == hcat(t, t2)
    @test hcat(t, t2) isa StructArray
end

f_infer() = StructArray{ComplexF64}(rand(2,2), rand(2,2))

g_infer() = StructArray([(a=(b="1",), c=2)], unwrap = t -> t <: NamedTuple)
tup_infer() = StructArray([(1, 2), (3, 4)])

@testset "inferrability" begin
    @inferred f_infer()
    @inferred g_infer()
    @test g_infer().a.b == ["1"]
    s = @inferred tup_infer()
    @test s[1] == (1, 2)
    @test s[2] == (3, 4)
end

@testset "propertynames" begin
    a = StructArray{ComplexF64}(Float64[], Float64[])
    @test sort(collect(propertynames(a))) == [:im, :re]
end

struct S
    x::Int
    y::Float64
    S(x) = new(x, x)
end

LightStructArrays.SkipConstructor(::Type{<:S}) = true

@testset "inner" begin
    v = StructArray{S}([1], [1])
    @test v[1] == S(1)
    @test v[1].y isa Float64
end

