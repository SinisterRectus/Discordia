local class = require('../class')

local Struct = require('./Struct')

local Attachment, get = class('Attachment', Struct)

function Attachment:__init(data)
	Struct.__init(self, data)
end

function get:id()
	return self._id
end

function get:filename()
	return self._filename
end

function get:contentType()
	return self._content_type
end

function get:size()
	return self._size
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

return Attachment
