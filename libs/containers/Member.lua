local Container = require('utils/Container')

local Member = require('class')('Member', Container)

function Member:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:insert(data.user)
	return self:_loadMore(data)
end

function Member:__hash()
	return self._user._id
end

function Member:_load(data)
	Container._load(self, data)
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
