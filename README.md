# Discordia

**Discord API library written in Lua for the Luvit framework**

### Introduction

**[Discord](https://discordapp.com/)** is a free, multi-platform, voice and text client designed for gamers.

**[Luvit](https://luvit.io)** provides an asynchronous I/O environment for Lua, similar that of [Node.js](https://nodejs.org/en/).

This library provides an object-oriented environment for developing Discord bots or clients using Lua. Coroutines are used internally for asynchronous operations, while emitters and callbacks are used for event handling.

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provide for your platform.
- To install the Discord library, run `lit install SinisterRectus/discordia`
- Run your Lua scripts using, for example, `luvit bot.lua`

### FAQs

Can I run this on different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework, which is built on top of LuaJIT. Porting Discordia and its dependencies to pure LuaJIT or Lua 5.x may be possible, but it is not currently a priority.

Does Discordia support voice chat?
- The API can be used to move in and out of  voice channels, but there are no plans to implement voice chat at this time.

### To-Do
- Finish documentation
- Expand websocket support
- Bot accounts
- Permissions and Roles
- Embeds, mentions, and file sending
- Container class with get/add/find methods
- ???

### Changelog

*Backwards compatibility not guaranteed until after version 1.0.0*

- Future
	- Overhauled class system
	- Added Error and Warning classes
	- Implemented Invite handling
	- 403 (forbidden) and 429 (too many requests) HTTP errors are now handled


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
	- Added Server documentation
	- Added reply example script


- 0.0.7
	- Started writing documents
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
