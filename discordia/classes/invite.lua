local Object = require('./object')
local endpoints = require('../endpoints')

class('Invite', Object)

function Invite:__init(data, server)

    Object.__init(self, data.code, server.client)

    self.code = data.code
    self.server = server
    self.xkcdpass = data.xkcdpass
    self.channel = server:getChannelById(data.channel.id)

    self.uses = data.uses
    self.maxAge = data.maxAge -- seconds
    self.inviter = server:getMemberById(data.inviter.id)
    self.revoked = data.revoked
    self.maxUses = data.maxUses
    self.temporary = data.temporary
    self.createdAt = data.createdAt

end

function Invite:accept()
    return self.client:acceptInviteByCode(self.code)
end

function Invite:delete()
    return self.client:request('DELETE', {endpoints.invites, self.code})
end

return Invite
