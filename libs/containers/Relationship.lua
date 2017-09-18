local UserPresence = require('containers/abstract/UserPresence')

local Relationship, get = require('class')('Relationship', UserPresence)

--[[
@class Relationship x UserPresence

Represents a relationship between the current user and another Discord user.
This is generally either a friend or a blocked user. This class should only be
relevant to user-accounts; bots cannot normally have relationships.
]]
function Relationship:__init(data, parent)
	UserPresence.__init(self, data, parent)
end

--[[
@property name: string

Equivalent to `$.user.username`.
]]
function get.name(self)
	return self._user._username
end

--[[
@property type: number

The relationship type. See the `relationshipType` enumeration for a
human-readable representation.
]]
function get.type(self)
	return self._type
end

return Relationship
