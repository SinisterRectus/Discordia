--[=[
@c UserPresence x Container
@d Abstract base class that defines the base methods and/or properties for
classes that represent a user's current presence information. Note that any
method or property that exists for the User class is also available in the
UserPresence class and its subclasses.
]=]

local null = require('json').null
local User = require('containers/User')
local Activity = require('containers/Activity')
local Container = require('containers/abstract/Container')

local UserPresence, get = require('class')('UserPresence', Container)

function UserPresence:__init(data, parent)
	Container.__init(self, data, parent)
	self._user = self.client._users:_insert(data.user)
end

--[=[
@m __hash
@r string
@d Returns `UserPresence.user.id`
]=]
function UserPresence:__hash()
	return self._user._id
end

local activities = setmetatable({}, {__mode = 'v'})

function UserPresence:_loadPresence(presence)
	self._status = presence.status
	local game = presence.game
	if game == null then
		self._activity = nil
	elseif game then
		if self._activity then
			self._activity:_load(game)
		else
			local activity = activities[self:__hash()]
			if activity then
				activity:_load(game)
			else
				activity = Activity(game, self)
				activities[self:__hash()] = activity
			end
			self._activity = activity
		end
	end
end

function get.gameName(self)
	self.client:_deprecated(self.__name, 'gameName', 'activity.name')
	return self._activity and self._activity._name
end

function get.gameType(self)
	self.client:_deprecated(self.__name, 'gameType', 'activity.type')
	return self._activity and self._activity._type
end

function get.gameURL(self)
	self.client:_deprecated(self.__name, 'gameURL', 'activity.url')
	return self._activity and self._activity._url
end

--[=[@p status string The user's online status (online, dnd, idle, offline).]=]
function get.status(self)
	return self._status or 'offline'
end

--[=[@p user User The user that this presence represents.]=]
function get.user(self)
	return self._user
end

--[=[@p activity Activity The Activity that this presence represents.]=]
function get.activity(self)
	return self._activity
end

-- user shortcuts

for k, v in pairs(User) do
	UserPresence[k] = UserPresence[k] or function(self, ...)
		return v(self._user, ...)
	end
end

for k, v in pairs(User.__getters) do
	get[k] = get[k] or function(self)
		return v(self._user)
	end
end

return UserPresence
