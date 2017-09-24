local Container = require('containers/abstract/Container')

local Ban, get = require('class')('Ban', Container)

function Ban:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function Ban:__hash()
	return self._user._id
end

function Ban:delete()
	return self._parent:unbanUser(self._user)
end

function get.reason(self)
	return self._reason
end

function get.guild(self)
	return self._parent
end

function get.user(self)
	return self._user
end

return Ban
