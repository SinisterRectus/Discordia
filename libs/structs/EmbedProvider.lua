local class = require('../class')

local EmbedProvider, get = class('EmbedProvider')

function EmbedProvider:__init(data)
	self._name = data.name
	self._url = data.url
end

function get:name()
	return self._name
end

function get:url()
	return self._url
end

return EmbedProvider
