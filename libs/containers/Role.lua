--[=[@c Role x Snowflake desc]=]

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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
]=]
function Role:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:setColor(color)
	color = color and Resolver.color(color)
	return self:_modify({color = color or json.null})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:setPermissions(permissions)
	permissions = permissions and Resolver.permissions(permissions)
	return self:_modify({permissions = permissions or json.null})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:hoist()
	return self:_modify({hoist = true})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:unhoist()
	return self:_modify({hoist = false})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:enableMentioning()
	return self:_modify({mentionable = true})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:disableMentioning()
	return self:_modify({mentionable = false})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:enablePermissions(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:disablePermissions(...)
	local permissions = self:getPermissions()
	permissions:disable(...)
	return self:setPermissions(permissions)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:enableAllPermissions()
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:disableAllPermissions()
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:getColor()
	return Color(self._color)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Role:getPermissions()
	return Permissions(self._permissions)
end

--[=[@p hoisted type desc]=]
function get.hoisted(self)
	return self._hoist
end

--[=[@p mentionable type desc]=]
function get.mentionable(self)
	return self._mentionable
end

--[=[@p managed type desc]=]
function get.managed(self)
	return self._managed
end

--[=[@p name type desc]=]
function get.name(self)
	return self._name
end

--[=[@p position type desc]=]
function get.position(self)
	return self._position
end

--[=[@p color type desc]=]
function get.color(self)
	return self._color
end

--[=[@p permissions type desc]=]
function get.permissions(self)
	return self._permissions
end

--[=[@p mentionString type desc]=]
function get.mentionString(self)
	return format('<@&%s>', self._id)
end

--[=[@p guild type desc]=]
function get.guild(self)
	return self._parent
end

--[=[@p members type desc]=]
function get.members(self)
	if not self._members then
		self._members = FilteredIterable(self._parent._members, function(m)
			return m:hasRole(self)
		end)
	end
	return self._members
end

--[=[@p emojis type desc]=]
function get.emojis(self)
	if not self._emojis then
		self._emojis = FilteredIterable(self._parent._emojis, function(e)
			return e:hasRole(self)
		end)
	end
	return self._emojis
end

return Role
