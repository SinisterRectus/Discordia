local discordia = require("discordia")
local client = discordia.Client()

-- enables receiving message.content so it is not empty
-- make sure you also enable it in Developer Portal
-- see https://github.com/SinisterRectus/Discordia/discussions/369
client:enableIntents(discordia.enums.gatewayIntent.messageContent)

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
