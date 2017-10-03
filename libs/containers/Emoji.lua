local Snowflake = require('containers/abstract/Snowflake')
local ArrayIterable = require('iterables/ArrayIterable')

local format = string.format

local Emoji, get = require('class')('Emoji', Snowflake)

function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
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

function get.name(self)
	return self._name
end

function get.guild(self)
	return self._parent
end

function get.mentionString(self)
	return format('<:%s>', self.hash)
end

function get.url(self)
	return format('https://cdn.discordapp.com/emojis/%s.png', self._id)
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
