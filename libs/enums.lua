local names = {}

local function enum(tbl)
	local call = {}
	for k, v in pairs(tbl) do
		if type(k) ~= 'string' then
			return error('enumeration name must be a string')
		end
		call[v] = k
	end
	return setmetatable({}, {
		__index = function(_, k)
			if not tbl[k] then
				return error('invalid enumeration name: ' .. tostring(k))
			end
			return tbl[k]
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
		__pairs = function()
			local k, v
			return function()
				k, v = next(tbl, k)
				return k, v
			end
		end,
		__call = function(_, v)
			local k = call[v]
			if not k then
				v = tostring(v)
				k = call[v]
			end
			if not k then
				return error('invalid enumeration value: ' .. tostring(v))
			end
			return k, v
		end,
		__tostring = function(self)
			return 'enumeration: ' .. names[self]
		end
	})
end

local enums = {}
local proxy = setmetatable({}, {
	__index = function(_, k)
		return enums[k]
	end,
	__newindex = function(_, k, v)
		if enums[k] then
			return error('cannot overwrite enumeration')
		end
		v = enum(v)
		names[v] = k
		enums[k] = v
	end,
	__pairs = function()
		local k, v
		return function()
			k, v = next(enums, k)
			return k, v
		end
	end,
})

proxy.defaultAvatar = {
	blurple = 0,
	gray    = 1,
	green   = 2,
	orange  = 3,
	red     = 4,
}

proxy.notificationSetting = {
	allMessages  = 0,
	onlyMentions = 1,
}

proxy.channelType = {
	text     = 0,
	private  = 1,
	voice    = 2,
	group    = 3,
	category = 4,
	news     = 5,
	store    = 6,
}

proxy.webhookType = {
	incoming        = 1,
	channelFollower = 2,
}

proxy.messageType = {
	default                       = 0,
	recipientAdd                  = 1,
	recipientRemove               = 2,
	call                          = 3,
	channelNameChange             = 4,
	channelIconchange             = 5,
	pinnedMessage                 = 6,
	memberJoin                    = 7,
	premiumGuildSubscription      = 8,
	premiumGuildSubscriptionTier1 = 9,
	premiumGuildSubscriptionTier2 = 10,
	premiumGuildSubscriptionTier3 = 11,
	channelFollowAdd              = 12,
	-- unused (guildStream)       = 13,
	guildDiscoveryDisqualified    = 14,
	guildDiscoveryRequalified     = 15,
	guildDiscoveryInitialWarning  = 16,
	guildDiscoveryFinalWarning    = 17,
	threadCreated                 = 18,
	reply                         = 19,
	applicationCommand            = 20,
	threadStarterMessage          = 21,
	guildInviteReminder           = 22,
}

proxy.permissionOverwriteType = {
	role   = 0,
	member = 1,
}

proxy.status = {
	online       = 'online',
	idle         = 'idle',
	dnd          = 'dnd',
	invisible    = 'invisible', -- only sent?
	offline      = 'offline', -- only received?
}

proxy.whence = {
	around = 'around',
	before = 'before',
	after  = 'after',
}

proxy.activityType = {
	playing   = 0,
	streaming = 1,
	listening = 2,
	watching  = 3,
	custom    = 4,
}

proxy.verificationLevel = {
	none     = 0,
	low      = 1,
	medium   = 2,
	high     = 3,
	veryHigh = 4,
}

proxy.explicitContentLevel = {
	none   = 0,
	medium = 1,
	high   = 2,
}

proxy.premiumTier = {
	none  = 0,
	tier1 = 1,
	tier2 = 2,
	tier3 = 3,
}

proxy.logLevel = {
	none     = 0,
	critical = 1,
	error    = 2,
	warning  = 3,
	info     = 4,
	debug    = 5,
}

proxy.premiumType = {
	none         = 0,
	nitroClassic = 1,
	nitro        = 2,
}

proxy.actionType = {
	guildUpdate            = 1,
	channelCreate          = 10,
	channelUpdate          = 11,
	channelDelete          = 12,
	channelOverwriteCreate = 13,
	channelOverwriteUpdate = 14,
	channelOverwriteDelete = 15,
	memberKick             = 20,
	memberPrune            = 21,
	memberBanAdd           = 22,
	memberBanRemove        = 23,
	memberUpdate           = 24,
	memberRoleUpdate       = 25,
	memberMove             = 26,
	memberDisconnect       = 27,
	botAdd                 = 28,
	roleCreate             = 30,
	roleUpdate             = 31,
	roleDelete             = 32,
	inviteCreate           = 40,
	inviteUpdate           = 41,
	inviteDelete           = 42,
	webhookCreate          = 50,
	webhookUpdate          = 51,
	webhookDelete          = 52,
	emojiCreate            = 60,
	emojiUpdate            = 61,
	emojiDelete            = 62,
	messageDelete          = 72,
	messageBulkDelete      = 73,
	messagePin             = 74,
	messageUnpin           = 75,
	integrationCreate      = 80,
	integrationUpdate      = 81,
	integrationDelete      = 82,
	stageInstanceCreate    = 83,
	stageInstanceUpdate    = 84,
	stageInstanceDelete    = 85,
}

local function flag(n)
	return tostring(bit.lshift(1ULL, n)):match('%d*')
end

proxy.permission = {
	createInstantInvite = flag(0),
	kickMembers         = flag(1),
	banMembers          = flag(2),
	administrator       = flag(3),
	manageChannels      = flag(4),
	manageGuild         = flag(5),
	addReactions        = flag(6),
	viewAuditLog        = flag(7),
	prioritySpeaker     = flag(8),
	stream              = flag(9),
	viewChannel         = flag(10),
	sendMessages        = flag(11),
	sendTextToSpeech    = flag(12),
	manageMessages      = flag(13),
	embedLinks          = flag(14),
	attachFiles         = flag(15),
	readMessageHistory  = flag(16),
	mentionEveryone     = flag(17),
	useExternalEmojis   = flag(18),
	viewGuildInsights   = flag(19),
	connect             = flag(20),
	speak               = flag(21),
	muteMembers         = flag(22),
	deafenMembers       = flag(23),
	moveMembers         = flag(24),
	useVoiceActivity    = flag(25),
	changeNickname      = flag(26),
	manageNicknames     = flag(27),
	manageRoles         = flag(28),
	manageWebhooks      = flag(29),
	manageEmojis        = flag(30),
	useSlashCommands    = flag(31),
	requestToSpeak      = flag(32),
	manageEvents        = flag(33),
	manageThreads       = flag(34),
	usePublicThreads    = flag(35),
	usePrivateThreads   = flag(36),
}

proxy.messageFlag = {
	crossposted          = flag(0),
	isCrosspost          = flag(1),
	suppressEmbeds       = flag(2),
	sourceMessageDeleted = flag(3),
	urgent               = flag(4),
}

proxy.gatewayIntent = {
	guilds                = flag(0),
	guildMembers          = flag(1),
	guildBans             = flag(2),
	guildEmojis           = flag(3),
	guildIntegrations     = flag(4),
	guildWebhooks         = flag(5),
	guildInvites          = flag(6),
	guildVoiceStates      = flag(7),
	guildPresences        = flag(8),
	guildMessages         = flag(9),
	guildMessageReactions = flag(10),
	guildMessageTyping    = flag(11),
	directMessage         = flag(12),
	directMessageRections = flag(13),
	directMessageTyping   = flag(14),
}

proxy.userFlag = {
	discordEmployee      = flag(0),
	discordPartner       = flag(1),
	hypesquadEvents      = flag(2),
	bugHunterLevel1      = flag(3),
	-- unused            = flag(4),
	-- unused            = flag(5),
	houseBravery         = flag(6),
	houseBrilliance      = flag(7),
	houseBalance         = flag(8),
	earlySupporter       = flag(9),
	teamUser             = flag(10),
	-- unused            = flag(11),
	system               = flag(12),
	-- unused            = flag(13),
	bugHunterLevel2      = flag(14),
	-- unused            = flag(15),
	verifiedBot          = flag(16),
	verifiedBotDeveloper = flag(17),
	certifiedModerator   = flag(18),
}

return proxy
