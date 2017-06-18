local json = require('json')
local http = require('coro-http')
local package = require('../../package.lua')
local Date = require('utils/Date')
local Mutex = require('utils/Mutex')
local constants = require('constants')
local endpoints = require('endpoints')

local request = http.request
local f = string.format
local max, random = math.max, math.random
local encode, decode = json.encode, json.decode
local insert, concat = table.insert, table.concat
local difftime = os.difftime

local BASE_URL = constants.BASE_URL

local parseDate = Date.parseHeader

local function parseErrors(ret, errors, key)
	for k, v in pairs(errors) do
		if k == '_errors' then
			for _, err in ipairs(v) do
				insert(ret, f('%s in %s : %s', err.code, key or 'payload', err.message))
			end
		else
			if key then
				parseErrors(ret, v, f(k:find("^[%a_][%a%d_]*$") and '%s.%s' or '%s[%q]', key, k))
			else
				parseErrors(ret, v, k)
			end
		end
	end
	return concat(ret, '\n\t')
end

local majors = {guilds = true, channels = true}

local function buildRoute(method, endpoint)

	if endpoint:find('reactions') then -- special case for reactions
		endpoint = endpoint:gsub('reactions.*', 'reactions')
	end

	endpoint = endpoint:gsub('(%a+)/%d+', function(path)
		return not majors[path] and path
	end)

	if method == 'DELETE' then -- special case for message deletions
		local i, j = endpoint:find('/channels/%d+/messages')
		if i == 1 and j == #endpoint then
			endpoint = method .. endpoint
		end
	end

	return endpoint

end

local function buildURL(endpoint, query)
	if query and next(query) then
		local buffer = {}
		for k, v in pairs(query) do
			insert(buffer, f('%s=%s', k, v))
		end
		return f('%s%s?%s', BASE_URL, endpoint, concat(buffer, '&'))
	else
		return BASE_URL .. endpoint
	end
end

local mutexMeta = {
	__index = function(self, k)
		self[k] = Mutex()
		return self[k]
	end
}

local API = require('class')('API')

function API:__init(client)
	self._client = client
	self._mutexes = setmetatable({}, mutexMeta)
end

function API:authenticate(token)
	self._headers = {
		{'Authorization', token},
		{'User-Agent', f('DiscordBot (%s, %s)', package.homepage, package.version)},
	}
	-- return self:getCurrentUser() -- TODO: active this on release
	return decode(encode({id = '1234', bot = token:find('Bot')}))
end

function API:request(method, endpoint, payload, query)

	local url = buildURL(endpoint, query)
	local route = buildRoute(method, endpoint)

	local req
	if method:find('P') == 1 then -- TODO file attachments
		payload = payload and encode(payload) or '{}'
		req = {}
		for i, v in ipairs(self._headers) do
			req[i] = v
		end
		insert(req, {'Content-Type', 'application/json'})
		insert(req, {'Content-Length', #payload})
	else
		req = self._headers
	end

	local mutex = self._mutexes[route]

	return self:commit(method, url, req, payload, mutex, 0)

end

function API:commit(method, url, req, payload, mutex, retries)

	local client = self._client
	local options = client._options

	mutex:lock(retries > 0)

	local success, res, msg = pcall(request, method, url, req, payload)
	if not success then return nil, res end

	for i, v in ipairs(res) do
		res[v[1]] = v[2]
		res[i] = nil
	end

	local delay = options.routeDelay
	local reset = res['X-RateLimit-Reset']
	local remaining = res['X-RateLimit-Remaining']

	if reset and remaining == '0' then
		local dt = difftime(reset, parseDate(res['Date']))
		delay = max(1000 * dt, delay)
	end

	local data = msg
	if res['Content-Type'] == 'application/json' then
		data = decode(data)
	end

	if res.code > 299 then

		if type(data) == 'table' then

			local retry
			if res.code == 429 then -- TODO: global ratelimiting
				delay = data.retry_after
				retry = retries < options.maxRetries and 'Ratelimited'
			elseif res.code == 502 then
				delay = delay + random(2000)
				retry = retries < options.maxRetries and 'Bad Gateway'
			end

			if retry then
				client:warning('%s, retrying request after %i ms : %s %s', retry, delay, method, url)
				mutex:unlockAfter(delay)
				return self:commit(method, url, req, payload, mutex, retries + 1)
			end

			if data.code and data.message then
				msg = f('HTTP Error %i : %s', data.code, data.message)
			else
				msg = 'HTTP Error'
			end
			if data.errors then
				msg = parseErrors({msg}, data.errors)
			end

		end

		client:error('%i - %s : %s %s', res.code, res.reason, method, url)
		mutex:unlockAfter(delay)
		return nil, msg

	end

	client:debug('%i - %s : %s %s', res.code, res.reason, method, url)
	mutex:unlockAfter(delay)
	return data

end

-- start of auto-generated methods --

function API:getChannel(channel_id)
	local endpoint = f(endpoints.CHANNEL, channel_id)
	return self:request("GET", endpoint)
end

function API:modifyChannel(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL, channel_id)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteChannel(channel_id)
	local endpoint = f(endpoints.CHANNEL, channel_id)
	return self:request("DELETE", endpoint)
end

function API:getChannelMessages(channel_id)
	local endpoint = f(endpoints.CHANNEL_MESSAGES, channel_id)
	return self:request("GET", endpoint)
end

function API:getChannelMessage(channel_id, message_id)
	local endpoint = f(endpoints.CHANNEL_MESSAGE, channel_id, message_id)
	return self:request("GET", endpoint)
end

function API:createMessage(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL_MESSAGES, channel_id)
	return self:request("POST", endpoint, payload)
end

function API:createReaction(channel_id, message_id, emoji, payload)
	local endpoint = f(endpoints.CHANNEL_MESSAGE_REACTION_ME, channel_id, message_id, emoji)
	return self:request("PUT", endpoint, payload)
end

function API:deleteOwnReaction(channel_id, message_id, emoji)
	local endpoint = f(endpoints.CHANNEL_MESSAGE_REACTION_ME, channel_id, message_id, emoji)
	return self:request("DELETE", endpoint)
end

function API:deleteUserReaction(channel_id, message_id, emoji, user_id)
	local endpoint = f(endpoints.CHANNEL_MESSAGE_REACTION_USER, channel_id, message_id, emoji, user_id)
	return self:request("DELETE", endpoint)
end

function API:getReactions(channel_id, message_id, emoji)
	local endpoint = f(endpoints.CHANNEL_MESSAGE_REACTION, channel_id, message_id, emoji)
	return self:request("GET", endpoint)
end

function API:deleteAllReactions(channel_id, message_id)
	local endpoint = f(endpoints.CHANNEL_MESSAGE_REACTIONS, channel_id, message_id)
	return self:request("DELETE", endpoint)
end

function API:editMessage(channel_id, message_id, payload)
	local endpoint = f(endpoints.CHANNEL_MESSAGE, channel_id, message_id)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteMessage(channel_id, message_id)
	local endpoint = f(endpoints.CHANNEL_MESSAGE, channel_id, message_id)
	return self:request("DELETE", endpoint)
end

function API:bulkDeleteMessages(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL_MESSAGES_BULK_DELETE, channel_id)
	return self:request("POST", endpoint, payload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload)
	local endpoint = f(endpoints.CHANNEL_PERMISSION, channel_id, overwrite_id)
	return self:request("PUT", endpoint, payload)
end

function API:getChannelInvites(channel_id)
	local endpoint = f(endpoints.CHANNEL_INVITES, channel_id)
	return self:request("GET", endpoint)
end

function API:createChannelInvite(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL_INVITES, channel_id)
	return self:request("POST", endpoint, payload)
end

function API:deleteChannelPermission(channel_id, overwrite_id)
	local endpoint = f(endpoints.CHANNEL_PERMISSION, channel_id, overwrite_id)
	return self:request("DELETE", endpoint)
end

function API:triggerTypingIndicator(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL_TYPING, channel_id)
	return self:request("POST", endpoint, payload)
end

function API:getPinnedMessages(channel_id)
	local endpoint = f(endpoints.CHANNEL_PINS, channel_id)
	return self:request("GET", endpoint)
end

function API:addPinnedChannelMessage(channel_id, message_id, payload)
	local endpoint = f(endpoints.CHANNEL_PIN, channel_id, message_id)
	return self:request("PUT", endpoint, payload)
end

function API:deletePinnedChannelMessage(channel_id, message_id)
	local endpoint = f(endpoints.CHANNEL_PIN, channel_id, message_id)
	return self:request("DELETE", endpoint)
end

function API:groupDMAddRecipient(channel_id, user_id, payload)
	local endpoint = f(endpoints.CHANNEL_RECIPIENT, channel_id, user_id)
	return self:request("PUT", endpoint, payload)
end

function API:groupDMRemoveRecipient(channel_id, user_id)
	local endpoint = f(endpoints.CHANNEL_RECIPIENT, channel_id, user_id)
	return self:request("DELETE", endpoint)
end

function API:createGuild(payload)
	local endpoint = endpoints.GUILDS
	return self:request("POST", endpoint, payload)
end

function API:getGuild(guild_id)
	local endpoint = f(endpoints.GUILD, guild_id)
	return self:request("GET", endpoint)
end

function API:modifyGuild(guild_id, payload)
	local endpoint = f(endpoints.GUILD, guild_id)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteGuild(guild_id)
	local endpoint = f(endpoints.GUILD, guild_id)
	return self:request("DELETE", endpoint)
end

function API:getGuildChannels(guild_id)
	local endpoint = f(endpoints.GUILD_CHANNELS, guild_id)
	return self:request("GET", endpoint)
end

function API:createGuildChannel(guild_id, payload)
	local endpoint = f(endpoints.GUILD_CHANNELS, guild_id)
	return self:request("POST", endpoint, payload)
end

function API:modifyGuildChannelPositions(guild_id, payload)
	local endpoint = f(endpoints.GUILD_CHANNELS, guild_id)
	return self:request("PATCH", endpoint, payload)
end

function API:getGuildMember(guild_id, user_id)
	local endpoint = f(endpoints.GUILD_MEMBER, guild_id, user_id)
	return self:request("GET", endpoint)
end

function API:listGuildMembers(guild_id)
	local endpoint = f(endpoints.GUILD_MEMBERS, guild_id)
	return self:request("GET", endpoint)
end

function API:addGuildMember(guild_id, user_id, payload)
	local endpoint = f(endpoints.GUILD_MEMBER, guild_id, user_id)
	return self:request("PUT", endpoint, payload)
end

function API:modifyGuildMember(guild_id, user_id, payload)
	local endpoint = f(endpoints.GUILD_MEMBER, guild_id, user_id)
	return self:request("PATCH", endpoint, payload)
end

function API:modifyCurrentUsersNick(guild_id, payload)
	local endpoint = f(endpoints.GUILD_MEMBER_ME_NICK, guild_id)
	return self:request("PATCH", endpoint, payload)
end

function API:addGuildMemberRole(guild_id, user_id, role_id, payload)
	local endpoint = f(endpoints.GUILD_MEMBER_ROLE, guild_id, user_id, role_id)
	return self:request("PUT", endpoint, payload)
end

function API:removeGuildMemberRole(guild_id, user_id, role_id)
	local endpoint = f(endpoints.GUILD_MEMBER_ROLE, guild_id, user_id, role_id)
	return self:request("DELETE", endpoint)
end

function API:removeGuildMember(guild_id, user_id)
	local endpoint = f(endpoints.GUILD_MEMBER, guild_id, user_id)
	return self:request("DELETE", endpoint)
end

function API:getGuildBans(guild_id)
	local endpoint = f(endpoints.GUILD_BANS, guild_id)
	return self:request("GET", endpoint)
end

function API:createGuildBan(guild_id, user_id, payload)
	local endpoint = f(endpoints.GUILD_BAN, guild_id, user_id)
	return self:request("PUT", endpoint, payload)
end

function API:removeGuildBan(guild_id, user_id)
	local endpoint = f(endpoints.GUILD_BAN, guild_id, user_id)
	return self:request("DELETE", endpoint)
end

function API:getGuildRoles(guild_id)
	local endpoint = f(endpoints.GUILD_ROLES, guild_id)
	return self:request("GET", endpoint)
end

function API:createGuildRole(guild_id, payload)
	local endpoint = f(endpoints.GUILD_ROLES, guild_id)
	return self:request("POST", endpoint, payload)
end

function API:modifyGuildRolePositions(guild_id, payload)
	local endpoint = f(endpoints.GUILD_ROLES, guild_id)
	return self:request("PATCH", endpoint, payload)
end

function API:modifyGuildRole(guild_id, role_id, payload)
	local endpoint = f(endpoints.GUILD_ROLE, guild_id, role_id)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteGuildRole(guild_id, role_id)
	local endpoint = f(endpoints.GUILD_ROLE, guild_id, role_id)
	return self:request("DELETE", endpoint)
end

function API:getGuildPruneCount(guild_id)
	local endpoint = f(endpoints.GUILD_PRUNE, guild_id)
	return self:request("GET", endpoint)
end

function API:beginGuildPrune(guild_id, payload)
	local endpoint = f(endpoints.GUILD_PRUNE, guild_id)
	return self:request("POST", endpoint, payload)
end

function API:getGuildVoiceRegions(guild_id)
	local endpoint = f(endpoints.GUILD_REGIONS, guild_id)
	return self:request("GET", endpoint)
end

function API:getGuildInvites(guild_id)
	local endpoint = f(endpoints.GUILD_INVITES, guild_id)
	return self:request("GET", endpoint)
end

function API:getGuildIntegrations(guild_id)
	local endpoint = f(endpoints.GUILD_INTEGRATIONS, guild_id)
	return self:request("GET", endpoint)
end

function API:createGuildIntegration(guild_id, payload)
	local endpoint = f(endpoints.GUILD_INTEGRATIONS, guild_id)
	return self:request("POST", endpoint, payload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload)
	local endpoint = f(endpoints.GUILD_INTEGRATION, guild_id, integration_id)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteGuildIntegration(guild_id, integration_id)
	local endpoint = f(endpoints.GUILD_INTEGRATION, guild_id, integration_id)
	return self:request("DELETE", endpoint)
end

function API:syncGuildIntegration(guild_id, integration_id, payload)
	local endpoint = f(endpoints.GUILD_INTEGRATION_SYNC, guild_id, integration_id)
	return self:request("POST", endpoint, payload)
end

function API:getGuildEmbed(guild_id)
	local endpoint = f(endpoints.GUILD_EMBED, guild_id)
	return self:request("GET", endpoint)
end

function API:modifyGuildEmbed(guild_id, payload)
	local endpoint = f(endpoints.GUILD_EMBED, guild_id)
	return self:request("PATCH", endpoint, payload)
end

function API:getInvite(invite_code)
	local endpoint = f(endpoints.INVITE, invite_code)
	return self:request("GET", endpoint)
end

function API:deleteInvite(invite_code)
	local endpoint = f(endpoints.INVITE, invite_code)
	return self:request("DELETE", endpoint)
end

function API:acceptInvite(invite_code, payload)
	local endpoint = f(endpoints.INVITE, invite_code)
	return self:request("POST", endpoint, payload)
end

function API:getCurrentUser()
	local endpoint = endpoints.USER_ME
	return self:request("GET", endpoint)
end

function API:getUser(user_id)
	local endpoint = f(endpoints.USER, user_id)
	return self:request("GET", endpoint)
end

function API:modifyCurrentUser(payload)
	local endpoint = endpoints.USER_ME
	return self:request("PATCH", endpoint, payload)
end

function API:getCurrentUserGuilds()
	local endpoint = endpoints.USER_ME_GUILDS
	return self:request("GET", endpoint)
end

function API:leaveGuild(guild_id)
	local endpoint = f(endpoints.USER_ME_GUILD, guild_id)
	return self:request("DELETE", endpoint)
end

function API:getUserDMs()
	local endpoint = endpoints.USER_ME_CHANNELS
	return self:request("GET", endpoint)
end

function API:createDM(payload)
	local endpoint = endpoints.USER_ME_CHANNELS
	return self:request("POST", endpoint, payload)
end

function API:createGroupDM(payload)
	local endpoint = endpoints.USER_ME_CHANNELS
	return self:request("POST", endpoint, payload)
end

function API:getUsersConnections()
	local endpoint = endpoints.USER_ME_CONNECTIONS
	return self:request("GET", endpoint)
end

function API:listVoiceRegions()
	local endpoint = endpoints.VOICE_REGIONS
	return self:request("GET", endpoint)
end

function API:createWebhook(channel_id, payload)
	local endpoint = f(endpoints.CHANNEL_WEBHOOKS, channel_id)
	return self:request("POST", endpoint, payload)
end

function API:getChannelWebhooks(channel_id)
	local endpoint = f(endpoints.CHANNEL_WEBHOOKS, channel_id)
	return self:request("GET", endpoint)
end

function API:getGuildWebhooks(guild_id)
	local endpoint = f(endpoints.GUILD_WEBHOOKS, guild_id)
	return self:request("GET", endpoint)
end

function API:getWebhook(webhook_id)
	local endpoint = f(endpoints.WEBHOOK, webhook_id)
	return self:request("GET", endpoint)
end

function API:getWebhookWithToken(webhook_id, webhook_token)
	local endpoint = f(endpoints.WEBHOOK_TOKEN, webhook_id, webhook_token)
	return self:request("GET", endpoint)
end

function API:modifyWebhook(webhook_id, payload)
	local endpoint = f(endpoints.WEBHOOK, webhook_id)
	return self:request("PATCH", endpoint, payload)
end

function API:modifyWebhookWithToken(webhook_id, webhook_token, payload)
	local endpoint = f(endpoints.WEBHOOK_TOKEN, webhook_id, webhook_token)
	return self:request("PATCH", endpoint, payload)
end

function API:deleteWebhook(webhook_id)
	local endpoint = f(endpoints.WEBHOOK, webhook_id)
	return self:request("DELETE", endpoint)
end

function API:deleteWebhookWithToken(webhook_id, webhook_token)
	local endpoint = f(endpoints.WEBHOOK_TOKEN, webhook_id, webhook_token)
	return self:request("DELETE", endpoint)
end

function API:executeWebhook(webhook_id, webhook_token, payload)
	local endpoint = f(endpoints.WEBHOOK_TOKEN, webhook_id, webhook_token)
	return self:request("POST", endpoint, payload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload)
	local endpoint = f(endpoints.WEBHOOK_TOKEN_SLACK, webhook_id, webhook_token)
	return self:request("POST", endpoint, payload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload)
	local endpoint = f(endpoints.WEBHOOK_TOKEN_GITHUB, webhook_id, webhook_token)
	return self:request("POST", endpoint, payload)
end

function API:getGateway()
	local endpoint = endpoints.GATEWAY
	return self:request("GET", endpoint)
end

function API:getGatewayBot()
	local endpoint = endpoints.GATEWAY_BOT
	return self:request("GET", endpoint)
end

function API:getCurrentApplicationInformation()
	local endpoint = endpoints.OAUTH2_APPLICATION_ME
	return self:request("GET", endpoint)
end

-- end of auto-generated methods --

return API
