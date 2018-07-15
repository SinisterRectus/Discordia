local enums = require('enums')
local json = require('json')
local ssl = require('openssl')
local fs = require('fs')
local pathjoin = require('pathjoin')

local API = require('client/API')
local Logger = require('utils/Logger')
local Resolver = require('client/Resolver')

local Emitter = require('utils/Emitter')

local format = string.format
local insert, remove = table.insert, table.remove

local logLevel = enums.logLevel
local null = json.null
local base64 = ssl.base64
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath

local defaultOptions = {
	routeDelay = 300,
	maxRetries = 5,
	tts = false,
	nonce = "",
	logFile = 'discordia.log',
	logLevel = logLevel.info,
	dateTime = '%F %T',
	name = "",
	avatarURL = "",
	avatar = "",
	channel_id = "",
	guild_id = "",
	id = "",
	token = "",
	_user = {}
}

local function parseOptions(customOptions)
	if type(customOptions) == 'table' then
		local options = {}
		for k, default in pairs(defaultOptions) do -- load options
			local custom = customOptions[k]
			if custom ~= nil then
				options[k] = custom
			else
				options[k] = default
			end
		end
		for k, v in pairs(customOptions) do -- validate options
			local default = type(defaultOptions[k])
			local custom = type(v)
			if default ~= custom then
				return error(format('invalid client option %q (%s expected, got %s)', k, default, custom), 3)
			end
			if custom == 'number' and (v < 0 or v % 1 ~= 0) then
				return error(format('invalid client option %q (number must be a positive integer)', k), 3)
			end
		end
		return options
	else
		return defaultOptions
	end
end


local function parseFile(obj)
	if type(obj) == 'string' then
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		file = file or {}
		insert(file, {remove(splitPath(obj)), data})
	else
		return nil, 'Invalid file object: ' .. tostring(obj)
	end
	return file
end


local WebhookClient, get = require('class')('WebhookClient', Emitter)
WebhookClient.__description = "Represents a Webhook Client."

function WebhookClient:__init(id, token, options)
	Emitter.__init(self)

	options = options or {}
	options["id"] = id
	options["token"] = token

	self._options = parseOptions(options)
	self._logger = Logger(self._options.logLevel, self._options.dateTime, self._options.logFile)
	self._api = API(self)

	-- Sync our defaultOptions with the webhook data
	local webhook, err = self._api:getWebhookWithToken(self._options.id, self._options.token)
	if webhook then
		for key, value in pairs(webhook) do
			if type(value) ~= "table" then
				self._options[key] = value
			end
		end
	end

	if options then
		for k, v in pairs(options) do
			self._options[k] = v
		end
	end
end

for name, level in pairs(logLevel) do
	WebhookClient[name] = function(self, fmt, ...)
		local msg = self._logger:log(level, fmt, ...)
		if #self._listeners[name] > 0 then
			return self:emit(name, msg or format(fmt, ...))
		end
	end
end

-- Getters
function get.avatar(self)
	return self._options.avatar
end

function get.channelId(self)
	return self._options.channel_id
end

function get.guildId(self)
	return self._options.guild_id
end

function get.id(self)
	return self._options.id
end

function get.name(self)
	return self._options.name
end

function get.token(self)
	return self._options.token
end

-- Setters and Modifiers
function WebhookClient:_modify(tbl)
	for k, v in pairs(tbl) do
		if k ~= "channelId" then -- You can not change the channelId
			self._options[k] = v
		else
			self:info("modify does not accept a channelId key.")
		end
	end

	local data, err = self._api:modifyWebhookWithToken(self._options.id, self._options.token, tbl)
	if data then 
		return true
	else
		return false, err
	end
end

function WebhookClient:setAvatar(avatar)
	avatar = Resolver.base64(avatar) or null

	local data, err = self:_modify({avatar = avatar})
	if data then
		return true
	else
		return nil, err
	end
end

function WebhookClient:setName(name)
	local data, err = self:_modify({name = name})
	if data then
		return true
	else
		return nil, err
	end
end

-- Rest of functions
function WebhookClient:send(content, options) -- return message
	local files
	local query = {
		wait = options and options.wait or false
	}

	if options then
		for key, value in pairs(options) do
			self._options[key] = value -- merge new options
		end

		if options.file then -- Only one file can be sent at the same time.
			cntn, err = parseFile(options.file)
			if err then
				return nil, err
			end
			files = cntn
		end
	end

	if files then
		self._options.file = files
	end

	local webhookData = self._options
	local data, err = self._api:executeWebhook(self._options.id, self._options.token, { -- We insert these values manually so that we don't send extra (irrevelant) information
		content = content,
		username = webhookData.name,
		avatar_url = webhookData.avatarURL,
		tts = webhookData.tts,
		embeds = webhookData.embeds
	}, webhookData.file, wait)

	if data then
		return true
	else
		return nil, err
	end
end

function WebhookClient:deleteWebhook()
	local data, err = self._api:deleteWebhookWithToken(self._options.id, self._options.token)
	if data then
		return true
	else
		return false, err
	end
end

function WebhookClient:executeSlackCompatible(body)
	local data, err = self._api:executeSlackCompatibleWebhook(self._options.id, self._options.token, body)
	if data then
		return true
	else
		return false, err
	end
end

function WebhookClient:executeGitHubCompatible(body)
	local data, err = self._api:executeGitHubCompatibleWebhook(self._options.id, self._options.token, body)
	if data then
		return true
	else
		return false, err
	end
end

return WebhookClient
