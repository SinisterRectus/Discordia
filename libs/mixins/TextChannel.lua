local Message = require('../containers/Message')

local fs = require('fs')
local pathjoin = require('pathjoin')
local enums = require('../enums')
local typing = require('../typing')

local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger
local checkType = typing.checkType
local format = string.format
local concat, insert, remove = table.concat, table.insert, table.remove
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath

local methods = {}

function methods:getMessage(id)
	id = checkSnowflake(id)
	local data, err = self.client.api:getChannelMessage(self.id, id)
	if data then
		data.guild_id = self.guildId
		return Message(data, self.client)
	else
		return nil, err
	end
end

function methods:getFirstMessage()
	local data, err = self.client.api:getChannelMessages(self.id, {after = self.id, limit = 1})
	if data then
		if data[1] then
			data[1].guild_id = self.guildId
			return Message(data[1], self.client)
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function methods:getLastMessage()
	local data, err = self.client.api:getChannelMessages(self.id, {limit = 1})
	if data then
		if data[1] then
			data[1].guild_id = self.guildId
			return Message(data[1], self.client)
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function methods:getMessages(limit, whence, messageId)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(messageId)
	end
	local data, err = self.client.api:getChannelMessages(self.id, query)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.guildId
			data[i] = Message(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function methods:getPinnedMessages()
	local data, err = self.client.api:getPinnedMessages(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.guildId
			data[i] = Message(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function methods:triggerTyping()
	local data, err = self.client.api:triggerTypingIndicator(self.id)
	if data then
		return true
	else
		return false, err
	end
end

local function parseMention(obj, mentions)
	if not pcall(function()
		mentions = mentions or {}
		insert(mentions, checkType('string', obj.mentionString))
	end) then
		return nil, 'Unmentionable object: ' .. tostring(obj)
	end
	return mentions
end

local function parseFile(obj, files)
	if type(obj) == 'string' then
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		files = files or {}
		insert(files, {remove(splitPath(obj)), data})
		return files
	elseif type(obj) == 'table' and type(obj[1]) == 'string' and type(obj[2]) == 'string' then
		files = files or {}
		insert(files, obj)
		return files
	else
		return nil, 'Invalid file object: ' .. tostring(obj)
	end
end

function methods:send(payload)

	local data, err

	if type(payload) == 'table' then

		local content = payload.content

		if type(payload.code) == 'string' then
			content = format('```%s\n%s\n```', payload.code, content)
		elseif payload.code == true then
			content = format('```\n%s```', content)
		end

		local mentions
		if payload.mention then
			mentions, err = parseMention(payload.mention)
			if err then
				return nil, err
			end
		end

		if type(payload.mentions) == 'table' then
			for _, mention in ipairs(payload.mentions) do
				mentions, err = parseMention(mention, mentions)
				if err then
					return nil, err
				end
			end
		end

		if mentions then
			insert(mentions, content)
			content = concat(mentions, ' ')
		end

		local files
		if payload.file then
			files, err = parseFile(payload.file)
			if err then
				return nil, err
			end
		end

		if type(payload.files) == 'table' then
			for _, file in ipairs(payload.files) do
				files, err = parseFile(file, files)
				if err then
					return nil, err
				end
			end
		end

		data, err = self.client.api:createMessage(self.id, {
			content = content,
			tts = payload.tts,
			nonce = payload.nonce,
			embed = payload.embed,
		}, nil, files)

	else

		data, err = self.client.api:createMessage(self.id, {content = payload})

	end

	if data then
		data.guild_id = self.guildId
		return Message(data, self.client)
	else
		return nil, err
	end

end

local getters = {}

return {
	methods = methods,
	getters = getters,
}
