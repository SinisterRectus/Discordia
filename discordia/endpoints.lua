local api = "https://discordapp.com/api"

return {
	gateway = api .. "/gateway",
	users = api .. "/users",
	me = api .. "/users/@me",
	register = api .. "/auth/register",
	login = api .. "/auth/login",
	logout = api .. "/auth/logout",
	servers = api .. "/guilds",
	channels = api .. "/channels",
	invites = api .. "/invites",
	voice = api .. "/voice"
}
