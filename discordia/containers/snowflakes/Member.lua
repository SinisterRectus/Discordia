local Snowflake = require('../Snowflake')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Member, get, set = class('Member', Snowflake)

function Member:__init(data, parent)
	self._id = data.user.id
	Snowflake.__init(self, data, parent)
	local users = self._parent._parent._users
	self._user = users:get(data.user.id) or users:new(data.user)
	self:_update(data)
end

get('user', '_user', 'User')
get('deaf', '_deaf', 'boolean')
get('mute', '_mute', 'boolean')
get('nick', '_nick', 'string')
get('guild', '_parent', 'Guild')
get('nickname', '_nick', 'string')
get('joinedAt', '_joined_at', 'string')

get('status', function(self)
	return self._status or 'offline'
end, 'string')

get('gameName', function(self)
	return self._game and self._game.name
end, 'string')

get('name', function(self)
	return self._nick or self._user._username
end, 'string')

get('avatarUrl', function(self)
	return self._user.avatarUrl
end, 'string')

get('mentionString', function(self)
	return self._user.mentionString
end, 'string')

get('id', function(self) return self._user._id end, 'string')
get('bot', function(self) return self._user._bot end, 'boolean')
get('avatar', function(self) return self._user._avatar end, 'string')
get('username', function(self) return self._user._username end, 'string')
get('discriminator', function(self) return self._user._discriminator end, 'string')

local function setNick(self, nick)
	nick = nick or ''
	local guild = self._parent
	local client = guild._parent
	if self._user._id == client._user._id then
		return client:setNick(guild, nick)
	end
	local success = client._api:modifyGuildMember(guild._id, self._user._id, {nick = nick})
	if success then self._nick = nick end
	return success
end

set('nick', setNick)
set('nickname', setNick)

set('mute', function(self, mute)
	mute = mute or false
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {mute = mute})
	if success then self._mute = mute end
	return success
end)

set('deaf', function(self, deaf)
	deaf = deaf or false
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {deaf = deaf})
	if success then self._deaf = deaf end
	return success
end)

set('voiceChannel', function(self, channel)
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {channel_id = channel._id})
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
	local guild = self._parent
	local success = guild._parent._api:modifyGuildMember(guild._id, self._user._id, {roles = roles})
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

get('roleCount', function(self)
	return #self._roles
end, 'number')

get('roles', function(self)
	local roles = self._parent._roles
	return wrap(function()
		for _, id in ipairs(self._roles) do
			yield(roles:get(id))
		end
	end)
end, 'function')

function Member:getRole(key, value)
	local roles = self._parent._roles
	if key == nil and value == nil then return end
	if value == nil then
		value = key
		key = roles._key
	end
	for _, id in ipairs(self._roles) do
		local role = roles:get(id)
		if role[key] == value then return role end
	end
end

function Member:findRole(predicate)
	local roles = self._parent._roles
	for _, id in ipairs(self._roles) do
		local role = roles:get(id)
		if predicate(role) then return role end
	end
end

function Member:findRoles(predicate)
	return wrap(function()
		local roles = self._parent._roles
		for _, id in ipairs(self._roles) do
			local role = roles:get(id)
			if predicate(role) then yield(role) end
		end
	end)
end

return Member
