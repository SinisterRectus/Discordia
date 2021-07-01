local class = require('../class')

local EmbedAuthor, get = class('EmbedAuthor')

function EmbedAuthor:__init(data)
	self._name = data.name
	self._url = data.url
	self._icon_url = data.icon_url
	self._proxy_icon_url = data.proxy_icon_url
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
