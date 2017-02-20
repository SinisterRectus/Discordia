local json = require('json')
local timer = require('timer')
local http = require('coro-http')
local package = require('../package')
local Mutex = require('../utils/Mutex')

local format = string.format
local request = http.request
local setTimeout = timer.setTimeout
local max, random = math.max, math.random
local encode, decode = json.encode, json.decode
local insert, concat = table.insert, table.concat
local date, time, difftime = os.date, os.time, os.difftime

local months = {
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

local function parseDate(str)
	local _, day, month, year, hour, min, sec = str:match(
		'(%a-), (%d-) (%a-) (%d-) (%d-):(%d-):(%d-) GMT'
	)
	local serverDate = {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec,
	}
	local clientDate = date('!*t')
	clientDate.isdst = date('*t').isdst
	return difftime(time(serverDate), time(clientDate)) + time()
end

local function attachQuery(endpoint, query)
	if not query or not next(query) then return endpoint end
	local buffer = {}
	for k, v in pairs(query) do
		insert(buffer, format('%s=%s', k, v))
	end
	return format('%s?%s', endpoint, concat(buffer, '&'))
end

local boundary = 'Discordia' .. time()
local multipart = format('multipart/form-data;boundary=%s', boundary)

local function attachFile(payload, file)
	return concat {
		'\r\n--', boundary,
		'\r\nContent-Disposition:form-data;name="file";', format('filename=%q', file[1]),
		'\r\nContent-Type:application/octet-stream',
		'\r\n\r\n', file[2],
		'\r\n--', boundary,
		'\r\nContent-Disposition:form-data;name="payload_json"',
		'\r\nContent-Type:application/json',
		'\r\n\r\n', payload,
		'\r\n--', boundary, '--',
	}
end

local API = class('API')

function API:__init(client)
	self._client = client
	self._route_delay = client._options.routeDelay
	self._global_delay = client._options.globalDelay
	self._global_mutex = Mutex()
	self._route_mutexes = {}
	self._user_agent = format('DiscordBot (%s, %s)', package.homepage, package.version)
end

function API:checkToken(token)
	local res = request('GET', "https://discordapp.com/api/users/@me", {
		{'Authorization', token},
		{'User-Agent', self._user_agent},
	})
	return res.code == 200
end

function API:setToken(token)
	self._token = token
end

function API:request(method, route, endpoint, payload, file)

	local url = "https://discordapp.com/api" .. endpoint

	local reqHeaders = {
		{'Authorization', self._token},
		{'User-Agent', self._user_agent},
	}

	if method:find('P') then
		payload = payload and encode(payload) or '{}'
		if file then
			payload = attachFile(payload, file)
			insert(reqHeaders, {'Content-Type', multipart})
		else
			insert(reqHeaders, {'Content-Type', 'application/json'})
		end
		insert(reqHeaders, {'Content-Length', #payload})
	end

	local routeMutex = self._route_mutexes[route] or Mutex()
	self._route_mutexes[route] = routeMutex

	return self:commit(method, url, reqHeaders, payload, routeMutex, 1)

end

function API:commit(method, url, reqHeaders, payload, routeMutex, attempts)

	local isRetry = attempts > 1
	local routeDelay = self._route_delay
	local globalDelay = self._global_delay
	local globalMutex = self._global_mutex

	routeMutex:lock(isRetry)
	if self._globally_limited or globalMutex._active then
		globalMutex:lock(isRetry)
	end

	local res, str = request(method, url, reqHeaders, payload)

	local resHeaders = {}
	for i, v in ipairs(res) do
		resHeaders[v[1]] = v[2]
		res[i] = nil
	end

	local reset = resHeaders['X-RateLimit-Reset']
	local remaining = resHeaders['X-RateLimit-Remaining']

	if reset and remaining == '0' then
		local dt = difftime(reset, parseDate(resHeaders['Date']))
		routeDelay = max(1000 * dt, routeDelay)
	end

	local success, data = res.code < 300, decode(str)
	local shouldRetry = false

	if not success then
		self._client:warning(format('%i / %s / %s\n%s %s', res.code, res.reason, data.message, method, url))
		if res.code == 429 then
			if data.global then
				if not self._globally_limited then
					if not globalMutex._active then
						globalMutex:lock(isRetry)
					end
					self._globally_limited = true
					setTimeout(data.retry_after, function()
						self._globally_limited = false
					end)
				end
				globalDelay = data.retry_after
			end
			routeDelay = data.retry_after
			shouldRetry = attempts < 6
		elseif res.code == 502 then
			routeDelay = routeDelay + random(2000)
			shouldRetry = attempts < 6
		end
	end

	routeMutex:unlockAfter(routeDelay)
	if globalMutex._active then
		globalMutex:unlockAfter(globalDelay)
	end

	if shouldRetry then
		return self:commit(method, url, reqHeaders, payload, routeMutex, attempts + 1)
	end

	return success, data

end

-- endpoint methods auto-generated from Discord documentation --

function API:getChannel(channel_id) -- Client:getPrivateChannel fallback
	local route = format("/channels/%s", channel_id)
	return self:request("GET", route, route)
end

function API:modifyChannel(channel_id, payload) -- various channel methods
	local route = format("/channels/%s", channel_id)
	return self:request("PATCH", route, route, payload)
end

function API:deleteChannel(channel_id) -- Channel:delete
	local route = format("/channels/%s", channel_id)
	return self:request("DELETE", route, route)
end

function API:getChannelMessages(channel_id, query) -- TextChannel:getMessageHistory[Before|After|Around]
	local route = format("/channels/%s/messages", channel_id)
	return self:request("GET", route, attachQuery(route, query))
end

function API:getChannelMessage(channel_id, message_id) -- TextChannel:getMessage fallback
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("GET", route, format(route, message_id))
end

function API:createMessage(channel_id, payload, file) -- TextChannel:sendMessage
	local route = format("/channels/%s/messages", channel_id)
	return self:request("POST", route, route, payload, file)
end

function API:createReaction(channel_id, message_id, emoji) -- Message:addReaction
    local route = format("/channels/%s/messages/%%s/reactions/%%s/@me", channel_id)
    return self:request("PUT", route, format(route, message_id, emoji))
end

function API:deleteOwnReaction(channel_id, message_id, emoji) -- Message:removeReaction
    local route = format("/channels/%s/messages/%%s/reactions/%%s/@me", channel_id)
    return self:request("DELETE", route, format(route, message_id, emoji))
end

function API:deleteUserReaction(channel_id, message_id, emoji, user_id) -- Message:removeReaction
    local route = format("/channels/%s/messages/%%s/reactions/%%s/%%s", channel_id)
    return self:request("DELETE", route, format(route, message_id, emoji, user_id))
end

function API:getReactions(channel_id, message_id, emoji) -- Message:getReactionUsers
    local route = format("/channels/%s/messages/%%s/reactions/%%s", channel_id)
    return self:request("GET", route, format(route, message_id, emoji))
end

function API:deleteAllReactions(channel_id, message_id) -- Message:clearReactions
    local route = format("/channels/%s/messages/%%s/reactions", channel_id)
    return self:request("DELETE", route, format(route, message_id))
end

function API:editMessage(channel_id, message_id, payload) -- Message:setContent
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("PATCH", route, format(route, message_id), payload)
end

function API:deleteMessage(channel_id, message_id) -- Message:delete
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("DELETE", "DELETE" .. route, format(route, message_id)) -- special case
end

function API:bulkDeleteMessages(channel_id, payload) -- TextChannel:bulkDelete[Before|After|Around]
	local route = format("/channels/%s/messages/bulk-delete", channel_id)
	return self:request("POST", route, route, payload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload) -- various overwrite methods
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("PUT", route, format(route, overwrite_id), payload)
end

function API:getChannelInvites(channel_id) -- GuildChannel:getInvites
	local route = format("/channels/%s/invites", channel_id)
	return self:request("GET", route, route)
end

function API:createChannelInvite(channel_id, payload) -- GuildChannel:createInvite
	local route = format("/channels/%s/invites", channel_id)
	return self:request("POST", route, route, payload)
end

function API:deleteChannelPermission(channel_id, overwrite_id) -- PermissionOverwrite:delete
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("DELETE", route, format(route, overwrite_id))
end

function API:triggerTypingIndicator(channel_id, payload) -- TextChannel:broadcastTyping
	local route = format("/channels/%s/typing", channel_id)
	return self:request("POST", route, route, payload)
end

function API:getPinnedMessages(channel_id) -- TextChannel:getPinnedMessages
	local route = format("/channels/%s/pins", channel_id)
	return self:request("GET", route, route)
end

function API:addPinnedChannelMessage(channel_id, message_id, payload) -- Message:pin
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("PUT", route, format(route, message_id), payload)
end

function API:deletePinnedChannelMessage(channel_id, message_id) -- Message:unpin
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("DELETE", route, format(route, message_id))
end

function API:groupDMAddRecipient(channel_id, user_id, payload) -- not exposed, maybe in the future
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("PUT", route, format(route, user_id), payload)
end

function API:groupDMRemoveRecipient(channel_id, user_id) -- not exposed, maybe in the future
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:createGuild(payload) -- Client:createGuild
	local route = "/guilds"
	return self:request("POST", route, route, payload)
end

function API:getGuild(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s", guild_id)
	return self:request("GET", route, route)
end

function API:modifyGuild(guild_id, payload) -- various guild methods
	local route = format("/guilds/%s", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:deleteGuild(guild_id) -- Guild:delete
	local route = format("/guilds/%s", guild_id)
	return self:request("DELETE", route, route)
end

function API:getGuildChannels(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildChannel(guild_id, payload) -- Guild:create[Text|Voice]Channel
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildChannelPositions(guild_id, payload) -- TODO
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:getGuildMember(guild_id, user_id) -- Guild:getMember fallback
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("GET", route, format(route, user_id))
end

function API:listGuildMembers(guild_id) -- not exposed, use cache or Guild:_requestMembers
	local route = format("/guilds/%s/members", guild_id)
	return self:request("GET", route, route)
end

function API:addGuildMember(guild_id, user_id, payload) -- not exposed, maybe in the future
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PUT", route, format(route, user_id), payload)
end

function API:modifyGuildMember(guild_id, user_id, payload) -- various member methods
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PATCH", route, format(route, user_id), payload)
end

function API:addGuildMemberRole(guild_id, user_id, role_id) -- Member:addRole
	local route =  format("/guilds/%s/members/%%s/roles/%%s", guild_id)
	return self:request("PUT", route, format(route, user_id, role_id))
end

function API:deleteGuildMemberRole(guild_id, user_id, role_id) -- Member:removeRole
	local route =  format("/guilds/%s/members/%%s/roles/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id, role_id))
end

function API:removeGuildMember(guild_id, user_id) -- Guild:kickUser, User:kick, Member:kick
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:getGuildBans(guild_id) -- Guild:getBans
	local route = format("/guilds/%s/bans", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildBan(guild_id, user_id, payload, query) -- Guild:banUser, User:ban, Member:ban
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("PUT", route, attachQuery(format(route, user_id), query), payload)
end

function API:removeGuildBan(guild_id, user_id) -- Guild:unbanUser, User:unban, Member:unban
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("DELETE", route, format(route, user_id))
end

function API:getGuildRoles(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildRole(guild_id, payload) -- Guild:createRole
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildRolePositions(guild_id, payload) -- TODO
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:modifyGuildRole(guild_id, role_id, payload) -- various role methods
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("PATCH", route, format(route, role_id), payload)
end

function API:deleteGuildRole(guild_id, role_id) -- Role:delete
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("DELETE", route, format(route, role_id))
end

function API:getGuildPruneCount(guild_id, query) -- Guild:getPruneCount
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("GET", route, attachQuery(route, query))
end

function API:beginGuildPrune(guild_id, payload) -- Guild:pruneMembers
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("POST", route, route, payload)
end

function API:getGuildVoiceRegions(guild_id) -- Guild:listVoiceRegions
	local route = format("/guilds/%s/regions", guild_id)
	return self:request("GET", route, route)
end

function API:getGuildInvites(guild_id) -- Guild:getInvites
	local route = format("/guilds/%s/invites", guild_id)
	return self:request("GET", route, route)
end

function API:getGuildIntegrations(guild_id) -- not exposed, maybe in the future
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("GET", route, route)
end

function API:createGuildIntegration(guild_id, payload) -- not exposed, maybe in the future
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("POST", route, route, payload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload) -- not exposed, maybe in the future
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("PATCH", route, format(route, integration_id), payload)
end

function API:deleteGuildIntegration(guild_id, integration_id) -- not exposed, maybe in the future
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("DELETE", route, format(route, integration_id))
end

function API:syncGuildIntegration(guild_id, integration_id, payload) -- not exposed, maybe in the future
	local route = format("/guilds/%s/integrations/%%s/sync", guild_id)
	return self:request("POST", route, format(route, integration_id), payload)
end

function API:getGuildEmbed(guild_id) -- not exposed, maybe in the future
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("GET", route, route)
end

function API:modifyGuildEmbed(guild_id, payload) -- not exposed, maybe in the future
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("PATCH", route, route, payload)
end

function API:getInvite(invite_code) -- Client:getInvite
	local route = "/invites/%s"
	return self:request("GET", route, format(route, invite_code))
end

function API:deleteInvite(invite_code) -- Invite:delete
	local route = "/invites/%s"
	return self:request("DELETE", route, format(route, invite_code))
end

function API:acceptInvite(invite_code, payload) -- Invite:accept, Client:acceptInvite
	local route = "/invites/%s"
	return self:request("POST", route, format(route, invite_code), payload)
end

function API:getCurrentUser() -- not exposed, use cache (Client.user)
	local route = "/users/@me"
	return self:request("GET", route, route)
end

function API:getUser(user_id) -- Client:getUser fallback
	local route = "/users/%s"
	return self:request("GET", route, format(route, user_id))
end

function API:modifyCurrentUser(payload) -- various client methods
	local route = "/users/@me"
	return self:request("PATCH", route, route, payload)
end

function API:getCurrentUserGuilds() -- not exposed, use cache
	local route = "/users/@me/guilds"
	return self:request("GET", route, route)
end

function API:leaveGuild(guild_id) -- Guild:leave
	local route = "/users/@me/guilds/%s"
	return self:request("DELETE", route, format(route, guild_id))
end

function API:getUserDMs() -- not exposed, use cache
	local route = "/users/@me/channels"
	return self:request("GET", route, route)
end

function API:createDM(payload) -- User:sendMessage
	local route = "/users/@me/channels"
	return self:request("POST", route, route, payload)
end

function API:createGroupDM(payload) -- not exposed, maybe in the future
	local route = "/users/@me/channels"
	return self:request("POST", route, route, payload)
end

function API:getUsersConnections() -- not exposed, maybe in the future
	local route = "/users/@me/connections"
	return self:request("GET", route, route)
end

function API:listVoiceRegions() -- Client:listVoiceRegions
	local route = "/voice/regions"
	return self:request("GET", route, route)
end

function API:createWebhook(channel_id, payload) -- not exposed, maybe in the future
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("POST", route, route, payload)
end

function API:getChannelWebhooks(channel_id) -- not exposed, maybe in the future
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("GET", route, route)
end

function API:getGuildWebhooks(guild_id) -- not exposed, maybe in the future
	local route = format("/guilds/%s/webhooks", guild_id)
	return self:request("GET", route, route)
end

function API:getWebhook(webhook_id) -- not exposed, maybe in the future
	local route = "/webhooks/%s"
	return self:request("GET", route, format(route, webhook_id))
end

function API:getWebhookwithToken(webhook_id, webhook_token) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s"
	return self:request("GET", route, format(route, webhook_id, webhook_token))
end

function API:modifyWebhook(webhook_id, payload) -- not exposed, maybe in the future
	local route = "/webhooks/%s"
	return self:request("PATCH", route, format(route, webhook_id), payload)
end

function API:modifyWebhookwithToken(webhook_id, webhook_token, payload) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s"
	return self:request("PATCH", route, format(route, webhook_id, webhook_token), payload)
end

function API:deleteWebhook(webhook_id) -- not exposed, maybe in the future
	local route = "/webhooks/%s"
	return self:request("DELETE", route, format(route, webhook_id))
end

function API:deleteWebhookwithToken(webhook_id, webhook_token) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s"
	return self:request("DELETE", route, format(route, webhook_id, webhook_token))
end

function API:executeWebhook(webhook_id, webhook_token, payload) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s/slack"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload) -- not exposed, maybe in the future
	local route = "/webhooks/%s/%s/github"
	return self:request("POST", route, format(route, webhook_id, webhook_token), payload)
end

function API:getGateway(isBot) -- Client:_connectToGateway
	local route = isBot and "/gateway/bot" or "/gateway"
	return self:request("GET", route, route)
end

function API:getCurrentApplicationInformation() -- client.owner property
	local route = "/oauth2/applications/@me"
	return self:request("GET", route, route)
end

-- end of auto-generated methods --

function API:getToken(payload) -- Client:run (not recommended)
	local route = "/auth/login"
	return self:request('POST', route, route, payload)
end

function API:modifyCurrentUserNickname(guild_id, payload) -- Client:setNickname
	local route = format("/guilds/%s/members/@me/nick", guild_id)
	return self:request('PATCH', route, route, payload)
end

return API
