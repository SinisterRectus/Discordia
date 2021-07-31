local class = require('../class')
local Struct = require('./Struct')

local EmbedFooter, get = class('EmbedFooter', Struct)

function EmbedFooter:__init(data)
	Struct.__init(self, data)
end

function get:text()
	return self._text
end

function get:iconURL()
	return self._icon_url
end

function get:proxyIconURL()
	return self._proxy_icon_url
end

return EmbedFooter
