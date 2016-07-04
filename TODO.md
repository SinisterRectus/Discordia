Probable additions
- Handle USER_SETTINGS_UPDATE
- Handle MESSAGE_BULK_DELETE
- Move Server/Channel/Role positions
- Embeds and file sharing
- Sharding
- Optional Client init args (max messages, grab initial messages, auto reconnect, auto retry, max retries, default date format, toggle caching)
- Get server icon
- Implement Game object
- Twitch streaming url
- Logging support
- getMessageHistory before/after
- implement role creation
- return more values

Possible additions
- Change Client to use custom class
- Implement private/public attributes
- Helper functions, like getMembersWithRole, ...
- Dynamically generate object properties from data?
  - Rather than parse the data on object creation, parse it only when the object is accessed
- enhance permissions abstraction

Fixes Needed
- Make delayed ready event more explicit
- Fix voice state count
- Fix game updating
- Consider changing ban events to handle User objects, not Members
- fix member roles not being updated
