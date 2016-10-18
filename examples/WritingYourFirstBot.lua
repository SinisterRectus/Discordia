local discordia = require('discordia')
local client = discordia.Client:new()

-- this gets triggered every time someone joins a server where your bot is in.
client:on(
	'memberJoin',
	function(member) -- member will be the var that I'll use to access everything that is in the member object.
		-- from here everything will be executed EVERY time someone joins the server.
		if not member then return end -- a simple check (not necessary).
		-- we set up a welcome message.
		local WelcomeMessage = string.format("Hey %s, how is it going? Welcome to our server!", member.username) -- as previously said, 'member' is formed by different values, username is one of them.
		-- we have two options, 1. PMing the user a welcome message or 2. Welcoming him in a channel.
		-- Option 1:
		member:sendMessage(WelcomeMessage) -- By adding the object before :sendMessage we state where do we want to send the message.
		-- Option 2:
		-- we can specify where we want to send the message; all we need is the server ID and channel ID. As you are in Developer Mode (check the picture above) you can get IDs easily now, right click your server and press Copy ID, same for the channel.
		client:getServerById("YourServerID"):getChannelById("YourChannelID"):sendMessage(WelcomeMessage)
end)
