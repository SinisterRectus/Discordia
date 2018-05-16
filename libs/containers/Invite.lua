--[=[@c Invite x Container ...]=]

local Container = require('containers/abstract/Container')
local json = require('json')

local format = string.format
local null = json.null

local function load(v)
	return v ~= null and v or nil
end

local Invite, get = require('class')('Invite', Container)

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
	self._guild_id = load(data.guild.id)
	self._channel_id = load(data.channel.id)
	self._guild_name = load(data.guild.name)
	self._guild_icon = load(data.guild.icon)
	self._guild_splash = load(data.guild.splash)
	self._channel_name = load(data.channel.name)
	self._channel_type = load(data.channel.type)
	if data.inviter then
		self._inviter = self.client._users:_insert(data.inviter)
	end
end

function Invite:__hash()
	return self._code
end

--[=[
@m delete
@r boolean
@d ...
]=]
function Invite:delete()
	local data, err = self.client._api:deleteInvite(self._code)
	if data then
		return true
	else
		return false, err
	end
end

--[=[@p code string ...]=]
function get.code(self)
	return self._code
end

--[=[@p guildId string ...]=]
function get.guildId(self)
	return self._guild_id
end

--[=[@p guildName string ...]=]
function get.guildName(self)
	return self._guild_name
end

--[=[@p channelId string ...]=]
function get.channelId(self)
	return self._channel_id
end

--[=[@p channelName string ...]=]
function get.channelName(self)
	return self._channel_name
end

--[=[@p channelType number ...]=]
function get.channelType(self)
	return self._channel_type
end

--[=[@p guildIcon string|nil ...]=]
function get.guildIcon(self)
	return self._guild_icon
end

--[=[@p guildSplash string|nil ...]=]
function get.guildSplash(self)
	return self._guild_splash
end

--[=[@p guildIconURL string|nil ...]=]
function get.guildIconURL(self)
	local icon = self._guild_icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._guild_id, icon) or nil
end

--[=[@p guildSplashURL string|nil ...]=]
function get.guildSplashURL(self)
	local splash = self._guild_splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._guild_id, splash) or nil
end

--[=[@p inviter User|nil ...]=]
function get.inviter(self)
	return self._inviter
end

--[=[@p uses number|nil ...]=]
function get.uses(self)
	return self._uses
end

--[=[@p maxUses number|nil ...]=]
function get.maxUses(self)
	return self._max_uses
end

--[=[@p maxAge number|nil ...]=]
function get.maxAge(self)
	return self._max_age
end

--[=[@p temporary boolean|nil ...]=]
function get.temporary(self)
	return self._temporary
end

--[=[@p createdAt string ...]=]
function get.createdAt(self)
	return self._created_at
end

--[=[@p revoked boolean|nil ...]=]
function get.revoked(self)
	return self._revoked
end

--[=[@p approximatePresenceCount number|nil ...]=]
function get.approximatePresenceCount(self)
	return self._approximate_presence_count
end

--[=[@p approximateMemberCount number|nil ...]=]
function get.approximateMemberCount(self)
	return self._approximate_member_count
end

return Invite
