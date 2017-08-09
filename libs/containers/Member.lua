local enums = require('enums')
local class = require('class')
local Container = require('containers/abstract/Container')
local ArrayIterable = require('iterables/ArrayIterable')
local Color = require('utils/Color')
local Resolver = require('client/Resolver')
local GuildChannel = require('containers/abstract/GuildChannel')
local Permissions = require('utils/Permissions')

local insert, remove, sort = table.insert, table.remove, table.sort
local band, bor, bnot = bit.band, bit.bor, bit.bnot
local isInstance = class.isInstance
local permission = enums.permission

local Member, get = class('Member', Container)

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


function Member:getColor()
	return Color(self.color)
end

local function has(a, b)
	return band(a, b) > 0 or band(a, permission.administrator) > 0
end

function Member:hasPermission(channel, perm)

	if not perm then
		perm = channel
		channel = nil
	end

	local guild = self.guild
	if channel then
		if not isInstance(channel, GuildChannel) or channel.guild ~= guild then
			return error('Invalid GuildChannel: ' .. tostring(channel), 2)
		end
	end

	local n = Resolver.permission(perm)
	if not n then
		return error('Invalid permission: ' .. tostring(perm), 2)
	end

	if self.id == guild.ownerId then
		return true
	end

	if channel then

		local overwrites = channel.permissionOverwrites

		local overwrite = overwrites:get(self.id)
		if overwrite then
			if has(overwrite.allowedPermissions, n) then
				return true
			end
			if has(overwrite.deniedPermissions, n) then
				return false
			end
		end

		local allow, deny = 0, 0
		for role in self.roles:iter() do
			if role.id ~= guild.id then -- just in case
				overwrite = overwrites:get(role.id)
				if overwrite then
					allow = bor(allow, overwrite.allowedPermissions)
					deny = bor(deny, overwrite.deniedPermissions)
				end
			end
		end

		if has(allow, n) then
			return true
		end
		if has(deny, n) then
			return false
		end

		local everyone = overwrites:get(guild.id)
		if everyone then
			if has(everyone.allowedPermissions, n) then
				return true
			end
			if has(everyone.deniedPermissions, n) then
				return false
			end
		end

	end

	for role in self.roles:iter() do
		if role.id ~= guild.id then -- just in case
			if has(role.permissions, n) then
				return true
			end
		end
	end

	if has(guild.defaultRole.permissions, n) then
		return true
	end

	return false

end

function Member:getPermissions(channel)

	local guild = self.guild
	if channel then
		if not isInstance(channel, GuildChannel) or channel.guild ~= guild then
			return error('Invalid GuildChannel: ' .. tostring(channel), 2)
		end
	end

	if self.id == guild.ownerId then
		return Permissions.all()
	end

	local ret = guild.defaultRole.permissions

	for role in self.roles:iter() do
		if role.id ~= guild.id then -- just in case
			ret = bor(ret, role.permissions)
		end
	end

	if band(ret, permission.administrator) > 0 then
		return Permissions.all()
	end

	if channel then

		local overwrites = channel.permissionOverwrites

		local everyone = overwrites:get(guild.id)
		if everyone then
			ret = band(ret, bnot(everyone.deniedPermissions))
			ret = bor(ret, everyone.allowedPermissions)
		end

		local allow, deny = 0, 0
		for role in self.roles:iter() do
			if role.id ~= guild.id then -- just in case
				local overwrite = overwrites:get(role.id)
				if overwrite then
					deny = bor(deny, overwrite.deniedPermissions)
					allow = bor(allow, overwrite.allowedPermissions)
				end
			end
		end
		ret = band(ret, bnot(deny))
		ret = bor(ret, allow)

		local overwrite = overwrites:get(self.id)
		if overwrite then
			ret = band(ret, bnot(overwrite.deniedPermissions))
			ret = bor(ret, overwrite.allowedPermissions)
		end

	end

	return Permissions(ret)

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

function Member:mute()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {mute = true})
	if data then
		self._mute = true
		return true
	else
		return false, err
	end
end

function Member:unmute()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {mute = false})
	if data then
		self._mute = false
		return true
	else
		return false, err
	end
end

function Member:deafen()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {deaf = true})
	if data then
		self._deaf = true
		return true
	else
		return false, err
	end
end

function Member:undeafen()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {deaf = false})
	if data then
		self._deaf = false
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

function Member:send(content)
	return self._user:send(content)
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

local function sorter(a, b)
	if a._position == b._position then
		return tonumber(a._id) < tonumber(b._id)
	else
		return a._position > b._position
	end
end

function get.highestRole(self)
	local ret
	for role in self.roles:iter() do
		if not ret or sorter(role, ret) then
			ret = role
		end
	end
	return ret
end

local function predicate(role)
	return role._color > 0
end

function get.color(self)
	local roles = {}
	for role in self.roles:findAll(predicate) do
		insert(roles, role)
	end
	sort(roles, sorter)
	return roles[1] and roles[1]._color or 0
end

-- user shortcuts

function get.id(self)
	return self._user.id
end

function get.bot(self)
	return self._user.bot
end

function get.username(self)
	return self._user.username
end

function get.discriminator(self)
	return self._user.discriminator
end

function get.avatar(self)
	return self._user.avatar
end

function get.defaultAvatar(self)
	return self._user.defaultAvatar
end

function get.avatarURL(self)
	return self._user.avatarURL
end

function get.defaultAvatarURL(self)
	return self._user.defaultAvatarURL
end

function get.mentionString(self)
	return self._user.mentionString
end

return Member
