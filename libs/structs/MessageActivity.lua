local class = require('../class')

local MessageActivity, get = class('MessageActivity')

function MessageActivity:__init(data)
	self._type = data.type
	self._party_id = data.party_id
end

function get:type()
	return self._type
end

function get:partyId()
	return self._party_id
end

return MessageActivity
