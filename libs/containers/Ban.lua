--[=[
@c Ban x Container
@d Represents a Discord guild ban. Essentially a combination of the banned user and
a reason explaining the ban, if one was provided.
]=]

local Container = require('containers/abstract/Container')

local Ban, get = require('class')('Ban', Container)

function Ban:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

--[=[
@m __hash
@r string
@d Returns `Ban.user.id`
]=]
function Ban:__hash()
	return self._user._id
end

--[=[
@m delete
@r boolean
@d Deletes the ban object, essentially unbanning the corresponding user.
Equivalent to `Ban.guild:unbanUser(Ban.user)`.
]=]
function Ban:delete()
	return self._parent:unbanUser(self._user)
end

--[=[@p reason string/nil The reason for the ban, if one was set. This should be from 1 to 512 characters
in length.]=]
function get.reason(self)
	return self._reason
end

--[=[@p guild Guild The guild in which this ban object exists.]=]
function get.guild(self)
	return self._parent
end

--[=[@p user User The user that this ban object represents.]=]
function get.user(self)
	return self._user
end

return Ban
