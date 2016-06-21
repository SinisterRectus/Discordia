local Base = require('./base')
local Color = require('../color')
local Permissions = require('../permissions')
local endpoints = require('../../endpoints')

local Role = class('Role', Base)

function Role:__init(data, server)
	Base.__init(self, data.id, server.client)

	self.server = server -- Server, self explanatory
	self:_update(data) -- sets data, don't call this
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

--- NON-FUNCTIONAL FUNCTIONS ---
-- function Role:moveUp()
-- 
-- end
--
-- function Role:moveDown()
-- 
-- end
--------------------------------

-- attempts to delete the role
-- needs the appropriate permissions, of course

function Role:delete()
	self.client:request('DELETE', {endpoints.servers, self.server.id, 'roles', self.id})
end

-- gets the string you need to mention the role
-- usually <@&[role ID here]>

function Role:getMentionString()
	return string.format('<@&%s>', self.id)
end

return Role
