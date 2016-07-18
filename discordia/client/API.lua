local json = require('json')
local http = require('coro-http')
local timer = require('timer')
local package = require('../package')

local RateLimiter = require('../utils/RateLimiter')

local url = function(endpoint, ...)
	return "https://discordapp.com/api" .. string.format(endpoint, ...)
end

local emptyPayload = {}

local API = class('API')

function API:__init(client)
	self.client = client
	self.guildIds = {} -- populated by GuildChannel.__init
	self.limiters = {
		perGuild = {}, -- populated by EventHandler
		privateMessage = RateLimiter(5, 5000),
		globalMessage = RateLimiter(50, 10000),
	}
	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = string.format('DiscordBot (%s, %s)', package.homepage, package.version),
	}
end

function API:setToken(token)
	self.headers['Authorization'] = token
end

function API:request(method, url, payload, limiter1, limiter2)

	local headers = {}
	for k, v in pairs(self.headers) do
		table.insert(headers, {k, v})
	end

	if payload then
		payload = json.encode(payload)
		table.insert(headers, {'Content-Length', payload:len()})
	end

	if limiter1 then limiter1:start() end
	if limiter2 then limiter2:start() end

	local res, data = http.request(method, url, headers, payload)

	if limiter1 then limiter1:stop() end
	if limiter2 then limiter2:stop() end

	p('code: ' .. res.code) -- debug
	if res.code ~= 200 then p(res) end
	return (json.decode(data))

end

--[[
REST:
       bot:msg:dm |  5/5s    | account-wide -- done
   bot:msg:server |  5/5s    | guild-wide -- done
   bot:msg:global | 50/10s   | account-wide except DMs -- done
             dmsg |  5/1s    | guild-wide -- done
            bdmsg |  1/1s    | guild-wide -- done
     guild_member | 10/10s   | guild-wide
guild_member_nick |  1/1s    | guild-wide
       |Username| |  2/3600s | account-wide

WS Send:
|Presence Update| |   5/60s
         |Global| | 120/60s
]]

function API:getChannel(channelId) -- not exposed, use cache
	return self:request("GET", url("/channels/%s", channelId))
end

function API:modifyChannel(channelId, payload)
	return self:request("PUT/PATCH", url("/channels/%s", channelId), payload or emptyPayload)
end

function API:deleteChannel(channelId)
	return self:request("DELETE", url("/channels/%s", channelId))
end

function API:getChannelMessages(channelId)
	return self:request("GET", url("/channels/%s/messages", channelId))
end

function API:getChannelMessage(channelId, messageId)
	return self:request("GET", url("/channels/%s/messages/%s", channelId, messageId))
end

function API:createMessage(channelId, payload)
	local guildId = self.guildIds[channelId]
	local limiters = self.limiters
	local limiter1, limiter2
	if guildId then
		limiter1 = limiters.perGuild[guildId].createMessage
		limiter2 = limiters.globalMessage
	else
		limiter1 = limiters.privateMessage
	end
	return self:request("POST", url("/channels/%s/messages", channelId), payload, limiter1, limiter2)
end

function API:uploadFile(channelId, payload)
	return self:request("POST", url("/channels/%s/messages", channelId), payload)
end

function API:editMessage(channelId, messageId, payload)
	return self:request("PATCH", url("/channels/%s/messages/%s", channelId, messageId), payload)
end

function API:deleteMessage(channelId, messageId)
	local guildId = self.guildIds[channelId]
	local limiter1 = self.limiters.perGuild[guildId].deleteMessage -- TODO test
	return self:request("DELETE", url("/channels/%s/messages/%s", channelId, messageId))
end

function API:bulkDeleteMessages(channelId, payload)
	local guildId = self.guildIds[channelId]
	local limiter1 = self.limiters.perGuild[guildId].bulkDelete -- TODO test
	return self:request("POST", url("/channels/%s/messages/bulk_delete", channelId), payload)
end

function API:ackMessage(channelId, messageId, payload)
	return self:request("POST", url("/channels/%s/messages/%s/ack", channelId, messageId), payload or emptyPayload)
end

function API:editChannelPermissions(channelId, overwriteId, payload)
	return self:request("PUT", url("/channels/%s/permissions/%s", channelId, overwriteId), payload or emptyPayload)
end

function API:getChannelInvites(channelId)
	return self:request("GET", url("/channels/%s/invites", channelId))
end

function API:createChannelInvite(channelId, payload)
	return self:request("POST", url("/channels/%s/invites", channelId), payload or emptyPayload)
end

function API:deleteChannelPermissions(channelId, overwriteId)
	return self:request("DELETE", url("/channels/%s/permissions/%s", channelId, overwriteId))
end

function API:triggerTypingIndicator(channelId, payload)
	return self:request("POST", url("/channels/%s/typing", channelId), payload or emptyPayload)
end

function API:getPinnedMessages(channelId)
	return self:request("GET", url("/channels/%s/pins", channelId))
end

function API:addPinnedChannelMessage(channelId, messageId, payload)
	return self:request("PUT", url("/channels/%s/pins/%s", channelId, messageId), payload or emptyPayload)
end

function API:deletePinnedChannelMessage(channelId, messageId)
	return self:request("DELETE", url("/channels/%s/pins/%s", channelId, messageId))
end

function API:createGuild(payload)
	return self:request("POST", url("/guilds"), payload or emptyPayload)
end

function API:getGuild(guildId)
	return self:request("GET", url("/guilds/%s", guildId))
end

function API:modifyGuild(guildId, payload)
	return self:request("PATCH", url("/guilds/%s", guildId), payload)
end

function API:deleteGuild(guildId)
	return self:request("DELETE", url("/guilds/%s", guildId))
end

function API:getGuildChannels(guildId) -- not exposed, use cache
	return self:request("GET", url("/guilds/%s/channels", guildId))
end

function API:createGuildChannel(guildId, payload)
	return self:request("POST", url("/guilds/%s/channels", guildId), payload or emptyPayload)
end

function API:modifyGuildChannel(guildId, payload)
	return self:request("PATCH", url("/guilds/%s/channels", guildId), payload or emptyPayload)
end

function API:getGuildMember(guildId, userId)
	return self:request("GET", url("/guilds/%s/members/%s", guildId, userId))
end

function API:listGuildMembers(guildId)
	return self:request("GET", url("/guilds/%s/members", guildId))
end

function API:modifyGuildMember(guildId, userId, payload)
	return self:request("PATCH", url("/guilds/%s/members/%s", guildId, userId), payload or emptyPayload)
end

function API:removeGuildMember(guildId, userId)
	return self:request("DELETE", url("/guilds/%s/members/%s", guildId, userId))
end

function API:getGuildBans(guildId)
	return self:request("GET", url("/guilds/%s/bans", guildId))
end

function API:createGuildBan(guildId, userId, payload)
	return self:request("PUT", url("/guilds/%s/bans/%s", guildId, userId), payload or emptyPayload)
end

function API:removeGuildBan(guildId, userId)
	return self:request("DELETE", url("/guilds/%s/bans/%s", guildId, userId))
end

function API:getGuildRoles(guildId) -- not exposed, use cache
	return self:request("GET", url("/guilds/%s/roles", guildId))
end

function API:createGuildRole(guildId, payload)
	return self:request("POST", url("/guilds/%s/roles", guildId), payload or emptyPayload)
end

function API:batchModifyGuildRole(guildId, payload)
	return self:request("PATCH", url("/guilds/%s/roles", guildId), payload or emptyPayload)
end

function API:modifyGuildRole(guildId, roleId, payload)
	return self:request("PATCH", url("/guilds/%s/roles/%s", guildId, roleId), payload or emptyPayload)
end

function API:deleteGuildRole(guildId, roleId)
	return self:request("DELETE", url("/guilds/%s/roles/%s", guildId, roleId))
end

function API:getGuildPruneCount(guildId)
	return self:request("GET", url("/guilds/%s/prune", guildId))
end

function API:beginGuildPrune(guildId, payload)
	return self:request("POST", url("/guilds/%s/prune", guildId), payload or emptyPayload)
end

function API:getGuildVoiceRegions(guildId)
	return self:request("GET", url("/guilds/%s/regions", guildId))
end

function API:getGuildInvites(guildId)
	return self:request("GET", url("/guilds/%s/invites", guildId))
end

function API:getGuildIntegrations(guildId)
	return self:request("GET", url("/guilds/%s/integrations", guildId))
end

function API:createGuildIntegration(guildId, payload)
	return self:request("POST", url("/guilds/%s/integrations", guildId), payload or emptyPayload)
end

function API:modifyGuildIntegration(guildId, integrationId, payload)
	return self:request("PATCH", url("/guilds/%s/integrations/%s", guildId, integrationId), payload or emptyPayload)
end

function API:deleteGuildIntegration(guildId, integrationId)
	return self:request("DELETE", url("/guilds/%s/integrations/%s", guildId, integrationId))
end

function API:syncGuildIntegration(guildId, integrationId, payload)
	return self:request("POST", url("/guilds/%s/integrations/%s/sync", guildId, integrationId), payload or emptyPayload)
end

function API:getGuildEmbed(guildId)
	return self:request("GET", url("/guilds/%s/embed", guildId))
end

function API:modifyGuildEmbed(guildId, payload)
	return self:request("PATCH", url("/guilds/%s/embed", guildId), payload or emptyPayload)
end

function API:getInvite(inviteId)
	return self:request("GET", url("/invites/%s", inviteId))
end

function API:deleteInvite(inviteId)
	return self:request("DELETE", url("/invites/%s", inviteId))
end

function API:acceptInvite(inviteId, payload)
	return self:request("POST", url("/invites/%s", inviteId), payload or emptyPayload)
end

function API:queryUsers()
	return self:request("GET", url("/users"))
end

function API:getCurrentUser()
	return self:request("GET", url("/users/@me"))
end

function API:getUser(userId)
	return self:request("GET", url("/users/%s", userId))
end

function API:modifyCurrentUser(payload)
	return self:request("PATCH", url("/users/@me"), payload or emptyPayload)
end

function API:getCurrentUserGuilds() -- not exposed, use cache
	return self:request("GET", url("/users/@me/guilds"))
end

function API:leaveGuild(guildId)
	return self:request("DELETE", url("/users/@me/guilds/%s", guildId))
end

function API:getUserDMs()
	return self:request("GET", url("/users/@me/channels"))
end

function API:createDM(payload)
	return self:request("POST", url("/users/@me/channels"), payload or emptyPayload)
end

function API:getUsersConnections()
	return self:request("GET", url("/users/@me/connections"))
end

function API:listVoiceRegions()
	return self:request("GET", url("/voice/regions"))
end

function API:getGateway()
	return self:request("GET", url("/gateway"))
end

function API:getCurrentApplicationInformation()
	return self:request("GET", url("/oauth2/applications/@me"))
end

function API:getToken(payload)
	return self:request('POST', url('/auth/login'), payload)
end

return API
