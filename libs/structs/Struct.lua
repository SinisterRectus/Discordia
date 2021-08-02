local class = require('../class')
local json = require('json')

local null = json.null

local Struct = class('Struct')

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

function Struct:__init(data)
	for k, v in pairs(data) do
		if types[type(v)] then
			self['_' .. k] = v
		elseif v == null then
			self['_' .. k] = nil
			data[k] = nil
		end
	end
end

return Struct
