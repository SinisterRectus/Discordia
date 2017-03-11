# Changelog

### 1.4.2
- Fixed bug in Guild:setOwner
- Fixed nickname not being cleared from member objects
- Minor optimization in `printf`


### 1.4.1
- Added token check to socket reconnection
- Fixed bug when setting client nickname via Member
- Added default JSON table for non-JSON HTTP responses
- Added checks for invalid client options
- Restored fixed creationix/coro dependency versions
- Extensions added:
  - `string.random` for generating random string
  - `string.split2` for splitting strings by pattern [@FiniteReality]


### 1.4.0
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


### 1.3.1
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


### 1.3.0
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


### 1.2.2
- Added package metadata to main `discordia` module
- Reduced timeout on voice channel join from 10 to 5 seconds
- Fixed an overflow when writing the maximum least-significant byte to a buffer
- Fixed an issue that caused a crash after failing to join a voice channel
- Added a Clock utility class (not used by the library)
- Voice optimizations


### 1.2.1
- Fixed issue where PermissionOverwrite tostring value was not properly formatted
- Voice tweaks
  - Moved encryption mode to constants module
  - pcall'd FFmpeg handle closings to avoid rare nil error
  - Some minor optimizations


### 1.2.0
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


### 1.1.0
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


### 1.0.0

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
			-- 1.0 code ...
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


### 0.6.2
- Fixed issue where presences were applied to offline members on guild creation
- Fixed issue where roles where not properly being applied by Member:setRoles method


### 0.6.1
- Fixed issue where mentioned object would be nil
- Fixed issue with UTC time parsing
- Updated secure-socket dependency to version 0.1.4


### 0.6.0
- Member:setRoles now accepts a table of roles instead of IDs
- Tweaked internal Member updating
- Mentions are now ignored in private/direct messages
- Fixed issue where private message author was always the channel recipient
- Fixed erroneous private message parenting for User:sendMessage


### 0.5.8
- Partial restoration of class overhaul for critical fix


### 0.5.7
- Reverted class overhaul due to complicated bugs


### 0.5.6
- Added API client class (not yet exposed)
- Updated class constructor
  - Reduced memory footprint by 30 to 40%
- Added isInstanceOf utility function
- Equality operator now correctly considers type
  - Fixes an issue where Server == defaultChannel or defaultRole was true


### 0.5.5
- Fixed regression due to Message.channelId removal


### 0.5.4
- Added User object fallback for member[Ban/Unban]
- Added local datetime to Error/Warning output
- Fixed critical issue where client would not recognize a resumed connection


### 0.5.3
- Added "0x" to Color:toHex() output
- Added Permissions:toHex() method
- Fixed issue where server owner was nil
- Server.joinedAt is now a Unix timestamp
- utils.dateToTime and resulting timestamps now support milliseconds


### 0.5.2
- Fixed critical issue with lit package metadata


### 0.5.1
- Added Member:kick() overload method
- table.reverse now reverses a table in place
- Reorganized directories


### 0.5.0
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


### 0.4.5
- Overhauled WebSocket keep alive process
- Fixed issue where Server.defaultRole was nil
- Fixed UTC issue with dateToTime utility


### 0.4.4
- Added utility for converting UTC datetime string to Unix timestamp
	- Message timestamps and Message joinedAt is now a Unix timestamp
- messageUpdate is no longer fired for non-existing messages
- Fixed @everyone mention crash


### 0.4.3
- Critical: Removed code that accesses Server.memberCount


### 0.4.2
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


### 0.4.1
- Client:setNickname now uses proper endpoint
- Fixed issue where nickname would not update
- Fixed issue where deleting private channels crashed library
- Added table.randompair and table.randomipair


### 0.4.0
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


### 0.3.5
- Fixed issue where Member.gameName would be nil
- Removed logout POST until otherwise required
- Added timeout for WebSocket reconnections
- Improved rate limit handling


### 0.3.4
- ServerChannel:createInvite() now returns an Invite object
- Privatized update methods with leading underscore
- getMessageHistory now returns a table of objects
- Added User.bot parameter (boolean)
- Fixed issue where voiceLeave event would not fire


### 0.3.3
- Reworked logout and termination handling:
	- Client:logout() now also clears the stored token
	- Added Client:stop() method
	- Added Client:disconnectWebsocket() and WebSocket:disconnect() helpers
	- Renamed startWebsocketReceiver to startWebsocketHandler
	- Added condition for an expected WS disconnection, which should be only after logout() is called.
	- Added 'expected' argument to disconnect event.
- Added User.name alias for User.username


### 0.3.2
- Added HTTP 502 handling
- Caught exceptions no longer terminate the program
- Added convenient Server attributes defaultRole, defaultChannel, and me
- Added disconnect event
- Fixed missing presenceUpdate arguments
- Increased max messages to 500 per channel


### 0.3.1
- Fixed issue where offline member status was nil
- Fixed issue where nil gateways or tokens could potentially be cached as empty files
- Fixed issue where ready was not properly delayed
- Reworked login process
	- loginWithEmail accepts email and password for regular accounts only
	- loginWithToken accepts a token for any account
	- Client:run() calls the appropriate login method
	- Bot is prepended to the token according to the READY data


### 0.3.0
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


### 0.2.1
- Critical: Fixed package path issue


### 0.2.0
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


### 0.1.0
- First 'stable' release to coincide with official API documentation release
- Code overhauled for optimizations and bug fixes
- Event callbacks no longer block the main loop
- Added Member class, which extends a now simplified User class
- Implemented gateway caching
- Added 'raw' event
- Added setOwner, setAfkTimeout, setAfkChannel Server methods


### 0.0.8
- Established project name: Discordia
- Added reply example script


### 0.0.7
- Changed luvit/secure-socket version to 1.1.2
- Request data is now camelified
- Moved websocket handlers to their own Client methods
- Added op# shortcut WebSocket methods
- Role events no longer emit Server object, use role.server instead
- General Git version control employed instead of GitHub direct editing


### 0.0.6
- Implemented custom class module with multiple inheritance
- Added base Base class for Discord classes
- Added peek methods to Deque class
- Converted lone Channel class to multiple classes:
	- ServerChannel and TextChannel inherit from Base
	- PrivateChannel inherits from TextChannel
	- ServerTextChannel inherits from TextChannel and ServerChannel
	- ServerVoiceChannel inherit from ServerChannel
- Fixed token caching, which now uses an MD5 hash


### 0.0.5
- Implemented token caching
- Conformed user agent to API standard
- Message deques and maximum scrollback implemented
- Added member chunking
- 'discord' now includes utils (in addition to Client)
- Added string split and number clamp helpers to utils
- Added event handling for guildRoleCreate, guildRoleDelete, and guildRoleUpdate
- Added channel position and general role mutators
- Message updates now account for 'embeds only'


### 0.0.4
- Added getServers and getMessages User methods
- Added event handling for guildCreate, guildDelete, guildUpdate
- Added event handling for guildBanAdd and guildBanRemove
- Added event handling for guildMemberAdd, guildMemberRemove, and guildMemberUpdate
- Added getAvatarUrl method for user class
- Pasted MIT license info into package.lua


### 0.0.3
- Created PrivateChannel class
- Moved several methods from Client class to respective Discord classes
- Added event handling for typingStart, messageDelete, messageUpdate, and MessageAck
- Added event handling for channelUpdate, channelDelete, and channelCreate
- Added methods to update class instances
- Switched from multiple User classes to one main class for all types


### 0.0.2
- Added event handling for messageCreate and voiceStateUpdate
- get[Role|Channel|Server]By[Name|Id] now use cached data
- Expanded Message class


### 0.0.1
- Finished the majority of REST methods
- Started the majority of expected class definitions
- Added websocket support
- Added event handling for the ready event
