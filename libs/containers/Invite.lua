local Container = require('containers/abstract/Container')

local format = string.format

local Invite, get = require('class')('Invite', Container)

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
	self._guild_id = data.guild.id
	self._channel_id = data.channel.id
	self._guild_name = data.guild.name
	self._guild_icon = data.guild_icon
	self._guild_splash = data.guild_splash
	self._channel_name = data.channel.name
	self._channel_type = data.channel.type
	if data.inviter then
		self._inviter = self.client._users:_insert(data.inviter)
	end
end

function Invite:__hash()
	return self._code
end

--[[
@method delete
@ret boolean
]]
function Invite:delete()
	local data, err = self.client._api:deleteInvite(self._code)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@property code: string
]]
function get.code(self)
	return self._code
end

--[[
@property guildId: string
]]
function get.guildId(self)
	return self._guild_id
end

--[[
@property guildName: string
]]
function get.guildName(self)
	return self._guild_name
end

--[[
@property channelId: string
]]
function get.channelId(self)
	return self._channel_id
end

--[[
@property channelName: string
]]
function get.channelName(self)
	return self._channel_name
end

--[[
@property channelType: number
]]
function get.channelType(self)
	return self._channel_type
end

--[[
@property guildIcon: string|nil
]]
function get.guildIcon(self)
	return self._guild_icon
end

--[[
@property guildSplash: string|nil
]]
function get.guildSplash(self)
	return self._guild_splash
end

--[[
@property guildIconURL: string|nil
]]
function get.guildIconURL(self)
	local icon = self._guild_icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._guild_id, icon) or nil
end

--[[
@property guildSplashURL: string|nil
]]
function get.guildSplashURL(self)
	local splash = self._guild_splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._guild_id, splash) or nil
end

--[[
@property inviter: User|nil
]]
function get.inviter(self)
	return self._inviter
end

--[[
@property uses: number|nil
]]
function get.uses(self)
	return self._uses
end

--[[
@property maxUses: number|nil
]]
function get.maxUses(self)
	return self._max_uses
end

--[[
@property maxAge: number|nil
]]
function get.maxAge(self)
	return self._max_age
end

--[[
@property temporary: boolean|nil
]]
function get.temporary(self)
	return self._temporary
end

--[[
@property createdAt: string|nil
]]
function get.createdAt(self)
	return self._created_at
end

--[[
@property revoked: boolean|nil
]]
function get.revoked(self)
	return self._revoked
end

return Invite
