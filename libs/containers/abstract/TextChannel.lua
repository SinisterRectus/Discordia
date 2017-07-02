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

local TextChannel = require('class')('TextChannel', Channel)
local get = TextChannel.__getters

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self._messages = WeakCache(Message, self)
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

function TextChannel:send(args)

	local data, err

	if type(args) == 'table' then

		local content = args.content

		local mentions
		if args.mention then
			mentions, err = parseMention(args.mention)
			if err then
				return nil, err
			end
		end
		if type(args.mentions) == 'table' then
			for _, mention in ipairs(args.mentions) do
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
		if args.file then
			files, err = parseFile(args.file)
			if err then
				return nil, err
			end
		end
		if type(args.files) == 'table' then
			for _, file in ipairs(args.files) do
				files, err = parseFile(file, files)
				if err then
					return nil, err
				end
			end
		end

		data, err = self.client._api:createMessage(self._id, {
			content = content,
			tts = args.tts,
			nonce = args.nonce,
			embed = args.embed,
		}, files)

	else

		data, err = self.client._api:createMessage(self._id, {content = args})

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
