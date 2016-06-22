local json = require('json')
local http = require('coro-http')
local package = require('./package')

local url = function(endpoint, ...)
	return "https://discordapp.com/api" .. string.format(endpoint, ...)
end

local emptyBody = {}

local API = class('API')

function API:__init(token, client)
	self.client = client
	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = string.format('DiscordBot (%s, %s)', package.homepage, package.version),
		['Authorization'] = token,
	}
end

function API:request(method, url, body)

	local headers = {}
	for k, v in pairs(self.headers) do
		table.insert(headers, {k, v})
	end

	if body then
		body = json.encode(body)
		table.insert(headers, {'Content-Length', body:len()})
	end

	local res, data = http.request(method, url, headers, body)
	data = json.decode(data)

	return res, data

end

-- CHANNEL --

function API:getChannel(channelId)
	return self:request("GET", url("/channels/%s", channelId))
end

function API:modifyChannel(channelId, body)
	return self:request("PUT/PATCH", url("/channels/%s", channelId), body or emptyBody)
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

function API:createMessage(channelId, body)
	return self:request("POST", url("/channels/%s/messages", channelId), body or emptyBody)
end

function API:uploadFile(channelId, body)
	return self:request("POST", url("/channels/%s/messages", channelId), body or emptyBody)
end

function API:editMessage(channelId, messageId, body)
	return self:request("PATCH", url("/channels/%s/messages/%s", channelId, messageId), body or emptyBody)
end

function API:deleteMessage(channelId, messageId)
	return self:request("DELETE", url("/channels/%s/messages/%s", channelId, messageId))
end

function API:bulkDeleteMessages(channelId, body)
	return self:request("POST", url("/channels/%s/messages/bulk_delete", channelId), body or emptyBody)
end

function API:ackMessage(channelId, messageId, body)
	return self:request("POST", url("/channels/%s/messages/%s/ack", channelId, messageId), body or emptyBody)
end

function API:editChannelPermissions(channelId, overwriteId, body)
	return self:request("PUT", url("/channels/%s/permissions/%s", channelId, overwriteId), body or emptyBody)
end

function API:getChannelInvites(channelId)
	return self:request("GET", url("/channels/%s/invites", channelId))
end

function API:createChannelInvite(channelId, body)
	return self:request("POST", url("/channels/%s/invites", channelId), body or emptyBody)
end

function API:deleteChannelPermission(channelId, overwriteId)
	return self:request("DELETE", url("/channels/%s/permissions/%s", channelId, overwriteId))
end

function API:triggerTypingIndicator(channelId, body)
	return self:request("POST", url("/channels/%s/typing", channelId), body or emptyBody)
end

function API:getPinnedMessages(channelId)
	return self:request("GET", url("/channels/%s/pins", channelId))
end

function API:addPinnedChannelMessage(channelId, messageId, body)
	return self:request("PUT", url("/channels/%s/pins/%s", channelId, messageId), body or emptyBody)
end

function API:deletePinnedChannelMessage(channelId, messageId)
	return self:request("DELETE", url("/channels/%s/pins/%s", channelId, messageId))
end

function API:createGuild(body)
	return self:request("POST", url("/guilds"), body or emptyBody)
end

-- GUILD --

function API:getGuild(guildId)
	return self:request("GET", url("/guilds/%s", guildId))
end

function API:modifyGuild(guildId, body)
	return self:request("PATCH", url("/guilds/%s", guildId), body or emptyBody)
end

function API:deleteGuild(guildId)
	return self:request("DELETE", url("/guilds/%s", guildId))
end

function API:getGuildChannels(guildId)
	return self:request("GET", url("/guilds/%s/channels", guildId))
end

function API:createGuildChannel(guildId, body)
	return self:request("POST", url("/guilds/%s/channels", guildId), body or emptyBody)
end

function API:modifyGuildChannel(guildId, body)
	return self:request("PATCH", url("/guilds/%s/channels", guildId), body or emptyBody)
end

function API:getGuildMember(guildId, userId)
	return self:request("GET", url("/guilds/%s/members/%s", guildId, userId))
end

function API:listGuildMembers(guildId)
	return self:request("GET", url("/guilds/%s/members", guildId))
end

function API:modifyGuildMember(guildId, userId, body)
	return self:request("PATCH", url("/guilds/%s/members/%s", guildId, userId), body or emptyBody)
end

function API:removeGuildMember(guildId, userId)
	return self:request("DELETE", url("/guilds/%s/members/%s", guildId, userId))
end

function API:getGuildBans(guildId)
	return self:request("GET", url("/guilds/%s/bans", guildId))
end

function API:createGuildBan(guildId, userId, body)
	return self:request("PUT", url("/guilds/%s/bans/%s", guildId, userId), body or emptyBody)
end

function API:removeGuildBan(guildId, userId)
	return self:request("DELETE", url("/guilds/%s/bans/%s", guildId, userId))
end

function API:getGuildRoles(guildId)
	return self:request("GET", url("/guilds/%s/roles", guildId))
end

function API:createGuildRole(guildId, body)
	return self:request("POST", url("/guilds/%s/roles", guildId), body or emptyBody)
end

function API:batchModifyGuildRole(guildId, body)
	return self:request("PATCH", url("/guilds/%s/roles", guildId), body or emptyBody)
end

function API:modifyGuildRole(guildId, roleId, body)
	return self:request("PATCH", url("/guilds/%s/roles/%s", guildId, roleId), body or emptyBody)
end

function API:deleteGuildRole(guildId, roleId)
	return self:request("DELETE", url("/guilds/%s/roles/%s", guildId, roleId))
end

function API:getGuildPruneCount(guildId)
	return self:request("GET", url("/guilds/%s/prune", guildId))
end

function API:beginGuildPrune(guildId, body)
	return self:request("POST", url("/guilds/%s/prune", guildId), body or emptyBody)
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

function API:createGuildIntegration(guildId, body)
	return self:request("POST", url("/guilds/%s/integrations", guildId), body or emptyBody)
end

function API:modifyGuildIntegration(guildId, integrationId, body)
	return self:request("PATCH", url("/guilds/%s/integrations/%s", guildId, integrationId), body or emptyBody)
end

function API:deleteGuildIntegration(guildId, integrationId)
	return self:request("DELETE", url("/guilds/%s/integrations/%s", guildId, integrationId))
end

function API:syncGuildIntegration(guildId, integrationId, body)
	return self:request("POST", url("/guilds/%s/integrations/%s/sync", guildId, integrationId), body or emptyBody)
end

function API:getGuildEmbed(guildId)
	return self:request("GET", url("/guilds/%s/embed", guildId))
end

function API:modifyGuildEmbed(guildId, body)
	return self:request("PATCH", url("/guilds/%s/embed", guildId), body or emptyBody)
end

-- INVITE --

function API:getInvite(inviteId)
	return self:request("GET", url("/invites/%s", inviteId))
end

function API:deleteInvite(inviteId)
	return self:request("DELETE", url("/invites/%s", inviteId))
end

function API:acceptInvite(inviteId, body)
	return self:request("POST", url("/invites/%s", inviteId), body or emptyBody)
end

-- USER --

function API:queryUsers()
	return self:request("GET", url("/users"))
end

function API:getCurrentUser()
	return self:request("GET", url("/users/@me"))
end

function API:getUser(userId)
	return self:request("GET", url("/users/%s", userId))
end

function API:modifyCurrentUser(body)
	return self:request("PATCH", url("/users/@me"), body or emptyBody)
end

function API:getCurrentUserGuilds()
	return self:request("GET", url("/users/@me/guilds"))
end

function API:leaveGuild(guildId)
	return self:request("DELETE", url("/users/@me/guilds/%s", guildId))
end

function API:getUserDMs()
	return self:request("GET", url("/users/@me/channels"))
end

function API:createDM(body)
	return self:request("POST", url("/users/@me/channels"), body or emptyBody)
end

function API:getUsersConnections()
	return self:request("GET", url("/users/@me/connections"))
end

-- VOICE --

function API:listVoiceRegions()
	return self:request("GET", url("/voice/regions"))
end

-- AUTH --

function API:getGateway()
	return self:request("GET", url("/gateway"))
end

function API:getCurrentApplicationInformation()
	return self:request("GET", url("/oauth2/applications/@me"))
end

return API
