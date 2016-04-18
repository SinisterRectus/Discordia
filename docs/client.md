## Client
Extends Luvit's built-in **Emitter** object. This is the main object used for interacting with Discord and Discord objects.

*Note:* Asynchronous operations (HTTP requests, websocket read/writes) must be called from inside of a coroutine, or from a function called from inside of a coroutine, recursively. If you start your client with the **run** method, then you do not have to worry about this.

---

### Methods

#### `run(email, password)`
- email - *string*
- password - *string*

Calls the **login** and **websocketConnect** methods from within a coroutine. If you do not want to manually manage coroutines and the connection process, use this method to run your client.

#### `login(email, password)`
- email - *string*
- password - *string*

Initializes a token for the client, either by getting it from a local cache file or from Discord via **getToken**. Called by **run** from within a coroutine.

#### `logout()`
Sends a logout request to Discord. (WebSocket disconnection not yet implemented.)

#### `getToken(email, password)`
- email - *string*
- password - *string*

Gets an authentication token from Discord.

#### `getGateway()`
- Returns *string*

Requests a gateway URL to use for a websocket connection. Called by **websocketConnect** process.

#### `websocketConnect()`

Initializes a gateway for the client, either by getting it from a local cache file or from Discord via **getGateway**, initializes a websocket connection, sends the OP2 message, and initializes the event handler. This method is called by **run** after it successfully calls **login**.

#### `websocketReceiver()`

Initializes the main program loop, which listens for and handles incoming websocket messages.

#### `keepAliveHandler()`

This initializes a secondary program loop, which periodically sends an outgoing websocket message to keep the websocket connection alive.

#### `setUsername(newUsername, password)`
- newUsername - *string*
- password - *string*

Sets the username of the Discord account in use. The password should be the same one used to login.

#### `setAvatar(newAvatar, password)`
- newAvatar - *string*
- password - *string*

Sets the avatar of the Discord account in use. The avatar string must be an image encoded in base64 format. The password should be the same one used to login.

#### `setEmail(newEmail, password)`
- newEmail - *string*
- password - *string*

Sets the email address of the Discord account in use. The password should be the same one used to login.

#### `setPassword(newPassword, password)`
- newAvatar - *string*
- password - *string*

Sets the password of the Discord account in use. The password should be the same one used to login.

#### `getRegions()`

- Returns *Table*

Provides a table of region data. The id property is most useful; it is used for creating and editing server regions.

#### `createServer(name, regionId)`
- name - *string*
- regionId - *string*
- Returns *Server*

Creates a server with the specified name and region ID (us-east, london, frankfurt, etc). The *Server* object returned is not the same object as that which is later cached or emitted with the *serverCreate* event.

#### `getServerById(id)`
- id - *string*
- Returns *Server* or *nil*

Returns a locally cached *Server* object that has the provided ID, or *nil* if none is found.

#### `getServerByName(name)`
- name - *string*
- Returns *Server* or *nil*

Returns a locally cached *Server* object that has the provided name. Since more than one server can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

#### `getChannelById(id)`
- id - *string*
- Returns *PrivateChannel* or *ServerChannel* or *nil*

Returns a locally cached *PrivateChannel* or *ServerChannel* object that has the provided ID, or *nil* if none is found.

*Related:* `Server:getChannelById(id)`

#### `getChannelByName(name)`
- name - *string*
- Returns *PrivateChannel* or *ServerChannel* or *nil*

Returns a locally cached *PrivateChannel* or *ServerChannel* object that has the provided name. Since more than one channel can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match. Note that the private channel name is the username of the channel recipient.

*Related:* `Server:get[Text/Voice]ChannelByName(name)`

#### `getMemberById(id)`
- id - *string*
- Returns *Member* or *nil*

Returns a locally cached server *Member* object that has the provided ID, or *nil* if none is found.

*Related:* `Server:getMemberById(id)`

#### `getMemberByName(name)`
- name - *string*
- Returns *Member* or *nil*

Returns a locally cached server *Member* object that has the provided name. Since more than one member can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

*Related:* `Server:getMemberByName(name)`

#### `getRoleById(id)`
- id - *string*
- Returns *Role* or *nil*

Returns a locally cached *Role* object that has the provided ID, or *nil* if none is found.

*Related:* `Server:getRoleById(id)`

#### `getRoleByName(name)`
- name - *string*
- Returns *Role* or *nil*

Returns a locally cached *Role* object that has the provided name. Since more than one role can have the same name, the result is not guaranteed to be unique. The first match is returned, or *nil* if there is no match.

*Related:* `Server:getRoleByName(name)`

#### `getMessageById(id)`
- id - *string*
- Returns *Message* or *nil*

Returns a locally cached *Message* object that has the provided ID, or *nil* if none is found.

*Related:* `Server:getMessageById(id)` `Channel:getMessageById(id)`

---

### Properties

#### `headers`
*Table* of headers to use for HTTP requests. Always contains *Content-Type* and *User-Agent*. Contains *Authetication* after login. *Content-Length* is dynamically generated when it is needed.

#### `token`
*String* that represents the login token provided by Discord. Unique to each account.

#### `maxMessages`
*Number* that limits the number of messages per channel that are cached. Default 100.

#### `user`
*User* object that represents the client's logged in account.

#### `email`
*String* that represents the client's email address. This is not necessarily the same as the address used to login.

#### `verified`
*Boolean* indicating whether the client's email address is verified.

#### `servers`
*Table* of cached *Server* objects that are known to the client.

#### `privateChannels`
*Table* of cached *PrivateChannel* objects that are known to the client.

#### `websocket`
*WebSocket* object that represents the continuous connection used to send data to and from the client.
