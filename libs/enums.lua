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
	text     = 0,
	private  = 1,
	voice    = 2,
	group    = 3,
	category = 4,
	news     = 5,
}

enums.webhookType = enum {
	incoming        = 1,
	channelFollower = 2,
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
	custom    = 4,
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
	custom    = 4,
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
	createInstantInvite = 0x00000001,
	kickMembers         = 0x00000002,
	banMembers          = 0x00000004,
	administrator       = 0x00000008,
	manageChannels      = 0x00000010,
	manageGuild         = 0x00000020,
	addReactions        = 0x00000040,
	viewAuditLog        = 0x00000080,
	prioritySpeaker     = 0x00000100,
	stream              = 0x00000200,
	readMessages        = 0x00000400,
	sendMessages        = 0x00000800,
	sendTextToSpeech    = 0x00001000,
	manageMessages      = 0x00002000,
	embedLinks          = 0x00004000,
	attachFiles         = 0x00008000,
	readMessageHistory  = 0x00010000,
	mentionEveryone     = 0x00020000,
	useExternalEmojis   = 0x00040000,
	connect             = 0x00100000,
	speak               = 0x00200000,
	muteMembers         = 0x00400000,
	deafenMembers       = 0x00800000,
	moveMembers         = 0x01000000,
	useVoiceActivity    = 0x02000000,
	changeNickname      = 0x04000000,
	manageNicknames     = 0x08000000,
	manageRoles         = 0x10000000,
	manageWebhooks      = 0x20000000,
	manageEmojis        = 0x40000000,
}

enums.messageFlag = enum {
	crossposted          = 0x00000001,
	isCrosspost          = 0x00000002,
	suppressEmbeds       = 0x00000004,
	sourceMessageDeleted = 0x00000008,
	urgent               = 0x00000010,
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
}

enums.logLevel = enum {
	none    = 0,
	error   = 1,
	warning = 2,
	info    = 3,
	debug   = 4,
}

return enums
