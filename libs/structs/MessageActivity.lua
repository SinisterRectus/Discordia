local class = require('../class')
local Struct = require('./Struct')

local MessageActivity, get = class('MessageActivity', Struct)

function MessageActivity:__init(data)
	Struct.__init(self, data)
end

function get:type()
	return self._type
end

function get:partyId()
	return self._party_id
end

return MessageActivity
