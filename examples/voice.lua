local discordia = require('discordia')
local client = discordia.Client()

-- load the proper voice libraries
-- see the voice docs for more information
client.voice:loadOpus('libopus')
client.voice:loadSodium('libsodium')

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

	-- have the bot join your voice channel and play a music file
	if cmd == '!play' then -- example: "!play music.mp3"
		if message.member and message.member.voiceChannel then
			local connection = message.member.voiceChannel:join()
			if connection then
				return connection:playFile(arg)
			end
		end
		return message:reply('Could not join voice channel!')
	end

end)

-- run your client
-- don't forget to change the token to your own!
client:run('INSERT_TOKEN_HERE')
