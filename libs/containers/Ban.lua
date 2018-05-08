--[=[@c Ban x Container desc]=]

local Container = require('containers/abstract/Container')

local Ban, get = require('class')('Ban', Container)

function Ban:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function Ban:__hash()
	return self._user._id
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Ban:delete()
	return self._parent:unbanUser(self._user)
end

--[=[@p reason type desc]=]
function get.reason(self)
	return self._reason
end

--[=[@p guild type desc]=]
function get.guild(self)
	return self._parent
end

--[=[@p user type desc]=]
function get.user(self)
	return self._user
end

return Ban
