local class = require('../class')
local Struct = require('./Struct')

local EmbedProvider, get = class('EmbedProvider', Struct)

function EmbedProvider:__init(data)
	Struct.__init(self, data)
end

function get:name()
	return self._name
end

function get:url()
	return self._url
end

return EmbedProvider
