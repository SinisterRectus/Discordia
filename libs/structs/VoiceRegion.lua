local class = require('../class')
local Struct = require('./Struct')

local VoiceRegion, get = class('VoiceRegion', Struct)

function VoiceRegion:__init(data)
	Struct.__init(self, data)
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
