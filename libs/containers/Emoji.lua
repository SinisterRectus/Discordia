--[=[
@c Emoji x Snowflake
@d Represents a custom emoji object usable in message content and reactions.
Standard unicode emojis do not have a class; they are just strings.
]=]

local Snowflake = require('containers/abstract/Snowflake')
local Resolver = require('client/Resolver')
local ArrayIterable = require('iterables/ArrayIterable')
local json = require('json')

local format = string.format

local Emoji, get = require('class')('Emoji', Snowflake)

function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.client._emoji_map[self._id] = parent
	return self:_loadMore(data)
end

function Emoji:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Emoji:_loadMore(data)
	if data.roles then
		local roles = #data.roles > 0 and data.roles or nil
		if self._roles then
			self._roles._array = roles
		else
			self._roles_raw = roles
		end
	end
end

function Emoji:_modify(payload)
	local data, err = self.client._api:modifyGuildEmoji(self._parent._id, self._id, payload)
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
@d Sets the emoji's name. The name must be between 2 and 32 characters in length.
]=]
function Emoji:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setRoles
@t http
@p roles Role-ID-Resolvables
@r boolean
@d Sets the roles that can use the emoji.
]=]
function Emoji:setRoles(roles)
	roles = Resolver.roleIds(roles)
	return self:_modify({roles = roles or json.null})
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the emoji. This cannot be undone!
]=]
function Emoji:delete()
	local data, err = self.client._api:deleteGuildEmoji(self._parent._id, self._id)
	if data then
		local cache = self._parent._emojis
		if cache then
			cache:_delete(self._id)
		end
		return true
	else
		return false, err
	end
end

--[=[
@m hasRole
@t mem
@p id Role-ID-Resolvable
@r boolean
@d Returns whether or not the provided role is allowed to use the emoji.
]=]
function Emoji:hasRole(id)
	id = Resolver.roleId(id)
	local roles = self._roles and self._roles._array or self._roles_raw
	if roles then
		for _, v in ipairs(roles) do
			if v == id then
				return true
			end
		end
	end
	return false
end

--[=[@p name string The name of the emoji.]=]
function get.name(self)
	return self._name
end

--[=[@p guild Guild The guild in which the emoji exists.]=]
function get.guild(self)
	return self._parent
end

--[=[@p mentionString string A string that, when included in a message content, may resolve as an emoji image
in the official Discord client.]=]
function get.mentionString(self)
	local fmt = self._animated and '<a:%s>' or '<:%s>'
	return format(fmt, self.hash)
end

--[=[@p url string The URL that can be used to view a full version of the emoji.]=]
function get.url(self)
	local ext = self._animated and 'gif' or 'png'
	return format('https://cdn.discordapp.com/emojis/%s.%s', self._id, ext)
end

--[=[@p managed boolean Whether this emoji is managed by an integration such as Twitch or YouTube.]=]
function get.managed(self)
	return self._managed
end

--[=[@p requireColons boolean Whether this emoji requires colons to be used in the official Discord client.]=]
function get.requireColons(self)
	return self._require_colons
end

--[=[@p hash string String with the format `name:id`, used in HTTP requests.
This is different from `Emoji:__hash`, which returns only the Snowflake ID.
]=]
function get.hash(self)
	return self._name .. ':' .. self._id
end

--[=[@p animated boolean Whether this emoji is animated.]=]
function get.animated(self)
	return self._animated
end

--[=[@p roles ArrayIterable An iterable array of roles that may be required to use this emoji, generally
related to integration-managed emojis. Object order is not guaranteed.]=]
function get.roles(self)
	if not self._roles then
		local roles = self._parent._roles
		self._roles = ArrayIterable(self._roles_raw, function(id)
			return roles:get(id)
		end)
		self._roles_raw = nil
	end
	return self._roles
end

return Emoji
