local fs = require('fs')
local http = require('coro-http')
local pathjoin = require('pathjoin')

local request = http.request
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath
local insert, remove, concat = table.insert, table.remove, table.concat

local Channel = require('containers/abstract/Channel')
local Message = require('containers/Message')
local WeakCache = require('iterables/WeakCache')
local SecondaryCache = require('iterables/SecondaryCache')

local TextChannel = require('class')('TextChannel', Channel)
local get = TextChannel.__getters

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self._messages = WeakCache(Message, self)
end

function TextChannel:getMessage(id)
	local message = self._messages:get(id)
	if message then
		return message
	else
		local data, err = self.client._api:getChannelMessage(self._id, id)
		if data then
			return self._messages:_insert(data)
		else
			return nil, err
		end
	end
end

function TextChannel:getFirstMessage()
	local data, err = self.client._api:getChannelMessages(self._id, {after = self._id, limit = 1})
	if data then
		return self._messages:_insert(data[1])
	else
		return nil, err
	end
end

function TextChannel:getLastMessage()
	local data, err = self.client._api:getChannelMessages(self._id, {limit = 1})
	if data then
		return self._messages:_insert(data[1])
	else
		return nil, err
	end
end

local function getMessageHistory(self, query)
	local data, err = self.client._api:getChannelMessages(self._id, query)
	if data then
		return SecondaryCache(data, self._messages) -- TODO: static cache
	else
		return nil, err
	end
end

function TextChannel:getMessageHistory(limit)
	local query = limit and {limit = limit} or nil
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAfter(message, limit)
	local query = {after = message, limit = limit} -- TODO: resolve
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryBefore(message, limit)
	local query = {before = message, limit = limit} -- TODO: resolve
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAround(message, limit)
	local query = {around = message, limit = limit} -- TODO: resolve
	return getMessageHistory(self, query)
end

function TextChannel:getPinnedMessages()
	local data, err = self.client._api:getPinnedMessages(self._id)
	if data then
		return SecondaryCache(data, self._messages) -- TODO: static cache
	else
		return nil, err
	end
end

function TextChannel:broadcastTyping()
	local data, err = self.client._api:triggerTypingIndicator(self._id)
	if data then
		return true
	else
		return false, err
	end
end

local function readFile(path)
	if path:find('https?://') == 1 then
		local success, res, data = pcall(request, 'GET', path)
		if not success then
			return nil, res
		elseif res.code > 299 then
			return nil, res.reason
		else
			return data
		end
	else
		return readFileSync(path)
	end
end

local function parseFile(obj, files)
	if type(obj) == 'string' then
		local data, err = readFile(obj)
		if not data then
			return nil, err
		end
		files = files or {}
		insert(files, {remove(splitPath(obj)), data})
	elseif type(obj) == 'table' and type(obj[1]) == 'string' and type(obj[2]) == 'string' then
		files = files or {}
		insert(files, obj)
	else
		return nil, 'Invalid file object: ' .. tostring(obj)
	end
	return files
end

local function parseMention(obj, mentions)
	if type(obj) == 'table' and obj.mentionString then
		mentions = mentions or {}
		insert(mentions, obj.mentionString)
	else
		return nil, 'Unmentionable object: ' .. tostring(obj)
	end
	return mentions
end

function TextChannel:send(content)

	local data, err

	if type(content) == 'table' then

		local tbl = content
		content = tbl.content

		local mentions
		if tbl.mention then
			mentions, err = parseMention(tbl.mention)
			if err then
				return nil, err
			end
		end
		if type(tbl.mentions) == 'table' then
			for _, mention in ipairs(tbl.mentions) do
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
		if tbl.file then
			files, err = parseFile(tbl.file)
			if err then
				return nil, err
			end
		end
		if type(tbl.files) == 'table' then
			for _, file in ipairs(tbl.files) do
				files, err = parseFile(file, files)
				if err then
					return nil, err
				end
			end
		end

		data, err = self.client._api:createMessage(self._id, {
			content = content,
			tts = tbl.tts,
			nonce = tbl.nonce,
			embed = tbl.embed,
		}, files)

	else

		data, err = self.client._api:createMessage(self._id, {content = content})

	end

	if data then
		return self._messages:_insert(data)
	else
		return nil, err
	end

end

function get.messages(self)
	return self._messages
end

return TextChannel
