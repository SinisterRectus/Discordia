local json = require('json')
local http = require('coro-http')
local class = require('../class')
local constants = require('../constants')

local f = string.format

local API_BASE_URL = constants.API_BASE_URL
local JSON_CONTENT_TYPE = constants.JSON_CONTENT_TYPE
local USER_AGENT = constants.USER_AGENT

local function encodeChar(char)
	return string.format('%%%02X', string.byte(char))
end

local function encodeString(obj)
	return (string.gsub(obj, '[^%w%.%-_~]', encodeChar))
end

local function encodeQuery(query)
	local buf = {}
	for k, v in pairs(query) do
		k = encodeString(k) .. '='
		if type(v) == 'table' then
			for _, w in ipairs(v) do
				table.insert(buf, k .. encodeString(w))
			end
		else
			table.insert(buf, k .. encodeString(v))
		end
	end
	return table.concat(buf, '&')
end

local API = class('API')

function API:__init(client)
	self._client = client
end

function API:log(level, res, method, url)
	return self._client:log(level, '%s - %s : %s %s', res.code, res.reason, method, url)
end

function API:setToken(token)
	local prefix = self._client._tokenPrefix
	if token:find(prefix) == 1 then
		self._token = token
	else
		self._token = prefix .. token
	end
end

function API:request(options)

	local method = options.method
	local path = options.path
	local query = options.query
	local body = options.body

	local url = API_BASE_URL .. path
	if query and next(query) then
		url = url .. '?' .. encodeQuery(query)
	end

	local req = {{'User-Agent', USER_AGENT}}

	if self._token then
		table.insert(req, {'Authorization', self._token})
	end

	if body then
		body = json.encode(body)
		table.insert(req, {'Content-Type', JSON_CONTENT_TYPE})
		table.insert(req, {'Content-Length', #body})
	end

	local success, res, msg = pcall(http.request, method, url, req, body)

	if not success then
		self._client:log('error', 'HTTP client error: %s', res)
		return nil, res
	end

	local head = {}
	for _, v in ipairs(res --[[@as table]]) do
		head[string.lower(v[1])] = v[2]
	end

	local data = head['content-type'] == JSON_CONTENT_TYPE and json.decode(msg, 1, json.null, nil, nil) or {data = msg}

	if res.code < 300 then
		self:log('debug', res, method, url)
		return data
	else
		self:log('error', res, method, url)
		return nil, msg
	end

end

---- begin generated code ----

function API:getMyApplication() return self:request {
	method = "GET",
	path = "/applications/@me",
} end

function API:updateMyApplication(body) return self:request {
	method = "PATCH",
	path = "/applications/@me",
	body = assert(body),
} end

function API:getApplication(application_id) return self:request {
	method = "GET",
	path = f("/applications/%s", application_id),
} end

function API:updateApplication(application_id, body) return self:request {
	method = "PATCH",
	path = f("/applications/%s", application_id),
	body = assert(body),
} end

function API:applicationsGetActivityInstance(application_id, instance_id) return self:request {
	method = "GET",
	path = f("/applications/%s/activity-instances/%s", application_id, instance_id),
} end

function API:uploadApplicationAttachment(application_id) return self:request {
	method = "POST",
	path = f("/applications/%s/attachment", application_id),
} end

function API:bulkSetApplicationCommands(application_id, body) return self:request {
	method = "PUT",
	path = f("/applications/%s/commands", application_id),
	body = assert(body),
} end

function API:createApplicationCommand(application_id, body) return self:request {
	method = "POST",
	path = f("/applications/%s/commands", application_id),
	body = assert(body),
} end

function API:listApplicationCommands(application_id, query) return self:request {
	method = "GET",
	path = f("/applications/%s/commands", application_id),
	query = query,
} end

function API:deleteApplicationCommand(application_id, command_id) return self:request {
	method = "DELETE",
	path = f("/applications/%s/commands/%s", application_id, command_id),
} end

function API:getApplicationCommand(application_id, command_id) return self:request {
	method = "GET",
	path = f("/applications/%s/commands/%s", application_id, command_id),
} end

function API:updateApplicationCommand(application_id, command_id, body) return self:request {
	method = "PATCH",
	path = f("/applications/%s/commands/%s", application_id, command_id),
	body = assert(body),
} end

function API:createApplicationEmoji(application_id, body) return self:request {
	method = "POST",
	path = f("/applications/%s/emojis", application_id),
	body = assert(body),
} end

function API:listApplicationEmojis(application_id) return self:request {
	method = "GET",
	path = f("/applications/%s/emojis", application_id),
} end

function API:deleteApplicationEmoji(application_id, emoji_id) return self:request {
	method = "DELETE",
	path = f("/applications/%s/emojis/%s", application_id, emoji_id),
} end

function API:getApplicationEmoji(application_id, emoji_id) return self:request {
	method = "GET",
	path = f("/applications/%s/emojis/%s", application_id, emoji_id),
} end

function API:updateApplicationEmoji(application_id, emoji_id, body) return self:request {
	method = "PATCH",
	path = f("/applications/%s/emojis/%s", application_id, emoji_id),
	body = assert(body),
} end

function API:createEntitlement(application_id, body) return self:request {
	method = "POST",
	path = f("/applications/%s/entitlements", application_id),
	body = assert(body),
} end

function API:getEntitlements(application_id, query) return self:request {
	method = "GET",
	path = f("/applications/%s/entitlements", application_id),
	query = query,
} end

function API:deleteEntitlement(application_id, entitlement_id) return self:request {
	method = "DELETE",
	path = f("/applications/%s/entitlements/%s", application_id, entitlement_id),
} end

function API:getEntitlement(application_id, entitlement_id) return self:request {
	method = "GET",
	path = f("/applications/%s/entitlements/%s", application_id, entitlement_id),
} end

function API:consumeEntitlement(application_id, entitlement_id) return self:request {
	method = "POST",
	path = f("/applications/%s/entitlements/%s/consume", application_id, entitlement_id),
} end

function API:bulkSetGuildApplicationCommands(application_id, guild_id, body) return self:request {
	method = "PUT",
	path = f("/applications/%s/guilds/%s/commands", application_id, guild_id),
	body = assert(body),
} end

function API:createGuildApplicationCommand(application_id, guild_id, body) return self:request {
	method = "POST",
	path = f("/applications/%s/guilds/%s/commands", application_id, guild_id),
	body = assert(body),
} end

function API:listGuildApplicationCommands(application_id, guild_id, query) return self:request {
	method = "GET",
	path = f("/applications/%s/guilds/%s/commands", application_id, guild_id),
	query = query,
} end

function API:listGuildApplicationCommandPermissions(application_id, guild_id) return self:request {
	method = "GET",
	path = f("/applications/%s/guilds/%s/commands/permissions", application_id, guild_id),
} end

function API:deleteGuildApplicationCommand(application_id, guild_id, command_id) return self:request {
	method = "DELETE",
	path = f("/applications/%s/guilds/%s/commands/%s", application_id, guild_id, command_id),
} end

function API:getGuildApplicationCommand(application_id, guild_id, command_id) return self:request {
	method = "GET",
	path = f("/applications/%s/guilds/%s/commands/%s", application_id, guild_id, command_id),
} end

function API:updateGuildApplicationCommand(application_id, guild_id, command_id, body) return self:request {
	method = "PATCH",
	path = f("/applications/%s/guilds/%s/commands/%s", application_id, guild_id, command_id),
	body = assert(body),
} end

function API:getGuildApplicationCommandPermissions(application_id, guild_id, command_id) return self:request {
	method = "GET",
	path = f("/applications/%s/guilds/%s/commands/%s/permissions", application_id, guild_id, command_id),
} end

function API:setGuildApplicationCommandPermissions(application_id, guild_id, command_id, body) return self:request {
	method = "PUT",
	path = f("/applications/%s/guilds/%s/commands/%s/permissions", application_id, guild_id, command_id),
	body = assert(body),
} end

function API:getApplicationRoleConnectionsMetadata(application_id) return self:request {
	method = "GET",
	path = f("/applications/%s/role-connections/metadata", application_id),
} end

function API:updateApplicationRoleConnectionsMetadata(application_id, body) return self:request {
	method = "PUT",
	path = f("/applications/%s/role-connections/metadata", application_id),
	body = assert(body),
} end

function API:deleteChannel(channel_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s", channel_id),
} end

function API:getChannel(channel_id) return self:request {
	method = "GET",
	path = f("/channels/%s", channel_id),
} end

function API:updateChannel(channel_id, body) return self:request {
	method = "PATCH",
	path = f("/channels/%s", channel_id),
	body = assert(body),
} end

function API:followChannel(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/followers", channel_id),
	body = assert(body),
} end

function API:createChannelInvite(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/invites", channel_id),
	body = assert(body),
} end

function API:listChannelInvites(channel_id) return self:request {
	method = "GET",
	path = f("/channels/%s/invites", channel_id),
} end

function API:createMessage(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/messages", channel_id),
	body = assert(body),
} end

function API:listMessages(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/messages", channel_id),
	query = query,
} end

function API:bulkDeleteMessages(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/messages/bulk-delete", channel_id),
	body = assert(body),
} end

function API:listPins(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/messages/pins", channel_id),
	query = query,
} end

function API:createPin(channel_id, message_id) return self:request {
	method = "PUT",
	path = f("/channels/%s/messages/pins/%s", channel_id, message_id),
} end

function API:deletePin(channel_id, message_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/pins/%s", channel_id, message_id),
} end

function API:deleteMessage(channel_id, message_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/%s", channel_id, message_id),
} end

function API:getMessage(channel_id, message_id) return self:request {
	method = "GET",
	path = f("/channels/%s/messages/%s", channel_id, message_id),
} end

function API:updateMessage(channel_id, message_id, body) return self:request {
	method = "PATCH",
	path = f("/channels/%s/messages/%s", channel_id, message_id),
	body = assert(body),
} end

function API:crosspostMessage(channel_id, message_id) return self:request {
	method = "POST",
	path = f("/channels/%s/messages/%s/crosspost", channel_id, message_id),
} end

function API:deleteAllMessageReactions(channel_id, message_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/%s/reactions", channel_id, message_id),
} end

function API:deleteAllMessageReactionsByEmoji(channel_id, message_id, emoji_name) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/%s/reactions/%s", channel_id, message_id, emoji_name),
} end

function API:listMessageReactionsByEmoji(channel_id, message_id, emoji_name, query) return self:request {
	method = "GET",
	path = f("/channels/%s/messages/%s/reactions/%s", channel_id, message_id, emoji_name),
	query = query,
} end

function API:addMyMessageReaction(channel_id, message_id, emoji_name) return self:request {
	method = "PUT",
	path = f("/channels/%s/messages/%s/reactions/%s/@me", channel_id, message_id, emoji_name),
} end

function API:deleteMyMessageReaction(channel_id, message_id, emoji_name) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/%s/reactions/%s/@me", channel_id, message_id, emoji_name),
} end

function API:deleteUserMessageReaction(channel_id, message_id, emoji_name, user_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/messages/%s/reactions/%s/%s", channel_id, message_id, emoji_name, user_id),
} end

function API:createThreadFromMessage(channel_id, message_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/messages/%s/threads", channel_id, message_id),
	body = assert(body),
} end

function API:deleteChannelPermissionOverwrite(channel_id, overwrite_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/permissions/%s", channel_id, overwrite_id),
} end

function API:setChannelPermissionOverwrite(channel_id, overwrite_id, body) return self:request {
	method = "PUT",
	path = f("/channels/%s/permissions/%s", channel_id, overwrite_id),
	body = assert(body),
} end

function API:deprecatedListPins(channel_id) return self:request {
	method = "GET",
	path = f("/channels/%s/pins", channel_id),
} end

function API:deprecatedCreatePin(channel_id, message_id) return self:request {
	method = "PUT",
	path = f("/channels/%s/pins/%s", channel_id, message_id),
} end

function API:deprecatedDeletePin(channel_id, message_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/pins/%s", channel_id, message_id),
} end

function API:getAnswerVoters(channel_id, message_id, answer_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/polls/%s/answers/%s", channel_id, message_id, answer_id),
	query = query,
} end

function API:pollExpire(channel_id, message_id) return self:request {
	method = "POST",
	path = f("/channels/%s/polls/%s/expire", channel_id, message_id),
} end

function API:addGroupDmUser(channel_id, user_id, body) return self:request {
	method = "PUT",
	path = f("/channels/%s/recipients/%s", channel_id, user_id),
	body = assert(body),
} end

function API:deleteGroupDmUser(channel_id, user_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/recipients/%s", channel_id, user_id),
} end

function API:sendSoundboardSound(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/send-soundboard-sound", channel_id),
	body = assert(body),
} end

function API:listThreadMembers(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/thread-members", channel_id),
	query = query,
} end

function API:joinThread(channel_id) return self:request {
	method = "PUT",
	path = f("/channels/%s/thread-members/@me", channel_id),
} end

function API:leaveThread(channel_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/thread-members/@me", channel_id),
} end

function API:addThreadMember(channel_id, user_id) return self:request {
	method = "PUT",
	path = f("/channels/%s/thread-members/%s", channel_id, user_id),
} end

function API:deleteThreadMember(channel_id, user_id) return self:request {
	method = "DELETE",
	path = f("/channels/%s/thread-members/%s", channel_id, user_id),
} end

function API:getThreadMember(channel_id, user_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/thread-members/%s", channel_id, user_id),
	query = query,
} end

function API:createThread(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/threads", channel_id),
	body = assert(body),
} end

function API:listPrivateArchivedThreads(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/threads/archived/private", channel_id),
	query = query,
} end

function API:listPublicArchivedThreads(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/threads/archived/public", channel_id),
	query = query,
} end

function API:threadSearch(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/threads/search", channel_id),
	query = query,
} end

function API:triggerTypingIndicator(channel_id) return self:request {
	method = "POST",
	path = f("/channels/%s/typing", channel_id),
} end

function API:listMyPrivateArchivedThreads(channel_id, query) return self:request {
	method = "GET",
	path = f("/channels/%s/users/@me/threads/archived/private", channel_id),
	query = query,
} end

function API:updateVoiceChannelStatus(channel_id, body) return self:request {
	method = "PUT",
	path = f("/channels/%s/voice-status", channel_id),
	body = assert(body),
} end

function API:createWebhook(channel_id, body) return self:request {
	method = "POST",
	path = f("/channels/%s/webhooks", channel_id),
	body = assert(body),
} end

function API:listChannelWebhooks(channel_id) return self:request {
	method = "GET",
	path = f("/channels/%s/webhooks", channel_id),
} end

function API:getGateway() return self:request {
	method = "GET",
	path = "/gateway",
} end

function API:getBotGateway() return self:request {
	method = "GET",
	path = "/gateway/bot",
} end

function API:getGuildTemplate(code) return self:request {
	method = "GET",
	path = f("/guilds/templates/%s", code),
} end

function API:getGuild(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s", guild_id),
	query = query,
} end

function API:updateGuild(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s", guild_id),
	body = assert(body),
} end

function API:listGuildAuditLogEntries(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/audit-logs", guild_id),
	query = query,
} end

function API:createAutoModerationRule(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/auto-moderation/rules", guild_id),
	body = assert(body),
} end

function API:listAutoModerationRules(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/auto-moderation/rules", guild_id),
} end

function API:deleteAutoModerationRule(guild_id, rule_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/auto-moderation/rules/%s", guild_id, rule_id),
} end

function API:getAutoModerationRule(guild_id, rule_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/auto-moderation/rules/%s", guild_id, rule_id),
} end

function API:updateAutoModerationRule(guild_id, rule_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/auto-moderation/rules/%s", guild_id, rule_id),
	body = assert(body),
} end

function API:listGuildBans(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/bans", guild_id),
	query = query,
} end

function API:banUserFromGuild(guild_id, user_id, body) return self:request {
	method = "PUT",
	path = f("/guilds/%s/bans/%s", guild_id, user_id),
	body = assert(body),
} end

function API:getGuildBan(guild_id, user_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/bans/%s", guild_id, user_id),
} end

function API:unbanUserFromGuild(guild_id, user_id, body) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/bans/%s", guild_id, user_id),
	body = assert(body),
} end

function API:bulkBanUsersFromGuild(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/bulk-ban", guild_id),
	body = assert(body),
} end

function API:bulkUpdateGuildChannels(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/channels", guild_id),
	body = assert(body),
} end

function API:createGuildChannel(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/channels", guild_id),
	body = assert(body),
} end

function API:listGuildChannels(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/channels", guild_id),
} end

function API:createGuildEmoji(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/emojis", guild_id),
	body = assert(body),
} end

function API:listGuildEmojis(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/emojis", guild_id),
} end

function API:deleteGuildEmoji(guild_id, emoji_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/emojis/%s", guild_id, emoji_id),
} end

function API:getGuildEmoji(guild_id, emoji_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/emojis/%s", guild_id, emoji_id),
} end

function API:updateGuildEmoji(guild_id, emoji_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/emojis/%s", guild_id, emoji_id),
	body = assert(body),
} end

function API:updateGuildIncidentActions(guild_id, body) return self:request {
	method = "PUT",
	path = f("/guilds/%s/incident-actions", guild_id),
	body = assert(body),
} end

function API:listGuildIntegrations(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/integrations", guild_id),
} end

function API:deleteGuildIntegration(guild_id, integration_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/integrations/%s", guild_id, integration_id),
} end

function API:listGuildInvites(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/invites", guild_id),
} end

function API:listGuildMembers(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/members", guild_id),
	query = query,
} end

function API:updateMyGuildMember(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/members/@me", guild_id),
	body = assert(body),
} end

function API:searchGuildMembers(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/members/search", guild_id),
	query = query,
} end

function API:addGuildMember(guild_id, user_id, body) return self:request {
	method = "PUT",
	path = f("/guilds/%s/members/%s", guild_id, user_id),
	body = assert(body),
} end

function API:deleteGuildMember(guild_id, user_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/members/%s", guild_id, user_id),
} end

function API:getGuildMember(guild_id, user_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/members/%s", guild_id, user_id),
} end

function API:updateGuildMember(guild_id, user_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/members/%s", guild_id, user_id),
	body = assert(body),
} end

function API:addGuildMemberRole(guild_id, user_id, role_id) return self:request {
	method = "PUT",
	path = f("/guilds/%s/members/%s/roles/%s", guild_id, user_id, role_id),
} end

function API:deleteGuildMemberRole(guild_id, user_id, role_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/members/%s/roles/%s", guild_id, user_id, role_id),
} end

function API:guildSearch(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/messages/search", guild_id),
	query = query,
} end

function API:getGuildNewMemberWelcome(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/new-member-welcome", guild_id),
} end

function API:getGuildsOnboarding(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/onboarding", guild_id),
} end

function API:putGuildsOnboarding(guild_id, body) return self:request {
	method = "PUT",
	path = f("/guilds/%s/onboarding", guild_id),
	body = assert(body),
} end

function API:getGuildPreview(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/preview", guild_id),
} end

function API:previewPruneGuild(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/prune", guild_id),
	query = query,
} end

function API:pruneGuild(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/prune", guild_id),
	body = assert(body),
} end

function API:listGuildVoiceRegions(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/regions", guild_id),
} end

function API:getGuildJoinRequests(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/requests", guild_id),
	query = query,
} end

function API:actionGuildJoinRequest(guild_id, request_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/requests/%s", guild_id, request_id),
	body = assert(body),
} end

function API:bulkUpdateGuildRoles(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/roles", guild_id),
	body = assert(body),
} end

function API:createGuildRole(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/roles", guild_id),
	body = assert(body),
} end

function API:listGuildRoles(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/roles", guild_id),
} end

function API:guildRoleMemberCounts(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/roles/member-counts", guild_id),
} end

function API:deleteGuildRole(guild_id, role_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/roles/%s", guild_id, role_id),
} end

function API:getGuildRole(guild_id, role_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/roles/%s", guild_id, role_id),
} end

function API:updateGuildRole(guild_id, role_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/roles/%s", guild_id, role_id),
	body = assert(body),
} end

function API:createGuildScheduledEvent(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/scheduled-events", guild_id),
	body = assert(body),
} end

function API:listGuildScheduledEvents(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/scheduled-events", guild_id),
	query = query,
} end

function API:deleteGuildScheduledEvent(guild_id, guild_scheduled_event_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/scheduled-events/%s", guild_id, guild_scheduled_event_id),
} end

function API:getGuildScheduledEvent(guild_id, guild_scheduled_event_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/scheduled-events/%s", guild_id, guild_scheduled_event_id),
	query = query,
} end

function API:updateGuildScheduledEvent(guild_id, guild_scheduled_event_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/scheduled-events/%s", guild_id, guild_scheduled_event_id),
	body = assert(body),
} end

function API:createGuildScheduledEventException(guild_id, guild_scheduled_event_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/scheduled-events/%s/exceptions", guild_id, guild_scheduled_event_id),
	body = assert(body),
} end

function API:deleteGuildScheduledEventException(guild_id, guild_scheduled_event_id, exception_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/scheduled-events/%s/exceptions/%s", guild_id, guild_scheduled_event_id, exception_id),
} end

function API:updateGuildScheduledEventException(guild_id, guild_scheduled_event_id, exception_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/scheduled-events/%s/exceptions/%s", guild_id, guild_scheduled_event_id, exception_id),
	body = assert(body),
} end

function API:listGuildScheduledEventUsers(guild_id, guild_scheduled_event_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/scheduled-events/%s/users", guild_id, guild_scheduled_event_id),
	query = query,
} end

function API:countGuildScheduledEventUsers(guild_id, guild_scheduled_event_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/scheduled-events/%s/users/counts", guild_id, guild_scheduled_event_id),
	query = query,
} end

function API:listGuildScheduledEventExceptionUsers(guild_id, guild_scheduled_event_id, guild_scheduled_event_exception_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/scheduled-events/%s/%s/users", guild_id, guild_scheduled_event_id, guild_scheduled_event_exception_id),
	query = query,
} end

function API:createGuildSoundboardSound(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/soundboard-sounds", guild_id),
	body = assert(body),
} end

function API:listGuildSoundboardSounds(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/soundboard-sounds", guild_id),
} end

function API:deleteGuildSoundboardSound(guild_id, sound_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/soundboard-sounds/%s", guild_id, sound_id),
} end

function API:getGuildSoundboardSound(guild_id, sound_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/soundboard-sounds/%s", guild_id, sound_id),
} end

function API:updateGuildSoundboardSound(guild_id, sound_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/soundboard-sounds/%s", guild_id, sound_id),
	body = assert(body),
} end

function API:createGuildSticker(guild_id) return self:request {
	method = "POST",
	path = f("/guilds/%s/stickers", guild_id),
} end

function API:listGuildStickers(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/stickers", guild_id),
} end

function API:deleteGuildSticker(guild_id, sticker_id) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/stickers/%s", guild_id, sticker_id),
} end

function API:getGuildSticker(guild_id, sticker_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/stickers/%s", guild_id, sticker_id),
} end

function API:updateGuildSticker(guild_id, sticker_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/stickers/%s", guild_id, sticker_id),
	body = assert(body),
} end

function API:createGuildTemplate(guild_id, body) return self:request {
	method = "POST",
	path = f("/guilds/%s/templates", guild_id),
	body = assert(body),
} end

function API:listGuildTemplates(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/templates", guild_id),
} end

function API:deleteGuildTemplate(guild_id, code) return self:request {
	method = "DELETE",
	path = f("/guilds/%s/templates/%s", guild_id, code),
} end

function API:syncGuildTemplate(guild_id, code) return self:request {
	method = "PUT",
	path = f("/guilds/%s/templates/%s", guild_id, code),
} end

function API:updateGuildTemplate(guild_id, code, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/templates/%s", guild_id, code),
	body = assert(body),
} end

function API:getActiveGuildThreads(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/threads/active", guild_id),
} end

function API:getGuildVanityUrl(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/vanity-url", guild_id),
} end

function API:getSelfVoiceState(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/voice-states/@me", guild_id),
} end

function API:updateSelfVoiceState(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/voice-states/@me", guild_id),
	body = assert(body),
} end

function API:getVoiceState(guild_id, user_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/voice-states/%s", guild_id, user_id),
} end

function API:updateVoiceState(guild_id, user_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/voice-states/%s", guild_id, user_id),
	body = assert(body),
} end

function API:getGuildWebhooks(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/webhooks", guild_id),
} end

function API:getGuildWelcomeScreen(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/welcome-screen", guild_id),
} end

function API:updateGuildWelcomeScreen(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/welcome-screen", guild_id),
	body = assert(body),
} end

function API:getGuildWidgetSettings(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/widget", guild_id),
} end

function API:updateGuildWidgetSettings(guild_id, body) return self:request {
	method = "PATCH",
	path = f("/guilds/%s/widget", guild_id),
	body = assert(body),
} end

function API:getGuildWidget(guild_id) return self:request {
	method = "GET",
	path = f("/guilds/%s/widget.json", guild_id),
} end

function API:getGuildWidgetPng(guild_id, query) return self:request {
	method = "GET",
	path = f("/guilds/%s/widget.png", guild_id),
	query = query,
} end

function API:createInteractionResponse(interaction_id, interaction_token, body, query) return self:request {
	method = "POST",
	path = f("/interactions/%s/%s/callback", interaction_id, interaction_token),
	query = query,
	body = assert(body),
} end

function API:inviteResolve(code, query) return self:request {
	method = "GET",
	path = f("/invites/%s", code),
	query = query,
} end

function API:inviteRevoke(code) return self:request {
	method = "DELETE",
	path = f("/invites/%s", code),
} end

function API:getInviteTargetUsers(code) return self:request {
	method = "GET",
	path = f("/invites/%s/target-users", code),
} end

function API:updateInviteTargetUsers(code) return self:request {
	method = "PUT",
	path = f("/invites/%s/target-users", code),
} end

function API:getInviteTargetUsersJobStatus(code) return self:request {
	method = "GET",
	path = f("/invites/%s/target-users/job-status", code),
} end

function API:createLobby(body) return self:request {
	method = "POST",
	path = "/lobbies",
	body = assert(body),
} end

function API:createOrJoinLobby(body) return self:request {
	method = "PUT",
	path = "/lobbies",
	body = assert(body),
} end

function API:deleteLobby(lobby_id) return self:request {
	method = "DELETE",
	path = f("/lobbies/%s", lobby_id),
} end

function API:editLobby(lobby_id, body) return self:request {
	method = "PATCH",
	path = f("/lobbies/%s", lobby_id),
	body = assert(body),
} end

function API:getLobby(lobby_id) return self:request {
	method = "GET",
	path = f("/lobbies/%s", lobby_id),
} end

function API:editLobbyChannelLink(lobby_id, body) return self:request {
	method = "PATCH",
	path = f("/lobbies/%s/channel-linking", lobby_id),
	body = assert(body),
} end

function API:leaveLobby(lobby_id) return self:request {
	method = "DELETE",
	path = f("/lobbies/%s/members/@me", lobby_id),
} end

function API:createLinkedLobbyGuildInviteForSelf(lobby_id) return self:request {
	method = "POST",
	path = f("/lobbies/%s/members/@me/invites", lobby_id),
} end

function API:bulkUpdateLobbyMembers(lobby_id, body) return self:request {
	method = "POST",
	path = f("/lobbies/%s/members/bulk", lobby_id),
	body = assert(body),
} end

function API:addLobbyMember(lobby_id, user_id, body) return self:request {
	method = "PUT",
	path = f("/lobbies/%s/members/%s", lobby_id, user_id),
	body = assert(body),
} end

function API:deleteLobbyMember(lobby_id, user_id) return self:request {
	method = "DELETE",
	path = f("/lobbies/%s/members/%s", lobby_id, user_id),
} end

function API:createLinkedLobbyGuildInviteForUser(lobby_id, user_id) return self:request {
	method = "POST",
	path = f("/lobbies/%s/members/%s/invites", lobby_id, user_id),
} end

function API:createLobbyMessage(lobby_id, body) return self:request {
	method = "POST",
	path = f("/lobbies/%s/messages", lobby_id),
	body = assert(body),
} end

function API:getLobbyMessages(lobby_id, query) return self:request {
	method = "GET",
	path = f("/lobbies/%s/messages", lobby_id),
	query = query,
} end

function API:updateLobbyMessageExternalModerationMetadata(lobby_id, message_id, body) return self:request {
	method = "PUT",
	path = f("/lobbies/%s/messages/%s/moderation-metadata", lobby_id, message_id),
	body = assert(body),
} end

function API:getMyOauth2Authorization() return self:request {
	method = "GET",
	path = "/oauth2/@me",
} end

function API:getMyOauth2Application() return self:request {
	method = "GET",
	path = "/oauth2/applications/@me",
} end

function API:getPublicKeys() return self:request {
	method = "GET",
	path = "/oauth2/keys",
} end

function API:getOpenidConnectUserinfo() return self:request {
	method = "GET",
	path = "/oauth2/userinfo",
} end

function API:updateUserMessageExternalModerationMetadata(user_id_1, user_id_2, message_id, body) return self:request {
	method = "PUT",
	path = f("/partner-sdk/dms/%s/%s/messages/%s/moderation-metadata", user_id_1, user_id_2, message_id),
	body = assert(body),
} end

function API:partnerSdkUnmergeProvisionalAccount(body) return self:request {
	method = "POST",
	path = "/partner-sdk/provisional-accounts/unmerge",
	body = assert(body),
} end

function API:botPartnerSdkUnmergeProvisionalAccount(body) return self:request {
	method = "POST",
	path = "/partner-sdk/provisional-accounts/unmerge/bot",
	body = assert(body),
} end

function API:partnerSdkToken(body) return self:request {
	method = "POST",
	path = "/partner-sdk/token",
	body = assert(body),
} end

function API:botPartnerSdkToken(body) return self:request {
	method = "POST",
	path = "/partner-sdk/token/bot",
	body = assert(body),
} end

function API:getSkuSubscriptions(sku_id, query) return self:request {
	method = "GET",
	path = f("/skus/%s/subscriptions", sku_id),
	query = query,
} end

function API:getSkuSubscription(sku_id, subscription_id, query) return self:request {
	method = "GET",
	path = f("/skus/%s/subscriptions/%s", sku_id, subscription_id),
	query = query,
} end

function API:getSoundboardDefaultSounds() return self:request {
	method = "GET",
	path = "/soundboard-default-sounds",
} end

function API:createStageInstance(body) return self:request {
	method = "POST",
	path = "/stage-instances",
	body = assert(body),
} end

function API:deleteStageInstance(channel_id) return self:request {
	method = "DELETE",
	path = f("/stage-instances/%s", channel_id),
} end

function API:getStageInstance(channel_id) return self:request {
	method = "GET",
	path = f("/stage-instances/%s", channel_id),
} end

function API:updateStageInstance(channel_id, body) return self:request {
	method = "PATCH",
	path = f("/stage-instances/%s", channel_id),
	body = assert(body),
} end

function API:listStickerPacks() return self:request {
	method = "GET",
	path = "/sticker-packs",
} end

function API:getStickerPack(pack_id) return self:request {
	method = "GET",
	path = f("/sticker-packs/%s", pack_id),
} end

function API:getSticker(sticker_id) return self:request {
	method = "GET",
	path = f("/stickers/%s", sticker_id),
} end

function API:getMyUser() return self:request {
	method = "GET",
	path = "/users/@me",
} end

function API:updateMyUser(body) return self:request {
	method = "PATCH",
	path = "/users/@me",
	body = assert(body),
} end

function API:getCurrentUserApplicationEntitlements(application_id, query) return self:request {
	method = "GET",
	path = f("/users/@me/applications/%s/entitlements", application_id),
	query = query,
} end

function API:deleteApplicationUserRoleConnection(application_id) return self:request {
	method = "DELETE",
	path = f("/users/@me/applications/%s/role-connection", application_id),
} end

function API:getApplicationUserRoleConnection(application_id) return self:request {
	method = "GET",
	path = f("/users/@me/applications/%s/role-connection", application_id),
} end

function API:updateApplicationUserRoleConnection(application_id, body) return self:request {
	method = "PUT",
	path = f("/users/@me/applications/%s/role-connection", application_id),
	body = assert(body),
} end

function API:createDm(body) return self:request {
	method = "POST",
	path = "/users/@me/channels",
	body = assert(body),
} end

function API:listMyConnections() return self:request {
	method = "GET",
	path = "/users/@me/connections",
} end

function API:listMyGuilds(query) return self:request {
	method = "GET",
	path = "/users/@me/guilds",
	query = query,
} end

function API:leaveGuild(guild_id) return self:request {
	method = "DELETE",
	path = f("/users/@me/guilds/%s", guild_id),
} end

function API:getMyGuildMember(guild_id) return self:request {
	method = "GET",
	path = f("/users/@me/guilds/%s/member", guild_id),
} end

function API:getUser(user_id) return self:request {
	method = "GET",
	path = f("/users/%s", user_id),
} end

function API:listVoiceRegions() return self:request {
	method = "GET",
	path = "/voice/regions",
} end

function API:deleteWebhook(webhook_id) return self:request {
	method = "DELETE",
	path = f("/webhooks/%s", webhook_id),
} end

function API:getWebhook(webhook_id) return self:request {
	method = "GET",
	path = f("/webhooks/%s", webhook_id),
} end

function API:updateWebhook(webhook_id, body) return self:request {
	method = "PATCH",
	path = f("/webhooks/%s", webhook_id),
	body = assert(body),
} end

function API:deleteWebhookByToken(webhook_id, webhook_token) return self:request {
	method = "DELETE",
	path = f("/webhooks/%s/%s", webhook_id, webhook_token),
} end

function API:executeWebhook(webhook_id, webhook_token, body, query) return self:request {
	method = "POST",
	path = f("/webhooks/%s/%s", webhook_id, webhook_token),
	query = query,
	body = assert(body),
} end

function API:getWebhookByToken(webhook_id, webhook_token) return self:request {
	method = "GET",
	path = f("/webhooks/%s/%s", webhook_id, webhook_token),
} end

function API:updateWebhookByToken(webhook_id, webhook_token, body) return self:request {
	method = "PATCH",
	path = f("/webhooks/%s/%s", webhook_id, webhook_token),
	body = assert(body),
} end

function API:executeGithubCompatibleWebhook(webhook_id, webhook_token, body, query) return self:request {
	method = "POST",
	path = f("/webhooks/%s/%s/github", webhook_id, webhook_token),
	query = query,
	body = assert(body),
} end

function API:deleteOriginalWebhookMessage(webhook_id, webhook_token, query) return self:request {
	method = "DELETE",
	path = f("/webhooks/%s/%s/messages/@original", webhook_id, webhook_token),
	query = query,
} end

function API:getOriginalWebhookMessage(webhook_id, webhook_token, query) return self:request {
	method = "GET",
	path = f("/webhooks/%s/%s/messages/@original", webhook_id, webhook_token),
	query = query,
} end

function API:updateOriginalWebhookMessage(webhook_id, webhook_token, body, query) return self:request {
	method = "PATCH",
	path = f("/webhooks/%s/%s/messages/@original", webhook_id, webhook_token),
	query = query,
	body = assert(body),
} end

function API:deleteWebhookMessage(webhook_id, webhook_token, message_id, query) return self:request {
	method = "DELETE",
	path = f("/webhooks/%s/%s/messages/%s", webhook_id, webhook_token, message_id),
	query = query,
} end

function API:getWebhookMessage(webhook_id, webhook_token, message_id, query) return self:request {
	method = "GET",
	path = f("/webhooks/%s/%s/messages/%s", webhook_id, webhook_token, message_id),
	query = query,
} end

function API:updateWebhookMessage(webhook_id, webhook_token, message_id, body, query) return self:request {
	method = "PATCH",
	path = f("/webhooks/%s/%s/messages/%s", webhook_id, webhook_token, message_id),
	query = query,
	body = assert(body),
} end

function API:executeSlackCompatibleWebhook(webhook_id, webhook_token, body, query) return self:request {
	method = "POST",
	path = f("/webhooks/%s/%s/slack", webhook_id, webhook_token),
	query = query,
	body = assert(body),
} end

---- end generated code ----

return API