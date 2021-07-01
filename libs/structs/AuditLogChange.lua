local class = require('../class')

local AuditLogChange, get = class('AuditLogChange')

function AuditLogChange:__init(data)
	self._old_value = data.old_value
	self._new_value = data.new_value
	self._key = data._key
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
