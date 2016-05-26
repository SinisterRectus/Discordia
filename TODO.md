Upcoming

- perms and roles (parse mem.roles)

Probable additions
- Add a REST client that handles most, if not all, REST methods.
- Add methods like Client:sendMessage(messageId, channelId, content). If the objects are not found in cache by ID, then they are grabbed with the REST client.
- Handle USER_SETTINGS_UPDATE
- Move Server/Channel/Role positions
- Embeds and file sharing
- Sharding
- Optional Client init args (max messages, grab initial messages, auto reconnect, auto retry, max retries, default date format)
- Change Server to Guild
- Get server icon
- Implement Game object
- Twitch streaming url
- Better rate limiting

Possible additions
- Change Client to use custom class
- Iterators for things like getServers
- Implement private/public attributes
- Cache objects

Fixes Needed
- Make delayed ready event more explicit
- Add milliseconds to message.timestamp
- Remove channel id from message
- Change mentions iterator to pairs
- Fix voice state count
- Fix game updating
