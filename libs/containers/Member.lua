local Snowflake = require('containers/abstract/Snowflake')

local Member = require('class')('Member', Snowflake)

function Member:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._id = data.user.id -- hacks
	self._user = self.client._users:insert(data.user)
	return self:_loadMore(data)
end

function Member:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Member:_loadMore(data)
	self._roles = data.roles -- raw table of IDs
	self._nick = data.nick -- can be nil
end

function Member:_loadPresence(presence)
	self._status = presence.status
	self._game = presence.game
end

return Member
