local enums = require('enums')
local class = require('class')
local UserPresence = require('containers/abstract/UserPresence')
local ArrayIterable = require('iterables/ArrayIterable')
local Color = require('utils/Color')
local Resolver = require('client/Resolver')
local GuildChannel = require('containers/abstract/GuildChannel')
local Permissions = require('utils/Permissions')

local insert, remove, sort = table.insert, table.remove, table.sort
local band, bor, bnot = bit.band, bit.bor, bit.bnot
local isInstance = class.isInstance
local permission = enums.permission

local Member, get = class('Member', UserPresence)

function Member:__init(data, parent)
	UserPresence.__init(self, data, parent)
	return self:_loadMore(data)
end

function Member:_load(data)
	UserPresence._load(self, data)
	return self:_loadMore(data)
end

function Member:_loadMore(data)
	if data.roles then
		local roles = #data.roles > 0 and data.roles or nil
		if self._roles then
			self._roles._array = roles
		else
			self._roles_raw = roles
		end
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
		insert(roles, role)
	end
	sort(roles, sorter)
	return roles[1] and roles[1]:getColor() or Color()
end

local function has(a, b, admin)
	return band(a, b) > 0 or admin and band(a, permission.administrator) > 0
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
			if has(role.permissions, n, true) then
				return true
			end
		end
	end

	if has(guild.defaultRole.permissions, n, true) then
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

function Member:addRole(id)
	if self:hasRole(id) then return true end
	id = Resolver.roleId(id)
	local data, err = self.client._api:addGuildMemberRole(self._parent._id, self.id, id)
	if data then
		local roles = self._roles and self._roles._array or self._roles_raw
		if roles then
			insert(roles, id)
		else
			self._roles_raw = {id}
		end
		return true
	else
		return false, err
	end
end

function Member:removeRole(id)
	if not self:hasRole(id) then return true end
	id = Resolver.roleId(id)
	local data, err = self.client._api:removeGuildMemberRole(self._parent._id, self.id, id)
	if data then
		local roles = self._roles and self._roles._array or self._roles_raw
		if roles then
			for i, v in ipairs(roles) do
				if v == id then
					remove(roles, i)
					break
				end
			end
			if #roles == 0 then
				if self._roles then
					self._roles._array = nil
				else
					self._roles_raw = nil
				end
			end
		end
		return true
	else
		return false, err
	end
end

function Member:hasRole(id)
	id = Resolver.roleId(id)
	if id == self._parent._id then return true end -- @everyone
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

function Member:setVoiceChannel(id)
	id = Resolver.channelId(id)
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {channel_id = id})
	if data then
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

function get.voiceChannel(self)
	local guild = self._parent
	local state = guild._voice_states[self:__hash()]
	return state and guild._voice_channels:get(state.channel_id)
end

function get.muted(self)
	local state = self._parent._voice_states[self:__hash()]
	return state and (state.mute or state.self_mute) or self._mute
end

function get.deafened(self)
	local state = self._parent._voice_states[self:__hash()]
	return state and (state.deaf or state.self_deaf) or self._deaf
end

function get.guild(self)
	return self._parent
end

function get.highestRole(self)
	local ret
	for role in self.roles:iter() do
		if not ret or sorter(role, ret) then
			ret = role
		end
	end
	return ret or self.guild.defaultRole
end

return Member
