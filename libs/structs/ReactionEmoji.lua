local class = require('../class')

local ReactionEmoji, get = class('ReactionEmoji')

function ReactionEmoji:__init(data)
	self._name = data.name
	self._id = data.id
	self._animated = data.animated
end

function get:name()
	return self._name
end

function get:id()
	return self._id
end

function get:hash()
	if self._id then
		return self._name .. ':' .. self._id
	else
		return self._name
	end
end

function get:animated()
	return self._animated
end

return ReactionEmoji
