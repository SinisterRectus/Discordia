--[=[
@c Permissions
@t ui
@mt mem
@d Wrapper for a bitfield that is more specifically used to represent Discord
permissions. See the `permission` enumeration for acceptable permission values.
]=]

local enums = require('enums')
local Resolver = require('client/Resolver')

local permission = enums.permission

local format = string.format
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local sort, insert, concat = table.sort, table.insert, table.concat

local ALL = 0
for _, value in pairs(permission) do
	ALL = bor(ALL, value)
end

local Permissions, get = require('class')('Permissions')

function Permissions:__init(value)
	self._value = tonumber(value) or 0
end

--[=[
@m __tostring
@r string
@d Defines the behavior of the `tostring` function. Returns a readable list of
permissions stored for convenience of introspection.
]=]
function Permissions:__tostring()
	if self._value == 0 then
		return 'Permissions: 0 (none)'
	else
		local a = self:toArray()
		sort(a)
		return format('Permissions: %i (%s)', self._value, concat(a, ', '))
	end
end

--[=[
@m fromMany
@t static
@p ... Permission-Resolvables
@r Permissions
@d Returns a Permissions object with all of the defined permissions.
]=]
function Permissions.fromMany(...)
	local ret = Permissions()
	ret:enable(...)
	return ret
end

--[=[
@m all
@t static
@r Permissions
@d Returns a Permissions object with all permissions.
]=]
function Permissions.all()
	return Permissions(ALL)
end

--[=[
@m __eq
@r boolean
@d Defines the behavior of the `==` operator. Allows permissions to be directly
compared according to their value.
]=]
function Permissions:__eq(other)
	return self._value == other._value
end

local function getPerm(i, ...)
	local v = select(i, ...)
	local n = Resolver.permission(v)
	if not n then
		return error('Invalid permission: ' .. tostring(v), 2)
	end
	return n
end

--[=[
@m enable
@p ... Permission-Resolvables
@r nil
@d Enables a specific permission or permissions. See the `permission` enumeration
for acceptable permission values.
]=]
function Permissions:enable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local perm = getPerm(i, ...)
		value = bor(value, perm)
	end
	self._value = value
end

--[=[
@m disable
@p ... Permission-Resolvables
@r nil
@d Disables a specific permission or permissions. See the `permission` enumeration
for acceptable permission values.
]=]
function Permissions:disable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local perm = getPerm(i, ...)
		value = band(value, bnot(perm))
	end
	self._value = value
end

--[=[
@m has
@p ... Permission-Resolvables
@r boolean
@d Returns whether this set has a specific permission or permissions. See the
`permission` enumeration for acceptable permission values.
]=]
function Permissions:has(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local perm = getPerm(i, ...)
		if band(value, perm) == 0 then
			return false
		end
	end
	return true
end

--[=[
@m enableAll
@r nil
@d Enables all permissions values.
]=]
function Permissions:enableAll()
	self._value = ALL
end

--[=[
@m disableAll
@r nil
@d Disables all permissions values.
]=]
function Permissions:disableAll()
	self._value = 0
end

--[=[
@m toHex
@r string
@d Returns the hexadecimal string that represents the permissions value.
]=]
function Permissions:toHex()
	return format('0x%08X', self._value)
end

--[=[
@m toTable
@r table
@d Returns a table that represents the permissions value, where the keys are the
permission names and the values are `true` or `false`.
]=]
function Permissions:toTable()
	local ret = {}
	local value = self._value
	for k, v in pairs(permission) do
		ret[k] = band(value, v) > 0
	end
	return ret
end

--[=[
@m toArray
@r table
@d Returns an array of the names of the permissions that this objects represents.
]=]
function Permissions:toArray()
	local ret = {}
	local value = self._value
	for k, v in pairs(permission) do
		if band(value, v) > 0 then
			insert(ret, k)
		end
	end
	return ret
end

--[=[
@m union
@p other Permissions
@r Permissions
@d Returns a new Permissions object that contains the permissions that are in
either `self` or `other` (bitwise OR).
]=]
function Permissions:union(other)
	return Permissions(bor(self._value, other._value))
end

--[=[
@m intersection
@p other Permissions
@r Permissions
@d Returns a new Permissions object that contains the permissions that are in
both `self` and `other` (bitwise AND).
]=]
function Permissions:intersection(other) -- in both
	return Permissions(band(self._value, other._value))
end

--[=[
@m name
@p other Permissions
@r Permissions
@d Returns a new Permissions object that contains the permissions that are not
in `self` or `other` (bitwise XOR).
]=]
function Permissions:difference(other) -- not in both
	return Permissions(bxor(self._value, other._value))
end

--[=[
@m complement
@p other Permissions
@r Permissions
@d Returns a new Permissions object that contains the permissions that are not
in `self`, but are in `other` (or the set of all permissions if omitted).
]=]
function Permissions:complement(other) -- in other not in self
	local value = other and other._value or ALL
	return Permissions(band(bnot(self._value), value))
end

--[=[
@m copy
@r Permissions
@d Returns a new copy of the original permissions object.
]=]
function Permissions:copy()
	return Permissions(self._value)
end

--[=[@p value number The raw decimal value that represents the permissions value.]=]
function get.value(self)
	return self._value
end

return Permissions
