local class = require('../class')

local Container, get = class('Container')

function Container:__init(client)
	self._client = assert(client)
end

function Container.__eq()
	return error('__eq not implemented')
end

function get:client()
	return self._client
end

return Container
