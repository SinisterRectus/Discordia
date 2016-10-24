local Snowflake = require('../Snowflake')
local Color = require('../../utils/Color')
local Permissions = require('../../utils/Permissions')

local Role, accessors = class('Role', Snowflake)

accessors.guild = function(self) return self.parent end

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:update(data)
end

function Role:update(data)
	self.name = data.name
	self.hoist = data.hoist
	self.managed = data.managed
	self.mentionable = data.mentionable
	self.color = Color(data.color)
	self.permissions = Permissions(data.permissions)
end

function Role:getMentionString()
	return string.format('<@&%s>', self.id)
end

return Role
