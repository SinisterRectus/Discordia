local Base = class('Base')
local utils = require('../../utils')
local isInstanceOf = utils.isInstanceOf

function Base:__init(id, client)
	self.id = id
	self.client = client
end

function Base:__eq(other)
	return self.id == other.id and isInstanceOf(self, other.__index)
end

function Base:__tostring()
	return string.format('%s: %s', self.__name, self.content or self.name or self.id)
end

return Base
