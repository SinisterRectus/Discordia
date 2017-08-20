local Container = require('containers/abstract/Container')

local Ban, get = require('class')('Ban', Container)

--[[
@class Ban x Container

Represents a Discord guild ban. Essentially a combination of the banned user and
a reason explaining the ban, if one was provided.
]]
function Ban:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

function Ban:__hash()
	return self._user._id
end

--[[
@method delete
@tags http
@ret boolean

Deletes the ban object, essentially unbanning the corresponding user.
Equivalent to `$.guild:unbanUser($.user)`.
]]
function Ban:delete()
	return self._parent:unbanUser(self._user)
end

--[[
@property reason: string|nil

The reason for the ban, if one was set. This should be from 1 to 512 characters
in length.
]]
function get.reason(self)
	return self._reason
end

--[[
@property guild: Guild

The guild in which this ban object exists. Equivalen to `$.parent`.
]]
function get.guild(self)
	return self._parent
end

--[[
@property user: User

The user that this ban object represents.
]]
function get.user(self)
	return self._user
end

return Ban
