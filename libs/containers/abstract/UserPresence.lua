
local Container = require('containers/abstract/Container')

local UserPresence, get = require('class')('UserPresence', Container)

--[[
@abc UserPresence x Container

Abstract base class that defines the base methods and/or properties for
classes that represent a user's current presence information.
]]
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
@tags http
@param content: string|table
@ret Message

Equivalent to `$.user:send(content)`
]]
function UserPresence:send(content)
	return self._user:send(content)
end

--[[
@property gameName: string|nil

The game that the user is currently playing.
]]
function get.gameName(self)
	return self._game_name
end

--[[
@property gameType: number|nil

The type of user's game status. See the `gameType` enumeration for a
human-readable representation.
]]
function get.gameType(self)
	return self._game_type
end

--[[
@property gameURL: string|nil

The URL that is set for a user's streaming game status.
]]
function get.gameURL(self)
	return self._game_url
end

--[[
@property status: string

The user's online status (online, dnd, idle, offline).
]]
function get.status(self)
	return self._status or 'offline'
end

--[[
@property user: User

The user that this presence represents.
]]
function get.user(self)
	return self._user
end

-- user shortcuts

--[[
@property id: string
Equivalent to `$.user.id`.
]]
function get.id(self)
	return self._user.id
end

--[[
@property bot: boolean
Equivalent to `$.user.bot`.
]]
function get.bot(self)
	return self._user.bot
end

--[[
@property username: string
Equivalent to `$.user.username`.
]]
function get.username(self)
	return self._user.username
end

--[[
@property discriminator: string
Equivalent to `$.user.discriminator`.
]]
function get.discriminator(self)
	return self._user.discriminator
end

--[[
@property fullname: string
Equivalent to `$.user.fullname`.
]]
function get.fullname(self)
	return self._user.fullname
end

--[[
@property avatar: string|nil
Equivalent to `$.user.avatar`.
]]
function get.avatar(self)
	return self._user.avatar
end

--[[
@property defaultAvatar: number
Equivalent to `$.user.defaultAvatar`.
]]
function get.defaultAvatar(self)
	return self._user.defaultAvatar
end

--[[
@property avatarURL: string
Equivalent to `$.user.avatarURL`.
]]
function get.avatarURL(self)
	return self._user.avatarURL
end

--[[
@property defaultAvatarURL: string
Equivalent to `$.user.defaultAvatarURL`.
]]
function get.defaultAvatarURL(self)
	return self._user.defaultAvatarURL
end

--[[
@property mentionString: string
Equivalent to `$.user.mentionString`.
]]
function get.mentionString(self)
	return self._user.mentionString
end

--[[
@property createdAt: number
Equivalent to `$.user.createdAt`.
]]
function get.createdAt(self)
	return self._user.createdAt
end

--[[
@property timestamp: string
Equivalent to `$.user.timestamp`.
]]
function get.timestamp(self)
	return self._user.timestamp
end

return UserPresence
