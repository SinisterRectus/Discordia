local class = require('../class')

local EmbedFooter, get = class('EmbedFooter')

function EmbedFooter:__init(data)
	self._text = data.text
	self._icon_url = data.icon_url
	self._proxy_icon_url = data.proxy_icon_url
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
