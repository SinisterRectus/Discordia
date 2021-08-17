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
	text     		 = 0,
	private 		 = 1,
	voice   		 = 2,
	group   		 = 3,
	category		 = 4,
	news    		 = 5,
	store 			 = 6,
	news_thread 	 = 10,
	public_thread 	 = 11,
	private_thread 	 = 12,
	stage 	 		 = 13,
}

enums.webhookType = enum {
	incoming        = 1,
	channelFollower = 2,
}

enums.messageType = enum {
	default                                 = 0,
	recipientAdd                            = 1,
	recipientRemove                         = 2,
	call                                    = 3,
	channelNameChange                       = 4,
	channelIconchange                       = 5,
	pinnedMessage                           = 6,
	memberJoin                              = 7,
	premiumGuildSubscription                = 8,
	premiumGuildSubscriptionTier1           = 9,
	premiumGuildSubscriptionTier2           = 10,
	premiumGuildSubscriptionTier3           = 11,
	followAdd                               = 12,
	guildDiscoveryDisqualified              = 14,
	guildDiscoveryRequalified               = 15,
	guildDiscoveryGracePeriodInitialWarning	= 16,
	guildDiscoveryGracePeriodFinalWarning   = 17,
	threadCreated                           = 18,
	reply                                   = 19,
	applicationCommand                      = 20,
	threadStarterMessage                    = 21,
	guildInviteReminder                     = 22,
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
	online = 'online',
	idle = 'idle',
	doNotDisturb = 'dnd',
	invisible = 'invisible',
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

enums.permission = enum {
	createInstantInvite = 0x0000000001,
	kickMembers         = 0x0000000002,
	banMembers          = 0x0000000004,
	administrator       = 0x0000000008,
	manageChannels      = 0x0000000010,
	manageGuild         = 0x0000000020,
	addReactions        = 0x0000000040,
	viewAuditLog        = 0x0000000080,
	prioritySpeaker     = 0x0000000100,
	stream              = 0x0000000200,
	readMessages        = 0x0000000400,
	sendMessages        = 0x0000000800,
	sendTextToSpeech    = 0x0000001000,
	manageMessages      = 0x0000002000,
	embedLinks          = 0x0000004000,
	attachFiles         = 0x0000008000,
	readMessageHistory  = 0x0000010000,
	mentionEveryone     = 0x0000020000,
	useExternalEmojis   = 0x0000040000,
	connect             = 0x0000100000,
	speak               = 0x0000200000,
	muteMembers         = 0x0000400000,
	deafenMembers       = 0x0000800000,
	moveMembers         = 0x0001000000,
	useVoiceActivity    = 0x0002000000,
	changeNickname      = 0x0004000000,
	manageNicknames     = 0x0008000000,
	manageRoles         = 0x0010000000,
	manageWebhooks      = 0x0020000000,
	manageEmojis        = 0x0040000000,
	useSlashCommands    = 0x0080000000,
	manageThreads       = 0x0400000000,
	requestToSpeak      = 0x0100000000,
	usePublicThreads    = 0x0800000000,
	usePrivateThreads   = 0x1000000000,
	useExternalStickers = 0x2000000000,
}

enums.messageFlag = enum {
	crossposted          = 0x00000001,
	isCrosspost          = 0x00000002,
	suppressEmbeds       = 0x00000004,
	sourceMessageDeleted = 0x00000008,
	urgent               = 0x00000010,
	hasThread            = 0x00000020,
	ephemeral            = 0x00000040,
	loading              = 0x00000080,
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
	stickerCreate          = 90,
	stickerUpdate          = 91,
	stickerDelete          = 92,
}

enums.logLevel = enum {
	none    = 0,
	error   = 1,
	warning = 2,
	info    = 3,
	debug   = 4,
}

return enums
