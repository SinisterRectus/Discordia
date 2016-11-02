local Snowflake = require('../Snowflake')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Member, get, set = class('Member', Snowflake)

function Member:__init(data, parent)
	self._id = data.user.id
	Snowflake.__init(self, data, parent)
	self._user = self.client._users:get(data.user.id) or self.client._users:new(data.user)
	self:_update(data)
end

get('user', '_user')
get('deaf', '_deaf')
get('mute', '_mute')
get('mute', '_mute')
get('nick', '_nick')
get('game', '_game')
get('guild', '_parent')
get('nickname', '_nick')
get('joinedAt', '_joined_at')

get('status', function(self)
	return self._status or 'offline'
end)

get('name', function(self)
	return self._nick or self._user._username
end)

get('avatarUrl', function(self)
	return self._user.avatarUrl
end)

get('mentionString', function(self)
	return self._user.mentionString
end)

get('id', function(self) return self._user._id end)
get('bot', function(self) return self._user._bot end)
get('avatar', function(self) return self._user._avatar end)
get('username', function(self) return self._user._username end)
get('discriminator', function(self) return self._user._discriminator end)

local function setNick(self, nick)
	local nick = nick or ''
	if self._user._id == self.client._user._id then
		return self.client:setNick(self._parent, nick)
	end
	local success = self.client.api:modifyGuildMember(self._parent._id, self._user._id, {nick = nick})
	if success then self._nick = nick end
	return success
end

set('nick', setNick)
set('nickname', setNick)

set('mute', function(self, mute)
	mute = mute or false
	local success = self.client.api:modifyGuildMember(self._parent._id, self._user._id, {mute = mute})
	if success then self._mute = mute end
	return success
end)

set('deaf', function(self, deaf)
	deaf = deaf or false
	local success = self.client.api:modifyGuildMember(self._parent._id, self._user._id, {deaf = deaf})
	if success then self._deaf = deaf end
	return success
end)

set('voiceChannel', function(self, channel)
	local success = self.client.api:modifyGuildMember(self._parent._id, self._user._id, {channel_id = channel._id})
	return success
end)

function Member:__tostring()
	if self._nick then
		return format('%s: %s (%s)', self.__name, self._user._username, self._nick)
	else
		return format('%s: %s', self.__name, self._user._username)
	end
end

function Member:_update(data)
	Snowflake._update(self, data)
	self._roles = data.roles -- raw table of IDs
	self._nick = data.nick
end

function Member:_createPresence(data)
	self._status = data.status
	self._game = data.game
end

function Member:_updatePresence(data)
	self:_createPresence(data)
	self._user:_update(data.user)
end

-- User-compatability methods --

function Member:getMembership(guild)
	return self._user:getMembership(guild or self._parent)
end

function Member:sendMessage(...)
	return self._user:sendMessage(...)
end

function Member:ban(guild, days)
	if not days and type(guild) == 'number' then
		days, guild = guild, self._parent
	end
	return self._user:ban(guild or self._parent, days)
end

function Member:unban(guild)
	return self._user:unban(guild or self._parent)
end

function Member:kick(guild)
	return self._user:kick(guild or self._parent)
end

local function mapRoles(roles, map, tbl)
	if roles.iter then
		for role in roles:iter() do
			map(role, tbl)
		end
	else
		for _, role in pairs(roles) do
			map(role, tbl)
		end
	end
	return tbl
end

local function applyRoles(self, roles)
	local success = self.client.api:modifyGuildMember(self._parent._id, self._user._id, {roles = roles})
	if success then self._roles = roles end
	return success
end

set('roles', function(self, roles)
	local map = function(role, tbl)
		insert(tbl, role._id)
	end
	local role_ids = mapRoles(roles, map, {})
	return applyRoles(self, role_ids)
end)

function Member:addRoles(roles)
	local map = function(role, tbl)
		insert(tbl, role._id)
	end
	local role_ids = mapRoles(roles, map, self._roles)
	return applyRoles(self, role_ids)
end

function Member:removeRoles(roles)
	local map = function(role, tbl)
		tbl[role._id] = true
	end
	local removals = mapRoles(roles, map, {})
	local role_ids = {}
	for _, id in ipairs(self._roles) do
		if not removals[id] then
			insert(role_ids, id)
		end
	end
	return applyRoles(self, role_ids)
end

function Member:addRole(role)
	local role_ids = {role._id}
	for _, id in ipairs(self._roles) do
		insert(role_ids, id)
	end
	return applyRoles(self, role_ids)
end

function Member:removeRole(role)
	local role_ids = {}
	for _, id in ipairs(self._roles) do
		if id ~= role._id then
			insert(role_ids, id)
		end
	end
	return applyRoles(self, role_ids)
end

get('roles', function(self)
	local roles = self._parent._roles
	return wrap(function()
		for _, id in ipairs(self._roles) do
			yield(roles:get(id))
		end
	end)
end)

return Member
