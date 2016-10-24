local json = require('json')
local http = require('coro-http')
local timer = require('timer')
local package = require('../package')

local url = function(endpoint, ...)
	return "https://discordapp.com/api" .. string.format(endpoint, ...)
end

local emptyPayload = {}

local API = class('API')

function API:__init(client)
	self.client = client
	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = string.format('DiscordBot (%s, %s)', package.homepage, package.version),
	}
end

function API:setToken(token)
	self.headers['Authorization'] = token
end

function API:request(method, url, payload)

	local headers = {}
	for k, v in pairs(self.headers) do
		table.insert(headers, {k, v})
	end

	if payload then
		payload = json.encode(payload)
		table.insert(headers, {'Content-Length', payload:len()})
	end

	local res, data = http.request(method, url, headers, payload)
	local success, data = res.code < 300, json.decode(data)
	if not success then p(res, data) end -- debug
	return success, data

end

function API:getChannel(channel_id) -- not exposed, use cache
	return self:request("GET", url("/channels/%s", channel_id))
end

function API:modifyChannel(channel_id, payload) -- various channel methods
	return self:request("PATCH", url("/channels/%s", channel_id), payload or emptyPayload)
end

function API:deleteChannel(channel_id) -- Channel:delete
	return self:request("DELETE", url("/channels/%s", channel_id))
end

function API:getChannelMessages(channel_id, limit, field, message_id) -- TextChannel:getMessageHistory[Before|After|Around]
	if field and message_id then
		return self:request("GET", url("/channels/%s/messages?limit=%i&%s=%s", channel_id, limit, field, message_id))
	else
		return self:request("GET", url("/channels/%s/messages?limit=%i", channel_id, limit))
	end
end

function API:getChannelMessage(channel_id, message_id) -- not exposed, maybe in the future
	return self:request("GET", url("/channels/%s/messages/%s", channel_id, message_id))
end

function API:createMessage(channel_id, payload) -- TextChannel:[create|send]Message
	return self:request("POST", url("/channels/%s/messages", channel_id), payload or emptyPayload)
end

function API:uploadFile(channel_id, payload)
	return self:request("POST", url("/channels/%s/messages", channel_id), payload or emptyPayload)
end

function API:editMessage(channel_id, message_id, payload) -- Message:setContent
	return self:request("PATCH", url("/channels/%s/messages/%s", channel_id, message_id), payload or emptyPayload)
end

function API:deleteMessage(channel_id, message_id) -- Message:delete
	return self:request("DELETE", url("/channels/%s/messages/%s", channel_id, message_id))
end

function API:bulkDeleteMessages(channel_id, payload) -- TextChannel:bulkDelete
	return self:request("POST", url("/channels/%s/messages/bulk-delete", channel_id), payload or emptyPayload)
end

function API:editChannelPermissions(channel_id, overwrite_id, payload)
	return self:request("PUT", url("/channels/%s/permissions/%s", channel_id, overwrite_id), payload or emptyPayload)
end

function API:getChannelInvites(channel_id) -- GuildChannel:getInvites
	return self:request("GET", url("/channels/%s/invites", channel_id))
end

function API:createChannelInvite(channel_id, payload) -- GuildChannel:createInvite
	return self:request("POST", url("/channels/%s/invites", channel_id), payload or emptyPayload)
end

function API:deleteChannelPermission(channel_id, overwrite_id)
	return self:request("DELETE", url("/channels/%s/permissions/%s", channel_id, overwrite_id))
end

function API:triggerTypingIndicator(channel_id, payload) -- TextChannel:broadcastTyping
	return self:request("POST", url("/channels/%s/typing", channel_id), payload or emptyPayload)
end

function API:getPinnedMessages(channel_id) -- TextChannel:getPinnedMessages
	return self:request("GET", url("/channels/%s/pins", channel_id))
end

function API:addPinnedChannelMessage(channel_id, message_id, payload) -- Message:pin
	return self:request("PUT", url("/channels/%s/pins/%s", channel_id, message_id), payload or emptyPayload)
end

function API:deletePinnedChannelMessage(channel_id, message_id) -- Message:unpin
	return self:request("DELETE", url("/channels/%s/pins/%s", channel_id, message_id))
end

function API:groupDMAddRecipient(channel_id, user_id, payload)
	return self:request("PUT", url("/channels/%s/recipients/%s", channel_id, user_id), payload or emptyPayload)
end

function API:groupDMRemoveRecipient(channel_id, user_id)
	return self:request("DELETE", url("/channels/%s/recipients/%s", channel_id, user_id))
end

function API:createGuild(payload)
	return self:request("POST", url("/guilds"), payload or emptyPayload)
end

function API:getGuild(guild_id)
	return self:request("GET", url("/guilds/%s", guild_id))
end

function API:modifyGuild(guild_id, payload)
	return self:request("PATCH", url("/guilds/%s", guild_id), payload or emptyPayload)
end

function API:deleteGuild(guild_id)
	return self:request("DELETE", url("/guilds/%s", guild_id))
end

function API:getGuildChannels(guild_id)
	return self:request("GET", url("/guilds/%s/channels", guild_id))
end

function API:createGuildChannel(guild_id, payload)
	return self:request("POST", url("/guilds/%s/channels", guild_id), payload or emptyPayload)
end

function API:modifyGuildChannelPosition(guild_id, payload)
	return self:request("PATCH", url("/guilds/%s/channels", guild_id), payload or emptyPayload)
end

function API:getGuildMember(guild_id, user_id)
	return self:request("GET", url("/guilds/%s/members/%s", guild_id, user_id))
end

function API:listGuildMembers(guild_id)
	return self:request("GET", url("/guilds/%s/members", guild_id))
end

function API:addGuildMember(guild_id, user_id, payload)
	return self:request("PUT", url("/guilds/%s/members/%s", guild_id, user_id), payload or emptyPayload)
end

function API:modifyGuildMember(guild_id, user_id, payload)
	return self:request("PATCH", url("/guilds/%s/members/%s", guild_id, user_id), payload or emptyPayload)
end

function API:removeGuildMember(guild_id, user_id)
	return self:request("DELETE", url("/guilds/%s/members/%s", guild_id, user_id))
end

function API:getGuildBans(guild_id)
	return self:request("GET", url("/guilds/%s/bans", guild_id))
end

function API:createGuildBan(guild_id, user_id, payload)
	return self:request("PUT", url("/guilds/%s/bans/%s", guild_id, user_id), payload or emptyPayload)
end

function API:removeGuildBan(guild_id, user_id)
	return self:request("DELETE", url("/guilds/%s/bans/%s", guild_id, user_id))
end

function API:getGuildRoles(guild_id)
	return self:request("GET", url("/guilds/%s/roles", guild_id))
end

function API:createGuildRole(guild_id, payload)
	return self:request("POST", url("/guilds/%s/roles", guild_id), payload or emptyPayload)
end

function API:batchModifyGuildRole(guild_id, payload)
	return self:request("PATCH", url("/guilds/%s/roles", guild_id), payload or emptyPayload)
end

function API:modifyGuildRole(guild_id, role_id, payload)
	return self:request("PATCH", url("/guilds/%s/roles/%s", guild_id, role_id), payload or emptyPayload)
end

function API:deleteGuildRole(guild_id, role_id)
	return self:request("DELETE", url("/guilds/%s/roles/%s", guild_id, role_id))
end

function API:getGuildPruneCount(guild_id)
	return self:request("GET", url("/guilds/%s/prune", guild_id))
end

function API:beginGuildPrune(guild_id, payload)
	return self:request("POST", url("/guilds/%s/prune", guild_id), payload or emptyPayload)
end

function API:getGuildVoiceRegions(guild_id)
	return self:request("GET", url("/guilds/%s/regions", guild_id))
end

function API:getGuildInvites(guild_id) -- Guild:getInvites
	return self:request("GET", url("/guilds/%s/invites", guild_id))
end

function API:getGuildIntegrations(guild_id)
	return self:request("GET", url("/guilds/%s/integrations", guild_id))
end

function API:createGuildIntegration(guild_id, payload)
	return self:request("POST", url("/guilds/%s/integrations", guild_id), payload or emptyPayload)
end

function API:modifyGuildIntegration(guild_id, integration_id, payload)
	return self:request("PATCH", url("/guilds/%s/integrations/%s", guild_id, integration_id), payload or emptyPayload)
end

function API:deleteGuildIntegration(guild_id, integration_id)
	return self:request("DELETE", url("/guilds/%s/integrations/%s", guild_id, integration_id))
end

function API:syncGuildIntegration(guild_id, integration_id, payload)
	return self:request("POST", url("/guilds/%s/integrations/%s/sync", guild_id, integration_id), payload or emptyPayload)
end

function API:getGuildEmbed(guild_id)
	return self:request("GET", url("/guilds/%s/embed", guild_id))
end

function API:modifyGuildEmbed(guild_id, payload)
	return self:request("PATCH", url("/guilds/%s/embed", guild_id), payload or emptyPayload)
end

function API:getInvite(invite_code) -- Client:getInviteByCode
	return self:request("GET", url("/invites/%s", invite_code))
end

function API:deleteInvite(invite_code) -- Invite:delete
	return self:request("DELETE", url("/invites/%s", invite_code))
end

function API:acceptInvite(invite_code, payload) -- Invite:accept, Client:acceptInviteByCode
	return self:request("POST", url("/invites/%s", invite_code), payload or emptyPayload)
end

function API:getCurrentUser()
	return self:request("GET", url("/users/@me"))
end

function API:getUser(user_id)
	return self:request("GET", url("/users/%s", user_id))
end

function API:modifyCurrentUser(payload)
	return self:request("PATCH", url("/users/@me"), payload or emptyPayload)
end

function API:getCurrentUserGuilds()
	return self:request("GET", url("/users/@me/guilds"))
end

function API:leaveGuild(guild_id)
	return self:request("DELETE", url("/users/@me/guilds/%s", guild_id))
end

function API:getUserDMs()
	return self:request("GET", url("/users/@me/channels"))
end

function API:createDM(payload)
	return self:request("POST", url("/users/@me/channels"), payload or emptyPayload)
end

function API:createGroupDM(payload)
	return self:request("POST", url("/users/@me/channels"), payload or emptyPayload)
end

function API:getUsersConnections()
	return self:request("GET", url("/users/@me/connections"))
end

function API:listVoiceRegions()
	return self:request("GET", url("/voice/regions"))
end

function API:createWebhook(channel_id, payload)
	return self:request("POST", url("/channels/%s/webhooks", channel_id), payload or emptyPayload)
end

function API:getChannelWebhooks(channel_id)
	return self:request("GET", url("/channels/%s/webhooks", channel_id))
end

function API:getGuildWebhooks(guild_id)
	return self:request("GET", url("/guilds/%s/webhooks", guild_id))
end

function API:getWebhook(webhook_id)
	return self:request("GET", url("/webhooks/%s", webhook_id))
end

function API:getWebhookwithToken(webhook_id, webhook_token)
	return self:request("GET", url("/webhooks/%s/%s", webhook_id, webhook_token))
end

function API:modifyWebhook(webhook_id, payload)
	return self:request("PATCH", url("/webhooks/%s", webhook_id), payload or emptyPayload)
end

function API:modifyWebhookwithToken(webhook_id, webhook_token, payload)
	return self:request("PATCH", url("/webhooks/%s/%s", webhook_id, webhook_token), payload or emptyPayload)
end

function API:deleteWebhook(webhook_id)
	return self:request("DELETE", url("/webhooks/%s", webhook_id))
end

function API:deleteWebhookwithToken(webhook_id, webhook_token)
	return self:request("DELETE", url("/webhooks/%s/%s", webhook_id, webhook_token))
end

function API:executeWebhook(webhook_id, webhook_token, payload)
	return self:request("POST", url("/webhooks/%s/%s", webhook_id, webhook_token), payload or emptyPayload)
end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, payload)
	return self:request("POST", url("/webhooks/%s/%s/slack", webhook_id, webhook_token), payload or emptyPayload)
end

function API:executeGitHubCompatibleWebhook(webhook_id, webhook_token, payload)
	return self:request("POST", url("/webhooks/%s/%s/github", webhook_id, webhook_token), payload or emptyPayload)
end

function API:getGateway() -- Client:connectWebsocket (cached)
	return self:request("GET", url("/gateway"))
end

function API:getCurrentApplicationInformation()
	return self:request("GET", url("/oauth2/applications/@me"))
end

function API:getToken(payload) -- Client:loginwithEmail (not recommended)
	return self:request('POST', url('/auth/login'), payload)
end

function API:modifyCurrentUserNickname(guildId, payload) -- Client:setNickname
	return self:request('PATCH', url('/guilds/%s/members/@me/nick', guildId), payload)
end

return API
