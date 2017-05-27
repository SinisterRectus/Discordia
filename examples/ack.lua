-- this example marks every message read so you don't have to read them to get those pesky dots out from next to your channels/servers

local lib = require('discordia')
local bot = lib.Client:new()

bot:on('ready', function()
	print('Authenticated as ' .. bot.user.username)
end)

bot:on('messageCreate', function(msg)
  if msg.author == bot.user then return end -- you should try not to ack your own messages, even though it does nothing, I'd prefer you didn't
	msg:acknowledge() -- marks a message read (bot users will error when trying to use this, only use this with regular accounts)
	print('Acknowledged message "' .. msg.content .. '" in channel "' .. msg.channel.name .. '" in server "' .. msg.server.name .. '"')
	-- logs the message so if the user wants to see it, they can look in the terminal/command prompt (it also lists what channel and server it was sent in)
end)

bot:run('email here', 'password here') -- don't use a token, use your user account, because bot accounts won't work with this
