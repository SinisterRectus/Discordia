local json = require('json')
local timer = require('timer')
local http = require('coro-http')
local endpoints = require('../endpoints')
local helpers = require('../helpers')
local class = require('../class')
local constants = require('../constants')
local Mutex = require('../utils/Mutex')

local request = http.request
local format, lower = string.format, string.lower
local max, random = math.max, math.random
local encode, decode = json.encode, json.decode
local insert, concat = table.insert, table.concat
local running = coroutine.running
local urlEncode, attachQuery = helpers.urlEncode, helpers.attachQuery

local API_BASE_URL = constants.API_BASE_URL
local JSON_CONTENT_TYPE = constants.JSON_CONTENT_TYPE
local RATELIMIT_PRECISION = constants.RATELIMIT_PRECISION
local USER_AGENT = constants.USER_AGENT

local majorParams = {guilds = true, channels = true, webhooks = true}
local payloadRequired = {PUT = true, PATCH = true, POST = true}

local function parseErrors(ret, errors, key) -- TODO: optimize if possible
	for k, v in pairs(errors) do
		if k == '_errors' then
			for _, err in ipairs(v) do
				insert(ret, format('%s in %s : %s', err.code, key or 'payload', err.message))
			end
		else
			if key then
				parseErrors(ret, v, format(k:find("^[%a_][%a%d_]*$") and '%s.%s' or tonumber(k) and '%s[%s]' or '%s[%q]', key, k))
			else
				parseErrors(ret, v, k)
			end
		end
	end
	return concat(ret, '\n\t')
end

local function generateBoundary(files, boundary)
	boundary = boundary or tostring(random(0, 9))
	for _, v in ipairs(files) do
		if v[2]:find(boundary, 1, true) then
			return generateBoundary(files, boundary .. random(0, 9))
		end
	end
	return boundary
end

local function attachFiles(payload, files)
	local boundary = generateBoundary(files)
	local ret = {
		'--' .. boundary,
		'Content-Disposition:form-data;name="payload_json"',
		'Content-Type:application/json\r\n',
		payload,
	}
	for i, v in ipairs(files) do
		insert(ret, '--' .. boundary)
		insert(ret, format('Content-Disposition:form-data;name="file%i";filename=%q', i, v[1]))
		insert(ret, 'Content-Type:application/octet-stream\r\n')
		insert(ret, v[2])
	end
	insert(ret, '--' .. boundary .. '--')
	return concat(ret, '\r\n'), boundary
end

local meta = {__mode = 'v'}

local API, get = class('API')

function API:__init(client)
	self._client = assert(client)
	self._routeBuckets = {}
	self._bucketMutexes = {}
	self._routeMutexes = setmetatable({}, meta)
	self._rx = 0
	self._tx = 0
	self._requests = 0
	self._token = nil
end

function API:setToken(token)
	local prefix = self._client.tokenPrefix
	if token:sub(1, #prefix) == prefix then
		self._token = token
	else
		self._token = prefix .. token
	end
end

function API:log(level, res, method, url)
	return self._client:log(level, '%i - %s : %s %s', res.code, res.reason, method, url)
end

function API:request(method, endpoint, params, query, payload, files)

	local _, main = running()
	if main then
		return error('Cannot make HTTP request outside of a coroutine')
	end

	local url = {API_BASE_URL}
	local route = endpoint

	if #params > 0 then
		local i = 0
		route = route:gsub('(/(%a+)/)%%s', function(str, k)
			i = i + 1
			return majorParams[k] and str .. params[i]
		end)
		insert(url, endpoint:format(unpack(params)))
	else
		insert(url, endpoint)
	end

	if query and next(query) then
		attachQuery(url, query)
	end

	url = concat(url)

	local req = {
		{'User-Agent', USER_AGENT},
		{'X-RateLimit-Precision', RATELIMIT_PRECISION},
	}

	if self._token then
		insert(req, {'Authorization', self._token})
	end

	if payloadRequired[method] then
		payload = payload and encode(payload) or '{}'
		if files and #files > 0 then
			local boundary
			payload, boundary = attachFiles(payload, files)
			insert(req, {'Content-Type', 'multipart/form-data;boundary=' .. boundary})
		else
			insert(req, {'Content-Type', JSON_CONTENT_TYPE})
		end
		insert(req, {'Content-Length', #payload})
	end

	local bucket = self._routeBuckets[route]
	local bucketMutex = self._bucketMutexes[bucket]
	local routeMutex = self._routeMutexes[route]

	if bucketMutex then
		bucketMutex:lock()
	elseif not routeMutex then
		routeMutex = Mutex()
		self._routeMutexes[route] = routeMutex
	end

	if routeMutex then
		routeMutex:lock()
	end

	local data, err, delay = self:commit(method, url, req, payload, route, 0)

	if bucketMutex then
		bucketMutex:unlockAfter(delay)
	end

	if routeMutex then
		routeMutex:unlockAfter(delay)
	end

	if data then
		return data
	else
		return nil, err
	end

end

function API:commit(method, url, req, payload, route, retries)

	local client = self._client
	local delay = client.routeDelay

	local success, res, msg = pcall(request, method, url, req, payload)
	if not success then
		client:log('error', 'HTTP client error: %s', res)
		return nil, res, delay
	end

	local head = {}
	for _, v in ipairs(res) do
		head[lower(v[1])] = v[2]
	end

	self._rx = self._rx + #msg
	self._tx = self._tx + (payload and #payload or 0)
	self._requests = self._requests + 1
	client:emit('httpRequest', method, url, req, payload, res, msg)

	if head['x-ratelimit-remaining'] == '0' then
		delay = max(1000 * head['x-ratelimit-reset-after'], delay)
	end

	local bucket = head['x-ratelimit-bucket']
	if bucket then
		self._routeBuckets[route] = self._routeBuckets[route] or bucket
		self._bucketMutexes[bucket] = self._bucketMutexes[bucket] or Mutex()
	end

	local data = head['content-type'] == JSON_CONTENT_TYPE and decode(msg) or {}

	if res.code < 300 then
		self:log('debug', res, method, url)
		return data, nil, delay
	end

	local retry
	if res.code == 429 and data.retry_after then -- TODO: global ratelimiting
		delay = data.retry_after
		retry = retries < client.maxRetries
	elseif res.code == 502 then
		delay = delay + random(1000, 4000)
		retry = retries < client.maxRetries
	end

	if retry then
		self:log('warning', res, method, url)
		timer.sleep(delay)
		return self:commit(method, url, req, payload, retries + 1)
	end

	msg = format('HTTP Error %i : %s', data.code or 0, data.message or msg)
	if data.errors then
		msg = parseErrors({msg}, data.errors)
	end

	self:log('error', res, method, url)
	return nil, msg, delay

end

---- begin autogenerated methods ----

function API:getEntitlements(application_id, query)
	local endpoint = endpoints.APPLICATION_ENTITLEMENTS
	local params = {application_id}
	return self:request("GET", endpoint, params, query)
end

function API:getEntitlement(application_id, entitlement_id, query)
	local endpoint = endpoints.APPLICATION_ENTITLEMENT
	local params = {application_id, entitlement_id}
	return self:request("GET", endpoint, params, query)
end

function API:getSKUs(application_id, query)
	local endpoint = endpoints.APPLICATION_SKUS
	local params = {application_id}
	return self:request("GET", endpoint, params, query)
end

function API:consumeSKU(application_id, entitlement_id, payload, query)
	local endpoint = endpoints.APPLICATION_ENTITLEMENT_CONSUME
	local params = {application_id, entitlement_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:deleteTestEntitlement(application_id, entitlement_id, query)
	local endpoint = endpoints.APPLICATION_ENTITLEMENT
	local params = {application_id, entitlement_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:createPurchaseDiscount(sku_id, user_id, payload, query)
	local endpoint = endpoints.STORE_SKU_DISCOUNT
	local params = {sku_id, user_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:deletePurchaseDiscount(sku_id, user_id, query)
	local endpoint = endpoints.STORE_SKU_DISCOUNT
	local params = {sku_id, user_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getGuildAuditLog(guild_id, query)
	local endpoint = endpoints.GUILD_AUDIT_LOGS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getChannel(channel_id, query)
	local endpoint = endpoints.CHANNEL
	local params = {channel_id}
	return self:request("GET", endpoint, params, query)
end

function API:modifyChannel(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL
	local params = {channel_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteCloseChannel(channel_id, query)
	local endpoint = endpoints.CHANNEL
	local params = {channel_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getChannelMessages(channel_id, query)
	local endpoint = endpoints.CHANNEL_MESSAGES
	local params = {channel_id}
	return self:request("GET", endpoint, params, query)
end

function API:getChannelMessage(channel_id, message_id, query)
	local endpoint = endpoints.CHANNEL_MESSAGE
	local params = {channel_id, message_id}
	return self:request("GET", endpoint, params, query)
end

function API:createMessage(channel_id, payload, query, files)
	local endpoint = endpoints.CHANNEL_MESSAGES
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload, files)
end

function API:crosspostMessage(channel_id, message_id, payload, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_CROSSPOST
	local params = {channel_id, message_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:createReaction(channel_id, message_id, emoji, payload, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTION_ME
	local params = {channel_id, message_id, urlEncode(emoji)}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:deleteOwnReaction(channel_id, message_id, emoji, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTION_ME
	local params = {channel_id, message_id, urlEncode(emoji)}
	return self:request("DELETE", endpoint, params, query)
end

function API:deleteUserReaction(channel_id, message_id, emoji, user_id, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTION_USER
	local params = {channel_id, message_id, urlEncode(emoji), user_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getReactions(channel_id, message_id, emoji, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTION
	local params = {channel_id, message_id, urlEncode(emoji)}
	return self:request("GET", endpoint, params, query)
end

function API:deleteAllReactions(channel_id, message_id, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTIONS
	local params = {channel_id, message_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:deleteAllReactionsForEmoji(channel_id, message_id, emoji, query)
	local endpoint = endpoints.CHANNEL_MESSAGE_REACTION
	local params = {channel_id, message_id, urlEncode(emoji)}
	return self:request("DELETE", endpoint, params, query)
end

function API:editMessage(channel_id, message_id, payload, query)
	local endpoint = endpoints.CHANNEL_MESSAGE
	local params = {channel_id, message_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteMessage(channel_id, message_id, query)
	local endpoint = endpoints.CHANNEL_MESSAGE
	local params = {channel_id, message_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:bulkDeleteMessages(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL_MESSAGES_BULK_DELETE
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload, query)
	local endpoint = endpoints.CHANNEL_PERMISSION
	local params = {channel_id, overwrite_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:getChannelInvites(channel_id, query)
	local endpoint = endpoints.CHANNEL_INVITES
	local params = {channel_id}
	return self:request("GET", endpoint, params, query)
end

function API:createChannelInvite(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL_INVITES
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:deleteChannelPermission(channel_id, overwrite_id, query)
	local endpoint = endpoints.CHANNEL_PERMISSION
	local params = {channel_id, overwrite_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:followNewsChannel(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL_FOLLOWERS
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:triggerTypingIndicator(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL_TYPING
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getPinnedMessages(channel_id, query)
	local endpoint = endpoints.CHANNEL_PINS
	local params = {channel_id}
	return self:request("GET", endpoint, params, query)
end

function API:addPinnedChannelMessage(channel_id, message_id, payload, query)
	local endpoint = endpoints.CHANNEL_PIN
	local params = {channel_id, message_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:deletePinnedChannelMessage(channel_id, message_id, query)
	local endpoint = endpoints.CHANNEL_PIN
	local params = {channel_id, message_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:groupDMAddRecipient(channel_id, user_id, payload, query)
	local endpoint = endpoints.CHANNEL_RECIPIENT
	local params = {channel_id, user_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:groupDMRemoveRecipient(channel_id, user_id, query)
	local endpoint = endpoints.CHANNEL_RECIPIENT
	local params = {channel_id, user_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:listGuildEmojis(guild_id, query)
	local endpoint = endpoints.GUILD_EMOJIS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildEmoji(guild_id, emoji_id, query)
	local endpoint = endpoints.GUILD_EMOJI
	local params = {guild_id, emoji_id}
	return self:request("GET", endpoint, params, query)
end

function API:createGuildEmoji(guild_id, payload, query)
	local endpoint = endpoints.GUILD_EMOJIS
	local params = {guild_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:modifyGuildEmoji(guild_id, emoji_id, payload, query)
	local endpoint = endpoints.GUILD_EMOJI
	local params = {guild_id, emoji_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteGuildEmoji(guild_id, emoji_id, query)
	local endpoint = endpoints.GUILD_EMOJI
	local params = {guild_id, emoji_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:createGuild(payload, query)
	local endpoint = endpoints.GUILDS
	local params = {}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getGuild(guild_id, query)
	local endpoint = endpoints.GUILD
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildPreview(guild_id, query)
	local endpoint = endpoints.GUILD_PREVIEW
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:modifyGuild(guild_id, payload, query)
	local endpoint = endpoints.GUILD
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteGuild(guild_id, query)
	local endpoint = endpoints.GUILD
	local params = {guild_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getGuildChannels(guild_id, query)
	local endpoint = endpoints.GUILD_CHANNELS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:createGuildChannel(guild_id, payload, query)
	local endpoint = endpoints.GUILD_CHANNELS
	local params = {guild_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:modifyGuildChannelPositions(guild_id, payload, query)
	local endpoint = endpoints.GUILD_CHANNELS
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:getGuildMember(guild_id, user_id, query)
	local endpoint = endpoints.GUILD_MEMBER
	local params = {guild_id, user_id}
	return self:request("GET", endpoint, params, query)
end

function API:listGuildMembers(guild_id, query)
	local endpoint = endpoints.GUILD_MEMBERS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:addGuildMember(guild_id, user_id, payload, query)
	local endpoint = endpoints.GUILD_MEMBER
	local params = {guild_id, user_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:modifyGuildMember(guild_id, user_id, payload, query)
	local endpoint = endpoints.GUILD_MEMBER
	local params = {guild_id, user_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:modifyCurrentUserNick(guild_id, payload, query)
	local endpoint = endpoints.GUILD_MEMBERS_ME_NICK
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:addGuildMemberRole(guild_id, user_id, role_id, payload, query)
	local endpoint = endpoints.GUILD_MEMBER_ROLE
	local params = {guild_id, user_id, role_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:removeGuildMemberRole(guild_id, user_id, role_id, query)
	local endpoint = endpoints.GUILD_MEMBER_ROLE
	local params = {guild_id, user_id, role_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:removeGuildMember(guild_id, user_id, query)
	local endpoint = endpoints.GUILD_MEMBER
	local params = {guild_id, user_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getGuildBans(guild_id, query)
	local endpoint = endpoints.GUILD_BANS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildBan(guild_id, user_id, query)
	local endpoint = endpoints.GUILD_BAN
	local params = {guild_id, user_id}
	return self:request("GET", endpoint, params, query)
end

function API:createGuildBan(guild_id, user_id, payload, query)
	local endpoint = endpoints.GUILD_BAN
	local params = {guild_id, user_id}
	return self:request("PUT", endpoint, params, query, payload)
end

function API:removeGuildBan(guild_id, user_id, query)
	local endpoint = endpoints.GUILD_BAN
	local params = {guild_id, user_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getGuildRoles(guild_id, query)
	local endpoint = endpoints.GUILD_ROLES
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:createGuildRole(guild_id, payload, query)
	local endpoint = endpoints.GUILD_ROLES
	local params = {guild_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:modifyGuildRolePositions(guild_id, payload, query)
	local endpoint = endpoints.GUILD_ROLES
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:modifyGuildRole(guild_id, role_id, payload, query)
	local endpoint = endpoints.GUILD_ROLE
	local params = {guild_id, role_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteGuildRole(guild_id, role_id, query)
	local endpoint = endpoints.GUILD_ROLE
	local params = {guild_id, role_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getGuildPruneCount(guild_id, query)
	local endpoint = endpoints.GUILD_PRUNE
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:beginGuildPrune(guild_id, payload, query)
	local endpoint = endpoints.GUILD_PRUNE
	local params = {guild_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getGuildVoiceRegions(guild_id, query)
	local endpoint = endpoints.GUILD_REGIONS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildInvites(guild_id, query)
	local endpoint = endpoints.GUILD_INVITES
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildIntegrations(guild_id, query)
	local endpoint = endpoints.GUILD_INTEGRATIONS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:createGuildIntegration(guild_id, payload, query)
	local endpoint = endpoints.GUILD_INTEGRATIONS
	local params = {guild_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload, query)
	local endpoint = endpoints.GUILD_INTEGRATION
	local params = {guild_id, integration_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteGuildIntegration(guild_id, integration_id, query)
	local endpoint = endpoints.GUILD_INTEGRATION
	local params = {guild_id, integration_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:syncGuildIntegration(guild_id, integration_id, payload, query)
	local endpoint = endpoints.GUILD_INTEGRATION_SYNC
	local params = {guild_id, integration_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getGuildWidget(guild_id, query)
	local endpoint = endpoints.GUILD_WIDGET
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildEmbed(guild_id, query)
	local endpoint = endpoints.GUILD_EMBED
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:modifyGuildWidget(guild_id, payload, query)
	local endpoint = endpoints.GUILD_WIDGET
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:modifyGuildEmbed(guild_id, payload, query)
	local endpoint = endpoints.GUILD_EMBED
	local params = {guild_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:getGuildVanityURL(guild_id, query)
	local endpoint = endpoints.GUILD_VANITY_URL
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildWidgetImage(guild_id, query)
	local endpoint = endpoints.GUILD_WIDGET_PNG
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getInvite(invite_code, query)
	local endpoint = endpoints.INVITE
	local params = {invite_code}
	return self:request("GET", endpoint, params, query)
end

function API:deleteInvite(invite_code, query)
	local endpoint = endpoints.INVITE
	local params = {invite_code}
	return self:request("DELETE", endpoint, params, query)
end

function API:getCurrentUser(query)
	local endpoint = endpoints.USERS_ME
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:getUser(user_id, query)
	local endpoint = endpoints.USER
	local params = {user_id}
	return self:request("GET", endpoint, params, query)
end

function API:modifyCurrentUser(payload, query)
	local endpoint = endpoints.USERS_ME
	local params = {}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:getCurrentUserGuilds(query)
	local endpoint = endpoints.USERS_ME_GUILDS
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:leaveGuild(guild_id, query)
	local endpoint = endpoints.USERS_ME_GUILD
	local params = {guild_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:getUserDMs(query)
	local endpoint = endpoints.USERS_ME_CHANNELS
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:createDM(payload, query)
	local endpoint = endpoints.USERS_ME_CHANNELS
	local params = {}
	return self:request("POST", endpoint, params, query, payload)
end

function API:createGroupDM(payload, query)
	local endpoint = endpoints.USERS_ME_CHANNELS
	local params = {}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getUserConnections(query)
	local endpoint = endpoints.USERS_ME_CONNECTIONS
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:listVoiceRegions(query)
	local endpoint = endpoints.VOICE_REGIONS
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:createWebhook(channel_id, payload, query)
	local endpoint = endpoints.CHANNEL_WEBHOOKS
	local params = {channel_id}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getChannelWebhooks(channel_id, query)
	local endpoint = endpoints.CHANNEL_WEBHOOKS
	local params = {channel_id}
	return self:request("GET", endpoint, params, query)
end

function API:getGuildWebhooks(guild_id, query)
	local endpoint = endpoints.GUILD_WEBHOOKS
	local params = {guild_id}
	return self:request("GET", endpoint, params, query)
end

function API:getWebhook(webhook_id, query)
	local endpoint = endpoints.WEBHOOK
	local params = {webhook_id}
	return self:request("GET", endpoint, params, query)
end

function API:getWebhookWithToken(webhook_id, webhook_token, query)
	local endpoint = endpoints.WEBHOOK_TOKEN
	local params = {webhook_id, webhook_token}
	return self:request("GET", endpoint, params, query)
end

function API:modifyWebhook(webhook_id, payload, query)
	local endpoint = endpoints.WEBHOOK
	local params = {webhook_id}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:modifyWebhookWithToken(webhook_id, webhook_token, payload, query)
	local endpoint = endpoints.WEBHOOK_TOKEN
	local params = {webhook_id, webhook_token}
	return self:request("PATCH", endpoint, params, query, payload)
end

function API:deleteWebhook(webhook_id, query)
	local endpoint = endpoints.WEBHOOK
	local params = {webhook_id}
	return self:request("DELETE", endpoint, params, query)
end

function API:deleteWebhookWithToken(webhook_id, webhook_token, query)
	local endpoint = endpoints.WEBHOOK_TOKEN
	local params = {webhook_id, webhook_token}
	return self:request("DELETE", endpoint, params, query)
end

function API:executeWebhook(webhook_id, webhook_token, payload, query)
	local endpoint = endpoints.WEBHOOK_TOKEN
	local params = {webhook_id, webhook_token}
	return self:request("POST", endpoint, params, query, payload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload, query)
	local endpoint = endpoints.WEBHOOK_TOKEN_SLACK
	local params = {webhook_id, webhook_token}
	return self:request("POST", endpoint, params, query, payload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload, query)
	local endpoint = endpoints.WEBHOOK_TOKEN_GITHUB
	local params = {webhook_id, webhook_token}
	return self:request("POST", endpoint, params, query, payload)
end

function API:getGateway(query)
	local endpoint = endpoints.GATEWAY
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:getGatewayBot(query)
	local endpoint = endpoints.GATEWAY_BOT
	local params = {}
	return self:request("GET", endpoint, params, query)
end

function API:getCurrentApplicationInformation(query)
	local endpoint = endpoints.OAUTH2_APPLICATIONS_ME
	local params = {}
	return self:request("GET", endpoint, params, query)
end

---- end autogenerated methods ----

function get:requests()
	return self._requests
end

function get:bytesReceived()
	return self._rx
end

function get:bytesTransmitted()
	return self._tx
end

return API
