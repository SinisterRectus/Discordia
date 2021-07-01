local class = require('../class')

local VoiceRegion, get = class('VoiceRegion')

function VoiceRegion:__init(data)
	self._id = data.id
	self._name = data.name
	self._vip = data.vip
	self._optimal = data.optimal
	self._deprecated = data.deprecated
	self._custom = data.custom
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

function get:vip()
	return self._vip
end

function get:optimal()
	return self._optimal
end

function get:deprecated()
	return self._deprecated
end

function get:custom()
	return self._custom
end

return VoiceRegion
