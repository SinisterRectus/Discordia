local class = require('../class')

local ActivityButton, get = class('ActivityButton')

function ActivityButton:__init(data)
	self._label = data.label
	self._url = data.url
end

function get:label()
	return self._label
end

function get:url()
	return self._url
end

return ActivityButton
