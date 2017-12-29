local Iterable = require('iterables/Iterable')

local FilteredIterable = require('class')('FilteredIterable', Iterable)

function FilteredIterable:__init(base, predicate)
	self._base = base
	self._predicate = predicate
end

function FilteredIterable:__serializeJSON(null)
	local objects = {}
	for obj in self._base:findAll(self._predicate) do
		table.insert(objects, obj:__serializeJSON())
	end

	return {
		type = 'FilteredIterable',

		objects = objects
	}
end

function FilteredIterable:iter()
	return self._base:findAll(self._predicate)
end

return FilteredIterable
