local discordia = require("discordia")
local client = discordia.Client()

client:on("ready", function() -- bot is ready
	print("Logged in as " .. client.user.username)
end)

client:on("messageCreate", function(message)

	local content = message.content

	if content == "!ping" then
		message:reply("Pong!")
	elseif content == "!pong" then
		message:reply("Ping!")
	end

end)

client:run("Bot BOT_TOKEN") -- replace BOT_TOKEN with your bot token
