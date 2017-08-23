local Iterable = require('iterables/Iterable')

local FilteredIterable = require('class')('FilteredIterable', Iterable)

--[[
@class FilteredIterable x Iterable

Iterable class that wraps another iterable and serves a subset of the objects
that the original iterable contains.
]]
function FilteredIterable:__init(base, predicate)
	self._base = base
	self._predicate = predicate
end

--[[
@method iter
@ret function

Returns an iterator that returns all contained object. The order of the objects
is not guaranteed.
]]
function FilteredIterable:iter()
	return self._base:findAll(self._predicate)
end

return FilteredIterable
