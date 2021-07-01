local class = require('../class')

local Attachment, get = class('Attachment')

function Attachment:__init(data)
	self._id = data.id
	self._filename = data.filename
	self._content_type = data.content_type
	self._size = data.size
	self._url = data.url
	self._proxy_url = data.proxy_url
	self._height = data.height
	self._width = data.width
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
