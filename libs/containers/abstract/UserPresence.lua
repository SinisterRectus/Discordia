local User = require('containers/User')
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

function get.gameName(self)
	return self._game_name
end

function get.gameType(self)
	return self._game_type
end

function get.gameURL(self)
	return self._game_url
end

function get.status(self)
	return self._status or 'offline'
end

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
