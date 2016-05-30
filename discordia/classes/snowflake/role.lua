local Base = require('./base')
local Color = require('../color')
local Permissions = require('../permissions')
local endpoints = require('../../endpoints')

local Role = class('Role', Base)

function Role:__init(data, server)

	Base.__init(self, data.id, server.client)

	self.server = server
	self:_update(data)

end

function Role:_update(data)

	self.name = data.name
	self.hoist = data.hoist
	self.managed = data.managed
	self.position = data.position

	self.color = Color(data.color)
	self.permissions = Permissions(data.permissions)

end

local setParams = {'color', 'hoist', 'name', 'permissions'}
for _, param in ipairs(setParams) do
	local functionName = "set" .. (param:gsub("^%l", string.upper))
	Role[functionName] = function(self, value) return self:set({[param] = value}) end
end

function Role:set(options)
	local body = {}
	for _, param in ipairs(setParams) do
		body[param] = options[param] or self[param]
	end
	body.color = body.color:toDec()
	body.permissions = body.permissions:toDec()
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
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
