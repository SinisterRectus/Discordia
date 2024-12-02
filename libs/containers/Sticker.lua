--[=[
@c Sticker x Snowflake
@d Represents a sticker object.
]=]

local Snowflake = require('containers/abstract/Snowflake')
local json = require('json')

local format = string.format

local Sticker, get = require('class')('Sticker', Snowflake)

function Sticker:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.client._sticker_map[self._id] = parent
end

function Sticker:_load(data)
	Snowflake._load(self, data)
end

function Sticker:_modify(payload)
	local data, err = self.client._api:modifyGuildSticker(self._parent._id, self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[=[
@m setName
@t http
@p name string
@r boolean
@d Sets the stickers's name. The name must be between 2 and 30 characters in length.
]=]
function Sticker:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setDescription
@t http
@p description string
@r boolean
@d Sets the stickers's description. The description must be between 2 and 30 characters in length.
]=]
function Sticker:setDescription(description)
	return self:_modify({description = description or json.null})
end

--[=[
@m setTags
@t http
@p tags string
@r boolean
@d Sets the stickers's tags. The tags can only be up to 200 characters long.
]=]
function Sticker:setTags(tags)
	return self:_modify({tags = tags or json.null})
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the sticker. This cannot be undone!
]=]
function Sticker:delete()
	local data, err = self.client._api:deleteGuildSticker(self._parent._id, self._id)
	if data then
		self._parent._stickers:_delete(self._id)
		return true
	else
		return false, err
	end
end

--[=[@p name string The name of the sticker.]=]
function get.name(self)
	return self._name
end

--[=[@p description string The description of the sticker.]=]
function get.description(self)
	return self._description
end

--[=[@p tags string The tags of the sticker.]=]
function get.tags(self)
	return self._tags
end

--[=[@p type number The sticker format type.]=]
function get.type(self)
	return self._format_type
end

--[=[@p guild Guild The guild in which the sticker exists.]=]
function get.guild(self)
	return self._parent
end

--[=[@p url string The URL that can be used to view a full version of the sticker.]=]
function get.url(self)
	return format('https://cdn.discordapp.com/stickers/%s.png', self._id)
end

return Sticker