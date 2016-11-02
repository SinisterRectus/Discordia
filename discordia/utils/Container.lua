local Container, get = class('Container')

local types = {
	['string'] = true,
	['number'] = true,
	['boolean'] = true,
}

local function load(self, data)
	for k, v in pairs(data) do
		if types[type(v)] then
			self['_' .. k] = v
		end
	end
end

function Container:__init(data, parent)
	self._parent = parent
	return load(self, data)
end

get('client', function(self)
	return self._parent.client or self._parent
end, 'Client')

Container._update = load

return Container
