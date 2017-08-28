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

--[[
@class Member x UserPresence

Represents a Discord guild member. Though one user may be a member in more than
one guild, each presence is represented by a different member object associated
with that guild.
]]
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

--[[
@method getColor
@ret Color

Returns a color object that represents the member's color as determined by
its highest colored role. If the member has no colored roles, then the default
color with a value of 0 is returned.
]]
function Member:getColor()
	local roles = {}
	for role in self.roles:findAll(predicate) do
		insert(roles, role)
	end
	sort(roles, sorter)
	return roles[1] and roles[1]:getColor() or Color()
end

local function has(a, b)
	return band(a, b) > 0 or band(a, permission.administrator) > 0
end

--[[
@method hasPermission
@param [channel]: GuildChannel
@param perm: Permission Resolveable
@ret boolean

Checks whether the member has a specific permission. If `channel` is omitted,
then only guild-level permissions are checked. This is a relatively expensive
operation. If you need to check multiple permissions at once, use the
`getPermissions` method and check the resulting object.

]]
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

--[[
@method getPermissions
@param [channel]: GuildChannel
@ret Permissions

Returns a permissions object that represents the member's total permissions for
the guild, or for a specific channel if one is provided. If you just need to
check one permission, use the `hasPermission` method.
]]
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

--[[
@method addRole
@tags http
@param id: Role ID Resolveable
@ret boolean

Adds a role to the member. If the member already has the role, then no action is
taken. Note that the everyone role cannot be explicitly added.
]]
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

--[[
@method removeRole
@tags http
@param id: Role ID Resolveable
@ret boolean

Removes a role from the member. If the member does not have the role, then no
action is taken. Note that the everyone role cannot be removed.
]]
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

--[[
@method hasRole
@param id: Role ID Resolveable
@ret boolean

Checks whether the member has a specific role. This will return true for the
guild's default role in addition to any explicitly assigned roles.
]]
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

--[[
@method setNickname
@tags http
@param nickname: string
@ret boolean

Sets the member's nickname. This must be between 1 and 32 characters in length.
Pass `nil` to remove the nickname.
]]
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

--[[
@method mute
@tags http
@ret boolean

Mutes the member in its guild.
]]
function Member:mute()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {mute = true})
	if data then
		self._mute = true
		return true
	else
		return false, err
	end
end

--[[
@method unmute
@tags http
@ret boolean

Unmutes the member in its guild.
]]
function Member:unmute()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {mute = false})
	if data then
		self._mute = false
		return true
	else
		return false, err
	end
end

--[[
@method deafen
@tags http
@ret boolean

Deafens the member in its guild.
]]
function Member:deafen()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {deaf = true})
	if data then
		self._deaf = true
		return true
	else
		return false, err
	end
end

--[[
@method undeafen
@tags http
@ret boolean

Undeafens the member in its guild.
]]
function Member:undeafen()
	local data, err = self.client._api:modifyGuildMember(self._parent._id, self.id, {deaf = false})
	if data then
		self._deaf = false
		return true
	else
		return false, err
	end
end

--[[
@method kick
@tags http
@param [reason]: string
@ret boolean

Equivalent to `$.guild:kickUser($, reason)
]]
function Member:kick(reason)
	return self._parent:kickUser(self._user, reason)
end

--[[
@method ban
@tags http
@param [reason]: string
@param [days]: number
@ret boolean

Equivalent to `$.guild:banUser($, reason, days)`
]]
function Member:ban(reason, days)
	return self._parent:banUser(self._user, reason, days)
end

--[[
@method unban
@tags http
@param reason: string
@ret boolean

Equivalent to `$.guild:unbanUser($, reason)`
]]
function Member:unban(reason)
	return self._parent:unbanUser(self._user, reason)
end

--[[
@property roles: ArrayIterable

An iterable array of guild roles that the member has. This does not excplitly
include the default everyone role. Object order is not guaranteed.
]]
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

--[[
@property name: string

If the member has a nickname, then this will be equivalent to that nickname.
Otherwise, this is equivalent to `$.user.username`.
]]
function get.name(self)
	return self._nick or self._user._username
end

--[[
@property nickname: string|nil

The member's nickname, if one is set.
]]
function get.nickname(self)
	return self._nick
end

--[[
@property joinedAt: string

The date and time at which the current member joined the guild, represented as
an ISO 8601 string plus microseconds when available.
]]
function get.joinedAt(self)
	return self._joined_at
end

--[[
@property muted: boolean

Whether the member is muted in its guild.
]]
function get.muted(self)
	return self._mute
end

--[[
@property deafened: boolean

Whether the member is deafened in its guild.
]]
function get.deafened(self)
	return self._deaf
end

--[[
@property guild: Guild

The guild in which this member exists. Equivalent to `$.parent`.
]]
function get.guild(self)
	return self._parent
end

--[[
@property highestRole: Role

The highest positioned role that the member has. If the member has no
explicit roles, then this is equivalent to `$.guild.defaultRole`.
]]
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
