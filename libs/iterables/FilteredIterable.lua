local Iterable = require('iterables/Iterable')

local FilteredIterable = require('class')('FilteredIterable', Iterable)

function FilteredIterable:__init(base, filter)
	self._base = base
	self._filter = filter
end

function FilteredIterable:iter()
	return self._base:findAll(self._filter)
end

return FilteredIterable
