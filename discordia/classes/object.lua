class('Object')

function Object:__init(id, client)
    self.id = id
    self.client = client
end

function Object:__eq(other)
    return self.id == other.id
end

function Object:__tostring()
    return string.format('%s: %s', self.__name, self.content or self.name or self.username or self.id)
end

return Object
