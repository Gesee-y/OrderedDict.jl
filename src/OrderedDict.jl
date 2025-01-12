module OrderedDict

export Dictionary,reverse,items, reset!

import Base.==

"""An ordered dictionary

A reimplementation of the julia Dict which is faster and more ligthweight

Here are the default constructors

**Note** : It's recommended to create Dictionary with where all the keys have the same type (T) 
and all the values also the same type (N), they are faster this way

`Dictionary()`
`Dictionary{T,N}() where{T <: Any, N <: Any}`

Create an empty Dict
"""
mutable struct Dictionary{T <: Any,N <: Any}
	ky :: Vector{T}
	vl :: Vector{N}
	
	## Constructors ##

	Dictionary() = new{Any,Any}([],[])
	Dictionary{T,N}() where{T <: Any, N <: Any} = new{T,N}(T[],N[])

	function Dictionary(ky::Vector{T},vl::Vector{N}) where{T <: Any, N <: Any}
		
		if (length(ky) == length(vl)) new{T,N}(ky,vl)
		else error("Failed to create Dictionary. Dimension mismatch.")
		end
	end

	function Dictionary(dict::Dict{T,N}) where{T <: Any, N <: Any}
		Dictionary(collect(Base.keys(dict)),collect(Base.values(dict)))
	end

	function Dictionary{T,N}(args::Pair...) where{T <: Any, N <: Any}
		k = T[]
		v = N[]
		for pair in args
			key = convert(T,pair.first)
			value = convert(N,pair.second)
			push!(k,key)
			push!(v,value)
		end
		new{T,N}(k,v)
	end
	
	function Dictionary(args::Pair...)
		Dictionary{Any,Any}(args...)
	end
	
	function Dictionary{T}(;kwargs...) where{T <: Any}
		k = String[]
		v = T[]
		for (key,val) in kwargs
			push!(k,string(key))
			push!(v,val)
		end
		new{String,T}(k,v)
	end

	function Dictionary(;kwargs...)
		k = String[]
		v = []
		for (key,val) in kwargs
			push!(k,string(key))
			push!(v,val)
		end
		new{String,Any}(k,v)
	end
end

Base.length(d::Dictionary) = length(getfield(d,:ky))

function Base.getproperty(d::Dictionary,sym::Symbol)
	if sym === :keys
		return copy(getfield(d,:ky))
	elseif sym === :values
		return copy(getfield(d,:vl))
	else
		error("Dictionary don't have a $sym field !")
	end
end

function Base.setproperty!(d::Dictionary,sym::Symbol,value)
	error("Don't manually try to set the Dictionary properties !")
end

function Base.getindex(d::Dictionary,ky)
	val = [getfield(d,:vl)[k] for k in eachindex(getfield(d,:ky)) if getfield(d,:ky)[k] == ky]
	if isempty(val)
		error("There is no key $ky in dictionary")
	else
		return val[1]
	end
end

function Base.setindex!(d::Dictionary,v,ky)
	key = getfield(d,:ky)
	value = getfield(d,:vl)
	if ky in key
		for i in eachindex(key)
			if (key[i] == ky) 
				value[i] = v 
				break
			end
		end
	else
		push!(key,ky)
		push!(value,v)
	end
end

function Base.print(d::Dictionary)
	string_to_show = "{"
	for pair in d
		println(pair)
		string_to_show = string_to_show * "$(pair.first) : $(pair.second),"
	end
	string_to_show = string_to_show * "}"
end

function Base.print(io::IO,d::Dictionary)
	string_to_show = "{"
	for pair in d
		string_to_show = string_to_show * "$(pair.first) : $(pair.second),"
	end
	string_to_show = string_to_show[begin:end-1] * "}"

	write(io,string_to_show)
end

function Base.println(d::Dictionary)
	string_to_show = "{ "
	for (k,v) in zip(getfield(d,:ky),getfield(d,:vl))
		string_to_show = string_to_show * "$k : $v,"
	end
	string_to_show = string_to_show[begin:end-1] * " }"
	println(string_to_show)
end

function Base.println(io::IO,d::Dictionary)
	string_to_show = "{ "
	for (k,v) in zip(d.keys,d.values)
		string_to_show = string_to_show * "$k : $v,"
	end
	string_to_show = string_to_show[begin:end-1] * " }\n"

	write(io,string_to_show)
end

Base.:+(d1::Dictionary,d2::Dictionary) = Dictionary([d1.keys;d2.keys],[d1.values;d2.values])

function Base.sort!(inv::Dictionary;ord = Base.Order.Reverse)
	key = getfield(inv,:ky)
	value = getfield(inv,:vl)

	r_inv = [(qnt,name) for (name,qnt) in zip(inv.ky,inv.vl)]
	sort!(r_inv,order=ord)

	new_inv = [(name,qnt) for (qnt,name) in r_inv]
	key = [name for (name,qnt) in new_inv]
	value = [qnt for (name,qnt) in new_inv]
end

function Base.sort(inv::Dictionary;ord = Base.Order.Reverse)
	r_inv = [(qnt,name) for (name,qnt) in zip(inv.ky,inv.vl)]
	sort!(r_inv,order=ord)

	new_inv = [(name,qnt) for (qnt,name) in r_inv]
	return Dictionary([name for (name,qnt) in new_inv],[qnt for (name,qnt) in new_inv])
end

function reverse!(d::Dictionary)
	len = length(d.ky)
	r_k = [d.ky[i] for i in len:-1:1]
	r_v = [d.vl[i] for i in len:-1:1]
	
	setfield!(d,:ky,r_k)
	setfield!(d,:vl,r_v)
end

function reverse(d::Dictionary)
	len = length(d.ky)
	r_k = [d.ky[i] for i in len:-1:1]
	r_v = [d.vl[i] for i in len:-1:1]
	
	return Dictionary(r_k,r_v)
end

function Base.in(k,d::Dictionary)
	return k in getfield(d,:ky)
end

function Base.iterate(d::Dictionary,i=1)
	i <= length(d) ? ((getfield(d,:ky)[i], getfield(d,:vl)[i]), i+1) : nothing
end

function Base.collect(d::Dictionary{T,N}) where{T <: Any, N <: Any}
	array = Tuple{Union{T,N}}[]
	for pair in d
		push!(array,pair)
	end
	return array
end

function Base.delete!(d::Dictionary,elt)
	key = getfield(d,:ky)
	val = getfield(d,:vl)
	for i in eachindex(key)
		if key[i] == elt
			deleteat!(key,i)
			deleteat(val,i)
		end
	end
end

Base.sizehint!(dict::Dictionary,s) = begin sizehint(dict.ky.s) end

reset!(d::Dictionary{T,N}) where{T,N} = (setfield!(d,:ky,T[]);setfield!(d,:vl,N[]))

==(d1::Dictionary,d2::Dictionary) = (getfield(d1,:ky) == getfield(d2,:ky)) && (getfield(d1,:vl) == getfield(d2,:vl))

Base.copy(d::Dictionary) = Dictionary(d.key,d.value)

Base.isempty(d::Dictionary) = isempty(getfield(d,:ky))
items(d::Dictionary) = return [(k,v) for (k,v) in zip(getfield(d,:ky),getfield(d,:vl))]

end # module