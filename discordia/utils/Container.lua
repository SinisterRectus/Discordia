local Container, property = class('Container')
Container.__description = "Abstract base class used to contain the raw data of Discord objects."

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

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

local function getClient(self)
	return self._parent.client or self._parent
end

property('parent', '_parent', nil, '*', "Parent Discord object")
property('client', getClient, nil, 'Client', "Client object to which the Discord object is known")

Container._update = load

return Container
