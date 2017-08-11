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
]]
function Permissions:enableAll()
	self._value = ALL
end

--[[
@method disableAll
]]
function Permissions:disableAll()
	self._value = 0
end

--[[
@method toHex
@ret string
]]
function Permissions:toHex()
	return format('0x%08X', self._value)
end

--[[
@method toTable
@ret table
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
]]
function Permissions:union(other) -- in either
	return Permissions(bor(self._value, other._value))
end

--[[
@method intersection
@param other: Permissions
@ret Permissions
]]
function Permissions:intersection(other) -- in both
	return Permissions(band(self._value, other._value))
end

--[[
@method difference
@param other: Permissions
@ret Permissions
]]
function Permissions:difference(other) -- not in both
	return Permissions(bxor(self._value, other._value))
end

--[[
@method complement
@param other: Permissions
@ret Permissions
]]
function Permissions:complement(other) -- in other not in self
	local value = other and other._value or ALL
	return Permissions(band(bnot(self._value), value))
end

--[[
@method copy
@ret Permissions
]]
function Permissions:copy()
	return Permissions(self._value)
end

--[[
@property value: number
]]
function get.value(self)
	return self._value
end

return Permissions
