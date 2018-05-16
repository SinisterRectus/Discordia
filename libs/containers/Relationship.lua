--[=[@c Relationship x UserPresence ...]=]

local UserPresence = require('containers/abstract/UserPresence')

local Relationship, get = require('class')('Relationship', UserPresence)

function Relationship:__init(data, parent)
	UserPresence.__init(self, data, parent)
end

--[=[@p name string ...]=]
function get.name(self)
	return self._user._username
end

--[=[@p type number ...]=]
function get.type(self)
	return self._type
end

return Relationship
