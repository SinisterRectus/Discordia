local Container = require('utils/Container')
local ArrayIterable = require('iterables/ArrayIterable')
local Color = require('utils/Color')

local Member = require('class')('Member', Container)
local get = Member.__getters

function Member:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
	return self:_loadMore(data)
end

function Member:__hash()
	return self._user._id
end

function Member:_load(data)
	Container._load(self, data)
	return self:_loadMore(data)
end

function Member:_loadMore(data)
	self._nick = data.nick -- can be nil
	if data.roles then
		local roles = #data.roles > 0 and data.roles or nil
		if self._roles then
			self._roles._array = roles
		else
			self._roles_raw = roles
		end
	end
end

function Member:_loadPresence(presence)
	self._status = presence.status
	if presence.game then
		self._game_name = presence.game.name
		self._game_type = presence.game.type
		self._game_url = presence.game.url
	end
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

function get.name(self)
	return self._nick or self._user._username
end

function get.nickname(self)
	return self._nick
end

function get.joinedAt(self)
	return self._joined_at
end

function get.gameName(self)
	return self._game_name
end

function get.gameType(self)
	return self._game_type
end

function get.gameURL(self)
	return self._game_url
end

function get.status(self)
	return self._status
end

function get.guild(self)
	return self._parent
end

function get.user(self)
	return self._user
end

local function sorter(a, b)
	if a._position == b._position then -- TODO: needs testing
		return tonumber(a._id) < tonumber(b._id)
	else
		return a._position > b._position
	end
end

local function predicate(role)
	return role._color > 0
end

function get.color(self)
	local roles = {}
	for role in self.roles:findAll(predicate) do
		table.insert(roles, role)
	end
	table.sort(roles, sorter)
	return roles[1] and roles[1].color or Color()
end

-- TODO: user shortcuts

return Member
