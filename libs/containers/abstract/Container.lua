--[=[
@c Container
@t abc
@d Defines the base methods and properties for all Discord objects and
structures. Container classes are constructed internally with information
received from Discord and should never be manually constructed.
]=]

local json = require('json')

local null = json.null
local format = string.format

local Container, get = require('class')('Container')

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

local function load(self, data)
	-- assert(type(data) == 'table') -- debug
	for k, v in pairs(data) do
		if types[type(v)] then
			self['_' .. k] = v
		elseif v == null then
			self['_' .. k] = nil
		end
	end
end

function Container:__init(data, parent)
	-- assert(type(parent) == 'table') -- debug
	self._parent = parent
	return load(self, data)
end

--[=[
@m __eq
@r boolean
@d Defines the behavior of the `==` operator. Allows containers to be directly
compared according to their type and `__hash` return values.
]=]
function Container:__eq(other)
	return self.__class == other.__class and self:__hash() == other:__hash()
end

--[=[
@m __tostring
@r string
@d Defines the behavior of the `tostring` function. All containers follow the format
`ClassName: hash`.
]=]
function Container:__tostring()
	return format('%s: %s', self.__name, self:__hash())
end

Container._load = load

--[=[@p client Client A shortcut to the client object to which this container is visible.]=]
function get.client(self)
	return self._parent.client or self._parent
end

--[=[@p parent Container/Client The parent object of to which this container is
a child. For example, the parent of a role is the guild in which the role exists.]=]
function get.parent(self)
	return self._parent
end

return Container
