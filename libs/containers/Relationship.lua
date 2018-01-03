local UserPresence = require('containers/abstract/UserPresence')

local Relationship, get = require('class')('Relationship', UserPresence)

function Relationship:__init(data, parent)
	UserPresence.__init(self, data, parent)
end

function Relationship:__serializeJSON(null)
	return {
		type = 'Relationship',

		game_name = self._game_name or null,
		game_type = self._game_type or null,
		game_url = self._game_url or null,
		status = self._status or null,
		user = self._user:__serializeJSON(null),

		name = self._user._username,
		relationship_type = self._type
	}
end

function get.name(self)
	return self._user._username
end

function get.type(self)
	return self._type
end

return Relationship
