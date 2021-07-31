local class = require('../class')

local Struct = require('./Struct')

local AuditLogChange, get = class('AuditLogChange', Struct)

function AuditLogChange:__init(data)
	Struct.__init(self, data)
end

function get:old()
	return self._old_value
end

function get:new()
	return self._new_value
end

function get:key()
	return self._key
end

return AuditLogChange
