local discordia = require('discordia')
local client = discordia.Client()

-- this gets triggered every time someone joins a guild where your bot is in.
client:on('memberJoin', function(member) -- member will be the var that I'll use to access everything that is in the member object.
	-- we set up a welcome message.
	local WelcomeMessage = string.format("Hey %s, how is it going? Welcome to our guild!", member.name) -- as previously said, 'member' is formed by different values, name is one of them.
	
	-- This will send a DM
	member:sendMessage(WelcomeMessage) -- By adding the object before :sendMessage we state where do we want to send the message.
	
	-- we can specify where we want to send the message; all we need is the guild ID and channel ID. As you are in Developer Mode (if not check the guide again) you can get IDs easily now, right click your guild and press Copy ID, same for the channel.
	-- This will send the message to the specified channel
	client:getGuild("YourGuildID"):getChannel("YourChannelID"):sendMessage(WelcomeMessage)
end)

-- Let's say we want to mention someone with our bot:
client:on('messageCreate', function(message)

	local cmd, arg = string.match(message.content, '(%S+) (.*)')
	cmd = cmd or message.content
		
	if message.content == "!mention" then
		message.channel:sendMessage(string.format("%s mentioned!", message.author.mentionString)
	end


	if cmd == "!guild" then
		if arg == "name" then -- you should type !guild name in chat to call this
			message.channel:sendMessage(string.format("The name of this guild is %s.", message.guild.name)
		elseif arg == "id" then
			message.channel:sendMessage(string.format("The id of this guild is %s.", message.guild.id)
		else
			message.channel:sendMessage("Invalid argument.")
		end
	end	
end)


client:run("YourBotToken")
