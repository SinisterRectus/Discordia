# Discordia

**Discord API library written in Lua for the Luvit framework**

### Introduction

**[Discord](https://discordapp.com/)** is a free, multi-platform, voice and text client designed for gamers.

**[Luvit](https://luvit.io)** provides an asynchronous I/O environment for Lua, similar to that of [Node.js](https://nodejs.org/en/).

This library is a Lua wrapper for the official Discord API, and provides an object-oriented, event driven interface for rapidly developing Discord bots. By using Lua's native coroutines, asynchronous REST and WebSocket communication is internally abstracted in a way that allows end-users to write blocking-style code without blocking I/O.

Join the [Discord API server](https://discord.gg/0SBTUU1wZTWVpm07) to discuss Discordia and other Discord libraries!

### Installation

- To install Luvit, visit https://luvit.io and follow the instructions provide for your platform.
- To install the Discord library, run `lit install SinisterRectus/discordia`
- Run your Lua scripts using, for example, `luvit bot.lua`

### FAQs

Why Lua?
- Lua is a scripting language that tends to be beginner-friendly, but powerful in the hands of an advanced user at the same time. Although Lua might not have the same popularity as that of other scripting languages such as Python or JavaScript, Lua's expandability makes it equally as capable as the others, while remaining easy-to-use and often more resource efficient. While Discordia has not yet been benchmarked against other libraries, it is expected to perform well due Luvit's use of LuaJIT.

Can I run Discordia as a stand-alone application?
- The lit package manager can build stand-alone executables, but Discordia is not currently configured to allow this. It must be run using a luvit executable.

Can I run this on a different Lua distribution?
- The development and deployment of Discordia relies on the Luvit framework. Porting Discordia and its dependencies to pure LuaJIT or Lua 5.x may be possible, but it is not currently a priority.

Does Discordia support voice chat?
- There are no plans to implement voice chat at this time.

How can I contribute?
- Pull requests are welcomed, but it is a good idea to check with the library author before starting a major implementation. Contributions to the Wiki are helpful, too.

### Documentation

Please visit this repository's [Wiki](https://github.com/SinisterRectus/Discordia/wiki) for Discordia documentation. Contributions are encouraged.
