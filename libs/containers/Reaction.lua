local Container = require('utils/Container')

local format = string.format

local Reaction = require('class')('Reaction', Container)
local get = Reaction.__getters

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	self._emoji_id = data.emoji.id
	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id or self._emoji_name
end

function get.emojiId(self)
	return self._emoji_id
end

function get.emojiName(self)
	return self._emoji_name
end

function get.emojiURL(self)
	local id = self._emoji_id
	return id and format('https://cdn.discordapp.com/emojis/%s.png', id) or nil
end

function get.me(self)
	return self._me
end

function get.count(self)
	return self._count
end

function get.message(self)
	return self._parent
end

return Reaction
