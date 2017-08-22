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

--[[
@class Permissions

Wrapper for a bitfield that is more specifically used to represent Discord
permissions. See the `permission` enumeration for acceptible permission values.
]]
function Permissions:__init(value)
	self._value = tonumber(value) or 0
end

function Permissions:__tostring()
	if self._value == 0 then
		return 'Permissions: 0 (none)'
	else
		local a = self:toArray()
		sort(a)
		return format('Permissions: %i (%s)', self._value, concat(a, ', '))
	end
end

--[[
@method all
@ret Permissions

Constructs a new Permissions object that represents all has all known Discord
permissions enabled.
]]
function Permissions.all()
	return Permissions(ALL)
end

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

--[[
@method enable
@param ...: Permissions Resolveable(s)

Enables a specific permission or permissions. See the `permission` enumeration
for acceptible permission values.
]]
function Permissions:enable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local perm = getPerm(i, ...)
		value = bor(value, perm)
	end
	self._value = value
end

--[[
@method disable
@param ...: Permissions Resolveable(s)

Disables a specific permission or permissions. See the `permission` enumeration
for acceptible permission values.
]]
function Permissions:disable(...)
	local value = self._value
	for i = 1, select('#', ...) do
		local perm = getPerm(i, ...)
		value = band(value, bnot(perm))
	end
	self._value = value
end

--[[
@method has
@param ...: Permissions Resolveable(s)
@ret boolean

Returns whether this set has a specific permission or permissions. See the
`permission` enumeration for acceptible permission values.
]]
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

--[[
@method enableAll

Enables all permissions values.
]]
function Permissions:enableAll()
	self._value = ALL
end

--[[
@method disableAll

Disables all permissions values.
]]
function Permissions:disableAll()
	self._value = 0
end

--[[
@method toHex
@ret string

Returns the hexadecimal string that represents the permissions value.
]]
function Permissions:toHex()
	return format('0x%08X', self._value)
end

--[[
@method toTable
@ret table

Returns a table that represents the permissions value, where the keys are the
permission names and the values are `true` or `false`.
]]
function Permissions:toTable()
	local ret = {}
	local value = self._value
	for k, v in pairs(permission) do
		ret[k] = band(value, v) > 0
	end
	return ret
end

--[[
@method toArray
@ret table

Returns an array of the names of the permissions that this objects represents.
]]
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

--[[
@method union
@param other: Permissions
@ret Permissions

Returns a new Permissions object that contains the permissions that are in
either `self` or `other` (bitwise OR).
]]
function Permissions:union(other)
	return Permissions(bor(self._value, other._value))
end

--[[
@method intersection
@param other: Permissions
@ret Permissions

Returns a new Permissions object that contains the permissions that are in
both `self` and `other` (bitwise AND).
]]
function Permissions:intersection(other) -- in both
	return Permissions(band(self._value, other._value))
end

--[[
@method difference
@param other: Permissions
@ret Permissions

Returns a new Permissions object that contains the permissions that are not
in `self` or `other` (bitwise XOR).
]]
function Permissions:difference(other) -- not in both
	return Permissions(bxor(self._value, other._value))
end

--[[
@method complement
@param [other]: Permissions
@ret Permissions

Returnsa new Permissions object that contains the permissions that are not in
`self`, but are in `other` (or the set of all permissions if omitted).
]]
function Permissions:complement(other) -- in other not in self
	local value = other and other._value or ALL
	return Permissions(band(bnot(self._value), value))
end

--[[
@method copy
@ret Permissions

Returns a new copy of the original permissions object.
]]
function Permissions:copy()
	return Permissions(self._value)
end

--[[
@property value: number

The raw decimal value that represents the permissions value.
]]
function get.value(self)
	return self._value
end

return Permissions
