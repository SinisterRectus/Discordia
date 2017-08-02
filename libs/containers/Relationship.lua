local Snowflake = require('containers/abstract/Snowflake')

local Relationship, get = require('class')('Relationship', Snowflake)

function Relationship:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function Relationship:_loadPresence(presence)
	local game = presence.game
	self._game_name = game and game.name
	self._game_type = game and game.type
	self._game_url = game and game.url
	self._status = presence.status
end

function get.name(self)
	return self._user._username
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

function get.type(self)
	return self._type
end

-- user shortcuts
function get.id(self) return self._user.id end
function get.bot(self) return self._user.bot end
function get.username(self) return self._user.username end
function get.discriminator(self) return self._user.discriminator end
function get.avatar(self) return self._user.avatar end
function get.defaultAvatar(self) return self._user.defaultAvatar end
function get.avatarURL(self) return self._user.avatarURL end
function get.defaultAvatarURL(self) return self._user.defaultAvatarURL end
function get.mentionString(self) return self._user.mentionString end

return Relationship
