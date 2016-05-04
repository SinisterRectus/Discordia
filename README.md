# Discordia

**Discord API library written in Lua for the Luvit framework**

### Introduction

**[Discord](https://discordapp.com/)** is a free, multi-platform, voice and text client designed for gamers.

**[Luvit](https://luvit.io)** provides an asynchronous I/O environment for Lua, similar that of [Node.js](https://nodejs.org/en/).

This library provides an object-oriented environment for developing Discord bots or clients using Lua. Coroutines are used internally for asynchronous operations, while emitters and callbacks are used for event handling.

Join the [Discord API server](https://discord.gg/0SBTUU1wZTWVpm07) to discuss Discordia and other Discord libraries!

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provide for your platform.
- To install the Discord library, run `lit install SinisterRectus/discordia`
- Run your Lua scripts using, for example, `luvit bot.lua`

### FAQs

Can I run this on different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework, which is built on top of LuaJIT. Porting Discordia and its dependencies to pure LuaJIT or Lua 5.x may be possible, but it is not currently a priority.

Does Discordia support voice chat?
- There are no plans to implement voice chat at this time.

### To-Do

- Finish documentation
- Fix rate limiting per coroutine / per bucket
- Add timeout for WebSocket reconnection
- Nickname support
- Permissions and Roles
- Color class
- Embeds, mentions, and file sending
- Optional Client initialization arguments
- Table and string extensions
- Iterators for things like getServers

### Changelog

*Backwards compatibility not guaranteed until after version 1.0.0*

- Future
	- Removed logout POST until otherwise required
	- Added timeout for WebSocket reconnections


- 0.3.4
	- ServerChannel:createInvite() now returns an Invite object
	- Privatized update methods with leading underscore
	- getMessageHistory now returns a table of objects
	- Added User.bot parameter (boolean)
	- Fixed issue where voiceLeave event would not fire


- 0.3.3
	- Reworked logout and termination handling:
		- Client:logout() now also clears the stored token
		- Added Client:stop() method
		- Added Client:disconnectWebsocket() and WebSocket:disconnect() helpers
		- Renamed startWebsocketReceiver to startWebsocketHandler
		- Added condition for an expected WS disconnection, which should be only after logout() is called.
		- Added 'expected' argument to disconnect event.
	- Added User.name alias for User.username


- 0.3.2
	- Added HTTP 502 handling
	- Caught exceptions no longer terminate the program
	- Added convenient Server attributes defaultRole, defaultChannel, and me
	- Added disconnect event
	- Fixed missing presenceUpdate arguments
	- Increased max messages to 500 per channel


- 0.3.1
	- Fixed issue where offline member status was nil
	- Fixed issue where nil gateways or tokens could potentially be cached as empty files
	- Fixed issue where ready was not properly delayed
	- Reworked login process
		- loginWithEmail accepts email and password for regular accounts only
		- loginWithToken accepts a token for any account
		- Client:run() calls the appropriate login method
		- Bot is prepended to the token according to the READY data


- 0.3.0
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


- 0.2.1
	- Fixed package path issue


- 0.2.0
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


- 0.1.0
	- First 'stable' release to coincide with official API documentation release
	- Code overhauled for optimizations and bug fixes
	- Event callbacks no longer block the main loop
	- Added Member class, which extends a now simplified User class
	- Implemented gateway caching
	- Added 'raw' event
	- Added setOwner, setAfkTimeout, setAfkChannel Server methods


- 0.0.8
	- Established project name: Discordia
	- Added reply example script


- 0.0.7
	- Changed luvit/secure-socket version to 1.1.2
	- Request data is now camelified
	- Moved websocket handlers to their own Client methods
	- Added op# shortcut WebSocket methods
	- Role events no longer emit Server object, use role.server instead
	- General Git version control employed instead of GitHub direct editing


- 0.0.6
	- Implemented custom class module with multiple inheritance
	- Added base Base class for Discord classes
	- Added peek methods to Deque class
	- Converted lone Channel class to multiple classes:
		- ServerChannel and TextChannel inherit from Base
		- PrivateChannel inherits from TextChannel
		- ServerTextChannel inherits from TextChannel and ServerChannel
		- ServerVoiceChannel inherit from ServerChannel
	- Fixed token caching, which now uses an MD5 hash


- 0.0.5
	- Implemented token caching
	- Conformed user agent to API standard
	- Message deques and maximum scrollback implemented
	- Added member chunking
	- 'discord' now includes utils (in addition to Client)
	- Added string split and number clamp helpers to utils
	- Added event handling for guildRoleCreate, guildRoleDelete, and guildRoleUpdate
	- Added channel position and general role mutators
	- Message updates now account for 'embeds only'


- 0.0.4
	- Added getServers and getMessages User methods
	- Added event handling for guildCreate, guildDelete, guildUpdate
	- Added event handling for guildBanAdd and guildBanRemove
	- Added event handling for guildMemberAdd, guildMemberRemove, and guildMemberUpdate
	- Added getAvatarUrl method for user class
	- Pasted MIT license info into package.lua


- 0.0.3
	- Created PrivateChannel class
	- Moved several methods from Client class to respective Discord classes
	- Added event handling for typingStart, messageDelete, messageUpdate, and MessageAck
	- Added event handling for channelUpdate, channelDelete, and channelCreate
	- Added methods to update class instances
	- Switched from multiple User classes to one main class for all types


- 0.0.2
	- Added event handling for messageCreate and voiceStateUpdate
	- get[Role|Channel|Server]By[Name|Id] now use cached data
	- Expanded Message class


- 0.0.1
	- Finished the majority of REST methods
	- Started the majority of expected class definitions
	- Added websocket support
	- Added event handling for the ready event
