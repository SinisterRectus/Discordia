local discordia = require('discordia')
local client = discordia.Client()

client:on('ready', function()
	-- print to the console on a successful login
	-- p is luvit's global pretty-print function
	p(string.format('Logged in as %s', client.user.username))
end)

client:on('messageCreate', function(message)
	-- exit early if the author is the same as the client
	if message.author == client.user then return end

	-- split the message content into a command and everything else
	local cmd, arg = message.content:match('(%S+)%s+(.*)')
	cmd = cmd or message.content

	-- respond to the user if they type '!hello'
	if cmd == '!hello' then
		message.channel:sendMessage(string.format('Hello, %s', message.author.username))
	end

	-- send a direct message to the message author
	if cmd == '!dm' then
		message.author:sendMessage(string.format("Hey, %s, how are you?", message.author.username))
	end

end)

-- run your client
-- don't forget to change the token to your own!
client:run('INSERT_TOKEN_HERE')
