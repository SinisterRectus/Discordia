local Base = require('./base')
local Color = require('../color')
local Permissions = require('./permissions')
local endpoints = require('../../endpoints')

local Role = class('Role', Base)

function Role:__init(data, server)

	Base.__init(self, data.id, server.client)

	self.server = server
	self:_update(data)

end

function Role:_update(data)

	self.name = data.name -- text
	self.hoist = data.hoist -- boolean
	self.color = Color(data.color) -- number
	self.managed = data.managed -- boolean
	self.position = data.position -- number
	self.permissions = Permissions(data.permissions) -- number

end

-- Role:set* Functions
local setParams = { 'color', 'hoist', 'name', 'permissions' }
function Role:set(options)
	local body = {}
	for i,param in ipairs( setParams ) do
		body[param] = options[param] or self[param]
	end
	body.color = body.color:toDec()
	body.permissions = body.permissions:toDec()
	
	local data = self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
	if data then return Role(data, self.server) end
end
for i,param in ipairs( setParams ) do
	local Param = (param:gsub("^%l", string.upper))
	Role[ "set"..Param ] = function( self, value ) return self:set( { [param] = value } ) end
end

function Role:moveUp()
end

function Role:moveDown()
end

function Role:delete()
	self.client:request('DELETE', {endpoints.servers, self.server.id, 'roles', self.id})
end

function Role:getMentionString()
	return string.format('<@&%s>', self.id)
end

return Role
