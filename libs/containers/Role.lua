local json = require('json')
local Snowflake = require('containers/abstract/Snowflake')
local Color = require('utils/Color')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local format = string.format
local insert, sort = table.insert, table.sort
local min, max, floor = math.min, math.max, math.floor
local huge = math.huge

local Role, get = require('class')('Role', Snowflake)

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Role:_modify(payload)
	local data, err = self.client._api:modifyGuildRole(self._parent._id, self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[[
@method delete
@ret boolean
]]
function Role:delete()
	local data, err = self.client._api:deleteGuildRole(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

local function sorter(a, b)
	if a.position == b.position then
		return tonumber(a.id) < tonumber(b.id)
	else
		return a.position < b.position
	end
end

local function getSortedRoles(self)
	local guild = self._parent
	local id = self._parent._id
	local ret = {}
	for role in guild.roles:iter() do
		if role._id ~= id then
			insert(ret, {id = role._id, position = role._position})
		end
	end
	sort(ret, sorter)
	return ret
end

local function setSortedRoles(self, roles)
	local id = self._parent._id
	insert(roles, {id = id, position = 0})
	local data, err = self.client._api:modifyGuildRolePositions(id, roles)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method moveDown
@param [n]: number
@ret boolean
]]
function Role:moveDown(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveDown(-n)
	end

	local roles = getSortedRoles(self)

	local new = huge
	for i = #roles, 1, -1 do
		local v = roles[i]
		if v.id == self._id then
			new = max(1, i - floor(n))
			v.position = new
		elseif i >= new then
			v.position = i + 1
		else
			v.position = i
		end
	end

	return setSortedRoles(self, roles)

end

--[[
@method moveUp
@param [n]: number
@ret boolean
]]
function Role:moveUp(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveUp(-n)
	end

	local roles = getSortedRoles(self)

	local new = -huge
	for i = 1, #roles do
		local v = roles[i]
		if v.id == self._id then
			new = min(i + floor(n), #roles)
			v.position = new
		elseif i <= new then
			v.position = i - 1
		else
			v.position = i
		end
	end

	return setSortedRoles(self, roles)

end

--[[
@method setColor
@param color: Color Resolveable
@ret boolean
]]
function Role:setColor(color)
	color = color and Resolver.color(color)
	return self:_modify({color = color or json.null})
end

--[[
@method setPermissions
@param permissions: Permissions Resolveable
@ret boolean
]]
function Role:setPermissions(permissions)
	permissions = permissions and Resolver.permissions(permissions)
	return self:_modify({permissions = permissions or json.null})
end

--[[
@method hoist
@ret boolean
]]
function Role:hoist()
	return self:_modify({hoist = true})
end

--[[
@method hoist
@ret boolean
]]
function Role:unhoist()
	return self:_modify({hoist = false})
end

--[[
@method enableMentioning
@ret boolean
]]
function Role:enableMentioning()
	return self:_modify({mentionable = true})
end

--[[
@method disableMentioning
@ret boolean
]]
function Role:disableMentioning()
	return self:_modify({mentionable = false})
end

--[[
@method enablePermissions
@param ...: Permissions Resolveable(s)
@ret boolean
]]
function Role:enablePermissions(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

--[[
@method disablePermissions
@param ...: Permissions Resolveable(s)
@ret boolean
]]
function Role:disablePermissions(...)
	local permissions = self:getPermissions()
	permissions:disable(...)
	return self:setPermissions(permissions)
end

--[[
@method enableAllPermissions
@ret boolean
]]
function Role:enableAllPermissions()
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

--[[
@method disableAllPermissions
@ret boolean
]]
function Role:disableAllPermissions()
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

--[[
@method getColor
@ret Color
]]
function Role:getColor()
	return Color(self._color)
end

--[[
@method getPermissions
@ret Permissions
]]
function Role:getPermissions()
	return Permissions(self._permissions)
end

--[[
@property hoisted: boolean
]]
function get.hoisted(self)
	return self._hoist
end

--[[
@property mentionable: boolean
]]
function get.mentionable(self)
	return self._mentionable
end

--[[
@property managed: boolean
]]
function get.managed(self)
	return self._managed
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property position: number
]]
function get.position(self)
	return self._position
end

--[[
@property color: number
]]
function get.color(self)
	return self._color
end

--[[
@property permissions: number
]]
function get.permissions(self)
	return self._permissions
end

--[[
@property mentionString: string
]]
function get.mentionString(self)
	return format('<@&%s>', self._id)
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent
end

return Role
