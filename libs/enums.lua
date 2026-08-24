local enums = {}

local function new(name, tbl)

	if enums[name] then
		return error('cannot overwrite enumeration')
	end

	local call = {}
	for k, v in pairs(tbl) do
		if type(k) ~= 'string' then
			return error('enumeration name must be a string')
		end
		call[v] = k
	end

	enums[name] = setmetatable({}, {
		__index = function(_, k)
			if tbl[k] == nil then
				return error(string.format('invalid enumeration name: %s', k))
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
			if tbl[v] ~= nil then
				return tbl[v]
			elseif call[v] ~= nil then
				return v
			else
				return error(string.format('invalid %s: %s', name, v))
			end
		end,
		__tostring = function()
			return 'enumeration: ' .. name
		end
	})

	return enums[name]

end

local function enum(name)
	return function(tbl)
		return new(name, tbl)
	end
end

enum 'timestampStyle' {
	shortTime     = 't',
	longTime      = 'T',
	shortDate     = 'd',
	longDate      = 'D',
	shortDateTime = 'f',
	longDateTime  = 'F',
	relativeTime  = 'R',
}

enum 'logLevel' {
	none     = 0,
	critical = 1,
	error    = 2,
	warning  = 3,
	info     = 4,
	debug    = 5,
}

---- begin generated code ----

enum "actionType" {
	typingStart = "TYPING_START", -- User started typing in a channel
	inviteCreate = "INVITE_CREATE", -- Invite to a channel was created
	inviteDelete = "INVITE_DELETE", -- Invite to a channel was deleted
	webhooksUpdate = "WEBHOOKS_UPDATE", -- Guild channel webhook was created, updated, or deleted
	channelCreate = "CHANNEL_CREATE", -- New guild channel created
	voiceChannelStatusUpdate = "VOICE_CHANNEL_STATUS_UPDATE", -- Voice channel status was updated
	channelUpdate = "CHANNEL_UPDATE", -- Channel was updated
	channelDelete = "CHANNEL_DELETE", -- Channel was deleted
	channelPinsUpdate = "CHANNEL_PINS_UPDATE", -- Message was pinned or unpinned
	threadCreate = "THREAD_CREATE", -- Thread created, also sent when being added to a private thread
	threadUpdate = "THREAD_UPDATE", -- Thread was updated
	threadDelete = "THREAD_DELETE", -- Thread was deleted
	threadListSync = "THREAD_LIST_SYNC", -- Sent when gaining access to a channel, contains all active threads in that channel
	threadMemberUpdate = "THREAD_MEMBER_UPDATE", -- Thread member for the current user was updated
	threadMembersUpdate = "THREAD_MEMBERS_UPDATE", -- Some user(s) were added to or removed from a thread
	guildCreate = "GUILD_CREATE", -- Lazy-load for unavailable guild, guild became available, or user joined a new guild
	guildUpdate = "GUILD_UPDATE", -- Guild was updated
	guildDelete = "GUILD_DELETE", -- Guild became unavailable, or user left/was removed from a guild
	guildEmojisUpdate = "GUILD_EMOJIS_UPDATE", -- Guild emojis were updated
	guildStickersUpdate = "GUILD_STICKERS_UPDATE", -- Guild stickers were updated
	guildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE", -- Guild integration was updated
	guildMemberAdd = "GUILD_MEMBER_ADD", -- New user joined a guild
	guildMemberUpdate = "GUILD_MEMBER_UPDATE", -- Guild member was updated
	guildMemberRemove = "GUILD_MEMBER_REMOVE", -- User was removed from a guild
	guildBanAdd = "GUILD_BAN_ADD", -- User was banned from a guild
	guildBanRemove = "GUILD_BAN_REMOVE", -- User was unbanned from a guild
	guildRoleCreate = "GUILD_ROLE_CREATE", -- Guild role was created
	guildRoleUpdate = "GUILD_ROLE_UPDATE", -- Guild role was updated
	guildRoleDelete = "GUILD_ROLE_DELETE", -- Guild role was deleted
	guildMembersChunk = "GUILD_MEMBERS_CHUNK", -- Response to Request Guild Members
	messageCreate = "MESSAGE_CREATE", -- Message was created
	messageUpdate = "MESSAGE_UPDATE", -- Message was edited
	messageDelete = "MESSAGE_DELETE", -- Message was deleted
	messageDeleteBulk = "MESSAGE_DELETE_BULK", -- Multiple messages were deleted at once
	messageReactionAdd = "MESSAGE_REACTION_ADD", -- User reacted to a message
	messageReactionRemove = "MESSAGE_REACTION_REMOVE", -- User removed a reaction from a message
	messageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL", -- All reactions were explicitly removed from a message
	messageReactionRemoveEmoji = "MESSAGE_REACTION_REMOVE_EMOJI", -- All reactions for a given emoji were explicitly removed from a message
	userUpdate = "USER_UPDATE", -- Properties about the user changed
	entitlementCreate = "ENTITLEMENT_CREATE", -- Entitlement was created
	entitlementUpdate = "ENTITLEMENT_UPDATE", -- Entitlement was updated
	entitlementDelete = "ENTITLEMENT_DELETE", -- Entitlement was deleted
	ready = "READY", -- Contains the initial state information
	resumed = "RESUMED", -- Response to Resume
	presenceUpdate = "PRESENCE_UPDATE", -- User was updated
	voiceStateUpdate = "VOICE_STATE_UPDATE", -- Someone joined, left, or moved a voice channel
	voiceServerUpdate = "VOICE_SERVER_UPDATE", -- Guild's voice server was updated
	lobbyMessageCreate = "LOBBY_MESSAGE_CREATE", -- Sent when a message is created in a lobby
	lobbyMessageUpdate = "LOBBY_MESSAGE_UPDATE", -- Sent when a message is updated in a lobby
	lobbyMessageDelete = "LOBBY_MESSAGE_DELETE", -- Sent when a message is deleted from a lobby
	gameDirectMessageCreate = "GAME_DIRECT_MESSAGE_CREATE", -- Sent when a direct message is created during an active Social SDK session
	gameDirectMessageDelete = "GAME_DIRECT_MESSAGE_DELETE", -- Sent when a direct message is deleted during an active Social SDK session
	gameDirectMessageUpdate = "GAME_DIRECT_MESSAGE_UPDATE", -- Sent when a direct message is updated during an active Social SDK session
	interactionCreate = "INTERACTION_CREATE", -- User used an interaction, such as an Application Command
	integrationCreate = "INTEGRATION_CREATE", -- Guild integration was created
	integrationUpdate = "INTEGRATION_UPDATE", -- Guild integration was updated
	integrationDelete = "INTEGRATION_DELETE", -- Guild integration was deleted
	applicationCommandPermissionsUpdate = "APPLICATION_COMMAND_PERMISSIONS_UPDATE", -- Application command permission was updated
	applicationAuthorized = "APPLICATION_AUTHORIZED", -- Sent when an app was authorized by a user to a server or their account
	applicationDeauthorized = "APPLICATION_DEAUTHORIZED", -- Sent when an app was deauthorized by a user
	stageInstanceCreate = "STAGE_INSTANCE_CREATE", -- Stage instance was created
	stageInstanceUpdate = "STAGE_INSTANCE_UPDATE", -- Stage instance was updated
	stageInstanceDelete = "STAGE_INSTANCE_DELETE", -- Stage instance was deleted or closed
	guildAuditLogEntryCreate = "GUILD_AUDIT_LOG_ENTRY_CREATE", -- A guild audit log entry was created
	guildScheduledEventCreate = "GUILD_SCHEDULED_EVENT_CREATE", -- Guild scheduled event was created
	guildScheduledEventUpdate = "GUILD_SCHEDULED_EVENT_UPDATE", -- Guild scheduled event was updated
	guildScheduledEventDelete = "GUILD_SCHEDULED_EVENT_DELETE", -- Guild scheduled event was deleted
	guildScheduledEventUserAdd = "GUILD_SCHEDULED_EVENT_USER_ADD", -- User subscribed to a guild scheduled event
	guildScheduledEventUserRemove = "GUILD_SCHEDULED_EVENT_USER_REMOVE", -- User unsubscribed from a guild scheduled event
	autoModerationRuleCreate = "AUTO_MODERATION_RULE_CREATE", -- Auto Moderation rule was created
	autoModerationRuleUpdate = "AUTO_MODERATION_RULE_UPDATE", -- Auto Moderation rule was updated
	autoModerationRuleDelete = "AUTO_MODERATION_RULE_DELETE", -- Auto Moderation rule was deleted
	autoModerationActionExecution = "AUTO_MODERATION_ACTION_EXECUTION", -- Auto Moderation rule was triggered and an action was executed (.e.g. a message was blocked)
	guildSoundboardSoundsUpdate = "GUILD_SOUNDBOARD_SOUNDS_UPDATE",
	guildSoundboardSoundCreate = "GUILD_SOUNDBOARD_SOUND_CREATE",
	guildSoundboardSoundUpdate = "GUILD_SOUNDBOARD_SOUND_UPDATE",
	guildSoundboardSoundDelete = "GUILD_SOUNDBOARD_SOUND_DELETE",
	questUserEnrollment = "QUEST_USER_ENROLLMENT", -- User was added to a Quest (currently unavailable)
	rateLimited = "RATE_LIMITED",
}

enum "activityActionType" {
	join = 1,
	spectate = 2,
	listen = 3,
	joinRequest = 5,
	streamRequest = 6,
}

enum "afkTimeout" {
	oneMinute = 60,
	fiveMinutes = 300,
	fifteenMinutes = 900,
	thirtyMinutes = 1800,
	oneHour = 3600,
}

enum "allowedMentionType" {
	users = "users", -- Controls role mentions
	roles = "roles", -- Controls user mentions
	everyone = "everyone", -- Controls @everyone and @here mentions
}

enum "applicationCommandHandler" {
	appHandler = 1, -- The app handles the interaction using an interaction token
	discordLaunchActivity = 2, -- Discord handles the interaction by launching an Activity and sending a follow-up message without coordinating with the app
}

enum "applicationCommandOptionType" {
	subCommand = 1, -- A sub-action within a command or group
	subCommandGroup = 2, -- A group of subcommands
	string = 3, -- A string option
	integer = 4, -- An integer option. Any integer between -2^53 and 2^53 is a valid value
	boolean = 5, -- A boolean option
	user = 6, -- A snowflake option that represents a User
	channel = 7, -- A snowflake option that represents a Channel. Includes all channel types and categories
	role = 8, -- A snowflake option that represents a Role
	mentionable = 9, -- A snowflake option that represents anything you can mention
	number = 10, -- A number option. Any double between -2^53 and 2^53 is a valid value
	attachment = 11, -- An attachment option
}

enum "applicationCommandPermissionType" {
	role = 1, -- This permission is for a role.
	user = 2, -- This permission is for a user.
	channel = 3, -- This permission is for a channel.
}

enum "applicationCommandType" {
	chat = 1, -- Slash commands; a text-based command that shows up when a user types /
	user = 2, -- A UI-based command that shows up when you right click or tap on a user
	message = 3, -- A UI-based command that shows up when you right click or tap on a message
	primaryEntryPoint = 4, -- A command that represents the primary way to use an application (e.g. launching an Activity)
}

enum "applicationEventWebhooksStatu" {
	disabled = 1, -- Webhook events are disabled by developer
	enabled = 2, -- Webhook events are enabled by developer
	disabledByDiscord = 3, -- Webhook events are disabled by Discord, usually due to inactivity
}

enum "applicationExplicitContentFilterType" {
	inherit = 0, -- inherit guild content filter setting
	always = 1, -- interactions will always be scanned
}

enum "applicationIdentityProviderAuthType" {
	oidc = "OIDC",
	epicOnlineServicesAccessToken = "EPIC_ONLINE_SERVICES_ACCESS_TOKEN",
	epicOnlineServicesIdToken = "EPIC_ONLINE_SERVICES_ID_TOKEN",
	steamSessionTicket = "STEAM_SESSION_TICKET",
	unityServicesIdToken = "UNITY_SERVICES_ID_TOKEN",
	discordBotIssuedAccessToken = "DISCORD_BOT_ISSUED_ACCESS_TOKEN",
	appleIdToken = "APPLE_ID_TOKEN",
	playstationNetworkIdToken = "PLAYSTATION_NETWORK_ID_TOKEN",
}

enum "applicationIntegrationType" {
	guildInstall = 0, -- For Guild install.
	userInstall = 1, -- For User install.
}

enum "applicationType" {
	guildRoleSubscriptions = 4,
}

enum "auditLogActionType" {
	guildUpdate = 1,
	channelCreate = 10,
	channelUpdate = 11,
	channelDelete = 12,
	channelOverwriteCreate = 13,
	channelOverwriteUpdate = 14,
	channelOverwriteDelete = 15,
	memberKick = 20,
	memberPrune = 21,
	memberBanAdd = 22,
	memberBanRemove = 23,
	memberUpdate = 24,
	memberRoleUpdate = 25,
	memberMove = 26,
	memberDisconnect = 27,
	botAdd = 28,
	roleCreate = 30,
	roleUpdate = 31,
	roleDelete = 32,
	inviteCreate = 40,
	inviteUpdate = 41,
	inviteDelete = 42,
	webhookCreate = 50,
	webhookUpdate = 51,
	webhookDelete = 52,
	emojiCreate = 60,
	emojiUpdate = 61,
	emojiDelete = 62,
	messageDelete = 72,
	messageBulkDelete = 73,
	messagePin = 74,
	messageUnpin = 75,
	integrationCreate = 80,
	integrationUpdate = 81,
	integrationDelete = 82,
	stageInstanceCreate = 83,
	stageInstanceUpdate = 84,
	stageInstanceDelete = 85,
	stickerCreate = 90,
	stickerUpdate = 91,
	stickerDelete = 92,
	guildScheduledEventCreate = 100,
	guildScheduledEventUpdate = 101,
	guildScheduledEventDelete = 102,
	threadCreate = 110,
	threadUpdate = 111,
	threadDelete = 112,
	applicationCommandPermissionUpdate = 121,
	soundboardSoundCreate = 130,
	soundboardSoundUpdate = 131,
	soundboardSoundDelete = 132,
	autoModerationRuleCreate = 140,
	autoModerationRuleUpdate = 141,
	autoModerationRuleDelete = 142,
	autoModerationBlockMessage = 143,
	autoModerationFlagToChannel = 144,
	autoModerationUserCommDisabled = 145,
	autoModerationQuarantineUser = 146,
	creatorMonetizationRequestCreated = 150,
	creatorMonetizationTermsAccepted = 151,
	onboardingPromptCreate = 163,
	onboardingPromptUpdate = 164,
	onboardingPromptDelete = 165,
	onboardingCreate = 166,
	onboardingUpdate = 167,
	guildHomeFeatureItem = 171,
	guildHomeRemoveItem = 172,
	harmfulLinksBlockedMessage = 180,
	homeSettingsCreate = 190,
	homeSettingsUpdate = 191,
	voiceChannelStatusCreate = 192,
	voiceChannelStatusDelete = 193,
	guildScheduledEventExceptionCreate = 200, -- Scheduled event exception was created
	guildScheduledEventExceptionUpdate = 201, -- Scheduled event exception was updated
	guildScheduledEventExceptionDelete = 202, -- Scheduled event exception was deleted
	guildProfileUpdate = 211,
}

enum "authorType" {
	user = "user",
	bot = "bot",
	webhook = "webhook",
	noUser = "-user",
	noBot = "-bot",
	noWebhook = "-webhook",
}

enum "automodActionType" {
	blockMessage = 1, -- Block a user's message and prevent it from being posted. A custom explanation can be specified and shown to members whenever their message is blocked
	flagToChannel = 2, -- Send a system message to a channel in order to log the user message that triggered the rule
	userCommunicationDisabled = 3, -- Temporarily disable a user's ability to communicate in the server (timeout)
	quarantineUser = 4, -- Prevent a user from interacting in the server
}

enum "automodEventType" {
	messageSend = 1, -- A user submitted a message to a channel
	guildMemberJoinOrUpdate = 2, -- A user is attempting to join the server or a member's properties were updated.
}

enum "automodKeywordPresetType" {
	profanity = 1, -- Words and phrases that may be considered profanity
	sexualContent = 2, -- Words and phrases that may be considered as sexual content
	slurs = 3, -- Words and phrases that may be considered slurs and hate speech
}

enum "automodTriggerType" {
	keyword = 1, -- Check if content contains words from a list of keywords or matches regex
	mlSpam = 3, -- Check if content represents generic spam
	defaultKeywordList = 4, -- Check if content contains words from internal pre-defined wordsets
	mentionSpam = 5, -- Check if content contains more unique mentions than allowed
	userProfile = 6, -- Check if user profile fields contains words from a list of keywords or matches regex
}

enum "availableLocalesEnum" {
	ar = "ar", -- The ar locale
	bg = "bg", -- The bg locale
	cs = "cs", -- The cs locale
	da = "da", -- The da locale
	de = "de", -- The de locale
	el = "el", -- The el locale
	["en-gb"] = "en-GB", -- The en-GB locale
	["en-us"] = "en-US", -- The en-US locale
	["es-419"] = "es-419", -- The es-419 locale
	["es-es"] = "es-ES", -- The es-ES locale
	fi = "fi", -- The fi locale
	fr = "fr", -- The fr locale
	he = "he", -- The he locale
	hi = "hi", -- The hi locale
	hr = "hr", -- The hr locale
	hu = "hu", -- The hu locale
	id = "id", -- The id locale
	it = "it", -- The it locale
	ja = "ja", -- The ja locale
	ko = "ko", -- The ko locale
	lt = "lt", -- The lt locale
	nl = "nl", -- The nl locale
	no = "no", -- The no locale
	pl = "pl", -- The pl locale
	["pt-br"] = "pt-BR", -- The pt-BR locale
	ro = "ro", -- The ro locale
	ru = "ru", -- The ru locale
	["sv-se"] = "sv-SE", -- The sv-SE locale
	th = "th", -- The th locale
	tr = "tr", -- The tr locale
	uk = "uk", -- The uk locale
	vi = "vi", -- The vi locale
	["zh-cn"] = "zh-CN", -- The zh-CN locale
	["zh-tw"] = "zh-TW", -- The zh-TW locale
}

enum "buttonStyleType" {
	primary = 1,
	secondary = 2,
	success = 3,
	danger = 4,
	link = 5,
	premium = 6,
}

enum "channelPermissionOverwrite" {
	role = 0,
	member = 1,
}

enum "channelType" {
	dm = 1, -- A direct message between users
	groupDm = 3, -- A direct message between multiple users
	guildText = 0, -- A text channel within a server
	guildVoice = 2, -- A voice channel within a server
	guildCategory = 4, -- An organizational category that contains up to 50 channels
	guildAnnouncement = 5, -- A channel that users can follow and crosspost into their own server (formerly news channels)
	announcementThread = 10, -- A temporary sub-channel within a GUILD_ANNOUNCEMENT channel
	publicThread = 11, -- A temporary sub-channel within a GUILD_TEXT or GUILD_THREADS_ONLY channel type set
	privateThread = 12, -- A temporary sub-channel within a GUILD_TEXT channel that is only viewable by those invited and those with the MANAGE_THREADS permission
	guildStageVoice = 13, -- A voice channel for hosting events with an audience
	guildDirectory = 14, -- The channel in a hub containing the listed servers
	guildForum = 15, -- Channel that can only contain threads
}

enum "connectedAccountProvider" {
	battlenet = "battlenet",
	bluesky = "bluesky",
	bungie = "bungie",
	ebay = "ebay",
	epicGames = "epicgames",
	facebook = "facebook",
	github = "github",
	instagram = "instagram",
	mastodon = "mastodon",
	leagueOfLegends = "leagueoflegends",
	paypal = "paypal",
	playstation = "playstation",
	reddit = "reddit",
	riotGames = "riotgames",
	roblox = "roblox",
	skype = "skype",
	spotify = "spotify",
	steam = "steam",
	tiktok = "tiktok",
	twitch = "twitch",
	twitter = "twitter",
	xbox = "xbox",
	youtube = "youtube",
	domain = "domain",
}

enum "connectedAccountVisibility" {
	none = 0,
	everyone = 1,
}

enum "embeddedActivityLocationKind" {
	guildChannel = "gc", -- guild channel
	privateChannel = "pc", -- private channel
	party = "party", -- party
}

enum "entitlementOwnerType" {
	guild = 1, -- A guild subscription
	user = 2, -- A user subscription
}

enum "entitlementTenantFulfillmentStatusResponse" {
	unknown = 0,
	fulfillmentNotNeeded = 1,
	fulfillmentNeeded = 2,
	fulfilled = 3,
	fulfillmentFailed = 4,
	unfulfillmentNeeded = 5,
	unfulfilled = 6,
	unfulfillmentFailed = 7,
}

enum "entitlementType" {
	applicationSubscription = 8,
	questReward = 10,
}

enum "forumLayout" {
	default = 0, -- No default has been set for forum channel
	list = 1, -- Display posts as a list
	grid = 2, -- Display posts as a collection of tiles
}

enum "guildExplicitContentFilterType" {
	disabled = 0, -- media content will not be scanned
	membersWithoutRoles = 1, -- media content sent by members without roles will be scanned
	allMembers = 2, -- media content sent by all members will be scanned
}

enum "guildFeature" {
	animatedBanner = "ANIMATED_BANNER", -- guild has access to set an animated guild banner image
	animatedIcon = "ANIMATED_ICON", -- guild has access to set an animated guild icon
	applicationCommandPermissionsV2 = "APPLICATION_COMMAND_PERMISSIONS_V2", -- guild is using the old permissions configuration behavior
	autoModeration = "AUTO_MODERATION", -- guild has set up auto moderation rules
	banner = "BANNER", -- guild has access to set a guild banner image
	community = "COMMUNITY", -- guild can enable welcome screen, Membership Screening, stage channels and discovery, and             receives community updates
	creatorMonetizableProvisional = "CREATOR_MONETIZABLE_PROVISIONAL", -- guild has enabled monetization
	creatorStorePage = "CREATOR_STORE_PAGE", -- guild has enabled the role subscription promo page
	developerSupportServer = "DEVELOPER_SUPPORT_SERVER", -- guild has been set as a support server on the App Directory
	discoverable = "DISCOVERABLE", -- guild is able to be discovered in the directory
	featurable = "FEATURABLE", -- guild is able to be featured in the directory
	invitesDisabled = "INVITES_DISABLED", -- guild has paused invites, preventing new users from joining
	inviteSplash = "INVITE_SPLASH", -- guild has access to set an invite splash background
	memberVerificationGateEnabled = "MEMBER_VERIFICATION_GATE_ENABLED", -- guild has enabled Membership Screening
	moreStickers = "MORE_STICKERS", -- guild has increased custom sticker slots
	news = "NEWS", -- guild has access to create announcement channels
	partnered = "PARTNERED", -- guild is partnered
	previewEnabled = "PREVIEW_ENABLED", -- guild can be previewed before joining via Membership Screening or the directory
	raidAlertsDisabled = "RAID_ALERTS_DISABLED", -- guild has disabled activity alerts in the configured safety alerts channel
	pruneRequiresAdmin = "PRUNE_REQUIRES_ADMIN", -- guild has restricted member prune to administrators and the guild owner
	roleIcons = "ROLE_ICONS", -- guild is able to set role icons
	roleSubscriptionsAvailableForPurchase = "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE", -- guild has role subscriptions that can be purchased
	roleSubscriptionsEnabled = "ROLE_SUBSCRIPTIONS_ENABLED", -- guild has enabled role subscriptions
	ticketedEventsEnabled = "TICKETED_EVENTS_ENABLED", -- guild has enabled ticketed events
	vanityUrl = "VANITY_URL", -- guild has access to set a vanity URL
	verified = "VERIFIED", -- guild is verified
	vipRegions = "VIP_REGIONS", -- guild has access to set 384kbps bitrate in voice (previously VIP voice servers)
	welcomeScreenEnabled = "WELCOME_SCREEN_ENABLED", -- guild has enabled the welcome screen
	officialGameGuild = "OFFICIAL_GAME_GUILD", -- guild is an official guild for one or more games
}

enum "guildJoinRequestApplicationStatu" {
	started = "STARTED", -- Applicant started but not yet submitted join request
	submitted = "SUBMITTED", -- Applicant submitted join request that is awaiting review
	rejected = "REJECTED", -- Join request rejected
	approved = "APPROVED", -- Join request approved
}

enum "guildMFALevel" {
	none = 0, -- Guild has no MFA/2FA requirement for moderation actions
	elevated = 1, -- Guild has a 2FA requirement for moderation actions
}

enum "guildMemberVerificationFormFieldType" {
	terms = "TERMS", -- Field requiring applicant to acknowledge list of terms
	textInput = "TEXT_INPUT", -- Short text input field
	paragraph = "PARAGRAPH", -- Long-form text input field
	multipleChoice = "MULTIPLE_CHOICE", -- Field where applicant selects one of many options
}

enum "guildNSFWContentLevel" {
	default = 0,
	explicit = 1,
	safe = 2,
	ageRestricted = 3,
}

enum "guildOnboardingMode" {
	onboardingDefault = 0, -- Only Default Channels considered in constraints
	onboardingAdvanced = 1, -- Default Channels and Onboarding Prompts considered in constraints
}

enum "guildScheduledEventEntityType" {
	none = 0,
	stageInstance = 1,
	voice = 2,
	external = 3,
}

enum "guildScheduledEventPrivacyLevel" {
	guildOnly = 2, -- the scheduled event is only accessible to guild members
}

enum "guildScheduledEventStatuse" {
	scheduled = 1,
	active = 2,
	completed = 3,
	canceled = 4,
}

enum "guildScheduledEventUserResponse" {
	uninterested = 0, -- User is not interested in the event
	interested = 1, -- User is interested in the event
}

enum "hasOption" {
	link = "link",
	embed = "embed",
	file = "file",
	image = "image",
	video = "video",
	sound = "sound",
	sticker = "sticker",
	poll = "poll",
	snapshot = "snapshot",
	noLink = "-link",
	noEmbed = "-embed",
	noFile = "-file",
	noImage = "-image",
	noVideo = "-video",
	noSound = "-sound",
	noSticker = "-sticker",
	noPoll = "-poll",
	noSnapshot = "-snapshot",
}

enum "integrationExpireBehaviorType" {
	removeRole = 0, -- Remove role
	kick = 1, -- Kick
}

enum "integrationExpireGracePeriodType" {
	oneDay = 1, -- 1 day
	threeDays = 3, -- 3 days
	sevenDays = 7, -- 7 days
	fourteenDays = 14, -- 14 days
	thirtyDays = 30, -- 30 days
}

enum "integrationType" {
	discord = "discord",
	twitch = "twitch",
	youtube = "youtube",
	guildSubscription = "guild_subscription",
}

enum "interactionCallbackType" {
	pong = 1,
	channelMessageWithSource = 4,
	deferredChannelMessageWithSource = 5,
	deferredUpdateMessage = 6,
	updateMessage = 7,
	applicationCommandAutocompleteResult = 8,
	modal = 9,
	launchActivity = 12,
	socialLayerSkuPurchaseEligibility = 13,
}

enum "interactionContextType" {
	guild = 0, -- This command can be used within a Guild.
	botDm = 1, -- This command can be used within a DM with this application's bot.
	privateChannel = 2, -- This command can be used within DMs and Group DMs with users.
}

enum "interactionType" {
	ping = 1, -- Sent by Discord to validate your application's interaction handler
	applicationCommand = 2, -- Sent when a user uses an application command
	messageComponent = 3, -- Sent when a user interacts with a message component previously sent by your application
	applicationCommandAutocomplete = 4, -- Sent when a user is filling in an autocomplete option in a chat command
	modalSubmit = 5, -- Sent when a user submits a modal previously sent by your application
	socialLayerSkuPurchaseEligibility = 6, -- Sent when Discord is checking if a user can purchase a Social Layer SKU
}

enum "inviteTargetType" {
	stream = 1,
	embeddedApplication = 2,
	roleSubscriptionsPurchase = 3,
}

enum "inviteType" {
	guild = 0,
	groupDm = 1,
	friend = 2,
}

enum "messageComponentSeparatorSpacingSize" {
	small = 1, -- Small spacing
	large = 2, -- Large spacing
}

enum "messageComponentType" {
	actionRow = 1, -- Container for other components
	button = 2, -- Button object
	stringSelect = 3, -- Select menu for picking from defined text options
	textInput = 4, -- Text input object
	userSelect = 5, -- Select menu for users
	roleSelect = 6, -- Select menu for roles
	mentionableSelect = 7, -- Select menu for mentionables (users and roles)
	channelSelect = 8, -- Select menu for channels
	section = 9, -- Section component
	textDisplay = 10, -- Text component
	thumbnail = 11, -- Thumbnail component
	mediaGallery = 12, -- Media gallery component
	file = 13, -- File component
	separator = 14, -- Separator component
	container = 17, -- Container component
	label = 18, -- Label component
	fileUpload = 19, -- File upload component
	radioGroup = 21, -- Radio group component
	checkboxGroup = 22, -- Checkbox group component
	checkbox = 23, -- Checkbox component
}

enum "messageReferenceType" {
	default = 0, -- Reference to a message
}

enum "messageShareCustomUserThemeBaseTheme" {
	unset = 0, -- No base theme
	dark = 1, -- Dark base theme
	light = 2, -- Light base theme
	darker = 3, -- Darker base theme
	midnight = 4, -- Midnight base theme
}

enum "messageType" {
	default = 0,
	recipientAdd = 1,
	recipientRemove = 2,
	call = 3,
	channelNameChange = 4,
	channelIconChange = 5,
	channelPinnedMessage = 6,
	userJoin = 7,
	guildBoost = 8,
	guildBoostTier1 = 9,
	guildBoostTier2 = 10,
	guildBoostTier3 = 11,
	channelFollowAdd = 12,
	guildDiscoveryDisqualified = 14,
	guildDiscoveryRequalified = 15,
	guildDiscoveryGracePeriodInitialWarning = 16,
	guildDiscoveryGracePeriodFinalWarning = 17,
	threadCreated = 18,
	reply = 19,
	chatInputCommand = 20,
	threadStarterMessage = 21,
	guildInviteReminder = 22,
	contextMenuCommand = 23,
	autoModerationAction = 24,
	roleSubscriptionPurchase = 25,
	interactionPremiumUpsell = 26,
	stageStart = 27,
	stageEnd = 28,
	stageSpeaker = 29,
	stageTopic = 31,
	guildApplicationPremiumSubscription = 32,
	guildIncidentAlertModeEnabled = 36,
	guildIncidentAlertModeDisabled = 37,
	guildIncidentReportRaid = 38,
	guildIncidentReportFalseAlarm = 39,
	pollResult = 46,
	hdStreamingUpgraded = 55,
}

enum "metadataItemType" {
	integerLessThanEqual = 1, -- the metadata value (integer) is less than or equal to the guild's configured value (integer)
	integerGreaterThanEqual = 2, -- the metadata value (integer) is greater than or equal to the guild's configured value (integer)
	integerEqual = 3, -- the metadata value (integer) is equal to the guild's configured value (integer)
	integerNotEqual = 4, -- the metadata value (integer) is not equal to the guild's configured value (integer)
	datetimeLessThanEqual = 5, -- the metadata value (ISO8601 string) is less than or equal to the guild's configured value (integer; days before current date)
	datetimeGreaterThanEqual = 6, -- the metadata value (ISO8601 string) is greater than or equal to the guild's configured value (integer; days before current date)
	booleanEqual = 7, -- the metadata value (integer) is equal to the guild's configured value (integer; 1)
	booleanNotEqual = 8, -- the metadata value (integer) is not equal to the guild's configured value (integer; 1)
}

enum "nameplatePalette" {
	crimson = "crimson", -- Crimson color palette
	berry = "berry", -- Berry color palette
	sky = "sky", -- Sky color palette
	teal = "teal", -- Teal color palette
	forest = "forest", -- Forest color palette
	bubbleGum = "bubble_gum", -- Bubble gum color palette
	violet = "violet", -- Violet color palette
	cobalt = "cobalt", -- Cobalt color palette
	clover = "clover", -- Clover color palette
	lemon = "lemon", -- Lemon color palette
	white = "white", -- White color palette
	black = "black", -- Black color palette
}

enum "newMemberActionType" {
	view = 0,
	talk = 1,
}

enum "oAuth2Scope" {
	identify = "identify", -- allows /users/@me without email
	email = "email", -- enables /users/@me to return an email
	connections = "connections", -- allows /users/@me/connections to return linked third-party accounts
	guilds = "guilds", -- allows /users/@me/guilds to return basic information about all of a user's guilds
	guildsJoin = "guilds.join", -- allows /guilds/{guild.id}/members/{user.id} to be used for joining users to a guild
	guildsMembersRead = "guilds.members.read", -- allows /users/@me/guilds/{guild.id}/member to return a user's member information in a guild
	gdmJoin = "gdm.join", -- allows your app to join users to a group dm
	bot = "bot", -- for oauth2 bots, this puts the bot in the user's selected guild by default
	rpc = "rpc", -- for local rpc server access, this allows you to control a user's local Discord client - requires Discord approval
	rpcNotificationsRead = "rpc.notifications.read", -- for local rpc server access, this allows you to receive notifications pushed out to the user - requires Discord approval
	rpcVoiceRead = "rpc.voice.read", -- for local rpc server access, this allows you to read a user's voice settings and listen for voice events - requires Discord approval
	rpcVoiceWrite = "rpc.voice.write", -- for local rpc server access, this allows you to update a user's voice settings - requires Discord approval
	rpcVideoRead = "rpc.video.read", -- for local rpc server access, this allows you to read a user's video status - requires Discord approval
	rpcVideoWrite = "rpc.video.write", -- for local rpc server access, this allows you to update a user's video settings - requires Discord approval
	rpcScreenshareRead = "rpc.screenshare.read", -- for local rpc server access, this allows you to read a user's screenshare status- requires Discord approval
	rpcScreenshareWrite = "rpc.screenshare.write", -- for local rpc server access, this allows you to update a user's screenshare settings- requires Discord approval
	rpcActivitiesWrite = "rpc.activities.write", -- for local rpc server access, this allows you to update a user's activity - requires Discord approval
	webhookIncoming = "webhook.incoming", -- this generates a webhook that is returned in the oauth token response for authorization code grants
	messagesRead = "messages.read", -- for local rpc server api access, this allows you to read messages from all client channels (otherwise restricted to channels/guilds your app creates)
	applicationsBuildsUpload = "applications.builds.upload", -- allows your app to upload/update builds for a user's applications - requires Discord approval
	applicationsBuildsRead = "applications.builds.read", -- allows your app to read build data for a user's applications
	applicationsCommands = "applications.commands", -- allows your app to use commands in a guild
	applicationsCommandsPermissionsUpdate = "applications.commands.permissions.update", -- allows your app to update permissions for its commands in a guild a user has permissions to
	applicationsCommandsUpdate = "applications.commands.update", -- allows your app to update its commands using a Bearer token - client credentials grant only
	applicationsStoreUpdate = "applications.store.update", -- allows your app to read and update store data (SKUs, store listings, achievements, etc.) for a user's applications
	applicationsEntitlements = "applications.entitlements", -- allows your app to read entitlements for a user's applications
	activitiesRead = "activities.read", -- allows your app to fetch data from a user's "Now Playing/Recently Played" list - requires Discord approval
	activitiesWrite = "activities.write", -- allows your app to update a user's activity - requires Discord approval (NOT REQUIRED FOR GAMESDK ACTIVITY MANAGER)
	activitiesInvitesWrite = "activities.invites.write", -- allows your app to send activity invites - requires Discord approval (NOT REQUIRED FOR GAMESDK ACTIVITY MANAGER)
	relationshipsRead = "relationships.read", -- allows your app to know a user's friends and implicit relationships - requires Discord approval
	voice = "voice", -- allows your app to connect to voice on user's behalf and see all the voice members - requires Discord approval
	dmChannelsRead = "dm_channels.read", -- allows your app to see information about the user's DMs and group DMs - requires Discord approval
	roleConnectionsWrite = "role_connections.write", -- allows your app to update a user's connection and metadata for the app
	openid = "openid", -- for OpenID Connect, this allows your app to receive user id and basic profile information
}

enum "onboardingPromptType" {
	multipleChoice = 0, -- Multiple choice options
	dropdown = 1, -- Many options shown as a dropdown
}

enum "pollLayoutType" {
	default = 1, -- The, uhm, default layout type.
}

enum "premiumGuildTier" {
	none = 0, -- Guild has not unlocked any Server Boost perks
	tier1 = 1, -- Guild has unlocked Server Boost level 1 perks
	tier2 = 2, -- Guild has unlocked Server Boost level 2 perks
	tier3 = 3, -- Guild has unlocked Server Boost level 3 perks
}

enum "premiumType" {
	none = 0, -- None
	tier1 = 1, -- Nitro Classic
	tier2 = 2, -- Nitro Standard
	tier0 = 3, -- Nitro Basic
}

enum "purchaseType" {
	guildProduct = 0,
}

enum "reactionType" {
	normal = 0, -- Normal reaction type
	burst = 1, -- Burst reaction type
}

enum "recurrenceRuleFrequency" {
	daily = 3,
	weekly = 2,
	monthly = 1,
	yearly = 0,
}

enum "recurrenceRuleMonth" {
	january = 1,
	february = 2,
	march = 3,
	april = 4,
	may = 5,
	june = 6,
	july = 7,
	august = 8,
	september = 9,
	october = 10,
	november = 11,
	december = 12,
}

enum "recurrenceRuleWeekday" {
	monday = 0,
	tuesday = 1,
	wednesday = 2,
	thursday = 3,
	friday = 4,
	saturday = 5,
	sunday = 6,
}

enum "sKUIneligibilityReason" {
	other = 0, -- Other / catch-all
	ownsSkuOrBundleComponent = 1, -- User already owns this SKU or one of its components
	platformRestriction = 2, -- User account is not on an eligible platform
}

enum "searchableEmbedType" {
	image = "image",
	video = "video",
	gifv = "gif",
	sound = "sound",
	article = "article",
}

enum "snowflakeSelectDefaultValueType" {
	user = "user",
	role = "role",
	channel = "channel",
}

enum "sortingMode" {
	relevance = "relevance",
	timestamp = "timestamp",
}

enum "sortingOrder" {
	asc = "asc",
	desc = "desc",
}

enum "stageInstancesPrivacyLevel" {
	public = 1, -- The Stage instance is visible publicly. (deprecated)
	guildOnly = 2, -- The Stage instance is visible to only guild members.
}

enum "stickerFormatType" {
	png = 1,
	apng = 2,
	lottie = 3,
	gif = 4,
}

enum "stickerType" {
	standard = 1, -- an official sticker in a pack, part of Nitro or in a removed purchasable pack
	guild = 2, -- a sticker uploaded to a guild for the guild's members
}

enum "subscriptionResponseStatusType" {
	active = 0, -- Subscription is active and scheduled to renew
	inactive = 1, -- Subscription is inactive and not being charged
	ending = 2, -- Subscription is active but will not renew
}

enum "targetUsersJobStatusType" {
	unspecified = 0, -- The default value.
	processing = 1, -- The job is still being processed.
	completed = 2, -- The job has been completed successfully.
	failed = 3, -- The job has failed, see error_message field for more details.
}

enum "teamMemberRole" {
	admin = "admin", -- Admins have similar access as owners, except they cannot take destructive actions on the team or team-owned apps.
	developer = "developer", -- Developers can access information about team-owned apps, like the client secret or public key. They can also take limited actions on team-owned apps, like configuring interaction endpoints or resetting the bot token. Members with the Developer role cannot manage the team or its members, or take destructive actions on team-owned apps.
	readOnly = "read_only", -- Read-only members can access information about a team and any team-owned apps. Some examples include getting the IDs of applications and exporting payout records. Members can also invite bots associated with team-owned apps that are marked private.
}

enum "teamMembershipState" {
	invited = 1, -- User has been invited to the team.
	accepted = 2, -- User has accepted the team invitation.
}

enum "textInputStyleType" {
	short = 1, -- Single-line input
	paragraph = 2, -- Multi-line input
}

enum "threadAutoArchiveDuration" {
	oneHour = 60, -- One hour
	oneDay = 1440, -- One day
	threeDay = 4320, -- Three days
	sevenDay = 10080, -- Seven days
}

enum "threadSearchTagSetting" {
	matchAll = "match_all", -- The thread tags must contain all tags in the search query
	matchSome = "match_some", -- The thread tags must contain at least one of tags in the search query
}

enum "threadSortOrder" {
	latestActivity = 0, -- Sort forum posts by activity
	creationDate = 1, -- Sort forum posts by creation time (from most recent to oldest)
}

enum "threadSortingMode" {
	relevance = "relevance",
	creationTime = "creation_time",
	lastMessageTime = "last_message_time",
	archiveTime = "archive_time",
}

enum "userNotificationSetting" {
	allMessages = 0, -- members will receive notifications for all messages by default
	onlyMentions = 1, -- members will receive notifications only for messages that @mention them by default
}

enum "verificationLevel" {
	none = 0, -- unrestricted
	low = 1, -- must have verified email on account
	medium = 2, -- must be registered on Discord for longer than 5 minutes
	high = 3, -- must be a member of the server for longer than 10 minutes
	veryHigh = 4, -- must have a verified phone number
}

enum "videoQualityMode" {
	auto = 1, -- Discord chooses the quality for optimal performance
	full = 2, -- 720p
}

enum "webhookType" {
	guildIncoming = 1, -- Incoming Webhooks can post messages to channels with a generated token
	channelFollower = 2, -- Channel Follower Webhooks are internal webhooks used with Channel Following to post new messages into channels
	applicationIncoming = 3, -- Application webhooks are webhooks used with Interactions
}

enum "widgetImageStyle" {
	shield = "shield", -- shield style widget with Discord icon and guild members online count
	banner1 = "banner1", -- large image with guild icon, name and online count. "POWERED BY DISCORD" as the footer of the widget
	banner2 = "banner2", -- smaller widget style with guild icon, name and online count. Split on the right with Discord logo
	banner3 = "banner3", -- large image with guild icon, name and online count. In the footer, Discord logo on the left and "Chat Now" on the right
	banner4 = "banner4", -- large Discord logo at the top of the widget. Guild icon, name and online count in the middle portion of the widget and a "JOIN MY SERVER" button at the bottom
}

enum "widgetUserDiscriminator" {
	zeroes = "0000",
}

---- end generated code ----

return setmetatable({}, {
	__index = enums,
	__pairs = function()
		local k, v
		return function()
			k, v = next(enums, k)
			return k, v
		end
	end,
})