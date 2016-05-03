local Base = require('./base')
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
	self.color = data.color -- number
	self.managed = data.managed -- boolean
	self.position = data.position -- number
	self.permissions = data.permissions -- number

end

function Role:setColor(color)
	local body = {color = color, hoist = self.hoist, name = self.name, permissions = self.permissions}
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
end

function Role:setHoist(hoist)
	local body = {color = self.color, hoist = hoist, name = self.name, permissions = self.permissions}
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
end

function Role:setName(name)
	local body = {color = self.color, hoist = self.hoist, name = name, permissions = self.permissions}
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
end

function Role:setPermissions(permissions)
	local body = {color = self.color, hoist = self.hoist, name = self.name, permissions = permissions}
	self.client:request('PATCH', {endpoints.servers, self.server.id, 'roles', self.id}, body)
end

function Role:moveUp()
end

function Role:moveDown()
end

function Role:delete()
	self.client:request('DELETE', {endpoints.servers, self.server.id, 'roles', self.id})
end

return Role
