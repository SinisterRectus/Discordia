local Container = require('containers/abstract/Container')

local Ban, get = require('class')('Ban', Container)

function Ban:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function Ban:__hash()
	return self._user._id
end

--[[
@method delete
@ret boolean
]]
function Ban:delete()
	return self._parent:unbanUser(self._user)
end

--[[
@property reason: string|nil
]]
function get.reason(self)
	return self._reason
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent
end

--[[
@property user: User
]]
function get.user(self)
	return self._user
end

return Ban
