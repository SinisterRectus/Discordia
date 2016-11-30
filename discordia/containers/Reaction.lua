local Container = require('../utils/Container')

local format = string.format
local concat = table.concat

local Reaction, property = class('Reaction', Container)
Reaction.__description = "Represents a Discord message reaction."

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	local emoji = data.emoji
	if emoji.id then
		local emojis = self._parent._parent._parent._emojis
		emoji = emojis:get(emoji.id) or emojis:new(emoji)
	else
		emoji = emoji.name
	end
	self._emoji = emoji
end

function Reaction:__tostring()
	local emoji = self._emoji
	if emoji._name then
		emoji = emoji._name
	else
		emoji =	format('%s (%s)', emoji, '\\' .. concat({emoji:byte(1, #emoji)}, '\\'))
	end
	return format('%s: %s', self.__name, emoji)
end

property('me', '_me', nil, 'boolean', "Whether the current user has used this reaction")
property('count', '_count', nil, 'number', "How many times this reaction has been used")
property('emoji', '_emoji', nil, 'Emoji or string', "The emoji that this reaction represents")
property('message', '_parent', nil, 'Message', "The message for which this reaction exists")

return Reaction
