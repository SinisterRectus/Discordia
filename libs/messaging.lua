local fs = require('fs')
local pathjoin = require('pathjoin')
local typing = require('./typing')

local format = string.format
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath
local insert, remove, concat = table.insert, table.remove, table.concat
local checkSnowflake = typing.checkSnowflake

local function parseMention(obj, mentions)
	if type(obj) == 'table' and type(obj.toMention) == 'function' then
		insert(mentions, obj:toMention())
		return mentions
	end
	return error('invalid mention: ' .. tostring(obj), 2)
end

local function parseEmbed(obj, embeds)
	if type(obj) == 'table' then
		insert(embeds, obj)
		return embeds
	elseif type(obj) == 'string' then
		insert(embeds, {description = obj})
		return embeds
	end
	return error('invalid embed: ' .. tostring(obj), 2)
end

local function parseFile(obj, files)
	if type(obj) == 'string' then
		local data = readFileSync(obj)
		if data then
			insert(files, {remove(splitPath(obj)), data})
		end
		return files
	elseif type(obj) == 'table' and type(obj[1]) == 'string' and type(obj[2]) == 'string' then
		insert(files, obj)
		return files
	end
	return error('invalid file: ' .. tostring(obj), 2)
end

local messaging = {}

function messaging.parseContent(payload)

	local content = payload.content

	if type(payload.code) == 'string' then
		content = format('```%s\n%s\n```', payload.code, content or '\n')
	elseif payload.code == true then
		content = format('```\n%s```', content or '\n')
	end

	local mentions = payload.mention and parseMention(payload.mention, {})
	if type(payload.mentions) == 'table' then
		for _, mention in pairs(payload.mentions) do
			mentions = parseMention(mention, mentions or {})
		end
	end

	if mentions then
		insert(mentions, content)
		content = concat(mentions, ' ')
	end

	return content

end

function messaging.parseEmbeds(payload)
	local embeds = payload.embed and parseEmbed(payload.embed, {})
	if type(payload.embeds) == 'table' then
		for _, embed in pairs(payload.embeds) do
			embeds = parseEmbed(embed, embeds or {})
		end
	end
	return embeds
end

function messaging.parseFiles(payload)
	local files = payload.file and parseFile(payload.file, {})
	if type(payload.files) == 'table' then
		for _, file in pairs(payload.files) do
			files = parseFile(file, files or {})
		end
	end
	return files
end

local types = {'users', 'roles', 'everyone'}
function messaging.parseAllowedMentions(payload, default)
	local ret = {parse = {}}
	local input = payload.allowedMentions
	if type(input) == 'table' then
		for _, k in ipairs(types) do
			if input[k] == true or (input[k] == nil and default[k] == true) then
				insert(ret.parse, k)
			end
		end
		if input.repliedUser == true or (input.repliedUser == nil and default.repliedUser == true) then
			ret.replied_user = true
		end
	else
		for _, k in ipairs(types) do
			if default[k] == true then
				insert(ret.parse, k)
			end
		end
		if default.repliedUser == true then
			ret.replied_user = true
		end
	end
	return ret
end

function messaging.parseMessageReference(payload)
	local messageReference
	if type(payload.reference) == 'table' then
		messageReference = {
			message_id = checkSnowflake(payload.reference.message),
		}
	end
	return messageReference
end

return messaging
