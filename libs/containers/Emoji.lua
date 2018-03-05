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

function Emoji:setName(name)
	return self:_modify({name = name or json.null})
end

function Emoji:setRoles(roles)
	roles = Resolver.roleIds(roles)
	return self:_modify({roles = roles or json.null})
end

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

function get.name(self)
	return self._name
end

function get.guild(self)
	return self._parent
end

function get.mentionString(self)
	local fmt = self._animated and '<a:%s>' or '<:%s>'
	return format(fmt, self.hash)
end

function get.url(self)
	local ext = self._animated and 'gif' or 'png'
	return format('https://cdn.discordapp.com/emojis/%s.%s', self._id, ext)
end

function get.managed(self)
	return self._managed
end

function get.requireColons(self)
	return self._require_colons
end

function get.hash(self)
	return self._name .. ':' .. self._id
end

function get.animated(self)
	return self._animated
end

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
