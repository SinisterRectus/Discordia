local json = require('json')
local enums = require('enums')
local request = require("coro-http").request
local ssl = require('openssl')
local fs = require('fs')
local pathjoin = require('pathjoin')

local Resolver = require('client/Resolver')

local Snowflake = require('containers/abstract/Snowflake')
local User = require('containers/User')


local format = string.format
local insert, remove = table.insert, table.remove
local defaultAvatar = enums.defaultAvatar
local base64 = ssl.base64
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath

local function resolveImage(avatar, id)
	if avatar and id then
		return format("https://cdn.discordapp.com/avatars/%s/%s.png", id, avatar)
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


local Webhook, get = require('class')('Webhook', Snowflake)

function Webhook:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._user = data.user and self.client._users:_insert(data.user) -- DNE if getting by token
end

-- Getters
function Webhook:getAvatarURL(size, ext)
	return self._avatarURL ~= "" and self._avatarURL or User.getAvatarURL(self, size, ext)
end

function Webhook:getDefaultAvatarURL(size)
	return User.getDefaultAvatarURL(self, size)
end

function get.id(self)
	return self._id
end

function get.guildId(self)
	return self._guild_id
end

function get.channelId(self)
	return self._channel_id
end

function get.user(self)
	return self._user
end

function get.token(self)
	return self._token
end

function get.name(self)
	return self._name
end

function get.avatar(self)
	return self._avatar
end

function get.avatarURL(self)
	return self:getAvatarURL()
end

function get.defaultAvatar()
	return defaultAvatar.blurple
end

function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end


-- Setters and Modifiers
function Webhook:_modify(payload)
	local data, err = self.client._api:modifyWebhook(self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Webhook:setAvatar(avatar)
	self._avatarUrl = avatar
	self._avatar = Resolver.base64(avatar) or resolveImage(avatar) or json.null

	local data, err = self:_modify({avatar = self._avatar})
	if data then
		return true
	else
		return nil, err
	end
end

function Webhook:setChannelId(channelId)
	self._channel_id = channelId

	local data, err = self:_modify({channel_id = channelId})
	if data then
		return true
	else
		return nil, err
	end
end

function Webhook:setName(name)
	self._name = name

	local data, err = self:_modify({name = name})
	if data then
		return true
	else
		return nil, err
	end
end

-- Rest of functions
function Webhook:send(content, options) -- return message
	local files, tts = false, embeds
	local query = {
		wait = options and options.wait or false
	}
	if options then
		for key, value in pairs(options) do
			self["_"..key] = value -- merge new options
		end

		if options.file then -- Only one file can be sent at the same time.
			cntn, err = parseFile(options.file)
			if err then
				return nil, err
			end
			files = cntn
		end

		if options.tts then tts = options.tts end
		if options.embeds then tts = embeds.embeds end
	end

	local data, err = self.client._api:executeWebhook(self._id, self._token, { -- We insert these values manually so that we don't send extra (irrevelant) information
		content = content,
		username = self._name,
		avatar_url = self._avatarURL,
		tts = tts,
		embeds = embeds
	}, files, query)

	if data then
		return true
	else
		return nil, err
	end
end

function Webhook:delete()
	local data, err = self.client._api:deleteWebhook(self._id)
	if data then
		return true
	else
		return false, err
	end
end

function Webhook:deleteWithToken()
	local data, err = self.client._api:deleteWebhookWithToken(self._id, self._token)
	if data then
		return true
	else
		return false, err
	end
end

function Webhook:executeSlackCompatible(body)
	local data, err = self.client._api:executeSlackCompatibleWebhook(self._id, self._token, body)
	if data then
		return true
	else
		return false, err
	end
end

function Webhook:executeGitHubCompatible(body)
	local data, err =  self.client._api:executeGitHubCompatibleWebhook(self._id, self._token, body)
	if data then
		return true
	else
		return false, err
	end
end

return Webhook
