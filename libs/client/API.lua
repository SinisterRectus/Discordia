local json = require('json')
local http = require('coro-http')
local package = require('../../package.lua')
local Mutex = require('utils/Mutex')
local constants = require('constants')

local request = http.request
local format = string.format
local max, random = math.max, math.random
local encode, decode = json.encode, json.decode
local insert, concat = table.insert, table.concat
local date, time, difftime = os.date, os.time, os.difftime

local BASE_URL = constants.BASE_URL

local months = {
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

local function parseDate(str)
	local day, month, year, hour, min, sec = str:match(
		'%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT'
	)
	local serverDate = {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec,
	}
	local clientDate = date('!*t')
	clientDate.isdst = date('*t').isdst
	return difftime(time(serverDate), time(clientDate)) + time()
end

local function parseErrors(ret, errors, key)
	for k, v in pairs(errors) do
		if k == '_errors' then
			for _, err in ipairs(v) do
				insert(ret, format('%s in %s : %s', err.code, key or 'payload', err.message))
			end
		else
			if key then
				parseErrors(ret, v, format(k:find("^[%a_][%a%d_]*$") and '%s.%s' or '%s[%q]', key, k))
			else
				parseErrors(ret, v, k)
			end
		end
	end
	return concat(ret, '\n\t')
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
		{'User-Agent', format('DiscordBot (%s, %s)', package.homepage, package.version)},
	}
	-- return self:getCurrentUser()
	return {id = '1234', bot = token:find('Bot')} -- TODO: remove debug
end

function API:request(method, route, endpoint, payload)

	local url = BASE_URL .. endpoint

	local req

	-- if method:find('P') == 1 then
	if payload then -- TODO: test with all endpoints (some don't use payloads?)
		-- payload = payload and encode(payload) or '{}'
		payload = encode(payload)
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

	client:debug('HTTP : %i - %s : %s %s', res.code, res.reason, method, url)

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

	local data = decode(msg) or msg

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
				msg = format('HTTP Error %i : %s', data.code, data.message)
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

	mutex:unlockAfter(delay)
	return data

end

-- start of auto-generated methods --

function API:getChannel(channel_id)
	local route = format("/channels/%s", channel_id)
	return self:request("GET", route, route)
end

function API:modifyChannel(channel_id, payload)
	local route = format("/channels/%s", channel_id)
	return self:request("PUT/PATCH", route, route, payload)
end

function API:deleteChannel(channel_id)
	local route = format("/channels/%s", channel_id)
	return self:request("DELETE", route, route)
end

function API:getChannelMessages(channel_id)
	local route = format("/channels/%s/messages", channel_id)
	return self:request("GET", route, route)
end

function API:getChannelMessage(channel_id, message_id)
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("GET", route, format(route, message_id))
end

function API:createMessage(channel_id, payload)
	local route = format("/channels/%s/messages", channel_id)
	return self:request("POST", route, route, payload)
end

function API:createReaction(channel_id, message_id, emoji, payload)
	local route = format("/channels/%s/messages/%%s/reactions/%%s/@me", channel_id)
	return self:request("PUT", route, format(route, message_id, emoji), payload)
end

function API:deleteOwnReaction(channel_id, message_id, emoji)
	local route = format("/channels/%s/messages/%%s/reactions/%%s/@me", channel_id)
	return self:request("DELETE", route, format(route, message_id, emoji))
end

function API:deleteUserReaction(channel_id, message_id, emoji, user_id)
	local route = format("/channels/%s/messages/%%s/reactions/%%s/%%s", channel_id)
	return self:request("DELETE", route, format(route, message_id, emoji, user_id))
end

function API:getReactions(channel_id, message_id, emoji)
	local route = format("/channels/%s/messages/%%s/reactions/%%s", channel_id)
	return self:request("GET", route, format(route, message_id, emoji))
end

function API:deleteAllReactions(channel_id, message_id)
	local route = format("/channels/%s/messages/%%s/reactions", channel_id)
	return self:request("DELETE", route, format(route, message_id))
end

function API:editMessage(channel_id, message_id, payload)
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("PATCH", route, format(route, message_id), payload)
end

function API:deleteMessage(channel_id, message_id)
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("DELETE", route, format(route, message_id))
end

function API:bulkDeleteMessages(channel_id, payload)
	local route = format("/channels/%s/messages/bulk-delete", channel_id)
	return self:request("POST", route, route, payload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload)
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("PUT", route, format(route, overwrite_id), payload)
end

function API:getChannelInvites(channel_id)
	local route = format("/channels/%s/invites", channel_id)
	return self:request("GET", route, route)
end

function API:createChannelInvite(channel_id, payload)
	local route = format("/channels/%s/invites", channel_id)
	return self:request("POST", route, route, payload)
end

function API:deleteChannelPermission(channel_id, overwrite_id)
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("DELETE", route, format(route, overwrite_id))
end

function API:triggerTypingIndicator(channel_id, payload)
	local route = format("/channels/%s/typing", channel_id)
	return self:request("POST", route, route, payload)
end

function API:getPinnedMessages(channel_id)
	local route = format("/channels/%s/pins", channel_id)
	return self:request("GET", route, route)
end

function API:addPinnedChannelMessage(channel_id, message_id, payload)
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("PUT", route, format(route, message_id), payload)
end

function API:deletePinnedChannelMessage(channel_id, message_id)
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("DELETE", route, format(route, message_id))
end

function API:groupDMAddRecipient(channel_id, user_id, payload)
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("PUT", route, format(route, user_id), payload)
end

function API:groupDMRemoveRecipient(channel_id, user_id)
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:createGuild(payload)
	local route = "/guilds"
	return self:request("POST", route, route, payload)
end

function API:getGuild(guild_id)
	local route = format("/guilds/%s", guild_id)
	return self:request("GET", route, route)
end

function API:modifyGuild(guild_id, payload)
	local route = format("/guilds/%s", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:deleteGuild(guild_id)
	local route = format("/guilds/%s", guild_id)
	return self:request("DELETE", route, route)
end

function API:getGuildChannels(guild_id)
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildChannel(guild_id, payload)
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildChannelPositions(guild_id, payload)
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:getGuildMember(guild_id, user_id)
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("GET", route, format(route, user_id))
end

function API:listGuildMembers(guild_id)
	local route = format("/guilds/%s/members", guild_id)
	return self:request("GET", route, route)
end

function API:addGuildMember(guild_id, user_id, payload)
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PUT", route, format(route, user_id), payload)
end

function API:modifyGuildMember(guild_id, user_id, payload)
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PATCH", route, format(route, user_id), payload)
end

function API:modifyCurrentUsersNick(guild_id, payload)
	local route = format("/guilds/%s/members/@me/nick", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:addGuildMemberRole(guild_id, user_id, role_id, payload)
	local route = format("/guilds/%s/members/%%s/roles/%%s", guild_id)
	return self:request("PUT", route, format(route, user_id, role_id), payload)
end

function API:removeGuildMemberRole(guild_id, user_id, role_id)
	local route = format("/guilds/%s/members/%%s/roles/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id, role_id))
end

function API:removeGuildMember(guild_id, user_id)
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:getGuildBans(guild_id)
	local route = format("/guilds/%s/bans", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildBan(guild_id, user_id, payload)
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("PUT", route, format(route, user_id), payload)
end

function API:removeGuildBan(guild_id, user_id)
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:getGuildRoles(guild_id)
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildRole(guild_id, payload)
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildRolePositions(guild_id, payload)
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:modifyGuildRole(guild_id, role_id, payload)
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("PATCH", route, format(route, role_id), payload)
end

function API:deleteGuildRole(guild_id, role_id)
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("DELETE", route, format(route, role_id))
end

function API:getGuildPruneCount(guild_id)
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("GET", route, route)
end

function API:beginGuildPrune(guild_id, payload)
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("POST", route, route, payload)
end

function API:getGuildVoiceRegions(guild_id)
	local route = format("/guilds/%s/regions", guild_id)
	return self:request("GET", route, route)
end

function API:getGuildInvites(guild_id)
	local route = format("/guilds/%s/invites", guild_id)
	return self:request("GET", route, route)
end

function API:getGuildIntegrations(guild_id)
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildIntegration(guild_id, payload)
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload)
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("PATCH", route, format(route, integration_id), payload)
end

function API:deleteGuildIntegration(guild_id, integration_id)
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("DELETE", route, format(route, integration_id))
end

function API:syncGuildIntegration(guild_id, integration_id, payload)
	local route = format("/guilds/%s/integrations/%%s/sync", guild_id)
	return self:request("POST", route, format(route, integration_id), payload)
end

function API:getGuildEmbed(guild_id)
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("GET", route, route)
end

function API:modifyGuildEmbed(guild_id, payload)
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:getInvite(invite_code)
	local route = "/invites/%s"
	return self:request("GET", route, format(route, invite_code))
end

function API:deleteInvite(invite_code)
	local route = "/invites/%s"
	return self:request("DELETE", route, format(route, invite_code))
end

function API:acceptInvite(invite_code, payload)
	local route = "/invites/%s"
	return self:request("POST", route, format(route, invite_code), payload)
end

function API:getCurrentUser() -- API:authenticate
	local route = "/users/@me"
	return self:request("GET", route, route)
end

function API:getUser(user_id) --  Client:getUser
	local route = "/users/%s"
	return self:request("GET", route, format(route, user_id))
end

function API:modifyCurrentUser(payload)
	local route = "/users/@me"
	return self:request("PATCH", route, route, payload)
end

function API:getCurrentUserGuilds()
	local route = "/users/@me/guilds"
	return self:request("GET", route, route)
end

function API:leaveGuild(guild_id)
	local route = format("/users/@me/guilds/%s", guild_id)
	return self:request("DELETE", route, route)
end

function API:getUserDMs()
	local route = "/users/@me/channels"
	return self:request("GET", route, route)
end

function API:createDM(payload)
	local route = "/users/@me/channels"
	return self:request("POST", route, route, payload)
end

function API:createGroupDM(payload)
	local route = "/users/@me/channels"
	return self:request("POST", route, route, payload)
end

function API:getUsersConnections()
	local route = "/users/@me/connections"
	return self:request("GET", route, route)
end

function API:listVoiceRegions()
	local route = "/voice/regions"
	return self:request("GET", route, route)
end

function API:createWebhook(channel_id, payload)
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("POST", route, route, payload)
end

function API:getChannelWebhooks(channel_id)
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("GET", route, route)
end

function API:getGuildWebhooks(guild_id)
	local route = format("/guilds/%s/webhooks", guild_id)
	return self:request("GET", route, route)
end

function API:getWebhook(webhook_id)
	local route = "/webhooks/%s"
	return self:request("GET", route, format(route, webhook_id))
end

function API:getWebhookWithToken(webhook_id, webhook_token)
	local route = "/webhooks/%s/%s"
	return self:request("GET", route, format(route, webhook_id, webhook_token))
end

function API:modifyWebhook(webhook_id, payload)
	local route = "/webhooks/%s"
	return self:request("PATCH", route, format(route, webhook_id), payload)
end

function API:modifyWebhookWithToken(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s"
	return self:request("PATCH", route, format(route, webhook_id, webhook_token), payload)
end

function API:deleteWebhook(webhook_id)
	local route = "/webhooks/%s"
	return self:request("DELETE", route, format(route, webhook_id))
end

function API:deleteWebhookWithToken(webhook_id, webhook_token)
	local route = "/webhooks/%s/%s"
	return self:request("DELETE", route, format(route, webhook_id, webhook_token))
end

function API:executeWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s/slack"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s/github"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:getGateway() -- Client:run
	local route = "/gateway"
	return self:request("GET", route, route)
end

function API:getGatewayBot() -- Client:run
	local route = "/gateway/bot"
	return self:request("GET", route, route)
end

function API:getCurrentApplicationInformation()
	local route = "/oauth2/applications/@me"
	return self:request("GET", route, route)
end

-- end of auto-generated methods --

return API
