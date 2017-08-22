local json = require('json')
local Snowflake = require('containers/abstract/Snowflake')
local Color = require('utils/Color')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')
local FilteredIterable = require('iterables/FilteredIterable')

local format = string.format
local insert, sort = table.insert, table.sort
local min, max, floor = math.min, math.max, math.floor
local huge = math.huge

local Role, get = require('class')('Role', Snowflake)

--[[
@class Role x Snowflake

Represents a Discord guild role, which is used to assign priority, permissions,
and a color to guild members.
]]
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
@tags http
@ret boolean

Permanently deletes the role. This cannot be undone!
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
@tags http
@param [n]: number
@ret boolean

Moves a role down its list. The parameter `n` indicates how many spaces the
role should be moved, clamped to the lowest position, with a default of 1 if
it is omitted. This will also normalize the positions of all roles. Note that
the default everyone role cannot be moved.
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
@tags http
@param [n]: number
@ret boolean

Moves a role up its list. The parameter `n` indicates how many spaces the
role should be moved, clamped to the highest position, with a default of 1 if
it is omitted. This will also normalize the positions of all roles. Note that
the default everyone role cannot be moved.
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
@method setName
@tags http
@param name:
@ret boolean

Sets the role's name. The name must be between 1 and 100 characters in length.
]]
function Role:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setColor
@tags http
@param color: Color Resolveable
@ret boolean

Sets the role's display color.
]]
function Role:setColor(color)
	color = color and Resolver.color(color)
	return self:_modify({color = color or json.null})
end

--[[
@method setPermissions
@tags http
@param permissions: Permissions Resolveable
@ret boolean

Sets the permissions that this role explicitly allows.
]]
function Role:setPermissions(permissions)
	permissions = permissions and Resolver.permissions(permissions)
	return self:_modify({permissions = permissions or json.null})
end

--[[
@method hoist
@tags http
@ret boolean

Causes members with this role to display above unhoisted roles in the member
list.
]]
function Role:hoist()
	return self:_modify({hoist = true})
end

--[[
@method unhoist
@tags http
@ret boolean

Causes member with this role to display amongst other unhoisted members.
]]
function Role:unhoist()
	return self:_modify({hoist = false})
end

--[[
@method enableMentioning
@tags http
@ret boolean

Allows anyone to mention this role in text messages.
]]
function Role:enableMentioning()
	return self:_modify({mentionable = true})
end

--[[
@method disableMentioning
@tags http
@ret boolean

Disallows anyone to mention this role in text messages.
]]
function Role:disableMentioning()
	return self:_modify({mentionable = false})
end

--[[
@method enablePermissions
@tags http
@param ...: Permissions Resolveable(s)
@ret boolean

Enables individual permissions for this role. This does not necessarily fully
allow the permissions.
]]
function Role:enablePermissions(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

--[[
@method disablePermissions
@tags http
@param ...: Permissions Resolveable(s)
@ret boolean

Disables individual permissions for this role.This does not necessarily fully
allow the permissions.
]]
function Role:disablePermissions(...)
	local permissions = self:getPermissions()
	permissions:disable(...)
	return self:setPermissions(permissions)
end

--[[
@method enableAllPermissions
@tags http
@ret boolean

Enables all permissions for this role. This does not necessarily fully
allow the permissions.
]]
function Role:enableAllPermissions()
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

--[[
@method disableAllPermissions
@tags http
@ret boolean

Disables all permissions for this role. This does not necessarily fully
allow the permissions.
]]
function Role:disableAllPermissions()
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

--[[
@method getColor
@ret Color

Returns a color object that represents the role's display color.
]]
function Role:getColor()
	return Color(self._color)
end

--[[
@method getPermissions
@ret Permissions

Returns a permissions object that represents the permissions that this role
has enabled.
]]
function Role:getPermissions()
	return Permissions(self._permissions)
end

--[[
@property hoisted: boolean

Whether members with this role should be shown separated from other members
in the guild member list.
]]
function get.hoisted(self)
	return self._hoist
end

--[[
@property mentionable: boolean

Whether this role can be mentioned in a text channel message.
]]
function get.mentionable(self)
	return self._mentionable
end

--[[
@property managed: boolean

Whether this role is managed by some integration or bot inclusion.
]]
function get.managed(self)
	return self._managed
end

--[[
@property name: string

The name of the role. This shoud be between 1 and 100 characters in length.
]]
function get.name(self)
	return self._name
end

--[[
@property position: number

The position of the role, where 0 is the lowest.
]]
function get.position(self)
	return self._position
end

--[[
@property color: number

Represents the display color of the role as a decimal value.
]]
function get.color(self)
	return self._color
end

--[[
@property permissions: number

Represents the total permissions of the role as a decimal value.
]]
function get.permissions(self)
	return self._permissions
end

--[[
@property mentionString: string

A string that, when included in a message content, may resolve as a role
notification in the official Discord client.
]]
function get.mentionString(self)
	return format('<@&%s>', self._id)
end

--[[
@property guild: Guild

The guild in which this role exists. Equivalent to `$.parent`.
]]
function get.guild(self)
	return self._parent
end

--[[
@property members: FilteredIterable

A filtered iterable of guild members that have this role. If you want to check
whether a specific member has this role, it would be better to get the member
object elsewhere and use `Member:hasRole` rather than check whether the member
exists here.
]]
function get.members(self)
	if not self._members then
		self._members = FilteredIterable(self._parent._members, function(m)
			return m:hasRole(self)
		end)
	end
	return self._members
end

return Role
