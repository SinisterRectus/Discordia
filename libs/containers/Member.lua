local Container = require('utils/Container')
local ArrayIterable = require('iterables/ArrayIterable')

local Member = require('class')('Member', Container)
local get = Member.__getters

function Member:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
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
	self._nick = data.nick -- can be nil
	if data.roles then
		local roles = #data.roles > 0 and data.roles or nil
		if self._roles then
			self._roles._array = roles
		else
			self._roles_raw = roles
		end
	end
end

function Member:_loadPresence(presence)
	self._status = presence.status
	self._game = presence.game
end

function get.roles(self)
	if not self._roles then
		local roles = self._parent._roles
		self._roles = ArrayIterable(self._roles_raw, function(id)
			return roles:get(id)
		end)
		self._roles_raw = nil
	end
	return self._roles
end

return Member
