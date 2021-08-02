local class = require('../class')
local json = require('json')

local null = json.null

local Container, get = class('Container')

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

function Container:__init(data, client)
	self._client = assert(client)
	for k, v in pairs(data) do
		if types[type(v)] then
			self['_' .. k] = v
		elseif v == null then
			self['_' .. k] = nil
			data[k] = nil
		end
	end
end

function Container.__eq()
	return error('__eq not implemented')
end

function get:client()
	return self._client
end

return Container
