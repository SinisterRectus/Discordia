local json = require('json')
local http = require('coro-http')
local package = require('../package')
local RateLimiter = require('../utils/RateLimiter')

local format = string.format
local request = http.request
local insert, concat = table.insert, table.concat
local encode, decode = json.encode, json.decode

local function url(route, ...)
	return "https://discordapp.com/api" .. format(route, ...)
end

local function attachQuery(url, query)
	if not query or not next(query) then return url end
	local buffer = {}
	for k, v in pairs(query) do
		insert(buffer, format('%s=%s', k, v))
	end
	return format('%s?%s', url, concat(buffer, '&'))
end

local API = class('API')

function API:__init(client)
	self.client = client
	self.limiters = {}
	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = format('DiscordBot (%s, %s)', package.homepage, package.version),
	}
end

function API:setToken(token)
	self.headers['Authorization'] = token
end

function API:request(method, route, url, payload)

	local headers = {}
	for k, v in pairs(self.headers) do
		insert(headers, {k, v})
	end

	if method:find('P') then
		payload = payload and encode(payload) or '{}'
		insert(headers, {'Content-Length', #payload})
	end

	local limiter = self.limiters[route] or RateLimiter()
	self.limiters[route] = limiter -- what about global RLs?

	limiter:open()
	local res, data = request(method, url, headers, payload)
	limiter:close(res)

	local success, data = res.code < 300, decode(data)
	if not success then p(res, data) end -- debug
	return success, data

end

-- endpoint methods auto-generated from Discord documentation --

function API:getChannel(channel_id) -- not exposed, use cache
	local route = format("/channels/%s", channel_id)
	return self:request("GET", route, url(route))
end

function API:modifyChannel(channel_id, payload) -- various channel methods
	local route = format("/channels/%s", channel_id)
	return self:request("PATCH", route, url(route), payload)
end

function API:deleteChannel(channel_id) -- Channel:delete
	local route = format("/channels/%s", channel_id)
	return self:request("DELETE", route, url(route))
end

function API:getChannelMessages(channel_id, query) -- TextChannel:getMessageHistory[Before|After|Around]
	local route = format("/channels/%s/messages", channel_id)
	return self:request("GET", route, attachQuery(url(route), query))
end

function API:getChannelMessage(channel_id, message_id) -- not exposed, maybe in the future
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("GET", route, url(route, message_id))
end

function API:createMessage(channel_id, payload) -- TextChannel:[create|send]Message
	local route = format("/channels/%s/messages", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:uploadFile(channel_id, payload) -- TODO
	local route = format("/channels/%s/messages", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:editMessage(channel_id, message_id, payload) -- Message:setContent
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("PATCH", route, url(route, message_id), payload)
end

function API:deleteMessage(channel_id, message_id) -- Message:delete
	local route = format("/channels/%s/messages/%%s", channel_id)
	return self:request("DELETE", route, url(route, message_id))
end

function API:bulkDeleteMessages(channel_id, payload) -- TextChannel:bulkDelete
	local route = format("/channels/%s/messages/bulk-delete", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload) -- TODO
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("PUT", route, url(route, overwrite_id), payload)
end

function API:getChannelInvites(channel_id) -- GuildChannel:getInvites
	local route = format("/channels/%s/invites", channel_id)
	return self:request("GET", route, url(route))
end

function API:createChannelInvite(channel_id, payload) -- GuildChannel:createInvite
	local route = format("/channels/%s/invites", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:deleteChannelPermission(channel_id, overwrite_id) -- TODO
	local route = format("/channels/%s/permissions/%%s", channel_id)
	return self:request("DELETE", route, url(route, overwrite_id))
end

function API:triggerTypingIndicator(channel_id, payload) -- TextChannel:broadcastTyping
	local route = format("/channels/%s/typing", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:getPinnedMessages(channel_id) -- TextChannel:getPinnedMessages
	local route = format("/channels/%s/pins", channel_id)
	return self:request("GET", route, url(route))
end

function API:addPinnedChannelMessage(channel_id, message_id, payload) -- Message:pin
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("PUT", route, url(route, message_id), payload)
end

function API:deletePinnedChannelMessage(channel_id, message_id) -- Message:unpin
	local route = format("/channels/%s/pins/%%s", channel_id)
	return self:request("DELETE", route, url(route, message_id))
end

function API:groupDMAddRecipient(channel_id, user_id, payload) -- TODO
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("PUT", route, url(route, user_id), payload)
end

function API:groupDMRemoveRecipient(channel_id, user_id) -- TODO
	local route = format("/channels/%s/recipients/%%s", channel_id)
	return self:request("DELETE", route, url(route, user_id))
end

function API:createGuild(payload) -- TODO
	local route = "/guilds"
	return self:request("POST", route, url(route), payload)
end

function API:getGuild(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s", guild_id)
	return self:request("GET", route, url(route))
end

function API:modifyGuild(guild_id, payload) -- various guild methods
	local route = format("/guilds/%s", guild_id)
	return self:request("PATCH", route, url(route), payload)
end

function API:deleteGuild(guild_id) -- Guild:delete
	local route = format("/guilds/%s", guild_id)
	return self:request("DELETE", route, url(route))
end

function API:getGuildChannels(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("GET", route, url(route))
end

function API:createGuildChannel(guild_id, payload) -- Guild:create[Text|Voice]Channel
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("POST", route, url(route), payload)
end

function API:modifyGuildChannelPosition(guild_id, payload) -- not exposed, see modifyChannel
	local route = format("/guilds/%s/channels", guild_id)
	return self:request("PATCH", route, url(route), payload)
end

function API:getGuildMember(guild_id, user_id) -- not exposed, use cache or Guild:requestMembers
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("GET", route, url(route, user_id))
end

function API:listGuildMembers(guild_id) -- not exposed, use cache or Guild:requestMembers
	local route = format("/guilds/%s/members", guild_id)
	return self:request("GET", route, url(route))
end

function API:addGuildMember(guild_id, user_id, payload) -- Guild:addMember (limit use, requires guild.join scope)
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PUT", route, url(route, user_id), payload)
end

function API:modifyGuildMember(guild_id, user_id, payload) -- various member methods
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("PATCH", route, url(route, user_id), payload)
end

function API:removeGuildMember(guild_id, user_id) -- Guild:kickUser, User:kick, Member:kick
	local route = format("/guilds/%s/members/%%s", guild_id)
	return self:request("DELETE", route, url(route, user_id))
end

function API:getGuildBans(guild_id) -- Guild:getBans
	local route = format("/guilds/%s/bans", guild_id)
	return self:request("GET", route, url(route))
end

function API:createGuildBan(guild_id, user_id, payload, query) -- Guild:banUser, User:ban, Member:ban
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("PUT", route, attachQuery(url(route, user_id), query), payload)
end

function API:removeGuildBan(guild_id, user_id) -- Guild:unbanUser, User:unban, Member:unban
	local route = format("/guilds/%s/bans/%%s", guild_id)
	return self:request("DELETE", route, url(route, user_id))
end

function API:getGuildRoles(guild_id) -- not exposed, use cache
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("GET", route, url(route))
end

function API:createGuildRole(guild_id, payload) -- Guild:createRole
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("POST", route, url(route), payload)
end

function API:batchModifyGuildRole(guild_id, payload) -- TODO
	local route = format("/guilds/%s/roles", guild_id)
	return self:request("PATCH", route, url(route), payload)
end

function API:modifyGuildRole(guild_id, role_id, payload) -- various role methods
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("PATCH", route, url(route, role_id), payload)
end

function API:deleteGuildRole(guild_id, role_id) -- Role:delete
	local route = format("/guilds/%s/roles/%%s", guild_id)
	return self:request("DELETE", route, url(route, role_id))
end

function API:getGuildPruneCount(guild_id)
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("GET", route, url(route))
end

function API:beginGuildPrune(guild_id, payload)
	local route = format("/guilds/%s/prune", guild_id)
	return self:request("POST", route, url(route), payload)
end

function API:getGuildVoiceRegions(guild_id)
	local route = format("/guilds/%s/regions", guild_id)
	return self:request("GET", route, url(route))
end

function API:getGuildInvites(guild_id) -- Guild:getInvites
	local route = format("/guilds/%s/invites", guild_id)
	return self:request("GET", route, url(route))
end

function API:getGuildIntegrations(guild_id)
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("GET", route, url(route))
end

function API:createGuildIntegration(guild_id, payload)
	local route = format("/guilds/%s/integrations", guild_id)
	return self:request("POST", route, url(route), payload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload)
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("PATCH", route, url(route, integration_id), payload)
end

function API:deleteGuildIntegration(guild_id, integration_id)
	local route = format("/guilds/%s/integrations/%%s", guild_id)
	return self:request("DELETE", route, url(route, integration_id))
end

function API:syncGuildIntegration(guild_id, integration_id, payload)
	local route = format("/guilds/%s/integrations/%%s/sync", guild_id)
	return self:request("POST", route, url(route, integration_id), payload)
end

function API:getGuildEmbed(guild_id)
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("GET", route, url(route))
end

function API:modifyGuildEmbed(guild_id, payload)
	local route = format("/guilds/%s/embed", guild_id)
	return self:request("PATCH", route, url(route), payload)
end

function API:getInvite(invite_code) -- Client:getInviteByCode
	local route = "/invites/%s"
	return self:request("GET", route, url(route, invite_code))
end

function API:deleteInvite(invite_code) -- Invite:delete
	local route = "/invites/%s"
	return self:request("DELETE", route, url(route, invite_code))
end

function API:acceptInvite(invite_code, payload) -- Invite:accept, Client:acceptInviteByCode
	local route = "/invites/%s"
	return self:request("POST", route, url(route, invite_code), payload)
end

function API:getCurrentUser()
	local route = "/users/@me"
	return self:request("GET", route, url(route))
end

function API:getUser(user_id)
	local route = "/users/%s"
	return self:request("GET", route, url(route, user_id))
end

function API:modifyCurrentUser(payload)
	local route = "/users/@me"
	return self:request("PATCH", route, url(route), payload)
end

function API:getCurrentUserGuilds()
	local route = "/users/@me/guilds"
	return self:request("GET", route, url(route))
end

function API:leaveGuild(guild_id) -- Guild:leave
	local route = "/users/@me/guilds/%s"
	return self:request("DELETE", route, url(route, guild_id))
end

function API:getUserDMs()
	local route = "/users/@me/channels"
	return self:request("GET", route, url(route))
end

function API:createDM(payload)
	local route = "/users/@me/channels"
	return self:request("POST", route, url(route), payload)
end

function API:createGroupDM(payload)
	local route = "/users/@me/channels"
	return self:request("POST", route, url(route), payload)
end

function API:getUsersConnections()
	local route = "/users/@me/connections"
	return self:request("GET", route, url(route))
end

function API:listVoiceRegions()
	local route = "/voice/regions"
	return self:request("GET", route, url(route))
end

function API:createWebhook(channel_id, payload)
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("POST", route, url(route), payload)
end

function API:getChannelWebhooks(channel_id)
	local route = format("/channels/%s/webhooks", channel_id)
	return self:request("GET", route, url(route))
end

function API:getGuildWebhooks(guild_id)
	local route = format("/guilds/%s/webhooks", guild_id)
	return self:request("GET", route, url(route))
end

function API:getWebhook(webhook_id)
	local route = "/webhooks/%s"
	return self:request("GET", route, url(route, webhook_id))
end

function API:getWebhookwithToken(webhook_id, webhook_token)
	local route = "/webhooks/%s/%s"
	return self:request("GET", route, url(route, webhook_id, webhook_token))
end

function API:modifyWebhook(webhook_id, payload)
	local route = "/webhooks/%s"
	return self:request("PATCH", route, url(route, webhook_id), payload)
end

function API:modifyWebhookwithToken(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s"
	return self:request("PATCH", route, url(route, webhook_id, webhook_token), payload)
end

function API:deleteWebhook(webhook_id)
	local route = "/webhooks/%s"
	return self:request("DELETE", route, url(route, webhook_id))
end

function API:deleteWebhookwithToken(webhook_id, webhook_token)
	local route = "/webhooks/%s/%s"
	return self:request("DELETE", route, url(route, webhook_id, webhook_token))
end

function API:executeWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s"
	return self:request("POST", route, url(route, webhook_id, webhook_token), payload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s/slack"
	return self:request("POST", route, url(route, webhook_id, webhook_token), payload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload)
	local route = "/webhooks/%s/%s/github"
	return self:request("POST", route, url(route, webhook_id, webhook_token), payload)
end

function API:getGateway() -- Client:connectWebsocket (cached)
	local route = "/gateway"
	return self:request("GET", route, url(route))
end

function API:getGatewayBot() -- TODO
	local route = "/gateway/bot"
	return self:request("GET", route, url(route))
end

function API:getCurrentApplicationInformation()
	local route = "/oauth2/applications/@me"
	return self:request("GET", route, url(route))
end

-- end of auto-generated methods --

function API:getToken(payload) -- Client:loginwithEmail (not recommended)
	local route = "/auth/login"
	return self:request('POST', route, url(route), payload)
end

function API:modifyCurrentUserNickname(guildId, payload) -- Client:setNickname
	local route = format("/guilds/%s/members/@me/nick", guildId)
	return self:request('PATCH', route, url(route), payload)
end

return API
