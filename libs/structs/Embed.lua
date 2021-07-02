local class = require('../class')

local helpers = require('../helpers')

local EmbedFooter = require('./EmbedFooter')
local EmbedImage = require('./EmbedImage')
local EmbedThumbnail = require('./EmbedThumbnail')
local EmbedVideo = require('./EmbedVideo')
local EmbedProvider = require('./EmbedProvider')
local EmbedAuthor = require('./EmbedAuthor')
local EmbedField = require('./EmbedField')

local Embed, get = class('Embed')

function Embed:__init(data)

	self._title = data.title
	self._type = data.type
	self._description = data.description
	self._url = data.url
	self._timestamp = data.timestamp
	self._color = data.color

	self._footer = data.footer and EmbedFooter(data.footer)
	self._image = data.image and EmbedImage(data.image)
	self._thumbnail = data.thumbnail and EmbedThumbnail(data.thumbnail)
	self._video = data.video and EmbedVideo(data.video)
	self._provider = data.provider and EmbedProvider(data.provider)
	self._author = data.author and EmbedAuthor(data.author)

	self._fields = helpers.structs(EmbedField, data.fields)

end

function get:title()
	return self._title
end

function get:type()
	return self._type
end

function get:description()
	return self._description
end

function get:url()
	return self._url
end

function get:timestamp()
	return self._timestamp
end

function get:color()
	return self._color
end

function get:footer()
	return self._footer
end

function get:image()
	return self._image
end

function get:thumbnail()
	return self._thumbnail
end

function get:video()
	return self._video
end

function get:provider()
	return self._provider
end

function get:author()
	return self._author
end

function get:fields()
	return self._fields
end

return Embed
