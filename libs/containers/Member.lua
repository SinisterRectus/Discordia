local Container = require('containers/abstract/Container')
local ArrayIterable = require('iterables/ArrayIterable')
local Color = require('utils/Color')
local Resolver = require('client/Resolver')

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

local function sorter(a, b)
	if a._position == b._position then
		return tonumber(a._id) < tonumber(b._id)
	else
		return a._position > b._position
	end
end

local function predicate(role)
	return role._color > 0
end

function Member:getColor()
	local roles = {}
	for role in self.roles:findAll(predicate) do
		table.insert(roles, role)
	end
	table.sort(roles, sorter)
	return roles[1] and roles[1].color or Color()
end

function Member:addRole(role) -- TODO: add to roles array
	role = Resolver.roleId(role)
	local data, err = self.client._api:addGuildMemberRole(self._parent._id, self.id, role)
	if data then
		return true
	else
		return false, err
	end
end

function Member:removeRole(role) -- TODO: remove from roles array
	role = Resolver.roleId(role)
	local data, err = self.client._api:removeGuildMemberRole(self._parent._id, self.id, role)
	if data then
		return true
	else
		return false, err
	end
end

function Member:hasRole(role)
	local roles = self._roles and self._roles._array or self._roles_raw
	if roles then
		role = Resolver.roleId(role)
		for _, id in ipairs(roles) do
			if id == role then
				return true
			end
		end
	end
	return false
end

function Member:setNickname(nick)
	nick = nick or ''
	local data, err
	if self.id == self.client._user._id then
		data, err = self.client._api:modifyCurrentUsersNick(self._parent._id, {nick = nick})
	else
		data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {nick = nick})
	end
	if data then
		if nick == '' then
			self._nick = nil
		else
			self._nick = nick
		end
		return true
	else
		return false, err
	end
end

function Member:setMuted(mute)
	mute = mute or false
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {mute = mute})
	if data then
		self._mute = mute
		return true
	else
		return false, err
	end
end

function Member:setDeafened(deaf)
	deaf = deaf or false
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {deaf = deaf})
	if data then
		self._deaf = deaf
		return true
	else
		return false, err
	end
end

function Member:kick() -- TODO: query
	return self._parent:kickUser(self._user)
end

function Member:ban() -- TODO: query
	return self._parent:banUser(self._user)
end

function Member:unban() -- TODO: query
	return self._parent:unbanUser(self._user)
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

function get.muted(self)
	return self._mute
end

function get.deafened(self)
	return self._deaf
end

function get.guild(self)
	return self._parent
end

function get.user(self)
	return self._user
end

-- user shortcuts
function get.id(self) return self._user.id end
function get.bot(self) return self._user.bot end
function get.name(self) return self._user.name end
function get.username(self) return self._user.username end
function get.discriminator(self) return self._user.discriminator end
function get.avatar(self) return self._user.avatar end
function get.defaultAvatar(self) return self._user.defaultAvatar end
function get.avatarURL(self) return self._user.avatarURL end
function get.defaultAvatarURL(self) return self._user.defaultAvatarURL end
function get.mentionString(self) return self._user.mentionString end

return Member
