local class = require('../class')
local Struct = require('./Struct')

local EmbedAuthor, get = class('EmbedAuthor', Struct)

function EmbedAuthor:__init(data)
	Struct.__init(self, data)
end

function get:name()
	return self._name
end

function get:url()
	return self._url
end

function get:iconURL()
	return self._icon_url
end

function get:proxyIconURL()
	return self._proxy_icon_url
end

return EmbedAuthor
