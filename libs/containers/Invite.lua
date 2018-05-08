--[=[@c Invite x Container desc]=]

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
@m name
@p name type
@r type
@d desc
]=]
function Invite:delete()
	local data, err = self.client._api:deleteInvite(self._code)
	if data then
		return true
	else
		return false, err
	end
end

--[=[@p code type desc]=]
function get.code(self)
	return self._code
end

--[=[@p guildId type desc]=]
function get.guildId(self)
	return self._guild_id
end

--[=[@p guildName type desc]=]
function get.guildName(self)
	return self._guild_name
end

--[=[@p channelId type desc]=]
function get.channelId(self)
	return self._channel_id
end

--[=[@p channelName type desc]=]
function get.channelName(self)
	return self._channel_name
end

--[=[@p channelType type desc]=]
function get.channelType(self)
	return self._channel_type
end

--[=[@p guildIcon type desc]=]
function get.guildIcon(self)
	return self._guild_icon
end

--[=[@p guildSplash type desc]=]
function get.guildSplash(self)
	return self._guild_splash
end

--[=[@p guildIconURL type desc]=]
function get.guildIconURL(self)
	local icon = self._guild_icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._guild_id, icon) or nil
end

--[=[@p guildSplashURL type desc]=]
function get.guildSplashURL(self)
	local splash = self._guild_splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._guild_id, splash) or nil
end

--[=[@p inviter type desc]=]
function get.inviter(self)
	return self._inviter
end

--[=[@p uses type desc]=]
function get.uses(self)
	return self._uses
end

--[=[@p maxUses type desc]=]
function get.maxUses(self)
	return self._max_uses
end

--[=[@p maxAge type desc]=]
function get.maxAge(self)
	return self._max_age
end

--[=[@p temporary type desc]=]
function get.temporary(self)
	return self._temporary
end

--[=[@p createdAt type desc]=]
function get.createdAt(self)
	return self._created_at
end

--[=[@p revoked type desc]=]
function get.revoked(self)
	return self._revoked
end

--[=[@p approximatePresenceCount type desc]=]
function get.approximatePresenceCount(self)
	return self._approximate_presence_count
end

--[=[@p approximateMemberCount type desc]=]
function get.approximateMemberCount(self)
	return self._approximate_member_count
end

return Invite
