# Changelog

## 3.0.0-dev (subject to change)

### General

#### Enhancements

- Added support for gateway intents ("guilds" intent is required)
- Added support for slash commands
- Added support for application teams
- Added support for guild templates, welcome screens, and previews
- Added support for stage instances
- Improved support for message replies and allowed mentions
- Added client statistics (latency, uptime, etc)
- Loggers, including the client's default logger, can now be configured at runtime (you can toggle the colors, too)
- Most previously raw tables are now available as rich classes or structs
- Added many direct client methods (e.g. `client:createMessage(channelId, ...)` can be used as an alternative to `channel:send(...)`, which uses the former internally)
- In addition to the methods above, added "modify" methods for batch-patching objects (e.g. `channel:modify(payload)`)
- Added dynamic type checking and resolution to user-facing methods
- Updated to Discord gateway v8
- Updated to Discord REST API v8
- Events no longer depend on cached data; they only give you what Discord provides
- Gateway loop logic was re-written to (hopefully) be more robust
- Bot tokens do not need to be manually prefixed anymore, but a `tokenPrefix` client option exists for optional configuration
- Disconnecting a bot with `client:stop()` now correctly closes the connection (finally)
- Bots now gracefully disconnect on interrupt (SIGINT)
- Gateway information is not cached to disk anymore (no more `gateway.json`)
- Member chunking on startup was removed, making startup times much faster; to compensate `guild:requestMembers()` has been made more useful
- Removed "userbot/selfbot" legacy code

#### Discordia Module

- Added `setInterval`, `setTimeout`, `clearTimer`, and `sleep` functions
- Added new `Bitfield` class to replace `Permissions` class
- Removed `extensions` module (you can easily implement these yourself)
- Removed `Deque` and `Permissions` class

#### Caches, Iterables, and Containers

- `Guild`, `Role`, `Emoji`, and guild `Channel` containers are always cached
- `User`, `Reaction`, and `PermissionOverwrite` containers, generally being "sub" objects of those above, are always weakly cached
- All other containers are never explicitly cached!
- Where cached containers used to be accessible in a dynamic `Cache` handle (e.g. `guild.roles`), the library will now fetch them (from a hidden cache or HTTP request) and return them in a new static `Iterable` (e.g. `guild:getRoles()`)
- Containers do not have a "parent" object anymore; the only parent of every container is the base `Client` object

#### Class Behavior

- Added `info`, `mixin`, and `copy` to the `class` module
- Removed `classes`, `type`, and `serialize` from the `class` module
- Changed from multi- to single-inheritance
- Class members are now stored in upvalues instead of on the classes
- Accessing an undefined class member now throws an error
- Class properties cannot be declared outside of the `__init` method (subject to change)
- Class properties prefixed by `_` cannot be accessed outside of class member functions (subject to change)
- Default `__tostring` metamethod added: if the class has a `toString` method, `__tostring` returns `{name}: {string}` where `{name}` is the name of the class and `{string}` is the result of the `toString` call; otherwise, it returns `object: {name}` where `name` is the name of the class
- Default `__pairs` metamethod added: iterates the `getter` members for the class and returns their `name, value` pair

#### Enumeration Behavior

- Members of the `enums` module are now protected from being overwritten
- To create a new enumeration set, simply set a field to the `enums` module instead of calling `enums.enum`
- Different enumerations may now have the same value within the same set
- All "flags" are now strings to accommodate integer precision greater than that which is allowed by Lua's numbers
- Resolution by calling an enumeration has been improved: The name may be provided as if indexing the enumeration or a numerical value may be provided as a `number` or as a `string`
- The result of a successful enumeration set call is now a `name, value` pair instead of just the `name`
- Example: `channelType("text")`, `channelType(0)`, and `channelType("0")` will all return `"text", 0`; `channelType.text` will only return `0`

#### Dependencies

- Updated coro-http from 3.1.0 to 3.2.2
- Updated coro-websocket from 3.1.0 to 3.1.1
- Updated secure-socket from 1.2.2 to 1.2.3

### Public API

#### Classes

- Added utility classes:
	- `Bitfield`
	- `Listener`
- Added container classes:
	- `Application`
	- `Command`
	- `Interaction`
	- `GuildTemplate`
	- `InviteChannel`
	- `InviteGuild`
	- `MessageInteraction`
	- `StageInstance`
	- `Team`
	- `TeamMember`
	- `WebhookChannel`
	- `WebhookGuild`
	- `WelcomeScreen`
- Added struct classes:
	- `Activity` (previously was a container)
	- `ActivityAssets`
	- `ActivityButton`
	- `ActivityEmoji`
	- `ActivityParty`
	- `ActivitySecrets`
	- `ActivityTimestamps`
	- `Attachment`
	- `AuditLogChange`
	- `AuditLogOptions`
	- `CommandChoice`
	- `CommandOption`
	- `Embed`
	- `EmbedAuthor`
	- `EmbedField`
	- `EmbedFooter`
	- `EmbedImage`
	- `EmbedProvider`
	- `EmbedThumbnail`
	- `EmbedVideo`
	- `GuildCounts`
	- `InteractionData`
	- `InteractionOption`
	- `Mention` (does not correspond to an official structure)
	- `MessageActivity`
	- `VoiceRegion`
	- `WelcomeChannel`
- Merged `GuildChannel`, `TextChannel`, `GuildCategoryChannel`, `GuildTextChannel`, `GuildVoiceChannel`, and `PrivateChannel` into one `Channel` class
- Merged `ArrayIterable`, `TableIterable`, and `FilteredIterable` into one `Iterable` class
- Renamed `Member` to `GuildMember`
- Renamed `Role` to `GuildRole`
- Renamed `Emoji` to `GuildEmoji`
- Removed `Cache`, `SecondaryCache`, and `WeakCache` (some form of these still used internally)
- Removed `GroupChannel` class (concept was not merged into `Channel`)
- Removed `Permissions` class (replaced by more general `Bitfield` class)
- Removed `UserPresence` abstract class (functionality moved into `Presence` class)
- Removed `Deque` class (just use a `table`)
- Removed `Relationship` class (not used by bots)

#### Enumerations

- Changed internal code to prevent invalid public access
- Added `permissionOverwriteType` enumerations
- Added `whence` enumerations
- Added `premiumType` enumerations
- Added `gatewayIntent` enumerations
- Added `userFlag` enumerations
- Added `clientEvent` enumerations
- Added `messageActivityType` enumerations
- Added `embedType` enumerations
- Added `timestampStyle` enumerations
- Added `mentionType` enumerations
- Added `teamMembershipState` enumerations
- Added `stagePrivacyLevel` enumerations
- Added `commanOptionType` enumerations
- Added `commandPermissionType` enumerations
- Added `interactionRequestType` enumerations
- Added `interactionResponseType` enumerations
- Added `interactionResponseFlag` enumerations
- Added `applicationFlag` enumerations
- Added `channelType.store`
- Added `channelType.newsThread`
- Added `channelType.publicThread`
- Added `channelType.privateThread`
- Added `channelType.stageVoice`
- Added `messageType.channelFollowAdd`
- Added `messageType.guildDiscoveryDisqualified`
- Added `messageType.guildDiscoveryRequalified`
- Added `messageType.guildDiscoveryInitialWarning`
- Added `messageType.guildDiscoveryFinalWarning`
- Added `messageType.threadCreated`
- Added `messageType.reply`
- Added `messageType.applicationCommand`
- Added `messageType.threadStarterMessage`
- Added `messageType.guildInviteReminder`
- Added `status.offline`
- Added `actionType.stageInstanceCreate`
- Added `actionType.stageInstanceUpdate`
- Added `actionType.stageInstanceDelete`
- Added `activityType.watching`
- Added `activityType.custom`
- Added `activityType.competing`
- Added `logLevel.critical`
- Added `permission.useSlashCommands`
- Added `permission.requestToSpeak`
- Added `permission.manageEvents`
- Added `permission.manageThreads`
- Added `permission.usePublicThreads`
- Added `permission.usePrivateThreads`
- Changed `permission.readMessages` to `permission.viewChannel`
- Removed `relationshipType` enumeration (not used by bots)
- Removed `gameType` enumeration (use `actionType` enumeration)

#### Events

- TODO

#### Client Options

- Added `latencyLimit`
- Added `tokenPrefix`
- Added `gatewayIntents`
- Added `defaultImageExtension`
- Added `defaultImageSize`
- Added `defaultAllowedMentions`
- Added `logColors`
- Added `status`
- Added `activity`
- Renamed `shardCount` to `totalShardCount`
- Renamed `compress` to `payloadCompression`
- Renamed `dateTime` to `dateFormat`
- Renamed `bitrate` to `defaultBitrate`
- Removed `firstShard`
- Removed `lastShard`
- Removed `largeThreshold`
- Removed `cacheAllMembers`
- Removed `autoReconnect`
- Removed `syncGuilds`
- Removed `gatewayFile`

#### Client Methods

- Added GuildClient mixin methods:
	- `getGuildShardId`
	- `getGuild` (technically not new)
	- `getGuildCounts`
	- `getGuildPreview`
	- `modifyGuild`
	- `getGuildMember`
	- `getGuildChannel`
	- `getGuildRole`
	- `getGuildEmoji`
	- `getGuildMembers`
	- `getGuildRoles`
	- `getGuildEmojis`
	- `getGuildChannels`
	- `getGuildVoiceRegions`
	- `searchGuildMembers`
	- `createGuildRole`
	- `createGuildEmoji`
	- `createGuildChannel`
	- `getGuildPruneCount`
	- `pruneGuildMembers`
	- `getGuildBan`
	- `getGuildBans`
	- `getGuildInvites`
	- `getGuildWebhooks`
	- `getGuildAuditLogs`
	- `leaveGuild`
	- `deleteGuild`
	- `removeGuildMember`
	- `createGuildBan`
	- `removeGuildBan`
	- `getGuildWelcomeScreen`
	- `modifyGuildWelcomeScreen`
	- `getGuildTemplates`
	- `createGuildTemplate`
	- `syncGuildTemplate`
	- `modifyGuildTemplate`
	- `deleteGuildTemplate`
	- `modifyGuildEmoji`
	- `deleteGuildEmoji`
	- `modifyGuildRole`
	- `modifyGuildRolePositions`
	- `deleteGuildRole`
	- `modifyGuildMember`
	- `addGuildMemberRole`
	- `removeGuildMemberRole`
	- `modifyGuildChannelPositions`
- Added ChannelClient mixin methods:
	- `getChannel` (technically not new)
	- `modifyChannel`
	- `editChannelPermissions`
	- `deleteChannelPermission`
	- `deleteChannel`
	- `createChannelInvite`
	- `getChannelInvites`
	- `createWebhook`
	- `getChannelWebhooks`
	- `createStageInstance`
	- `getStageInstance`
	- `modifyStageInstance`
	- `deleteStageInstance`
	- `bulkDeleteMessages`
	- `getChannelMessage`
	- `getChannelMessages`
	- `getChannelFirstMessage`
	- `getChannelLastMessage`
	- `getPinnedMessages`
	- `triggerTypingIndicator`
	- `createMessage`
	- `editMessage`
	- `deleteMessage`
	- `pinMessage`
	- `unpinMessage`
	- `addReaction`
	- `removeReaction`
	- `clearReactions`
	- `getReactionUsers`
	- `crosspostMessage`
	- `followNewsChannel`
- Added CommandClient mixin methods:
	- `getGlobalApplicationCommand`
	- `getGlobalApplicationCommands`
	- `createGlobalApplicationCommand`
	- `editGlobalApplicationCommand`
	- `deleteGlobalApplicationCommand`
	- `bulkOverwriteGlobalApplicationCommands`
	- `getGuildApplicationCommand`
	- `getGuildApplicationCommands`
	- `createGuildApplicationCommand`
	- `editGuildApplicationCommand`
	- `deleteGuildApplicationCommand`
	- `bulkOverwriteGuildApplicationCommands`
	- `createInteractionResponse`
	- `getOriginalInteractionResponse`
	- `editOriginalInteractionResponse`
	- `deleteOriginalInteractionResponse`
	- `createFollowupMessage`
	- `editFollowupMessage`
	- `deleteFollowupMessage`
- Added `log` method
- Added `requestGuildMembers` method
- Added `getGatewayURL` method
- Added `modifyCurrentUser` method
- Added `getGuildTemplate`
- Added `deleteInvite` method
- Added `modifyWebhook` method
- Added `deleteWebhook` method
- Added `getGatewayStatistics` method
- Renamed `getApplicationInformation` method to `getApplication`
- Renamed `getGame` method to `getActivity`
- Removed auto-generated logging methods (use `log` method)
- Removed `createGuild` method
- Removed `createGroupChannel` method
- Removed `getRole` method (use `getGuildRole` method)
- Removed `getEmoji` method (use `getGuildEmoji` method)
- Removed `listVoiceRegions` method
- Removed `getConnections` method
- Removed `setAFK` method

#### Client Properties

- Added `uptime` property
- Added `apiRequests` property
- Added `apiBytesReceived` property
- Added `apiBytesTransmitted` property
- Added `apiLatency` property
- Added `ready` property
- Added `log` method
- Added `userId` property
- Added `token` property
- Added `logger` property
- Added `routeDelay` property
- Added `maxRetries` property
- Added `latencyLimit` property
- Added `tokenPrefix` property
- Added `gatewayIntents` property
- Added `totalShardCount` property
- Added `payloadCompression` property
- Added `defaultImageExtension` property
- Added `defaultImageSize` property
- Added `defaultAllowedMentions` property
- Added `defaultBitrate` property
- Added `status` property
- Added `activity` property
- Added `api` property (advanced users only)
- Added `cdn` property (advanced users only)
- Added `state` property (advanced users only)
- Removed `shardCount` property
- Removed `owner` property (use `getApplication` method)
- Removed `verified` property
- Removed `mfaEnabled` property
- Removed `email` property
- Removed `guilds` property (use `getGuilds` method)
- Removed `users` property (use `getUser` method)
- Removed `privateChannels` property
- Removed `groupChannels` property
- Removed `relationships` property

#### Container

- `__eq` metamethod is now implemented by subclasses
- `__tostring` metamethod is now implemented by subclasses
- Removed `parent` property

#### Snowflake

- Added `toString` method
- Removed `createdAt` property (use `getDate():toSeconds()`)
- Removed `timestamp` property (use `getDate():toISO()`)

#### Activity

Note: Changed to a struct. See documentation.

- Added `createdAt` property
- Added `timestamps` property
- Added `emoji` property
- Added `party` property
- Added `assets` property
- Added `secrets` property
- Added `instance` property
- Added `flags` property
- Added `buttons` property
- Removed `start` property (use `timestamps.start` property)
- Removed `stop` property (use `timestamps.stop` property)
- Removed `textSmall` property (use `assets.smallText` property)
- Removed `textLarge` property (use `assets.largeText` property)
- Removed `imageSmall` property (use `assets.smallImage` property)
- Removed `imageLarge` property (use `assets.largeImage` property)
- Removed `partySize` property (use `party.currentSize` property)
- Removed `partyMax` property (use `party.maxSize` property)
- Removed `emojiId` property (use `emoji.id` property)
- Removed `emojiName` property (use `emoji.name` property)
- Removed `emojiHash` property (use `emoji.hash` property)
- Removed `emojiURL` property

#### AuditLogEntry

- Added `getGuild` method
- Added `guildId` property
- Changed `changes` property from a raw table to an `Iterable` of `AuditLogChange` objects
- Changed `options` property from a raw table to an `AuditLogOptions` object
- Removed `getBeforeAfter` method
- Removed `guild` property (use `guildId` property or `getGuild` method)
- Removed `getTarget` method (use `targetId` property)

#### Channel

Note: All previously existing individual channel sub-classes are considered here.

- Added `whence` and `messageId` parameters to `getMessages` method
- Added `modify` method
- Added `setPermissionOverwrites` method
- Renamed `broadcastTyping` method to `triggerTyping`
- Removed `getMessagesAfter` method (use `getMessages` method)
- Removed `getMessagesBefore` method (use `getMessages` method)
- Removed `getMessagesAround` method (use `getMessages` method)
- Removed `sendf` method (use `send` method with `string.format`)
- Added `follow` method
- Added `getParent` method
- Added `editPermissions` method
- Added `getGuild` method
- Added `toMention` method
- Added `guildId` property
- Added `setPosition` method
- Added `createStageInstance`
- Changed `permissionOverwrites` property from a `Cache` to `Iterable`
- Changed `recipients` property from a `SecondaryCache` to `Iterable`
- Removed `moveUp` method (use `setPosition` or `Guild:sortChannels` method)
- Removed `moveDown` method (use `setPosition` or `Guild:sortChannels` method)
- Removed `getPermissionOverwriteFor` method (use `permissionOverwrites` property or `editPermissions` method)
- Removed `category` method (use `parentId` property or `getParent` method)
- Removed `guild` property (use `guildId` property or `getParent` method)
- Removed `private` property
- Removed `createTextChannel` method (use `Guild:createChannel` method)
- Removed `createVoiceChannel` method (use `Guild:createChannel` method)
- Removed `textChannels` property (use `Guild:getChannels` method)
- Removed `voiceChannels` property (use `Guild:getChannels` method)
- Removed `isNews` property (use `type` property)
- Removed `mentionString` property (use `toMention` method)

#### Ban

- Added `getGuild` method
- Added `guildId` property
- Added `toString` method
- Added `id` property as a shortcut for `user.id`
- Changed `__eq` consider the guild in addition to the user
- Removed `guild` property (use `guildId` property or `getGuild` method)

#### GuildEmoji

Note: Renamed from `Emoji`

- Added `getURL` method
- Added `getGuild` method
- Added `toMention` method
- Added `guildId` property
- Added `getRoles` method
- Added `roleIds` property
- Added `available` property
- Added `modify` method
- Removed `url` property (use `getURL` method)
- Removed `guild` property (use `guildId` property or `getGuild` method)
- Removed `roles` property (use `roleIds` property or `getRoles` method)
- Removed `mentionString` property (use `toMention` method)

#### Guild

- Added `payload` and `callback` parameters to `requestMembers` method
- Added `getIconURL` method
- Added `getBannerURL` method
- Added `getSplashURL` method
- Added `getDiscoveryURL` method
- Added `getMembers` method
- Added `getEmojis` method
- Added `getRoles` method
- Added `getChannels` method
- Added `searchMembers` method
- Added `createChannel` method
- Added `sortRoles` method
- Added `sortChannels` method
- Added `setRulesChannel` method
- Added `setPublicUpdatesChannel` method
- Added `setDiscoverySplash` method
- Added `setPreferredLocale` method
- Added `setDescription` method
- Added `discoverySplash` property
- Added `applicationId` property
- Added `systemChannelFlags` property
- Added `rulesChannelId` property
- Added `preferredLocale` property
- Added `publicUpdatesChannelId` property
- Added `maxVideoChannelUsers` property
- Added `modify` method
- Changed `createRole` method to accept a `name` string or `payload` table
- Changed `createEmoji` method to accept a `payload` table
- Changed `pruneMembers` method to accept a `payload` table
- Renamed `setExplicitContentSetting` to `setExplicitContentLevel`
- Renamed `listVoiceRegions` method to `getVoiceRegions`
- Renamed `kickUser` method to `removeMember`
- Renamed `banUser` method to `createBan`
- Renamed `unbanUser` method to `removeBan`
- Renamed `totalMemberCount` property to `memberCount`
- Renamed `explicitContentSetting` property to `explicitContentLevel`
- Removed `createTextChannel` method (use `createChannel` method)
- Removed `createVoiceChannel` method (use `createChannel` method)
- Removed `createCategory` method (use `createChannel` method)
- Removed `sync` method (not used by bots)
- Removed `iconURL` property (use `getIconURL` method)
- Removed `splashURL` property (use `getSplashURL` method)
- Removed `bannerURL` property (use `getBannerURL` method)
- Removed `large` property
- Removed `lazy` property
- Removed `maxMembers` property
- Removed `maxPresences` property
- Removed `unavailable` property
- Removed `me` property (use `getMember` method)
- Removed `owner` property (use `ownerId` property or `getMember`)
- Removed `afkChannel` property (use `afkChannelId` property or `getChannel` method)
- Removed `systemChannel` property (use `systemChannelId` property or `getChannel` method)
- Removed `roles` property (use `getRole` or `getRoles` method)
- Removed `emojis` property (use `getEmoji` or `getEmojis` method)
- Removed `members` property (use `getMember` or `getMembers` or `requestMembers` method)
- Removed `textChannels` property (use `getChannel` or `getChannels` method)
- Removed `voiceChannels` property (use `getChannel` or `getChannels` method)
- Removed `categories` property (use `getChannel` or `getChannels` method)

#### Invite

- Added `channel` property
- Added `guild` property
- Added `toString` method
- Removed `guildId` property (use `guild.id` property)
- Removed `guildName` property (use `guild.name` property)
- Removed `guildIcon` property (use `guild.icon` property)
- Removed `guildBanner` property (use `guild.banner` property)
- Removed `guildSplash` property (use `guild.splash` property)
- Removed `guildIconURL` property (use `guild:getIconURL` method)
- Removed `guildBannerURL` property (use `guild:getBannerURL` method)
- Removed `guildSplashURL` property (use `guild:getSplashURL` method)
- Removed `guildDescription` property (use `guild.description` property)
- Removed `guildVerificationLevel` property (use `guild.verificationLevel` property)
- Removed `channelId` property (use `channel.id` property)
- Removed `channelName` property (use `channel.name` property)
- Removed `channelType` property (use `channel.type` property)

#### GuildMember

Note: Renamed from `GuildMember`

- Added `getRoles` method
- Added `getGuild` method
- Added `getHighestRole` method
- Added `toMention` method
- Added `modify` method
- Added `toString` method
- Added `guildId` property
- Added `roleIds` property
- Added `id` property as a shortcut for `user.id`
- Changed superclass from `UserPresence` to `Container`
- Removed `hasPermission` method (use `getPermissions()`)
- Removed `roles` property (use `roleIds` property or `getRoles` method)
- Removed `guild` property (use `guildId` property or `getGuild` method)
- Removed `highestRole` property (use `getHighestRole` method)
- Removed (most) "user shortcuts" (use `user` property instead)

#### Message

- Added `getMentions` method
- Added `getMember` method
- Added `getGuild` method
- Added `getChannel` method
- Added `guildId` property
- Added `channelId` property
- Added `activity` property
- Changed `reactions` property from a `Cache` to an `Iterable`
- Changed `embed` property from a raw table to an `Embed` object
- Changed `attachment` property from a raw table to an `Attachment` object
- Changed `embeds` property from a raw table to an `Iterable` of `Embed` objects
- Changed `attachments` property from a raw table to an `Iterable` of `Attachment` objects
- Removed `cleanContent` property
- Removed `oldContent` property
- Removed `mentionedRoles` property (use `getRawMentions` metod)
- Removed `mentionedChannels` property (use `getRawMentions` metethod)
- Removed `mentionedEmojis` property (use `getRawMentions` method)
- Removed `member` property (use `user` property or `getMember` method)
- Removed `guild` property (use `guildId` property or `getGuild` method)
- Removed `channel` property (use `channelId` property or `getChannel` method)

#### PermissionOverwrite

- Added `getChannel` method
- Added `channelId` property
- Added `toString`
- Changed `__eq` consider the channel in addition to the role/member
- Removed `getAllowedPermissions` method (use `allowedPermissions` property and `Bitfield` class)
- Removed `getDeniedPermissions` method (use `deniedPermissions` property and `Bitfield` class)
- Removed `setAllowedPermissions` (use `setPermissions` method)
- Removed `setDeniedPermissions` (use `setPermissions` method)
- Removed `allowAllPermissions` method
- Removed `clearAllPermissions` method
- Removed `denyAllPermissions` method
- Removed `getObject` method
- Removed `guild` property
- Removed `channel` property (use `channelId` property or `getChannel` method)

#### Presence

Note: Technically a new class that implements the former `UserPresence` features

- Added `getUser` method
- Added `getGuild` method
- Added `getMember` method
- Added `userId` property
- Added `guildId` property
- Added `activities` property
- Changed `activity` property from a raw table to an `Activity` object
- Removed `user` property (use `userId` property or `getUser` method)
- Removed deprecated `gameName` property (use `activity.name` property)
- Removed deprecated `gameType` property (use `activity.type` property)
- Removed deprecated `gameURL` property (use `activity.url` property)

#### Reaction

- Added `getChannel` method
- Added `getMessage` method
- Added `getEmojiURL` method
- Added `toString` method
- Added `channelId` property
- Added `messageId` property
- Added `hash` property (evaluates `emoji.id or emoji.name`)
- Added `whence` and `userId` parameters to `getUsers` method
- Changed `__eq` consider the message in addition to the emoji
- Removed `channel` property (use `channelId` property or `getChannel` method)
- Removed `message` property (use `messageId` property or `getMessage` method)
- Removed `getUsersBefore` method (use `getUsers` method)
- Removed `getUsersAfter` method (use `getUsers` method)
- Removed `emojiId` property (use `emoji.id` property)
- Removed `emojiName` property (use `emoji.name` property)
- Removed `emojiHash` property (use `emoji.hash` property)
- Removed `emojiURL` property

#### GuildRole

Note: Renamed from `Role`

- Added `getGuild` method
- Added `toMention` method
- Added `guildId` property
- Added `modify` method
- Removed `guild` property (use `guildId` property or `getGuild` method)
- Removed `moveUp` method (use `Guild:sortRoles` method)
- Removed `moveDown` method (use `Guild:sortRoles` method)
- Removed `enableAllPermissions` method (use `enablePermissions` or `setPermissions` method)
- Removed `disableAllPermissions` method (use `disablePermissions` or `setPermissions` method)
- Removed `getColor` method (use `color` property and `Color` class)
- Removed `getPermissions` method (use `permissions` property and `Bitfield` class)
- Removed `members` property
- Removed `emojis` property
- Removed `mentionString` property (use `toMention` method)

#### User

- Added `hasFlag` method
- Added `toMention` method
- Removed `sendf` method (use `send` method with `string.format`)
- Removed deprecated `fullname` property (use `tag` property)
- Removed `avatarURL` property (use `getAvatarURL` method)
- Removed `defaultAvatarURL` property (use `getDefaultAvatarURL` method)
- Removed `mutualGuilds` property
- Removed `mentionString` property (use `toMention` method)

#### Webhook

- Added `setChannel` method
- Added `applicationId` property
- Added `sourceChannel` property
- Added `sourceGuild` property
- Added `modify` method
- Removed `avatarURL` property (use `getAvatarURL` method)
- Removed `defaultAvatarURL` property (use `getDefaultAvatarURL` method)

#### Iterable

Note: This is effectively a new class compared to the old one. It provides a similar API, but its behavior in the library is quite different. See documentation for details. The major difference for the context here is that objects are stored in an sequential table instead of a associated table.

- Added `__ipairs` metamethod
- Added optional support for numerical indexing to `get` method
- Added `sort` method
- Added `filter` method
- Added `toTable` method
- Added `copy` method
- Removed `findAll` method (use `filter` method)
- Removed `sortBy` and `fn` parameters from `toArray` method
- Removed `pick` method (nil values are problematic)
- Removed forced sorting in `select` method

#### Clock

- No public changes

#### Color

- Added `__lt` metamethod
- Added `__le` metamethod
- Added `lerp` method
- Added `toString` method (used by default `__tostring` metamethod)
- Added optional `base` parameter to initializer (default = `10`)
- Added `toDec` method
- Added `fromDec` static method
- Changed `fromRGB` static method to clamp input to [0, 255] range
- Removed `#` prefix support `toHex` method
- Removed `#` prefix support from `fromHex` static method
- Removed explicit `__tostring` metamethod (uses default)
- Removed `setRed` method (make a new object)
- Removed `setGreen` method (make a new object)
- Removed `setBlue` method (make a new object)

#### Date

- Added microsecond precision to empty/current objects
- Added `__lt` metamethod
- Added `__le` metamethod
- Added support for more strings in `fromISO` static method
- Added support for `usec` in `fromTable` and `fromTableUTC` static methods
- Added support for `usec` in `toTable` and `toTableUTC` methods
- Added `toMention` method
- Changed `toParts` method to return normalized seconds and microseconds
- Removed `sep` and `tz` parameters from `toISO` method
- Removed explicit `__tostring` metamethod (uses default)
- Removed explicit default format from `toString` method (uses `os.date` default)
- Removed `parseISO` method (use `fromISO` method)
- Removed `parseHeader` method (no replacement)
- Removed `parseSnowflake` method (use `fromSnowflake` method)
- Removed `parseTable` method (use `fromTable` method)
- Removed `parseTableUTC` method (use `fromTableUTC` method)
- Removed `toHeader` method (use `toString`)

#### Emitter

- Added optional error handler `err` parameter to `on` method
- Added optional error handler `err` parameter to `once` method
- Changed `on` and `once` return from `function` to `Listener` object
- Changed `getListeners` return from `function` to `Iterable` object
- Changed `emit` method to always coroutine-wrap callbacks
- Changed `emit` method to `pcall` callbacks if an error handler is available
- Changed `removeListener` to stop after the first positive result
- Changed `removeListener` second parameter from `function` to `Listener`
- Removed `onSync` method (use `on` method)
- Removed `onceSync` method (use `once` method)
- Removed `getListenerCount` method (use length operator with `getListeners()`)

#### Logger

- Changed label colors from bold standard to non-bold bright
- Added "critical" log-level with highest priority
- Added `filePath` and `useColors` parameters to initializer
- Added `setLevel` method
- Added `setDateTime` method
- Added `setFile` method
- Added `enableColors` method
- Added `disableColors` method

#### Mutex

- Removed `Deque` superclass (a regular table is used internally)

#### Stopwatch

- Added `toString` method (equivalent to `getTime():toString()`)
- Removed explicit `__tostring` metamethod (uses default)
- Removed `milliseconds` property (use `getTime()`)

#### Time

- Added `__mod` metamethod
- Added `fromMicroseconds` static method
- Added `value` property (internal microseconds value)
- Changed milliseconds to microsecond precision (1000x)
- Removed explicit `__tostring` metamethod (uses default)

## 2.9.1
- The mentioned author of a referenced message is now in `Message.mentionedUsers`
- Fixed a bug where mentions were ignored in replies

## 2.9.0
- Added basic support for message replies
	- Added `content.reference` field for `TextChannel:send(content)`
	- Added `Message.referencedMessage` property
- Added `Activity:__hash` method
- Added `INVITE` and `INTEGRATION` events to the internal ignore list
- Added ability to set member voice channel to `nil` (voice-kick)
- Changed reconnection request from `warning` to `info` in logging
- Fixed rare crash on receiving invalid message reaction data

## 2.8.4
- Updated the `discordapp` domain name to `discord` where necessary (CDN links remain the same)

## 2.8.3
- Fixed an issue where the gateway session would not attempt to resume after a reconnection

## 2.8.2
- Fixed issue where objects would not be cached if they were re-created after being recently deleted
- Fixed issue where ratelimit headers were ignored

## 2.8.1
- Multiple presences are now flattened into one
- Fixed typo in `Guild.splashURL` result
- Fixed issue where `Ban` objects generated by `Guild:getBan` did not have the correct parent type
- Fixed crash when FFmpeg process would close before reading
- Removed FFI dependency in Date class

## 2.8.0
- Added support for custom statuses:
	- Added `Activity.emojiId` property
	- Added `Activity.emojiName` property
	- Added `Activity.emojiHash` property
	- Added `Activity` as a valid emoji and emojiId resolvable
	- Added `activityType.custom` enumeration
- Added support for message flags and embed suppression
	- Added `Message:hasFlag` method
	- Added `Message:hideEmbeds` method
	- Added `Message:showEmbeds` method
	- Added `messageFlag` enumerations:
		- `crossposted`
		- `isCrosspost`
		- `suppressEmbeds`
		- `sourceMessageDeleted`
		- `urgent`
- Added `Message:update` method
- Added `webhookType` enumerations:
	- `incoming`
	- `channelFollower`
- Added `Webhook.type` property
- Added `permission.stream` enumeration
- Added `gatewayFile` client option
- Switched to millisecond precision for HTTP ratelimiting
	- Reduced default `routeDelay` client option from 300 to 250 ms
	- Bots can now add and remove reactions more quickly
- Added `actionType` enumerations:
	- `memberMove`
	- `memberDisconnect`
	- `botAdd`
	- `messageBulkDelete`
	- `messagePin`
	- `messageUnpin`
	- `integrationCreate`
	- `integrationUpdate`
	- `integrationDelete`
- Fixed issue where `Reaction.emojiURL` used `.png` for animated emojis
- Fixed issue where `Guild.features` did not update
- Fixed issue where deleted objects would be uncached prematurely
- Fixed issue where internal session ID was removed before it was used
- Refactored `docgen.lua` and improved class documentation
- Other changes
	- Added error message for missing `ffmpeg` executable
	- Removed coroutine wrappers for internal iterators
	- Switched to a dynamic multi-part file boundary
	- Emojis are now properly URL-encoded
	- Minor `Time` class refactor

## 2.7.0
- Added support for status differentiation
	- Added `UserPresence.webStatus` property
	- Added `UserPresence.mobileStatus` property
	- Added `UserPresence.desktopStatus` property
- Added support for premium guilds
	- Added `Guild.premiumTier` property
	- Added `Guild.premiumSubscriptionCount` property
	- Added `Member.premiumSince` property
	- Added `messageType.premiumGuildSubscription` enumeration
	- Added `messageType.premiumGuildSubscriptionTier1` enumeration
	- Added `messageType.premiumGuildSubscriptionTier2` enumeration
	- Added `messageType.premiumGuildSubscriptionTier3` enumeration
- Added support for guild banners
	- Added `Guild.banner` property
	- Added `Guild.bannerURL` property
	- Added `Guild:setBanner` method
- Other additions
	- Added `Guild.vanityCode` property
	- Added `Guild.description` property
	- Added `Guild.maxMembers` property
	- Added `Guild.maxPresences` property
	- Added `Iterable:pick` method
	- Added `Permissions.fromMany` static method
	- Added `Client:getApplicationInformation` method
	- Added `Message.webhookId` property
	- Added `Snowflake:getDate` method
	- Added `AuditLogEntry.userId` property
	- Added `GuildChannel.private` property
- Other changes and bug fixes
	- `Emitter:removeAllListeners` now does exactly that if no `name` is passed
	- Added support for Discord's new count boolean in `Guild:pruneMembers`
	- Added an optional format parameter to `Date:toString` that obeys the same rules as `os.date` rules.
	- Removed parsing of `_trace` properties in gateway payloads
	- Added basic support for guild news channels (Discordia treats them as text channels for now)
	- Fixed a bug in emoji ID resolution
	- Fixed `Member:hasPermission` returning false for administrators in some conditions
	- Optimized libsodium char array construction
	- Fixed emoji detection for `Message.cleanContent`
	- Fixed issue converting `Date` to a snowflake on Windows
	- Various documentation fixes
- Dependency updates
	- Updated `luvit/secure-socket` from `1.2.0` to `1.2.2`
	- Updated `creationix/coro-http` from `3.0.0` to `3.1.0`

## 2.6.0
- Added `GuildTextChannel.rateLimit` and `GuildTextChannel:setRateLimit` for slowmode handling
- Added parsing of members in the VOICE_STATE_UPDATE event and the mentioned users array for message handling
- Added `status` enumeration for presence or activity statuses
- Reverted memoization changes from 2.5.0 (fixes an unidentified bug in role caching)

## 2.5.2
- Fixed an issue where `Message.reactions` was always empty

## 2.5.1
- Fixed nil index issue in Emoji and Member methods

## 2.5.0
- Added `message.link` property for jump-to links
- Added `Guild.lazy` property
- Added `Guild:getBan` for checking individual bans
- `Activity` now correctly inherits `Container`
- Removed global reaction ratelimit
- Memoized iterables are now weakly cached for memory optimization

## 2.4.1
- Fixed a bug in `Emitter:waitFor` when using a predicate

## 2.4.0
- Added support for sending voice/audio
	- Added `VoiceConnection` class and other internal voice classes
	- `GuildVoiceChannel:join` is now functional
	- Added `GuildVoiceChannel:leave`
	- See documentation for more information
- Added support for advanced presences/activities
	- Added `Activity` class
	- Added `Member.activity` and `Relationship.activity` via `UserPresence.activity`
	- Deprecated `UserPresence.gameName`, use `UserPresence.activity.name`
	- Deprecated `UserPresence.gameType`, use `UserPresence.activity.type`
	- Deprecated `UserPresence.gameURL`, use `UserPresence.activity.url`
- Other additions
	- Added inline documentation and a documentation generator for classes
	- Added `GuildCategoryChannel:createTextChannel` and `GuildCategoryChannel:createVoiceChannel`
	- Added `Client:getRole` and `ClientgetEmoji`
	- Added `PermissionOverwrite:setPermissions`
	- Added `prioritySpeaker` permission
	- Added `Stopwatch:__tostring`
	- Added `class.serialize` function
	- Added `shardDisconnect` event
	- Added optional predicate to `Emitter:waitFor`
	- Added ability to get member counts with `Client:getInvite`, `Invite.approximatePresenceCount`, and `Invite.approximateMemberCount`
	- Added donation link to README
- Bug fixes
	- Fixed overflow issue with `extensions.table.deepcount`
	- Fixed leading-zero issue in `Date:toISO`
	- Fixed issue when comparing two `Date` objects
	- Fixed issue in `Time:toString`
	- Fixed issue that caused a crash on guild initialization
	- Fixed `Client.shardCount`
	- Fixed cache consistency issue with `PermissionOverwrite`s
	- Fixed issue in mention matching when an unpaired `<` was encountered
- Other changes
	- Made `Date:__tostring` more consistent with other metamethods and added `Date:toString`
	- Overhauled WebSocket connection logic
	- Deprecated `User.fullname`, use `User.tag` instead
	- Calling an HTTP API method outside of a coroutine will now throw (instead of return) its error
	- Implemented internal gateway `message.member` parsing
	- All offline members are now uncached when `cacheAllMembers` is false (instead of just those in large guilds)

## 2.3.0
- Emoji improvements:
	- Added `Emoji:hasRole`
	- Added `Emoji:setRoles`
	- `Emoji.mentionString` will now provide the animated version `<a:name:id>` for animated emojis
	- `Emoji.url` will now provide a `.gif` URL for animated emojis
	- Added `Emoji.animated` boolean property
- Message mention improvements:
	- Mentions are now iterated in the order that they appear in the message content
	- Replicated mentions are still ignored as before
	- Added `Message.mentionedEmojis` (for custom emojis only)
	- Known cross-guild role and emoji mentions are now resolvable
	- Role mentions will now resolve even if the role is technically not mentionable
	- Emojis are now parsed in `Message.cleanContent`
	- Added `ArrayIterable.first` and `ArrayIterable.last` properties (eg: `message.mentionedUsers.first`)
- `Client:setGame` now supports arbitrary game/activity types
- Added `gameType.listening` enumeration
- Added `GuildVoiceChannel:join` (only joins the channel, no voice connection is made)
- Adjusted shard counting:
	- `Client.shardCount` was corrected to represent the number of shards that the single client instance is running
	- `Client.totalShardCount` was added to represent the total number of shards that the bot is running across all clients
	- The client option `shardCount` will remain unchanged; it still represents the total number of shards across all clients
- Added `GuildVoiceChannel.connectedMembers` iterable property
- Added `Time:toString` to obtain a natural-language time duration with proper grammatical number
- Other changes
	- Some internal `Emitter` class tweaks
	- Added `TableIterable` class (used internally)
	- HTTP User-Agent is now set during initialization instead of authentication
	- Fixed nil concatenation in enum module
	- Default class instance `__tostring` now provides only the class type
	- Fixed over-caching of members

## 2.2.0
- Added audit log support
	- Added `Guild:getAuditLogs`
	- Added `AuditLogEntry` class
	- Added `actionType` enumeration
- Added `Guild:getEmoji`
- Added support for `Reaction:getUsers` query
- Added `TextChannel:sendf` shortcut
- Objects deleted via HTTP are now synchronously uncached
- Fixed `Guild:listVoiceRegions`
- Ratelimit route tweaks
	- ID paths are now properly substituted
	- Webhooks are now treated as a major route
	- Reactions are now treated as a global route
- Fixed issue when setting status on manually-sharded bots
- Fixed crash on guild initialization when voice states were not present

## 2.1.0
- Added `Reaction.emojiHash` and `Emoji.hash` properties
- Added support for emoji endpoints and methods:
	- `Emoji:setName`
	- `Emoji:delete`
	- `Guild:createEmoji`
- Date instances are now valid Snowflake ID resolvables
- Added `textChannels` and `voiceChannels` filtered iterables to `GuildCategoryChannel`
- Added support for system channels
	- `Guild.systemChannel`
	- `Guild.systemChannelId`
	- `Guild:setSystemChannel`

## 2.0.1
- Added missing `Message.oldContent`, which was intended for 2.0.0
- `GuildTextChannel:bulkDelete` can now handle a minimum of 1 message instead of 2
- `Iterable:toArray(fn)` is now an acceptable overload for `Iterable:toArray(sortBy, fn)`
- Switched the base64 resolver to use OpenSSL instead of a pure Lua version
- Client owner data is now cached on authentication (still named gateway.json)
- Authentication cache now expires after 1 hour instead of 24 hours
- Reactions are now properly uncached when MESSAGE_REACTIONS_REMOVE_ALL occurs
- JSON `null` is now correctly handled for `Invites` and `Reactions`

## 2.0.0

The major goals of this rewrite were to add new or missing features and to improve consistency and efficiency. A lot of changes were made to Discordia to achieve these goals; many of them are breaking. Please read the following changelog carefully and update your applications accordingly.

**Note:** Due to changes made by Discord, versions of Discordia prior to 2.0.0 may not be supported on or after October 16, 2017.

### General Changes

#### Connectivity
- Bot tokens must now be manually prefixed with `Bot `
- The core of the library that establishes and maintains a connection to Discord has been overhauled (see Internal Changes for more information)
- More and clearer information regarding the client's connection is now logged
- Manual sharding is now supported
- Updated to Discord gateway v6
- Updated to Discord REST API v7
- Guilds are no longer automatically synced by default (user accounts only)

#### Dependencies
- Updated coro-http from 2.1.1 to 3.0.0
- Updated coro-websocket from 1.0.0 to 3.1.0
- Updated secure-socket from 1.1.4 to 1.2.0
- Removed coro-fs

#### Class Behavior
- Class methods are no longer automatically generated for class properties (eg: `User:getUsername` is not a valid alternative for `User.username`)
	- Properties are generally used for items that are immediately available for consumption
	- Methods are generally used for items that require arguments or an HTTP or WebSocket request to be procured
	- Some previously generated methods may still exist (eg: `TextChannel:getFirstMessage` exists; `TextChannel.firstMessage` does not exist)
	- Some previous property-method pairs may still exist (eg: `Role.color` exists and is a number; `Role:getColor` exists and returns a `Color` object)
	- Properties are never directly mutable; all mutations are done via methods
- `class` module is no longer automatically registered as a global (access the new `class` field of the `discordia` module instead)
- Added various helper functions: `isClass`, `isObject`, `isSubclass`, `isInstance`, `type`, `profile`
- Calling `class` now returns only a class and getter table (instead of a class table and property, method, and cache constructors)
- Changed the "private" `class.__classes` table to `class.classes`

#### Caches and Iterables
- Properties and methods that access caches have been removed and replaced by caches that can be directly accessed
- Some shortcut methods remain (eg: `client:getGuild` and `channel:getMessage`)
- Stand-alone iterators for cached objects have been changed to iterable objects (eg: `message.mentionedUsers` is now an `ArrayIterable`)
- Stand-alone iterators for HTTP-accessible objects have been removed and replaced by methods that return an iterable object (eg: `channel.invites` was replaced by `channel:getInvites`)
- Iterable objects are those that implement the `Iterable` mixin; all have an `iter` method plus methods that rely on this
- The `Iterable` mixin provides methods such as `get`, `find`, `forEach`, etc
- Classes that implement the `Iterable` mixin are:
	- `Cache` - for main Discord objects (eg: guilds, channels, roles)
	- `SecondaryCache` - for select references to objects that are cached elsewhere (eg: pinned messages)
	- `ArrayIterable` - for objects that are better represented in an ordered form, and sometimes mapped (eg: member roles, mentioned users)
	- `WeakCache` - for objects that are either never directly deleted or are temporarily referenced from other locations (eg: channel messages)

#### New Container Classes
- `Ban` - represents a guild ban (provides a user object and reason)
- `GroupChannel` - represents a group DM channel (user accounts only)
- `Relationship` - represents friends and blocked users (user accounts only)

#### New Utility Classes
- `Date` - used to represent a single instance in time
- `Time` - used to represent a specific length of time
- `Logger` - used to log messages to the console and files

#### Error Messages and Logging
- New `Logger` class added
	- Available log-levels are `error`, `warning`, `info`, `debug`, and `none`
	- Messages use a format `timestamp | level | message`
	- Messages are logged to the console and to a file
- The client uses a `Logger` instance with a default level of `info`, default file of `discordia.log`, and default timestamp of `%F %T`
- Shards use the main client logger, but prefix messages with `Shard: #` where `#` is the shard ID.
- Most methods that return false or nil to indicate a failure will now return an error message as their second return value
	- This generally applies to methods that make HTTP requests
	- When available, more detailed error messages will be provided than those that are sent to the client logger; always check these messages when debugging issues

#### Input resolution
- Added `Resolver` singleton (used internally)
- Methods that previously required certain objects now accept object hashes or objects that can be similarly hashed (eg: `member:addRole` now accepts either a `Role` object or snowflake ID)
- Methods that previously required raw base64 now also accept a path to a file

#### Enumerations
- Added `enums` module to the main `discordia` module
- Most types and levels are now enumerated as Lua numbers
- Enumerated properties can be more easily represented using fields within the `enums` module (eg: `channelType.voice` and `verificationLevel.medium`)

#### Extensions
- Module is no longer automatically loaded into the global Lua modules (call the modules to load them instead)
- Removed `printf` function
- Combined `string.split` and `string.split2` into one `string.split`
- Combined `string.padleft`, `string.padright`, and `string.padcenter` into one `string.pad`
- Renamed `table.find` to `table.search`
- Removed `table.hash`
- Removed `table.transposed`

### Public API Changes

#### Events
- Added `pinsUpdate` event
- Added `webhooksUpdate` event
- Added `reactionRemoveAll` event
- Added `reactionRemoveAllUncached` event
- Added `recipientAdd` event
- Added `recipientRemove` event
- Added `relationshipAdd` event
- Added `relationshipRemove` event
- Added `relationshipUpdate` event
- Added `info` event
- Added `debug` event
- Added group channel and category handling to `channelCreate`, `channelUpdate`, and `channelDelete`
- Renamed `resumed` event to `shardResumed`
- Removed `guildCreateUnavailable` event (check `guild.unavailable` on `guildCreate` instead)
- Removed `typingStartUncached` event
- Removed `mute` and `deaf` arguments from voice events (check `member.muted` and `member.deafened` instead)
- Changed `reactionAdd` and `reactionRemove` parameters from `(reaction, user)` to `(reaction, userId)`
- Changed `reactionAddUncached` and `reactionRemoveUncached` parameters from raw `(data)` table to `(channel, messageId, hash, userId)`
- Changed `typingStart` parameters from `(user, channel, timestamp)` to raw `(userId, channelId, timestamp)` table
- Changed `heartbeat` parameters from `(sequence, latency, shardId)` to `(shardId, latency)`
- Changed `raw` parameters from `(tbl, str)` to `(str)` where `str` is a JSON string

#### Client
- Added `shardCount` option
- Added `firstShard` option
- Added `lastShard` option
- Added `syncGuilds` option
- Added `logLevel` option (use `enums.logLevel` for convenience)
- Added `logFile` option (use an empty string `''` to disable)
- Removed `globalDelay` option
- Removed `messageLimit` option
- Changed `dateTime` option from `'%c'` to `'%F %T'`
- Non-integer options are now rejected (where relevant)
- Added `info` and `debug` methods and log-levels to complement `warning` and `error` methods and log-levels
- Registering a callback to log events no longer prevents messages from being logged
- Messages logged to the console are now also logged to a file
- Fixed issue where `gateway.json` did not have user-specific fields
- Added `setAFK` method
- Added `setGame` method
- Added `setStatus` method
- Added `getConnections` method
- Added `createGroupChannel` method
- Added `groupChannels` `Cache` property
- Added `relationships` `Cache` property
- Changed `run` to require a `Bot ` prefix for bot tokens
- Changed `run` to accept an initial presence as its second argument
- Changed `run` to not accept email and password for logins
- Changed `stop` method to never exit the process (do this manually instead)
- Changed `setAvatar` to accept a base64-resolvable
- Removed `setNickname` method (use `guild.me:setNickname` instead)
- Removed `setStatusOnline` and `setStatusIdle` methods (use `setStatus` instead)
- Removed `setGameName` method (use `setGame` instead)
- Removed `acceptInvite` method
- Replaced `users` properties and methods with directly accessible `Cache` property
- Replaced `guilds` properties and methods with directly accessible `Cache` property
- Replaced `privateChannels` properties and methods with directly accessible `Cache` property
- Removed `roles` properties and methods
- Removed `members` properties and methods
- Removed `channels` properties and methods
- Removed `messages` properties and methods
- Removed `textChannels` properties and methods
- Removed `voiceChannels` properties and methods
- Removed `guildVoiceChannels` properties and methods
- Removed `guildTextChannels` properties and methods
- Added stand-alone `getUser` method, which accepts only a userId-resolvable
- Added stand-alone `getGuild` method, which accepts only a guildId-resolvable
- Added stand-alone `getChannel` method, which accepts only a channelId-resolvable
- Removed `mobile` property

#### Ban
- New class! See documentation.

#### Channel
- Moved `mentionString` property from `GuildChannel` to `Channel`
- Removed `isPrivate` property (check `type` instead)
- Changed `type` property from string to number (use `enums.channelType`)

#### Container
- Added `__tostring` metamethod, which uses new `__hash` method(s)
- Added `__eq` metamethod, which uses new `__hash` method(s)

#### GuildChannel
- Added `category` property
- Added `setCategory` method
- Replaced `invites` property with `getInvites` method
- Replaced `permissionOverwrites` properties and methods with directly accessible `Cache` property
- Replaced `setPosition` method with `moveUp` and `moveDown` methods
- Changed `createInvite` parameters from `(maxAge, maxUses, temporary, unique)` to `(payload)`

#### Snowflake
- Added `__hash` method, which returns `id` property
- Removed `__eq` method (parent method is used instead)
- Removed `__tostring` method (parent method is used instead)
- Changed `timestamp` property to correctly match Python DateTime

#### TextChannel
- Removed `loadMessages` method
- Replaced `lastMessage` property with `getLastMessage` method
- Replaced `firstMessage` property with `getFirstMessage` method
- Replaced `pinnedMessages` property with `getPinnedMessages` method
- Replaced `messages` properties and methods with directly accessible `Cache` property
- Renamed `getMessageHistory` to `getMessages` and changed behavior (see documentation)
- Renamed `sendMessage` to `send` and changed behavior (see documentation)
- Added stand-alone `getMessage` method, which accepts only a messageId-resolvable

#### Emoji
- Changed `url` property to use cdn URL
- Renamed `string` to `mentionString` to be consistent with other "mentions"
- Added `roles` `ArrayIterable` for roles that may be required to use the emoji
- Removed explicit `__tostring` method (parent method is used instead)

#### GroupChannel
- New class! See documentation.

#### Guild
- Added `setVerificationLevel` method
- Added `setNotificationSetting` method
- Added `setExplicitContentSetting` method
- Added `explicitContentSetting` property
- Added `ownerId` property
- Added `afkChannelId` property
- Added `splash` property
- Added `splashURL`
- Added `setSplash` method
- Added optional `reason` argument to `kickUser`, `banUser`, and `unbanUser` methods
- Added `sync` method
- Added `requestMembers` method
- Added `categories` `Cache` property
- Added `createCategory` method
- Renamed `iconUrl` to `iconURL`
- Renamed `setAfkTimeout` to `setAFKTimeout`
- Renamed `setAfkChannel` to `setAFKChannel`
- Changed `setIcon` to accept a base64-resolvable
- Changed `setAFKChannel` to accept a channelId-resolvable
- Replaced `vip` boolean with raw `features` table
- Fixed `pruneMembers` method
- Changed `kickUser`, `banUser`, and `unbanUser` methods to accept userId-resolvables
- Changed `banUser` parameters from `(days)` to `(reason, days)`
- Removed `defaultChannel` property
- Replaced `bannedUsers` property with `getBans` method
- Replaced `invites` property with `getInvites` method
- Replaced `webhooks` property with `getWebhooks` method
- Replaced `roles` properties and methods with directly accessible `Cache` property
- Replaced `emojis` properties and methods with directly accessible `Cache` property
- Replaced `members` properties and methods with directly accessible `Cache` property
- Replaced `textChannels` properties and methods with directly accessible `Cache` property
- Replaced `voiceChannels` properties and methods with directly accessible `Cache` property
- Removed `messages` properties and methods
- Removed `channels` properties and methods
- Added stand-alone `getRole` method, which accepts only a roleId-resolvable
- Added stand-alone `getChannel` method, which accepts only a channelId-resolvable
- Added stand-alone `getMember` method, which accepts only a userId-resolvable

#### GuildCategoryChannel
- New class! See documentation.

#### GuildTextChannel
- Changed `bulkDelete` behavior (see documentation)
- Moved `mentionString` from `GuildChannel` to `Channel`
- Replaced `webhooks` property with `getWebhooks` method
- Added `enableNSFW` and `disableNSFW` methods
- Added `nsfw` property

#### GuildVoiceChannel
- Removed `join` and `leave` methods until voice is re-written
- Removed `connection` property until voice is re-written
- Removed `members` properties and methods until voice is re-written

#### Invite
- Added `__hash` method, which returns `code` property
- Added `guildSplash` property
- Added `guildIcon` property
- Added `guildSplashURL` property
- Added `guildIconURL` property
- Changed `channelType` from string to number (use `enums.channelType`)
- Removed `accept` method

#### Member
- Changed base class from `Snowflake` to `UserPresence`
- Added `__hash` method, which returns `user.id` property
- Replaced `roles` properties and methods with directly accessible `ArrayIterable` property
- Replaced `setMute` method with `mute` and `unmute` methods
- Replaced `setDeaf` method with `deafen` and `undeafen` methods
- Renamed `mute` property to `muted`
- Renamed `deaf` property to `deafened`
- Changed `color` property from `Color` object to number
- Added `getColor` method to access `Color` object
- Removed `addRoles`, `removeRoles`, and `hasRoles` methods
- Changed `addRole`, `removeRole`, and `hasRole` methods to accept a roleId-resolvable
- Added optional `reason` argument to `kick`, `ban`, and `unban` methods
- Changed `kick`, `ban`, and `unban` methods to always use the member's current guild (use `guild:kickUser(member), etc` if a different guild is required)
- Changed `ban` parameters from `(days)` to `(reason, days)`
- Renamed `sendMessage` method to `send` (see `TextChannel:send`)
- Removed `Member:getMembership(guild)` (use `Guild:getMember(member)` instead)
- Added `gameType` property (use `enums.gameType`)
- Added `gameURL` property
- Changed `hasRole` method to return `true` for `@everyone` role
- Added `getPermissions` method
- Added `hasPermission` method
- Added `members` `FilteredIterable` property

#### Message
- Replaced `reactions` properties and methods with directly accessible `Cache` property
- Replaced `mentionedUsers` properties and methods with directly accessible `ArrayIterable` property
- Replaced `mentionedRoles` properties and methods with directly accessible `ArrayIterable` property
- Replaced `mentionedChannels` properties and methods with directly accessible `ArrayIterable` property
- Changed `oldContent` property from a string to a table of strings
- Removed `editedTimestamp` property (use `oldContent` keys instead)
- Moved `Message:getReactionUsers(emoji)` to `Reaction:getUsers()`
- Added `type` property
- Added `mentionsEveryone` property
- Changed `@everyone` and `@here` mentions (in `cleanContent`) to use a zero-width space instead of a null character

#### PermissionOverwrite
- Removed `name` property (directly check name of object instead)
- Replaced `object` property with `getObject` method
- Changed `allowedPermissions` property from `Permissions` object to number
- Changed `deniedPermissions` property from `Permissions` object to number
- Added `getAllowedPermissions` method to access `Permissions` object
- Added `getDeniedPermissions` method to access `Permissions` object

#### PrivateChannel
- Changed `delete` method to `leave`

#### Reaction
- Added `__hash` method, which returns the emoji ID for custom emojis or emoji name for standard emojis
- Added `delete([user])` method
- Moved `Message:getReactionUsers(emoji)` to `Reaction:getUsers()`
- Removed `emoji` property
- Added `emojiId` property
- Added `emojiName` property
- Added `emojiURL` property

#### Relationship
- New class! See documentation.

#### Role
- Changed `color` property from `Color` object to number
- Changed `permissions` property from `Permissions` object to number
- Added `getColor` method to access `Color` object
- Added `getPermissions` method to access `Permissions` object
- Changed `setColor` to accept a color-resolvable
- Changed `setPermissions` to accept a permissions-resolvable
- Replaced `setHoist` method with `hoist` and `unhoist`
- Replaced `setMentionable` method with `enableMentioning` and `disableMentioning`
- Changed `hoist` property to `hoisted`
- Replaced `setPosition` method with `moveUp` and `moveDown` methods
- Added `members` `FilteredIterable` property

#### User
- Removed `User:getMembership(guild)` (use `Guild:getMember(user)` instead)
- Replaced `privateChannel` property with `getPrivateChannel` method
- Renamed `sendMessage` method to `send` (see `TextChannel:send`)
- Renamed `avatarUrl` to `avatarURL`
- Renamed `defaultAvatarUrl` to `defaultAvatarURL`
- Renamed `getAvatarUrl` to `getAvatarURL`
- Renamed `getDefaultAvatarUrl` to `getDefaultAvatarURL`
- Changed `defaultAvatar` hashes to numbers (use `enums.defaultAvatar`)
- Changed `setAvatar` to accept a base64-resolvable
- Changed `mutualGuilds` iterator function to a `FilteredIterable` instace
- Added `fullname` property
- Removed avatar default size of 1024 (pass an explicit size to `get[Default]AvatarURL` if a size is required)
- Removed `kick`, `ban`, and `unban` methods (used `Guild` methods instead)

#### UserPresence
- New class! See documentation.

#### Webhook
- Changed `setAvatar` to accept a base64-resolvable
- Renamed `avatarUrl` to `avatarURL`
- Renamed `getAvatarUrl` to `getAvatarURL`
- Added `getDefaultAvatarURL`
- Added `defaultAvatarURL`

#### ArrayIterable
- New class! See documentation.

#### Cache
- New class! See documentation.

#### FilteredIterable
- New class! See documentation.

#### Iterable
- New class! See documentation.

#### SecondaryCache
- New class! See documentation.

#### WeakCache
- New class! See documentation.

#### Buffer
- Removed class until voice is re-written

#### Clock
- No public changes

#### Color
- Changed constructor to accept only a number (use static methods for more options)
- Changed `__tostring` to display hex value and RGB
- Added `fromHex`, `fromRGB`, `fromHSV`, and `fromHSL` static methods
- Added `toHex`, `toRGB`, `toHSV`, and `toHSL` member methods

#### Date
- New class! See documentation.

#### Deque
- No public changes

#### Emitter
- Added `onSync` and `onceSync` method s for omitting automatic coroutine-wrapping of listener callbacks
- Changed `removeListener` to remove all listeners that match the provided function instead of just the first match
- Added awaitable `waitFor` method with optional timeout
- Removed `propagate` method

#### Logger
- New class! See documentation.

#### Mutex
- No public changes

#### Permissions
- Changed `enable`, `disable`, and `has` methods to accept a string (`"sendMessages"`) or a number (`0x800` or `enums.permission.sendMessages`)

#### Stopwatch
- Added `stopped` parameter to constructor to optionally initialize a stopped stopwatch
- Renamed `pause` method to `stop`
- Renamed `resume` method to `start`
- Renamed `restart` method to `reset`
- Removed `hours`, `minutes`, `seconds`, `microseconds`, and `nanoseconds` properties
- Added `getTime` method

#### Time
- New class! See documentation.

## 1.5.1
- Added partial handling of failed socket connections
- Added special handling for reaction ratelimits

## 1.5.0
- Implemented webhook features
	- Added `Webhook` class
	- Added `Guild.webhooks` and `GuildTextChannel.webhooks` iterators  (both use an HTTP request)
	- Added `GuildTextChannel:createWebhook` method
- Text channel and message improvements
	- `bulkDelete` and `getMessageHistory` improvements
		- Added optional predicates to filter specific messages
		- `After|Before|Around` methods now optionally accept a Snowflake ID instead of a `Message` object
	- Added `firstMessage` and `lastMessage` properties to `TextChannel` (both use an HTTP request)
	- Added support for raw data file attachments
	- Added support for multiple file attachments per message
- Added `User.privatechannel` property (uses an HTTP request)
- `Guild:createRole` now accepts an initial `name` argument
- Replaced `TYPING_START` warnings with `typingStartUncached` event
- Disabled member object creation on `PRESENCE_UPDATE`
	- Fixes lingering member objects after guild leave
	- Fixes missing `joinedAt` property
	- May provide a performance improvement
	- To compensate for missing members, enable `fetchMembers` on client initialization
- Other changes
	- Fixed voice sequence and timestamp incrementing
	- Fixed `Emitter` listener addition/removal
	- Fixed crash on guild creation due to rogue member presences
	- Changed `os.exit` in `client:stop` to `process:exit`
	- Changed `print` call in console logging function to `process.stdout:write`

## 1.4.2
- Fixed bug in Guild:setOwner
- Fixed nickname not being cleared from member objects
- Minor optimization in `printf`

## 1.4.1
- Added token check to socket reconnection
- Fixed bug when setting client nickname via Member
- Added default JSON table for non-JSON HTTP responses
- Added checks for invalid client options
- Restored fixed creationix/coro dependency versions
- Extensions added:
	- `string.random` for generating random string
	- `string.split2` for splitting strings by pattern [@FiniteReality]

## 1.4.0
- Implemented automatic gateway sharding
	- Multiple shards are automatically spawned on startup according to the Discord-recommended amount
	- Added a `shardReady` event that fires as each shard finishes loading with a shard ID as its argument
	- Shard ID is also now an argument for the `resumed` and `heartbeat` events
	- `Client.shardCount` and `Guild.shardId` are accessible properties
- Overhauled token parsing and login handling:
	- Tokens can now optionally be prefixed with `Bot `
	- Tokens are validated before establishing a gateway connection; invalid tokens are rejected with an error
	- Attempts to connect or reconnect to the gateway are no longer pcall'd
	- To simplify `READY` handling, failed loading of guild chunk or sync payloads will result in `ready` never firing instead of timing out
	- Added support for compressed gateway payloads (enabled by default)
	- Replaced `gateway.cache` with `gateway.json`
- Member conveniences:
	- Added `User.mutualGuilds` iterator
	- Added `Member.color` property
	- Added `Member:hasRole` and `Member:hasRoles` methods
	- Added `Member:addRole` and `Member:removeRole` methods
	- Added member cache accessors to `GuildVoiceChannel` class
	- Improved `User:getMembership` by reducing unnecessary HTTP requests
- Other changes:
	- Optimized classes to be more memory efficient
	- Minor optimizations in `TextChannel:sendMessage`
	- Minor HTTP request optimizations
	- Removed member check from `PRESENCE_UPDATE` handler
	- Fixed functions not explicitly returning `nil` in some cases
	- Added default audio library names which can allow for automatic loading of libopus.so and libsodium.so on POSIX systems or opus.dll and sodium.dll on Windows. (Call `loadOpus` or `loadSodium` without arguments to use the defaults)
	- Fixed a missing parameter in the sodium decrypt function (not currently used by Discordia)

## 1.3.1
- Event handler optimizations
	- If an uncached guild, channel, member, or role is encountered on their respective `UPDATE` or `DELETE` events, an object is now created and cached from the event payload instead of throwing a warning.
	- Events that parse a text channel ID are now more performant; the channel is found by using an channel map instead of by iterating over guilds.
- Token parsing on login was improved
	- Tokens are no longer prepended with `Bot ` on `READY`. Tokens are tested against a REST endpoint (`/users/@me`), and are prepended with `Bot ` only if necessary.
	- If an invalid token is provided, the library will throw an error instead of entering a connect/disconnect loop.
- Opus encoder fix
	- The encode method now expects an explicitly defined PCM length instead of one implicitly defined from the input table.
	- This should fix a segmentation fault issue which apparently was a result of passing a size that is too small.
	- Fixed an oversight where the positional return value of `string.unpack` was passed to the opus encoder for FFmpeg streams.

## 1.3.0
- Message enhancements
	- Deprecated `TextChannel:sendMessage(content, mentions, tts)` format
	- `TextChannel:sendMessage(content)` is now the suggested format, where `content` is a string or table. Table properties are:
		- `content`: raw content string
	- `mentions`: mentionable object or table of mentionable objects
	- `tts`: boolean indicating whether the message is TTS
	- `nonce`: unique message identifier
	- `file`: relative or absolute path to file for attachment
	- `filename`: custom name to use for attachment (not required)
	- `embed`: table of message embed data
	- File attachments made possible by multipart/form-data implementation [@PurgePJ]
	- Added `nonce` and `oldContent` properties to `Message` class
	- Added `attachments`, `embeds`, `attachment`, and `embed` properties to `Message` class. All are exposed as raw Lua tables with original Discord formatting.
	- Added `reactionAddUncached` and `reactionRemoveUncached` events for when reactions are added/removed to messages that are uncached. A raw data table is passed as the only argument.
- Added support for larger avatars and animated Nitro avatars
	- `User:getAvatar(size)` can be used for custom sizes
	- `gif` files are automatically returned if the avatar is animated
	- `png` is still used for static avatars
- Other changes:
	- Removed unnecessary fields from `PATCH /users/@me` request
	- Added `isPlaying`, `isPaused`, and `playTime` properties to `VoiceConnection` class

## 1.2.2
- Added package metadata to main `discordia` module
- Reduced timeout on voice channel join from 10 to 5 seconds
- Fixed an overflow when writing the maximum least-significant byte to a buffer
- Fixed an issue that caused a crash after failing to join a voice channel
- Added a Clock utility class (not used by the library)
- Voice optimizations

## 1.2.1
- Fixed issue where PermissionOverwrite tostring value was not properly formatted
- Voice tweaks
	- Moved encryption mode to constants module
	- pcall'd FFmpeg handle closings to avoid rare nil error
	- Some minor optimizations

## 1.2.0
- Implemented voice-send features
	- Streaming of PCM data from strings, tables, generators, or an FFmpeg process is now possible
 - Implemented `VoiceManager`, `VoiceConnection`, `VoiceSocket`, `AudioStream`, and `FFmpegPipe` classes
 - Implemented a re-written version of Luvit's `Buffer` class
 - Implemented `libopus` and `libsodium` bindings via LuaJIT FFI
 - `VOICE_SERVER_UPDATE` is now handled
 - `Member.voiceChannel` is now an accessible and mutable property
 - `Guild.connection` and `GuildVoiceChannel.connection` is now an accessible property
 - Added `GuildVoiceChannel` `join` and `leave` methods
 - Added `creationix/coro-spawn` dependency
- Other
 - Added optional patterns to string pad extensions
 - Added `pause` and `resume` methods for `Stopwatch`
 - Outgoing gateway payloads are now coroutine-wrapped
 - Fixed gateway reconnection bug

## 1.1.0
- Implemented emoji features
	- Added Emoji and Reaction classes
	- Added message reaction methods
		- `addReaction`, `removeReaction`, `clearReactions`, `getReactionUsers`, `getReactions`
	- Added handling of message reaction and emoji events
		- `reactionAdd`, `reactionRemove`, `emojisUpdate`
	- Emoji are formally cached per guild
	- Reactions are stored per message, but are not formally cached
- Fixed issue where PermissionOverwrites for members were not named
- Added more standard library extensions:
	- `table.slice`, `string.startswith`, `string.endswith`, `string.levenshtein`

## 1.0.0

- General

	- All mentions of *server* or *Server* were changed to *guild* or *Guild* to maintain consistency with internal Discord nomenclature
	- Methods that use the REST API and that previously returned nothing now return a boolean to indicate whether the call was successful
	- Discord-compliant ratelimiting has been implemented
	- User handling has been changed slightly:
		- `User` objects are now cached once per `Client` instead of per every `PrivateChannel` and `Guild`
		- The `Member` class now wraps the `User` class instead of extending it
		- To get a user's `Member` object, use `User:getMembership(guild)`
		- A member's `User` object is accessed via `Member.user`
		- Message authors, channel recipients, and invite inviters are always `User` objects
		- Guild owners and members are always `Member` objects
	- `utils` was removed from the main `discordia` module and has been replaced by individual utility classes
	- `Warning` and `Error` classes were removed in favor of events
		- Gateway disconnects, nil values on events, and HTTP errors are now handled more gracefully
	- All modules relevant to the `Client` class were refactored and moved with it into a `client` folder:
		- `Client` now extends a custom version of Luvit's built-in `Emitter`
			- Client instances are initialized using `discordia.Client()` instead of `discordia.Client:new()`
			- A table of options can be passed to the client initializer. Currently supported options are:
				- `routeDelay`: minimum time to wait between requests per-route (default: 300 ms)
				- `globalDelay`: minimum time to wait between requests globally after a global 429 (default: 10 ms)
				- `messageLimit`: limit to the number of cached messages per channel (default: 100)
				- `largeThreshold`: limit to how many members are initially fetched per-guild on start-up (default: 100)
				- `fetchMembers`: whether to fetch all members for all guilds (default: false)
				- `autoReconnect`: whether to attempt to reconnect after an unexpected gateway disconnection (default: true)
		- `endpoints` was changed to `API`
		- `events` was changed to `EventHandler`
		- `WebSocket` was changed to `Socket`
	- Discord objects are now stored in custom `Cache` objects instead of pure Lua tables
	- Many iterators were added to help with accessing cached objects or methods that used to return a table
	- The entire class system was overhauled
		- Internally used properties and methods are now prefixed with an underscore to indicate their protected status
		- Getter and setter properties and methods have been added.
			- For every public property that can be accessed/mutated, there is an associated get/set method
			```lua
			-- these lines examples are equivalent
			local name = guild.name
			local name = guild:getName()
			```
			```lua
			-- these lines examples are equivalent
			guild.name = "foo"
			guild:setName("foo")
			```
		- Objects that have caches have a variety of get and find methods for accessing those caches. For example:
			- `guild:getRoles()` or `guild.roles` - returns an iterator for all roles in the guild
			- `guild:getRoleCount()` or `guild.roleCount` - returns the number of roles cached
			- `guild:getRole(id)` - returns the role with the given Snowflake ID
			- `guild:getRole(key, value)` - returns the first found role matching a key, value pair
			- `guild:getRoles(key, value)` - returns an iterator for all roles matching the key, value pair
			- `guild:findRole(predicate)` - returns the first found role that makes the predicate true
			- `guild:findRoles(predicate)` - returns an iterator for all roles that makes the predicate true
			```lua
			-- pre-1.0 code
			for _, role in pairs(guild.roles) do
					print(role)
			end
			```
			```lua
			-- 1.0 code
			for role in guild.roles do
				print(role)
			end

			for role in guild:getRoles() do
				print(role)
			end
			```

- Events

	- Event handling was made more reliable by using the new `Cache` objects
	- Attempts to access uncached objects are now caught, and warnings are printed to the console
	- Guild sync was implemented for non-bot accounts
	- `serverCreate` was renamed/split into `guildCreate`, `guildAvailable`, and `guildCreateUnavailable`
	- `serverDelete` was renamed/split into `guildDelete` and `guildUnavailable`
	- `messageAcknowledge` and `membersChunk` were removed
	- `memberBan` and `memberUnban` were renamed to `userBan` and `userUnban` and now provide a `User` object instead of a `Member` object
	- `voiceJoin` and `VoiceLeave` were renamed/split into `VoiceChannel[Join|Leave]` and `voice[Connected|Disconnect]`
	- `typingStart` now has a timestamp as a third argument
	- `messageUpdateUncached` and `messageDeleteUncached` events were added for uncached message events
	- `warning` and `error` events were added
	- `heartbeat` event was added with event sequence and roundtrip latency arguments

- New Classes

	- `API` - Adds a layer of abstraction between Discord's REST API and Discordia's object oriented API
	- `Container` - Base object used to store Discord objects
	- `Cache` - Data structure used to store and access `Container` objects
	- `Emitter` - A simplified re-write of Luvit's built-in event emitter
	- `Mutex` - Extension of `Deque` that is used by the `API` class to throttle HTTP requests
	- `OrderedCache` - Extension of `Cache` that maintains the order of objects as a doubly-linked list
	- `Stopwatch` - Used to measure elapsed time with nanosecond precision
	- `PermissionOverwrite` - Extension of `Snowflake` that maintains per-channel permissions

- For other API changes, please consult the Discordia [wiki](https://github.com/SinisterRectus/Discordia/wiki).

## 0.6.2
- Fixed issue where presences were applied to offline members on guild creation
- Fixed issue where roles where not properly being applied by Member:setRoles method

## 0.6.1
- Fixed issue where mentioned object would be nil
- Fixed issue with UTC time parsing
- Updated secure-socket dependency to version 0.1.4

## 0.6.0
- Member:setRoles now accepts a table of roles instead of IDs
- Tweaked internal Member updating
- Mentions are now ignored in private/direct messages
- Fixed issue where private message author was always the channel recipient
- Fixed erroneous private message parenting for User:sendMessage

## 0.5.8
- Partial restoration of class overhaul for critical fix

## 0.5.7
- Reverted class overhaul due to complicated bugs

## 0.5.6
- Added API client class (not yet exposed)
- Updated class constructor
	- Reduced memory footprint by 30 to 40%
- Added isInstanceOf utility function
- Equality operator now correctly considers type
	- Fixes an issue where Server == defaultChannel or defaultRole was true

## 0.5.5
- Fixed regression due to Message.channelId removal

## 0.5.4
- Added User object fallback for member[Ban/Unban]
- Added local datetime to Error/Warning output
- Fixed critical issue where client would not recognize a resumed connection

## 0.5.3
- Added "0x" to Color:toHex() output
- Added Permissions:toHex() method
- Fixed issue where server owner was nil
- Server.joinedAt is now a Unix timestamp
- utils.dateToTime and resulting timestamps now support milliseconds

## 0.5.2
- Fixed critical issue with lit package metadata

## 0.5.1
- Added Member:kick() overload method
- table.reverse now reverses a table in place
- Reorganized directories

## 0.5.0
- Implemented basic Permissions handling
- Added abstract Channel superclass for TextChannel and ServerChannel
- Expanded Role features
	- Member.roles is now parsed into a table of Role objects
- User.name is now the User's display name: Either User.username by default, or User.nickname if one exists
- Other Chanegs
	- Added custom delimiter to string.split
	- Overhauled WebSocket reconnection process
	- Changed mentions iterator from ipairs to pairs
	- Default argument for TextChannel:getMessageHistory changed from 50 to 1
	- Removed redundant channelId from Message class
- Bug Fixes
	- Fixed issue when trying to access nil invites or bans tables
	- Fixed issue where handleWebSocketDisconnect was improperly called
	- Minor refactoring of token caching

## 0.4.5
- Overhauled WebSocket keep alive process
- Fixed issue where Server.defaultRole was nil
- Fixed UTC issue with dateToTime utility

## 0.4.4
- Added utility for converting UTC datetime string to Unix timestamp
	- Message timestamps and Message joinedAt is now a Unix timestamp
- messageUpdate is no longer fired for non-existing messages
- Fixed @everyone mention crash

## 0.4.3
- Critical: Removed code that accesses Server.memberCount

## 0.4.2
- TextChannel improvements
	- Added adjustable limit to getMessageHistory()
	- Reimplemented broadcastTyping() from an old version
	- Implemented bulkDelete()
- Removed memberCount from Server class
- Added utility for converting snowflake ID to creation time and date
- Added string.totable
- Color class changes:
	- RGB values are now rounded
	- Added add, sub, mul, and div operators
- Added error codes to HTTP warnings and errors

## 0.4.1
- Client:setNickname now uses proper endpoint
- Fixed issue where nickname would not update
- Fixed issue where deleting private channels crashed library
- Added table.randompair and table.randomipair

## 0.4.0
- Added standard library extensions (printf, string, table, and math)
- Implemented nickname support
	- Added Client:setNickname and Member:setNickname methods
	- Added Member.nickname attribute
	- getMemberByName now also searches nickname (may change in the future)
- Implemented role color support
	- Added Color class with RGB, hex, and dec support
	- Role.color and Role:setColor() now utilize Color class
- Implemented mentions support
	- Parsed message mentions into objects within Message.mentions table
	- Added Message:mentions[Member|Role|Channel] methods
	- Added getMentionString methods for User, Role, and ServerTextChannel
	- Added object array to sendMessage/createMessage method
- Other changes
	- Moved classes out of /classes/utils folder into /classes
	- VoiceState and Invite no longer inherit from Base, since they do not have Snowflake IDs
- Bug fixes
	- Fixed issue where role would not properly update
	- Fixed issue where member status was nil
	- Fixed issue where server owner was nil

## 0.3.5
- Fixed issue where Member.gameName would be nil
- Removed logout POST until otherwise required
- Added timeout for WebSocket reconnections
- Improved rate limit handling

## 0.3.4
- ServerChannel:createInvite() now returns an Invite object
- Privatized update methods with leading underscore
- getMessageHistory now returns a table of objects
- Added User.bot parameter (boolean)
- Fixed issue where voiceLeave event would not fire

## 0.3.3
- Reworked logout and termination handling:
	- Client:logout() now also clears the stored token
	- Added Client:stop() method
	- Added Client:disconnectWebsocket() and WebSocket:disconnect() helpers
	- Renamed startWebsocketReceiver to startWebsocketHandler
	- Added condition for an expected WS disconnection, which should be only after logout() is called.
	- Added 'expected' argument to disconnect event.
- Added User.name alias for User.username

## 0.3.2
- Added HTTP 502 handling
- Caught exceptions no longer terminate the program
- Added convenient Server attributes defaultRole, defaultChannel, and me
- Added disconnect event
- Fixed missing presenceUpdate arguments
- Increased max messages to 500 per channel

## 0.3.1
- Fixed issue where offline member status was nil
- Fixed issue where nil gateways or tokens could potentially be cached as empty files
- Fixed issue where ready was not properly delayed
- Reworked login process
	- loginWithEmail accepts email and password for regular accounts only
	- loginWithToken accepts a token for any account
	- Client:run() calls the appropriate login method
	- Bot is prepended to the token according to the READY data

## 0.3.0
- Added User:sendMessage() method
- Implemented support for bot accounts
	- Client:run() now accepts email and password or token
	- Renamed Client:login(email, pass) to Client:userLogin(email, pass)
	- Added Client:botLogin(token)
	- Initially unavailable servers are now accounted for
- Implemented channel editing
	- Added general edit method for ServerChannel
	- Added setName method for ServerChannel
	- Added setTopic method for ServerTextChannel
	- Added setBitrate method for ServerVoiceChannel

## 0.2.1
- Critical: Fixed package path issue

## 0.2.0
- Overhauled class system
- Implemented exception handling
	- New Error and Warning classes
	- HTTP 400 is raised
	- HTTP 403 is warned
	- HTTP 429 is handled and warned
	- Unhandled HTTP errors are raised
	- Unhandled WebSocket events are warned
	- Unhandled WebSocket payloads are warned
- Implemented Invite handling
- Added statusUpdate WebSocket method and corresponding client methods setStatusIdle, setStatusOnline, and setGameGame
- Implemented WebSocket reconnecting

## 0.1.0
- First 'stable' release to coincide with official API documentation release
- Code overhauled for optimizations and bug fixes
- Event callbacks no longer block the main loop
- Added Member class, which extends a now simplified User class
- Implemented gateway caching
- Added 'raw' event
- Added setOwner, setAfkTimeout, setAfkChannel Server methods

## 0.0.8
- Established project name: Discordia
- Added reply example script

## 0.0.7
- Changed luvit/secure-socket version to 1.1.2
- Request data is now camelified
- Moved websocket handlers to their own Client methods
- Added op# shortcut WebSocket methods
- Role events no longer emit Server object, use role.server instead
- General Git version control employed instead of GitHub direct editing

## 0.0.6
- Implemented custom class module with multiple inheritance
- Added base Base class for Discord classes
- Added peek methods to Deque class
- Converted lone Channel class to multiple classes:
	- ServerChannel and TextChannel inherit from Base
	- PrivateChannel inherits from TextChannel
	- ServerTextChannel inherits from TextChannel and ServerChannel
	- ServerVoiceChannel inherit from ServerChannel
- Fixed token caching, which now uses an MD5 hash

## 0.0.5
- Implemented token caching
- Conformed user agent to API standard
- Message deques and maximum scrollback implemented
- Added member chunking
- 'discord' now includes utils (in addition to Client)
- Added string split and number clamp helpers to utils
- Added event handling for guildRoleCreate, guildRoleDelete, and guildRoleUpdate
- Added channel position and general role mutators
- Message updates now account for 'embeds only'

## 0.0.4
- Added getServers and getMessages User methods
- Added event handling for guildCreate, guildDelete, guildUpdate
- Added event handling for guildBanAdd and guildBanRemove
- Added event handling for guildMemberAdd, guildMemberRemove, and guildMemberUpdate
- Added getAvatarUrl method for user class
- Pasted MIT license info into package.lua

## 0.0.3
- Created PrivateChannel class
- Moved several methods from Client class to respective Discord classes
- Added event handling for typingStart, messageDelete, messageUpdate, and MessageAck
- Added event handling for channelUpdate, channelDelete, and channelCreate
- Added methods to update class instances
- Switched from multiple User classes to one main class for all types

## 0.0.2
- Added event handling for messageCreate and voiceStateUpdate
- get[Role|Channel|Server]By[Name|Id] now use cached data
- Expanded Message class

## 0.0.1
- Finished the majority of REST methods
- Started the majority of expected class definitions
- Added websocket support
- Added event handling for the ready event
