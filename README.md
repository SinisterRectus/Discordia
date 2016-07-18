# Discordia

**Discord API library written in Lua for the Luvit framework**

### Introduction

**[Discord](https://discordapp.com/)** is a freeware, multi-platform, voice and text client designed for gamers.

**[Luvit](https://luvit.io)** provides an asynchronous I/O environment for Lua, similar to that of [Node.js](https://nodejs.org/en/).

This library is a Lua wrapper for the official Discord API, and provides an object-oriented, event driven interface for developing Discord bots. By using Lua's native coroutines, asynchronous REST and WebSocket communication is internally abstracted in a way that allows end-users to write blocking-style code without blocking I/O.

Join the [Discord API server](https://discord.gg/0SBTUU1wZTWVpm07) to discuss Discordia and other Discord libraries!

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provide for your platform.
- To install the Discord library, run `lit install SinisterRectus/discordia`
- Run your Lua scripts using, for example, `luvit bot.lua`

### Bug Reports

Before reporting a library issue:
 - Make sure that you are running the latest version of both Discordia and Luvit.
 - To the best of your ability, check that the issue is a library one and not a result of your own code.
 - In the event of an uncaught exception, please provide a full stacktrace.
 - If possible, provide a stripped-down code sample that reproduces the bug.

Issues can be reported via GitHub or the Discord channel linked above. Higher priority is placed on GitHub issues.

### History

The earliest version of Discordia, before it even had that name, was released as a [Just Cause 2 Multiplayer module](https://www.jc-mp.com/forums/index.php/topic,5936.0.html) on 7 March 2016. It utilized LuaSocket, LuaSec, and Copas to provide basic REST functionality in a sandboxed Lua 5.2 environment. The goal was to bridge the game chat with a Discord client.

Due to a lack of WebSocket support and difficulties in developing a stable module, the Just Cause 2 Multiplayer project was put on hold in favor of a general-purpose Lua library for Discord. At the time, [discord.lua](https://github.com/VideahGams/discord.lua), was the only other Discord library of which I was aware. It required LuaJIT, was very incomplete, and abandoned by its author indefinitely. I decided to start my Luvit-powered library from scratch.

During the development of Discordia, I discovered that a Luvit library had come before me: [luv-discord](https://github.com/sclark39/luv-discord). Like discord.lua, it was incomplete and had not been updated for months. So, here's an honorable mention to [sclark39](https://github.com/sclark39) for doing it first, and for contributing to Discordia.

### FAQs

Why Lua?
- Lua is a scripting language that tends to be beginner-friendly, but powerful in the hands of an advanced user at the same time. Although Lua might not have the same popularity as that of other scripting languages such as Python or JavaScript, Lua's expandability makes it equally as capable as the others, while remaining easy-to-use and often more resource efficient. While Discordia has not yet been benchmarked against other libraries, it is expected to perform well due Luvit's use of LuaJIT.

Can I run Discordia as a stand-alone application?
- The lit package manager can build stand-alone executables, but Discordia is not currently configured to allow this. It must be run using a luvit executable.

Can I run this on a different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework. Porting Discordia and its dependencies to pure LuaJIT or Lua 5.x may be possible, but it is not currently a priority.

Does Discordia support voice chat?
- Voice States are cached in Discordia, but full voice support is not currently available.

How can I contribute?
- Pull requests are welcomed, but it is a good idea to check with the library author before starting a major implementation. Contributions to the Wiki are helpful, too.

How does this differ from other Lua libraries?
- Discordia was the first Lua library to be officially recognized by the Discord API community linked above. As an open source library, Discordia relies on contributions and endorsements from its users to grow and expand. There is currently a second recognized Lua library, [litcord](https://github.com/satom99/litcord), in development. Both libraries are very similar user interfaces, but they have different internal structures. Please take this into consideration when choosing to use or contribute to one of the existing, or any future Lua libraries.

### Documentation

Please visit this repository's [Wiki](https://github.com/SinisterRectus/Discordia/wiki) for Discordia documentation. Contributions are encouraged.
