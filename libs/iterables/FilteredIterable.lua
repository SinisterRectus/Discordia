local Iterable = require('iterables/Iterable')

local FilteredIterable = require('class')('FilteredIterable', Iterable)

function FilteredIterable:__init(base, predicate)
	self._base = base
	self._predicate = predicate
end

function FilteredIterable:iter()
	return self._base:findAll(self._predicate)
end

return FilteredIterable
