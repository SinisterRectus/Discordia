local enums = require('enums')
local json = require('json')
local request = require("coro-http").request
local ssl = require('openssl')
local fs = require('fs')
local pathjoin = require('pathjoin')

local Logger = require('utils/Logger')
local Resolver = require('client/Resolver')

local Webhook = require('containers/Webhook')
local Message = require('containers/Message')

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
	tts = false,
	nonce = "",
	logFile = 'discordia.log',
	logLevel = logLevel.info,
	dateTime = '%F %T',
	name = "",
	avatarURL = "",
	avatar = "",
	channelId = "",
	guildId = "",
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

local function resolveImage(avatar, id)
	if avatar then
		if tostring(avatar):match("^(https?:)") then
			local res, data = request("GET", avatar)
			if res.code < 300 then
				return 'data:;base64,' .. base64(data)
			end
			return
		else
			return format("https://cdn.discordapp.com/avatars/%s/%s.png", id, avatar)
		end
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

local function clean(user)
	local cleanedUser = {}
	for k, v in pairs(user) do
		if k:find("_") then
			cleanedUser[k:gsub("_", "")] = v
		end
	end
	return cleanedUser
end

local function modify(self, tbl)
	local data, err = self._api:modifyWebhook(self._id, tbl)
	if data then 
		return true
	else
		return false, err
	end
end

local WebhookClient, get = require('class')('WebhookClient', Emitter)
WebhookClient.__description = "Represents a Webhook Client."

function WebhookClient:__init(id, token, options)
	Emitter.__init(self)

	self._options = parseOptions(options)
	self._id = tostring(id)
	self._token = tostring(token)
	self._logger = Logger(self._options.logLevel, self._options.dateTime, self._options.logFile)
	self._api = API
	self._webhook = ""

	-- Sync our defaultOptions with the webhook data
	local webhook, err = self._api:getWebhook(self._id) -- we do not use getWebhookWithToken because it does not return the user object
	if webhook then
		for key, value in pairs(webhook) do
			if type(value) ~= "table" then
				self._options[key] = value
			else 
				for user_key, user_value in pairs(value) do
					if not self._options[key] then self._options[key] = {} end
					self._options[key]["_" .. user_key] = user_value
				end
			end
		end
	end

	if options then
		modify(self, options)
		for k, v in pairs(options) do
			self._options[k] = v
		end
	end
	self._webhook = Webhook(self._options, self, self._api)
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
function get.avatarURL(self, size, ext)
	return self._options.avatarURL ~= "" and self._options.avatarURL or resolveImage(self._options.avatar, self._id)
end

function get.channelId(self)
	return self._options.channel_id
end

function get.guildId(self)
	return self._webhook.guildId
end

function get.id(self)
	return self._webhook.id
end

function get.name(self)
	return self._options.name
end

function get.token(self)
	return self._webhook.token
end

function get.user(self)
	return clean(self._webhook.user) -- does not return a full user object because it is not linked with Client
end


-- Setters and Modifiers
function WebhookClient:setAvatar(avatar)
	self._options.avatarURL = avatar
	avatar = resolveImage(avatar) or Resolver.base64(avatar) or null

	local bool, err = self:modify({avatar = avatar})
	if bool then
		return self
	else
		self:error(err)
	end
end

function WebhookClient:setChannelId(channelId)
	self._options.channelId = channelId
	local bool, err = self:modify({channel_id = channelId})

	if bool then
		return self
	else
		self:error(err)
	end
end

function WebhookClient:setName(name)
	self._options.name = name
	local bool, err = self:modify({name = name})

	if bool then
		return self
	else
		self:error(err)
	end
end

function WebhookClient:modify(tbl)
	assert(type(tbl) == "table", "Invalid modify parameter. Table expected")

	for k, v in pairs(tbl) do
		self._options[k] = v
	end

	return modify(self, tbl)
end

function WebhookClient:modifyWithToken(tbl) 
	assert(type(tbl) == "table", "Invalid modify parameter. Table expected")

	for k, v in pairs(tbl) do
		if k ~= "channelId" then -- You can not change the channelId
			self._options[k] = v
		else
			self:info("modifyWithToken does not accept a channelId key. Use 'modify' to change it.")
		end
	end
	self._api:modifyWebhookWithToken(self._id, self._token, tbl)

	return self
end

-- Rest of functions
function WebhookClient:send(content, options) -- return message
	local file
	if options then
		for key, value in pairs(options) do
			self._options[key] = value -- merge new options
		end

		if options.file then -- Only one file can be sent at the same time.
			cntn, err = parseFile(options.file)
			if err then
				return nil, err
			end
			file = cntn
		end
	end

	if file then
		self._options.file = file
	end

	local webhookData = self._options
	local data, err = self._api:executeWebhook(self._id, self._token, { -- We insert these values manually so that we don't send extra (irrevelant) information
		content = content,
		username = webhookData.name,
		avatar_url = webhookData.avatarURL,
		tts = webhookData.tts,
		embeds = webhookData.embeds
	}, webhookData.file)

	if data then
		return Message(data, self), self
	else
		return self:error(err)
	end
end

function WebhookClient:delete()
	local data, err = self._api:deleteWebhook(self._id)
	if data then
		return true
	else
		return false, err
	end
end

function WebhookClient:deleteWithToken()
	local data, err = self._api:deleteWebhookWithToken(self._id, self._token)
	if data then
		return true
	else
		return false, err
	end
end

function WebhookClient:executeSlackCompatible(body)
	self._api:executeSlackCompatibleWebhook(self._id, self._token, body)
end

function WebhookClient:executeGitHubCompatible(body)
	self._api:executeGitHubCompatibleWebhook(self._id, self._token, body)
end

return WebhookClient
