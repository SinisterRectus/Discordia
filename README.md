# Discordia

**Discord API library written in Lua for the Luvit framework**

### Introduction

**[Discord](https://discordapp.com/)** is a free, multi-platform, voice and text client designed for gamers.

**[Luvit](https://luvit.io)** provides an asynchronous I/O environment for Lua, similar to that of [Node.js](https://nodejs.org/en/).

This library provides an object-oriented environment for developing Discord bots using Lua. Coroutines are used internally for asynchronous operations, while emitters and callbacks are used for event handling.

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

How can I contribute?
- Pull requests are welcomed, but it is a good idea to check with the library author before starting a major implementation. Contributions to the Wiki are helpful, too.

### Documentation

Please visit this repository's [Wiki](https://github.com/SinisterRectus/Discordia/wiki) for Discordia documentation. Contributions are encouraged.

### To-Do

- Finish documentation
- User.nickname
- Permissions and Roles
- Embeds and file sending
- Optional Client initialization arguments
- Iterators for things like getServers
- Game streaming URL
- Sharding
