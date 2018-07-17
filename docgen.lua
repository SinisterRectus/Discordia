local fs = require('fs')
local pathjoin = require('pathjoin')

local function scan(dir)
	for fileName, fileType in fs.scandirSync(dir) do
		local path = pathjoin.pathJoin(dir, fileName)
		if fileType == 'file' then
			coroutine.yield(path)
		else
			scan(path)
		end
	end
end

local function iter(dir)
	return coroutine.wrap(function() scan(dir) end)
end

for f in iter('./libs') do

	local d = assert(fs.readFileSync(f))

	for docstring in d:gmatch('--%[=%[%s*(.-)%s*%]=%]') do

	end

end
