local class = require('../class')

local ActivityAssets, get = class('ActivityAssets')

function ActivityAssets:__init(data)
	self._large_image = data.large_image
	self._large_text = data.large_text
	self._small_image = data.small_image
	self._small_text = data.small_text
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
