local discordia = require('discordia')
local client = discordia.Client:new()

client:on('ready', function()
	p(string.format('Logged in as %s', client.user.username))
end)

client:on('messageCreate', function(message)
	-- exit early if the author is the same as the client
	if message.author == client.user then return end

	-- split the message content into and command and everything else
	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	if cmd == '!hello' then
		-- respond to the user
		message.channel:sendMessage(string.format('Hello, %s', message.author.username))
	end
end)

-- run your client
-- don't forget to change the email and password
client:run('email', 'password')
