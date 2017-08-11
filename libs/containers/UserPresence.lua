local Container = require('containers/abstract/Container')

local UserPresence, get = require('class')('UserPresence', Container)

function UserPresence:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function UserPresence:__hash()
	return self._user._id
end

function UserPresence:_loadPresence(presence)
	local game = presence.game
	self._game_name = game and game.name
	self._game_type = game and game.type
	self._game_url = game and game.url
	self._status = presence.status
end

--[[
@method send
@param content: string|table
@ret Message
]]
function UserPresence:send(content)
	return self._user:send(content)
end

--[[
@property gameName: string|nil
]]
function get.gameName(self)
	return self._game_name
end

--[[
@property gameType: number|nil
]]
function get.gameType(self)
	return self._game_type
end

--[[
@property gameURL: string|nil
]]
function get.gameURL(self)
	return self._game_url
end

--[[
@property status: string
]]
function get.status(self)
	return self._status or 'offline'
end

--[[
@property user: User
]]
function get.user(self)
	return self._user
end

-- user shortcuts

--[[
@property id: string
]]
function get.id(self)
	return self._user.id
end

--[[
@property bot: boolean
]]
function get.bot(self)
	return self._user.bot
end

--[[
@property username: string
]]
function get.username(self)
	return self._user.username
end

--[[
@property discriminator: string
]]
function get.discriminator(self)
	return self._user.discriminator
end

--[[
@property avatar: string|nil
]]
function get.avatar(self)
	return self._user.avatar
end

--[[
@property defaultAvatar: number
]]
function get.defaultAvatar(self)
	return self._user.defaultAvatar
end

--[[
@property avatarURL: string
]]
function get.avatarURL(self)
	return self._user.avatarURL
end

--[[
@property defaultAvatarURL: string
]]
function get.defaultAvatarURL(self)
	return self._user.defaultAvatarURL
end

--[[
@property mentionString: string
]]
function get.mentionString(self)
	return self._user.mentionString
end

return UserPresence
