local EventHandler = setmetatable({}, {__index = function(self, k)
	self[k] = function(_, _, shard)
		return shard:log('warning', 'Unhandled gateway event: %s', k)
	end
	return self[k]
end})

function EventHandler.READY(d, _, shard)
	shard:ready(d.session_id) -- maybe move this into shard:handlePayload
	return _:emit('ready')
end

function EventHandler.RESUMED(_, _, shard)
	shard:resumed() -- maybe move this into shard:handlePayload
end

return EventHandler
