# Changelog

*Backwards compatibility not guaranteed until after version 1.0.0*

### Future
- Added User object fallback for member[Ban/Unban]


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
