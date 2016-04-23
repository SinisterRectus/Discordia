local Base = class('Base')

function Base:__init(id, client)
	self.id = id
	self.client = client
end

function Base:__eq(other)
	return self.id == other.id
end

function Base:__tostring()
	return string.format('%s: %s', self.__name, self.content or self.name or self.username or self.id)
end

return Base
