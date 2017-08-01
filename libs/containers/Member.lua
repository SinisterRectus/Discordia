local Container = require('containers/abstract/Container')
local ArrayIterable = require('iterables/ArrayIterable')
local Color = require('utils/Color')
local Resolver = require('client/Resolver')

local insert, remove, sort = table.insert, table.remove, table.sort

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
	local game = presence.game
	self._game_name = game and game.name
	self._game_type = game and game.type
	self._game_url = game and game.url
	self._status = presence.status
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
		insert(roles, role)
	end
	sort(roles, sorter)
	return roles[1] and roles[1]:getColor() or Color()
end

function Member:addRole(role)
	if self:hasRole(role) then return true end
	role = Resolver.roleId(role)
	local data, err = self.client._api:addGuildMemberRole(self._parent._id, self.id, role)
	if data then
		local roles = self._roles and self._roles._array or self._roles_raw
		if roles then
			insert(roles, role)
		else
			self._roles_raw = {role}
		end
		return true
	else
		return false, err
	end
end

function Member:removeRole(role)
	if not self:hasRole(role) then return true end
	role = Resolver.roleId(role)
	local data, err = self.client._api:removeGuildMemberRole(self._parent._id, self.id, role)
	if data then
		local roles = self._roles and self._roles._array or self._roles_raw
		if roles then
			for i, v in ipairs(roles) do
				if v == role then
					remove(roles, i)
					break
				end
			end
		end
		if #roles == 0 then
			self._roles_raw = nil
			self._roles._array = nil
		end
		return true
	else
		return false, err
	end
end

function Member:hasRole(role)
	role = Resolver.roleId(role)
	if role == self._parent._id then return true end -- @everyone
	local roles = self._roles and self._roles._array or self._roles_raw
	if roles then
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
		self._nick = nick ~= '' and nick or nil
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

function Member:kick(reason)
	return self._parent:kickUser(self._user, reason)
end

function Member:ban(reason, days)
	return self._parent:banUser(self._user, reason, days)
end

function Member:unban(reason)
	return self._parent:unbanUser(self._user, reason)
end

function Member:send(...)
	return self._user:send(...)
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
function get.username(self) return self._user.username end
function get.discriminator(self) return self._user.discriminator end
function get.avatar(self) return self._user.avatar end
function get.defaultAvatar(self) return self._user.defaultAvatar end
function get.avatarURL(self) return self._user.avatarURL end
function get.defaultAvatarURL(self) return self._user.defaultAvatarURL end
function get.mentionString(self) return self._user.mentionString end

return Member
