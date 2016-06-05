Probable additions
- Add a REST client that handles most, if not all, REST methods.
	- Can use for methods like Client:sendMessage(channelId, content) when only the IDs are known.
	- Can be called by methods like Channel:sendMessage(content) when the objects exist.
	- Can be used with getObjectById when the object is not cached.
	- Better rate limiting
	- Error codes
- Handle USER_SETTINGS_UPDATE
- Handle MESSAGE_BULK_DELETE
- Move Server/Channel/Role positions
- Embeds and file sharing
- Sharding
- Optional Client init args (max messages, grab initial messages, auto reconnect, auto retry, max retries, default date format, toggle caching)
- Change Server to Guild
- Get server icon
- Implement Game object
- Twitch streaming url
- Utilities for iterating/searching/finding objects
- Timestamps for error messages
- Logging support

Possible additions
- Change Client to use custom class
- Iterators for things like getServers
- Implement private/public attributes
- Cache objects

Fixes Needed
- Make delayed ready event more explicit
- Fix voice state count
- Fix game updating
