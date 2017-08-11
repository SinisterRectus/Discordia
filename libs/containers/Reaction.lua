local Container = require('containers/abstract/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local Reaction, get = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	self._emoji_id = data.emoji.id
	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id or self._emoji_name
end

--[[
@method getUsers
@ret SecondaryCache
]]
function Reaction:getUsers()
	local emoji = Resolver.emoji(self)
	local message = self._parent
	local channel = message._parent
	local data, err = self.client._api:getReactions(channel._id, message._id, emoji)
	if data then
		return SecondaryCache(data, self.client._users)
	else
		return nil, err
	end
end

--[[
@method delete
@param id: User ID Resolveable
@ret boolean
]]
function Reaction:delete(id)
	return self._parent:removeReaction(self, id)
end

--[[
@property emojiId: string|nil
]]
function get.emojiId(self)
	return self._emoji_id
end

--[[
@property emojiName: string
]]
function get.emojiName(self)
	return self._emoji_name
end

--[[
@property emojiURL: string|nil
]]
function get.emojiURL(self)
	local id = self._emoji_id
	return id and format('https://cdn.discordapp.com/emojis/%s.png', id) or nil
end

--[[
@property me: boolean
]]
function get.me(self)
	return self._me
end

--[[
@property count: number
]]
function get.count(self)
	return self._count
end

--[[
@property message: Message
]]
function get.message(self)
	return self._parent
end

return Reaction
