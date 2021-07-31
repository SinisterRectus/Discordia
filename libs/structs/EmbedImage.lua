local class = require('../class')
local Struct = require('./Struct')

local EmbedImage, get = class('EmbedImage', Struct)

function EmbedImage:__init(data)
	Struct.__init(self, data)
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

return EmbedImage
