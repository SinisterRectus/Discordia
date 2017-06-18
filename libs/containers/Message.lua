local Cache = require('utils/Cache')
local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')

local Message = require('class')('Message', Snowflake)

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:insert(data.author)
	if data.reactions then
		self._reactions = Cache(Reaction, self)
		self._reactions:merge(data.reactions)
	end
	return self:_loadMore(data)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Message:_loadMore(data)

	-- TODO: maybe parse these
	-- TODO: if they are empty, maybe nil them on self

	if data.mentions then
		self._mentions = data.mentions
	end

	if data.mention_roles then
		self._mention_roles = data.mention_roles
	end

	if data.embeds then
		self._embeds = data.embeds
	end

	if data.attachments then
		self._attachments = data.attachments
	end

end

function Message:_addReaction(data, user)

	local reactions = self._reactions

	if not reactions then
		reactions = Cache(Reaction, self)
		self._reactions = reactions
	end

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	if reaction then
		reaction._count = reaction._count + 1
		if user == self.client._user then
			reaction._me = true
		end
	else
		data.me = user == self.client._user
		data.count = 1
		reaction = reactions:insert(data)
	end
	return reaction

end

function Message:_removeReaction(data, user)

	local reactions = self._reactions

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	reaction._count = reaction._count - 1
	if user == self.client._user then
		reaction._me = false
	end

	if reaction._count == 0 then
		reactions:delete(k)
	end

	return reaction

end

return Message
