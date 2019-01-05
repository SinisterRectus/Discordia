# Discordia

**Discord API library written in Lua for the Luvit runtime environment**

### Introduction

**[Discord](https://discordapp.com/)** is a freeware, multi-platform, voice and text client designed for gamers. It has a [documented RESTful API](https://discordapp.com/developers/docs/intro) that allows developers to make Discord bots for use on their servers.

**[Luvit](https://luvit.io)** is an open-source, asynchronous I/O Lua runtime environment. It is a combination of [LuaJIT](http://luajit.com/) and [libuv](http://libuv.org/), layered with various libraries to provide server-side functionality similar to that of [Node.js](https://nodejs.org/en/), but with Lua instead of JavaScript. Luvit's companion package manager, lit, makes it easy to set up the Luvit runtime and its published libraries.

Discordia is a Lua wrapper for the official Discord API, and provides a high-level, object-oriented, event-driven interface for developing Discord bots. By using Lua's native coroutines, asynchronous HTTP and WebSocket communication is internally abstracted in a way that allows end-users to write blocking-style code without blocking I/O operations.

Join the [Discord API community](https://discord.gg/NKM3XmF) to discuss Discordia and other Discord libraries!

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provided for your platform.
- To install Discordia, run `lit install SinisterRectus/discordia`
- Run your bot script using, for example, `luvit bot.lua`

### Example

```lua
local discordia = require('discordia')
local client = discordia.Client()

client:on('ready', function()
	print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(message)
	if message.content == '!ping' then
		message.channel:send('Pong!')
	end
end)

client:run('Bot INSERT_TOKEN_HERE')
```

### Documentation

Please visit this project's [Wiki](https://github.com/SinisterRectus/Discordia/wiki) for documentation and tutorials.

### History

The earliest version of Discordia, before it even had that name, was released as a [Just Cause 2 Multiplayer module](https://www.jc-mp.com/forums/index.php/topic,5936.0.html) on 7 March 2016. It utilized LuaSocket, LuaSec, and (eventually) Copas to provide basic REST functionality in a sandboxed Lua 5.2 environment. The goal was to bridge the game chat with a Discord client. Due to a lack of WSS support (at the time), the project was put on hold in favor of a general-purpose Lua library for Discord. After finishing a relatively stable version of Discordia, the JC2MP bridge was re-designed to connect with Discordia via inter-process communication.

### FAQs

Why Lua?
- Lua is a lightweight scripting language that tends to be beginner-friendly, but powerful in the hands of an advanced user at the same time. Although Lua might not have the same popularity as that of other scripting languages such as Python or JavaScript, Lua's expandability makes it equally as capable as the others, while remaining easy-to-use and often more resource efficient.

Why Luvit?
- Luvit makes Lua web development an easy task on multiple platforms. Its [installation](https://luvit.io/install.html) process is (optionally) automated and uses pre-built [luvi cores](https://github.com/luvit/luvi/releases) when available. It also comes with many libraries essential to async I/O programming and networking. Compared to Node.js, Luvit [advertises](https://luvit.io/blog/luvit-reborn.html) similar speed, but reduced memory consumption. Compared to other Discord libraries, Discordia is expected to perform well due Luvit's use of LuaJIT, although it has not been benchmarked.

Can I run this on a different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework and its package manager. Porting Discordia and its dependencies to classic Lua or LuaJIT may be possible, but this is not a current project goal.

How can I contribute?
- Pull requests are welcomed, but please check with the library author before starting a major implementation. Contributions to the Wiki are helpful, too.

Are there other Discord libraries?
- Absolutely. Check the official [libraries](https://discordapp.com/developers/docs/topics/community-resources) page of the Discord API documentation or the unofficial Discord API server linked above.
