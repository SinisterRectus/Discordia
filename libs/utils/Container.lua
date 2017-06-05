local Container, get = require('class')('Container')

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

local function load(self, data)
	assert(type(data) == 'table') -- debug
	for k, v in pairs(data) do
		if types[type(v)] then
			self['_' .. k] = v
		end
	end
end

function Container:__init(data, parent)
	assert(type(data) == 'table') -- debug
	assert(type(parent) == 'table') -- debug
	self._parent = parent
	return load(self, data)
end

Container._load = load

function get.client(self)
	return self._parent.client or self._parent
end

return Container
