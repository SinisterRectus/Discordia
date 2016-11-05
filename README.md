# Discordia

**Discord API library written in Lua for the Luvit runtime environment**

### Introduction

**[Discord](https://discordapp.com/)** is a freeware, multi-platform, voice and text client designed for gamers. It has a [documented RESTful API](https://discordapp.com/developers/docs/intro) that allows developers to make Discord bots for use on their servers.

**[Luvit](https://luvit.io)** is an open-source, asynchronous I/O Lua runtime environment. It is a version of [LuaJIT](http://luajit.com/) combined with [libuv](http://libuv.org/) and layered with various libraries to provide an API similar to that of [Node.js](https://nodejs.org/en/), but with Lua instead of JavaScript. Luvit's companion package manager, lit, makes it easy to set up the Luvit runtime and its published libraries.

Discordia is a Lua wrapper for the official Discord API, and provides a high-level, object-oriented, event driven interface for developing Discord bots. By using Lua's native coroutines, asynchronous HTTP and WebSocket communication is internally abstracted in a way that allows end-users to write blocking-style code without blocking I/O operations.

Join the [Discord API community](https://discord.gg/0SBTUU1wZTWVpm07) to discuss Discordia and other Discord libraries!

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provide for your platform.
- To install the Discord library, run `lit install SinisterRectus/discordia`
- Run your bot script using, for example, `luvit bot.lua`

### Documentation

Please visit this project's [Wiki](https://github.com/SinisterRectus/Discordia/wiki) for documentation and tutorials.

### Bug Reports

Before reporting a library issue:
 - Make sure that you are running the latest version of both Discordia and Luvit.
 - To the best of your ability, check that the issue is a library one and not a result of your own code.
 - Please provide a full stacktrace or console message when applicable.
 - If possible, provide a reduced code sample that reproduces the bug.

Issues can be reported via GitHub or the Discord channel linked above. Higher priority is placed on GitHub issues.

### History

The earliest version of Discordia, before it even had that name, was released as a [Just Cause 2 Multiplayer module](https://www.jc-mp.com/forums/index.php/topic,5936.0.html) on 7 March 2016. It utilized LuaSocket, LuaSec, and (eventually) Copas to provide basic REST functionality in a sandboxed Lua 5.2 environment. The goal was to bridge the game chat with a Discord client.

Due to a lack of secure WebSocket support (at the time) and difficulties in developing a stable module, the Just Cause 2 Multiplayer project was put on hold in favor of a general-purpose Lua library for Discord. At the time, [discord.lua](https://github.com/VideahGams/discord.lua), was the only other Discord library of which I was aware. It ran on LuaJIT, was very incomplete, and abandoned by its author indefinitely. I decided to start my Luvit-powered library from scratch.

During the development of Discordia, I discovered that a Luvit library had come before me: [luv-discord](https://github.com/sclark39/luv-discord). Like discord.lua, it was incomplete and had not been updated for months. Here is an honorable mention to [sclark39](https://github.com/sclark39) for doing it first, and for briefly contributing to Discordia.

### FAQs

Why Lua?
- Lua is a scripting language that tends to be beginner-friendly, but powerful in the hands of an advanced user at the same time. Although Lua might not have the same popularity as that of other scripting languages such as Python or JavaScript, Lua's expandability makes it equally as capable as the others, while remaining easy-to-use and often more resource efficient.

Why Luvit?
- Compared to classic Lua or LuaJIT, Luvit is easier to get up and running on all platforms. Luvit's [installation](https://luvit.io/install.html) process is (optionally) automated and uses pre-built [luvi cores](https://github.com/luvit/luvi/releases) when available. Luvit also comes with many libraries essential to async I/O programming and networking. Compared to Node.js, Luvit [advertises](https://luvit.io/blog/luvit-reborn.html) similar speed, but significantly reduced memory consumption. Compared to other Discord libraries, Discordia is expected to perform well due Luvit's use of LuaJIT, although it has not yet been benchmarked.

Can I run Discordia as a stand-alone application?
- The lit package manager can build stand-alone executables, but Discordia is not currently configured to allow this. It must be run using a luvit executable.

Can I run this on a different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework and its package manager. Porting Discordia and its dependencies to pure Lua or LuaJIT may be possible, but it is not currently a priority.

Does Discordia support voice chat?
- Voice states are cached in Discordia, but full voice support is not currently available.

How can I contribute?
- Pull requests are welcomed, but please check with the library author before starting a major implementation. Contributions to the Wiki are helpful, too.

Are there other Lua libraries?
- Discordia was the first Lua library to be officially recognized by the Discord API community. There is a second recognized Lua library, [litcord](https://github.com/satom99/litcord), and at least two abanonded libraries (mentioned above). If you'd like to contribute Lua code to a Discord project, please consider contributing to the Lua libraries already recognized by the Discord API community.
