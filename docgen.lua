local fs = require('fs')
local pathjoin = require('pathjoin')
local insert = table.insert

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

local function checkType(docstring, token)
	return docstring:find(token) == 1
end

local function match(s, pattern) -- only useful for one return value
	return assert(s:match(pattern), s)
end

local docs = {}

for f in coroutine.wrap(function() scan('./libs') end) do

	local d = assert(fs.readFileSync(f))

	local class = {
		methods = {},
		properties = {},
		parents = {},
	}

	for s in d:gmatch('--%[=%[%s*(.-)%s*%]=%]') do

		if checkType(s, '@i?c') then

			class.name = match(s, '@i?c (%w+)')
			class.userInitialized = checkType(s, '@ic') or nil
			for parent in s:gmatch('x (%w+)') do
				insert(class.parents, parent)
			end

		elseif checkType(s, '@s?m') then

			local method = {parameters = {}}
			method.name = match(s, '@s?m (%w+)')
			method.static = checkType(s, '@sm') or nil
			for optional, paramName, paramType in s:gmatch('@(o?)p (%w+)%s+(%w+)') do
				insert(method.parameters, {paramName, paramType, optional == 'o' or nil})
			end
			method.returnType = s:match('@r ([%w%p]+)')
			method.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')
			insert(class.methods, method)

		elseif checkType(s, '@p') then

			local propertyName, propertyType, propertyDesc = s:match('@p (%w+)%s+([%w%p]+)%s+(.+)')
			assert(propertyName, s); assert(propertyType, s); assert(propertyDesc, s)
			insert(class.properties, {propertyName, propertyType, propertyDesc:gsub('\r?\n', ' ')})

		end

	end

	if class.name then
		insert(docs, class)
	end

end

-- TODO: use docs table to generate markdown files
