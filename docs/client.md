## Client
Extends Luvit's built-in `Emitter` object. This is the initial object used to interact with Discord.

*Note:* Asynchronous operations (HTTP requests, WebSocket read/writes) must be called from within a coroutine. If you start your client with the `run` method, then you generally do not have to worry about this.

---

### Methods

#### `run(email, password)` or `run(token)`
- email - string
- password - string
- token - string

Calls the `loginWithEmail` or `loginWithToken` and `connectWebsocket` methods from within a coroutine. If you do not want to manually manage coroutines and the connection process, use this method to run your client. A token may be used for any account, while an email address and password may be used only for regular user accounts.

#### `stop()`
The opposite of `run`. Calls the `logout` and `disconnectWebsocket` methods before terminating the program.

#### `loginWithEmail(email, password)`
- email - string
- password - string

Authenticates the user by either getting a token from a local cache file or from Discord via `getToken`. Called by `run` from within a coroutine. This cannot be used for bot accounts.

#### `loginWithToken(token)`
- token - string

Authenticates the user by storing the provided token. Called by `run` from within a coroutine. This can be used for any account.

#### `logout()`
Deletes the client's locally stored token.

#### `stop()`
Called the `logout` method, disconnects the WebSocket, and terminates the program.

#### `getToken(email, password)` -> `string`
- email - string
- password - string

Gets an authentication token from Discord.

#### `request(method, url, body)` -> `table`
- method - string
- url - table or string
- body - table

Specially formatted for use with Discord HTTP requests. The internal request function uses coroutines to provide asynchronous behavior. HTTP errors are also caught here, thus, a table is only returned after a successful request. Note that all returned keys are camelified. For example, a server's `guild_id` attribute would be found at `guildId`.

#### `getGateway()` -> `string`
Requests a gateway URL to use for a websocket connection. Called by `connectWebsocket` method.

#### `connectWebsocket()`
Initializes a gateway for the client, either by getting it from a local cache file or from Discord via `getGateway`, initializes a WebSocket connection, sends the initial identify message, and initializes the event handler. This method is called by `run` after a successful login.

#### `disconnectWebsocket()`
If the client has a known WebSocket, this will attempt to disconnect it.

#### `startWebsocketHandler()`
Initializes the main program loop, which listens for and handles incoming WebSocket messages.

#### `startKeepAliveHandler()`
This initializes a secondary program loop, which periodically sends an outgoing WebSocket message to keep the websocket connection alive.

#### `stopKeepAliveHandlers()`
This flags the main keep alive handler to return on its next iteration, and in rare cases, any others that are running.

#### `setUsername(newUsername, password)`
- newUsername - string
- password - string

Sets the username of the Discord account in use. Password is required.

#### `setAvatar(newAvatar, password)`
- newAvatar - string
- password - string

Sets the avatar of the Discord account in use. The avatar string must be an image encoded in base64 format. Password is required.

#### `setEmail(newEmail, password)`
- newEmail - string
- password - string

Sets the email address of the Discord account in use. Password is required.

#### `setPassword(newPassword, password)`
- newAvatar - string
- password - string

Sets the password of the Discord account in use. Password is required.

#### `setStatusIdle()`
Sets the client's Discord activity status to idle. This will not work if the status or game name has been changed in the past 5 minutes.

#### `setStatusOnline()`
Sets the client's Discord activity status to online. This will not work if the status or game name has been changed in the past 5 minutes.

#### `setGameName(gameName)`
Sets the client's Discord game name to that provided. This will not work if the status or game name has been changed in the past 5 minutes.

#### `acceptInviteByCode(code)`
Allows a user account to join a server using the provided invitation code. Do not use this for bot accounts.

#### `createServer(name, regionId)` -> `Server`
- name - string
- regionId - string

Creates a server with the specified name and region ID (us-east, london, frankfurt, etc). The `Server` object returned is not the same object as that which is later cached or emitted with the `serverCreate` event.

#### `getRegions()` -> `table`
Provides a table of region data. The id property is most useful; it is used for creating and editing server regions.

#### `getServerById(id)` -> `Server` or `nil`
- id - string

Returns a locally cached `Server` object that has the provided ID, or `nil` if none is found.

#### `getServerByName(name)` -> `Server` or `nil`
- name - string

Returns a locally cached `Server` object that has the provided name. Since more than one server can have the same name, the result is not guaranteed to be unique. The first match is returned, or `nil` if there is no match.

#### `getChannelById(id)` -> `PrivateChannel` or `ServerChannel` or `nil`
- id - string

Returns a locally cached `PrivateChannel` or `ServerChannel` object that has the provided ID, or `nil` if none is found. The `ServerChannel` will technically be either a `ServerTextChannel` or `ServerVoiceChannel`, both of which are subclasses of `ServerChannel`.

*Related:* `Server:getChannelById(id)`

#### `getChannelByName(name)` -> `PrivateChannel` or `ServerChannel` or `nil`
- name - string

Returns a locally cached `PrivateChannel` or `ServerChannel` object that has the provided name. Since more than one channel can have the same name, the result is not guaranteed to be unique. The first match is returned, or `nil` if there is no match. The `ServerChannel` will technically be either a `ServerTextChannel` or `ServerVoiceChannel`, both of which are subclasses of `ServerChannel`. Note that the private channel name is the username of the channel recipient.

*Related:* `Server:get[Text/Voice]ChannelByName(name)`

#### `getMemberById(id)` -> `Member` or `nil`
- id - string

Returns a locally cached server `Member` object that has the provided ID. Since one user can be a member of multiple servers, the result is not guaranteed to be unique. The first match is returned, or `nil` if there is no match.

*Related:* `Server:getMemberById(id)`

#### `getMemberByName(name)` -> `Member` or `nil`
- name - string
- Returns *Member* or *nil*

Returns a locally cached server `Member` object that has the provided name. Since more than one member can have the same name, the result is not guaranteed to be unique. The first match is returned, or `nil` if there is no match.

*Related:* `Server:getMemberByName(name)`

#### `getRoleById(id)` -> `Role` or `nil`
- id - string

Returns a locally cached `Role` object that has the provided ID, or `nil` if none is found.

*Related:* `Server:getRoleById(id)`

#### `getRoleByName(name)` -> `Role` or `nil`
- name - string

Returns a locally cached `Role` object that has the provided name. Since more than one role can have the same name, the result is not guaranteed to be unique. The first match is returned, or `nil` if there is no match.

*Related:* `Server:getRoleByName(name)`

#### `getMessageById(id)` -> `Message` or `nil`
- id - string

Returns a locally cached `Message` object that has the provided ID, or `nil` if none is found.

*Related:* `Server:getMessageById(id)` `Channel:getMessageById(id)`

---

### Properties

#### `user`
The client's logged in `User` object.

#### `websocket`
The client's `WebSocket` handle used to send data to and from the client.

#### `email`
String that represents the client's email address. This is not necessarily the same as the address used to login.

#### `token`
String that represents the login token provided by Discord. Unique to each account. Pre-pended with 'Bot' for bot accounts.

#### `sessionId`
String that represents the WebSocket session ID. Used only for resuming a reconnected session.

#### `sequence`
Number that indicates the sequence position of the most recently received WebSocket payload.

#### `maxMessages`
Number that limits the number of messages per channel that are cached. Default 100.

#### `verified`
Boolean indicating whether the client's email address is verified.

#### `servers`
Table of cached `Server` objects that are known to the client.

#### `privateChannels`
Table of cached `PrivateChannel` objects that are known to the client.

#### `headers`
Table of headers to use for HTTP requests. Always contains *Content-Type* and *User-Agent*. Contains *Authorization* after login. *Content-Length* is dynamically generated when it is needed.

#### `keepAliveHandlers`
Table of references used by the client to flag keep alive handlers in the event of a WebSocket disconnect. Usually expected to be occupied by only one handler, or two in the event of a disconnect.

#### `readyTimeout`
A libuv timer object that delays the local firing of the `ready` event until one second after all server data has been received. Does not exist after `ready` has fired.

#### `isRateLimited`
Boolean indicating whether the client is currently being rate limited. Used to hold back additional requests.
