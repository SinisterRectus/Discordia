local class = require('../class')

local EmbedVideo, get = class('EmbedVideo')

function EmbedVideo:__init(data)
	self._url = data.url
	self._proxy_url = data.proxy_url
	self._height = data.height
	self._width = data.width
end

function get:url()
	return self._url
end

function get:proxyURL()
	return self._proxy_url
end

function get:height()
	return self._height
end

function get:width()
	return self._width
end

return EmbedVideo
