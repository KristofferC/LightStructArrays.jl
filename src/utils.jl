import Base: tuple_type_cons, tuple_type_head, tuple_type_tail, tail

eltypes(::Type{T}) where {T} = map_types(eltype, T)

map_types(f, ::Type{Tuple{}}) = Tuple{}
function map_types(f, ::Type{T}) where {T<:Tuple}
    tuple_type_cons(f(tuple_type_head(T)), map_types(f, tuple_type_tail(T)))
end
map_types(f, ::Type{NamedTuple{names, types}}) where {names, types} =
    NamedTuple{names, map_types(f, types)}

all_types(f, ::Type{Tuple{}}, ::Type{T}) where {T<:Tuple} = true

function all_types(f, ::Type{S}, ::Type{T}) where {S<:Tuple, T<:Tuple}
    f(tuple_type_head(S), tuple_type_head(T)) && all_types(f, tuple_type_tail(S), tuple_type_tail(T))
end

all_types(f, ::Type{NamedTuple{n1, t1}}, ::Type{NamedTuple{n2, t2}}) where {n1, t1, n2, t2} =
    all_types(f, t1, t2)

map_params(f, ::Type{Tuple{}}) = ()
function map_params(f, ::Type{T}) where {T<:Tuple}
    (f(tuple_type_head(T)), map_params(f, tuple_type_tail(T))...)
end
map_params(f, ::Type{NamedTuple{names, types}}) where {names, types} =
    NamedTuple{names}(map_params(f, types))

buildfromschema(initializer, ::Type{T}) where {T} = buildfromschema(initializer, T, staticschema(T))

function buildfromschema(initializer, ::Type{T}, ::Type{NT}) where {T, NT<:NamedTuple}
    nt = map_params(initializer, NT)
    StructArray{T}(nt)
end

Base.@pure SkipConstructor(::Type) = false

@generated function foreachcolumn(f, x::StructArray{T, N, NamedTuple{names, types}}, xs...) where {T, N, names, types}
    exprs = Expr[]
    for (i, field) in enumerate(names)
        sym = QuoteNode(field)
        args = [Expr(:call, :getfieldindex, :(getfield(xs, $j)), sym, i) for j in 1:length(xs)]
        push!(exprs, Expr(:call, :f, Expr(:., :x, sym), args...))
    end
    push!(exprs, :(return nothing))
    Expr(:block, exprs...)
end

function createinstance(::Type{T}, args...) where {T}
    SkipConstructor(T) ? unsafe_createinstance(T, args...) : T(args...)
end

createinstance(::Type{T}, args...) where {T<:Union{Tuple, NamedTuple}} = T(args)

@generated function unsafe_createinstance(::Type{T}, args...) where {T}
    v = fieldnames(T)
    new_tup = Expr(:(=), Expr(:tuple, v...), :args)
    construct = Expr(:new, :T, (:(convert(fieldtype(T, $(Expr(:quote, sym))), $sym)) for sym in v)...)
    Expr(:block, new_tup, construct)
end
