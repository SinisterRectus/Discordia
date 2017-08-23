local User = require('containers/User')
local Container = require('containers/abstract/Container')

local UserPresence, get = require('class')('UserPresence', Container)

--[[
@abc UserPresence x Container

Abstract base class that defines the base methods and/or properties for
classes that represent a user's current presence information. Note that any
method or property that exists for the User class is also available in the
UserPresence class and its subclasses.
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

for k, v in pairs(User) do
	UserPresence[k] = UserPresence[k] or function(self, ...)
		return v(self._user, ...)
	end
end

for k, v in pairs(User.__getters) do
	get[k] = get[k] or function(self)
		return v(self._user)
	end
end

return UserPresence
