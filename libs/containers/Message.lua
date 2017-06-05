local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')

local Message = require('class')('Message', Snowflake)

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:insert(data.author)
	return self:_loadMore(data)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Message:_loadMore(data)

	if data.mentions then
		local users = self.client._users
		local mentions = data.mentions
		for i, mention in ipairs(data.mentions) do
			mentions[i] = users:insert(mention)
		end
		self._mentions = mentions
	end

	if data.mention_roles then
		self._mention_roles = data.mention_roles -- raw table
	end

	if data.reactions then
		local reactions = data.reactions
		for i, reaction in ipairs(reactions) do
			local emoji = reaction.emoji
			reactions[emoji.id or emoji.name] = Reaction(reaction, self)
			reactions[i] = nil
		end
		self._reactions = reactions
	end

	if data.embeds then
		self._embeds = data.embeds -- raw table
	end

	if data.attachments then
		self._attachments = data.attachments -- raw table
	end

end

function Message:_addReaction(emoji, user)
	local reactions = self._reactions or {}
	local key = emoji.id or emoji.name
	local reaction = reactions[key]
	if reaction then
		reaction._count = reaction._count + 1
		if user == self.client._user then
			reaction._me = true
		end
	else
		reaction = Reaction({
			me = user == self.client._user,
			emoji = emoji,
			count = 1,
		}, self)
		reactions[key] = reaction
	end
	self._reactions = reactions
	return reaction
end

--TODO: remove object when count = 0?
function Message:_removeReaction(emoji, user)
	local reactions = self._reactions or {}
	local key = emoji.id or emoji.name
	local reaction = reactions[key]
	if reaction then
		reaction._count = reaction._count - 1
		if user == self.client._user then
			reaction._me = false
		end
	else -- is this even possible?
		reaction = Reaction({
			me = user == self.client._user,
			emoji = emoji,
			count = 0,
		}, self)
		reactions[key] = reaction -- adding a reaction with count = 0?
	end
	self._reactions = reactions
	return reaction
end

return Message
