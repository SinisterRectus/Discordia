--[=[
@c Role x Snowflake
@d Represents a Discord guild role, which is used to assign priority, permissions,
and a color to guild members.
]=]

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

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.client._role_map[self._id] = parent
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

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the role. This cannot be undone!
]=]
function Role:delete()
	local data, err = self.client._api:deleteGuildRole(self._parent._id, self._id)
	if data then
		local cache = self._parent._roles
		if cache then
			cache:_delete(self._id)
		end
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

--[=[
@m moveDown
@t http
@p n number
@r boolean
@d Moves a role down its list. The parameter `n` indicates how many spaces the
role should be moved, clamped to the lowest position, with a default of 1 if
it is omitted. This will also normalize the positions of all roles. Note that
the default everyone role cannot be moved.
]=]
function Role:moveDown(n) -- TODO: fix attempt to move roles that cannot be moved

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

--[=[
@m moveUp
@t http
@p n number
@r boolean
@d Moves a role up its list. The parameter `n` indicates how many spaces the
role should be moved, clamped to the highest position, with a default of 1 if
it is omitted. This will also normalize the positions of all roles. Note that
the default everyone role cannot be moved.
]=]
function Role:moveUp(n) -- TODO: fix attempt to move roles that cannot be moved

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

--[=[
@m setName
@t http
@p name string
@r boolean
@d Sets the role's name. The name must be between 1 and 100 characters in length.
]=]
function Role:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setColor
@t http
@p color Color-Resolvable
@r boolean
@d Sets the role's display color.
]=]
function Role:setColor(color)
	color = color and Resolver.color(color)
	return self:_modify({color = color or json.null})
end

--[=[
@m setPermissions
@t http
@p permissions Permissions-Resolvable
@r boolean
@d Sets the permissions that this role explicitly allows.
]=]
function Role:setPermissions(permissions)
	permissions = permissions and Resolver.permissions(permissions)
	return self:_modify({permissions = permissions or json.null})
end

--[=[
@m hoist
@t http
@r boolean
@d Causes members with this role to display above unhoisted roles in the member
list.
]=]
function Role:hoist()
	return self:_modify({hoist = true})
end

--[=[
@m unhoist
@t http
@r boolean
@d Causes member with this role to display amongst other unhoisted members.
]=]
function Role:unhoist()
	return self:_modify({hoist = false})
end

--[=[
@m enableMentioning
@t http
@r boolean
@d Allows anyone to mention this role in text messages.
]=]
function Role:enableMentioning()
	return self:_modify({mentionable = true})
end

--[=[
@m disableMentioning
@t http
@r boolean
@d Disallows anyone to mention this role in text messages.
]=]
function Role:disableMentioning()
	return self:_modify({mentionable = false})
end

--[=[
@m enablePermissions
@t http
@p ... Permission-Resolvables
@r boolean
@d Enables individual permissions for this role. This does not necessarily fully
allow the permissions.
]=]
function Role:enablePermissions(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

--[=[
@m disablePermissions
@t http
@p ... Permission-Resolvables
@r boolean
@d Disables individual permissions for this role. This does not necessarily fully
disallow the permissions.
]=]
function Role:disablePermissions(...)
	local permissions = self:getPermissions()
	permissions:disable(...)
	return self:setPermissions(permissions)
end

--[=[
@m enableAllPermissions
@t http
@r boolean
@d Enables all permissions for this role. This does not necessarily fully
allow the permissions.
]=]
function Role:enableAllPermissions()
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

--[=[
@m disableAllPermissions
@t http
@r boolean
@d Disables all permissions for this role. This does not necessarily fully
disallow the permissions.
]=]
function Role:disableAllPermissions()
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

--[=[
@m getColor
@t mem
@r Color
@d Returns a color object that represents the role's display color.
]=]
function Role:getColor()
	return Color(self._color)
end

--[=[
@m getPermissions
@t mem
@r Permissions
@d Returns a permissions object that represents the permissions that this role
has enabled.
]=]
function Role:getPermissions()
	return Permissions(self._permissions_new or self._permissions)
end

--[=[@p hoisted boolean Whether members with this role should be shown separated from other members
in the guild member list.]=]
function get.hoisted(self)
	return self._hoist
end

--[=[@p mentionable boolean Whether this role can be mentioned in a text channel message.]=]
function get.mentionable(self)
	return self._mentionable
end

--[=[@p managed boolean Whether this role is managed by some integration or bot inclusion.]=]
function get.managed(self)
	return self._managed
end

--[=[@p name string The name of the role. This should be between 1 and 100 characters in length.]=]
function get.name(self)
	return self._name
end

--[=[@p position number The position of the role, where 0 is the lowest.]=]
function get.position(self)
	return self._position
end

--[=[@p color number Represents the display color of the role as a decimal value.]=]
function get.color(self)
	return self._color
end

--[=[@p permissions number Represents the total permissions of the role as a decimal value.]=]
function get.permissions(self)
	return tonumber(self._permissions_new) or tonumber(self._permissions)
end

--[=[@p mentionString string A string that, when included in a message content, may resolve as a role
notification in the official Discord client.]=]
function get.mentionString(self)
	return format('<@&%s>', self._id)
end

--[=[@p guild Guild The guild in which this role exists.]=]
function get.guild(self)
	return self._parent
end

--[=[@p members FilteredIterable A filtered iterable of guild members that have
this role. If you want to check whether a specific member has this role, it would
be better to get the member object elsewhere and use `Member:hasRole` rather
than check whether the member exists here.]=]
function get.members(self)
	if not self._members then
		self._members = FilteredIterable(self._parent._members, function(m)
			return m:hasRole(self)
		end)
	end
	return self._members
end

--[=[@p emojis FilteredIterable A filtered iterable of guild emojis that have
this role. If you want to check whether a specific emoji has this role, it would
be better to get the emoji object elsewhere and use `Emoji:hasRole` rather
than check whether the emoji exists here.]=]
function get.emojis(self)
	if not self._emojis then
		self._emojis = FilteredIterable(self._parent._emojis, function(e)
			return e:hasRole(self)
		end)
	end
	return self._emojis
end

return Role
