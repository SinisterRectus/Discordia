local function enum(tbl)
	local call = {}
	for k, v in pairs(tbl) do
		if call[v] then
			return error(string.format('enum clash for %q and %q', k, call[v]))
		end
		call[v] = k
	end
	return setmetatable({}, {
		__call = function(_, k)
			if call[k] then
				return call[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__index = function(_, k)
			if tbl[k] then
				return tbl[k]
			else
				return error('invalid enumeration: ' .. tostring(k))
			end
		end,
		__pairs = function()
			return next, tbl
		end,
		__newindex = function()
			return error('cannot overwrite enumeration')
		end,
	})
end

local enums = {enum = enum}

enums.defaultAvatar = enum {
	blurple = 0,
	gray    = 1,
	green   = 2,
	orange  = 3,
	red     = 4,
}

enums.notificationSetting = enum {
	allMessages  = 0,
	onlyMentions = 1,
}

enums.channelType = enum {
	text          = 0,
	private       = 1,
	voice         = 2,
	group         = 3,
	category      = 4,
	news          = 5,
	store         = 6,
	-- unused     = 7,
	-- unused     = 8,
	-- unused     = 9,
	newsThread    = 10,
	publicThread  = 11,
	privateThread = 12,
	stageVoice    = 13,
	directory     = 14,
	forum         = 15,
}

enums.webhookType = enum {
	incoming        = 1,
	channelFollower = 2,
	application     = 3,
}

enums.messageType = enum {
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
	chatInputCommand              = 20,
	threadStarterMessage          = 21,
	guildInviteReminder           = 22,
	contextMenuCommand            = 23,
	autoModerationAction          = 24,
	roleSubscriptionPurchase      = 25,
}

enums.relationshipType = enum {
	none            = 0,
	friend          = 1,
	blocked         = 2,
	pendingIncoming = 3,
	pendingOutgoing = 4,
}

enums.activityType = enum {
	default   = 0,
	streaming = 1,
	listening = 2,
	watching  = 3,
	custom    = 4,
	competing = 5,
}

enums.status = enum {
	online       = 'online',
	idle         = 'idle',
	doNotDisturb = 'dnd',
	invisible    = 'invisible', -- only sent?
	offline      = 'offline', -- only received?
}

enums.gameType = enum { -- NOTE: deprecated; use activityType
	default   = 0,
	streaming = 1,
	listening = 2,
	watching  = 3,
	custom    = 4,
	competing = 5,
}

enums.verificationLevel = enum {
	none     = 0,
	low      = 1,
	medium   = 2,
	high     = 3, -- (╯°□°）╯︵ ┻━┻
	veryHigh = 4, -- ┻━┻ ﾐヽ(ಠ益ಠ)ノ彡┻━┻
}

enums.explicitContentLevel = enum {
	none   = 0,
	medium = 1,
	high   = 2,
}

enums.premiumTier = enum {
	none  = 0,
	tier1 = 1,
	tier2 = 2,
	tier3 = 3,
}

local function flag(n)
	return 2^n
end

enums.permission = enum {
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
	readMessages        = flag(10),
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

enums.messageFlag = enum {
	crossposted          = flag(0),
	isCrosspost          = flag(1),
	suppressEmbeds       = flag(2),
	sourceMessageDeleted = flag(3),
	urgent               = flag(4),
	hasThread            = flag(5),
	ephemeral            = flag(6),
	loading              = flag(7),
}

enums.gatewayIntent = enum {
	guilds                = flag(0),
	guildMembers          = flag(1), -- privileged
	guildModeration       = flag(2),
	guildEmojis           = flag(3),
	guildIntegrations     = flag(4),
	guildWebhooks         = flag(5),
	guildInvites          = flag(6),
	guildVoiceStates      = flag(7),
	guildPresences        = flag(8), -- privileged
	guildMessages         = flag(9),
	guildMessageReactions = flag(10),
	guildMessageTyping    = flag(11),
	directMessage         = flag(12),
	directMessageRections = flag(13),
	directMessageTyping   = flag(14),
	messageContent        = flag(15), -- privileged
	guildScheduledEvents  = flag(16),
	-- unused             = flag(17),
	-- unused             = flag(18),
	-- unused             = flag(19),
	autoModConfiguration  = flag(20),
	autoModExecution      = flag(21),
}

enums.actionType = enum {
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
	stickerCreate          = 90,
	stickerUpdate          = 91,
	stickerDelete          = 92,
	eventCreate            = 100,
	eventUpdate            = 101,
	eventDelete            = 102,
	threadCreate           = 110,
	threadUpdate           = 111,
	threadDelete           = 112,
	autoModRuleCreate      = 140,
	autoModRuleUpdate      = 141,
	autoModRuleDelete      = 142,
	autoModMessageBlock    = 143,
	autoModMessageFlag     = 144,
	autoModUserTimeout     = 145,
}

enums.logLevel = enum {
	none    = 0,
	error   = 1,
	warning = 2,
	info    = 3,
	debug   = 4,
}

return enums
