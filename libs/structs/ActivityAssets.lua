local class = require('../class')

local Struct = require('./Struct')

local ActivityAssets, get = class('ActivityAssets', Struct)

function ActivityAssets:__init(data)
	Struct.__init(self, data)
end

function get:largeImage()
	return self._large_image
end

function get:largeText()
	return self._large_text
end

function get:smallImage()
	return self._small_image
end

function get:smallText()
	return self._small_text
end


return ActivityAssets
