local discordia = require('discordia')
local client = discordia.Client()
local WebhookClient


client:on("ready", function()
	WebhookClient = discordia.WebhookClient("id", "token", {name = "Discordia's new era!"})
	p("Getters")
	print("token: " .. WebhookClient.token .. " from WebhookClient Instance.\n")

	print("ID: " .. WebhookClient.id .. " from WebhookClient Instance.\n")

	print("avatar: " .. WebhookClient.avatar .. " from WebhookClient Instance.\n")

	print("guildId: " .. WebhookClient.guildId .. " from WebhookClient Instance.\n")

	print("channelId: " .. WebhookClient.channelId .. " from WebhookClient Instance.\n")

	print("name: " .. WebhookClient.name .. " from WebhookClient Instance.\n")

	p("Setters")
	print("Changing WebhookClient name")
	WebhookClient:setName("Yes")

	print("Changing WebhookClient avatar")
	WebhookClient:setAvatar("shah.png")
	
	WebhookClient:send("hi")
	

	p("Functions")
	WebhookClient:send("Hi")

	WebhookClient:send("Sending 1 files.", {
		file = "HelloDiscord.ia"
	})
	
	-- There's also delete, Slack compatible (executeSlackCompatible(body)) - Github compatible (executeGitHubCompatible(body)) webhook functions

--[[
		Embedded message
	WebhookClient:send("Sending embedded message.", {
		embeds = {
			{
				title = "Test",
				description = "Is this working?",
				color = 15020811
			}
		}
	})
	

]]
end)

client:on("messageCreate", function(message)
	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content

	if cmd == "!name" then
		if arg then
			WebhookClient:setName(arg):send("Name changed.")
		end
	end
end)

client:run("Bot token")
