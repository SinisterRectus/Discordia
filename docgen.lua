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

local function checkType(docstring, token)
	return docstring:find(token) == 1
end

local function match(s, pattern) -- only useful for one return value
	return assert(s:match(pattern), s)
end

local docs = {}

for f in iter('./libs') do

	local d = assert(fs.readFileSync(f))

	local class = {
		methods = {},
		statics = {},
		properties = {},
		parents = {},
	}

	for s in d:gmatch('--%[=%[%s*(.-)%s*%]=%]') do

		if checkType(s, '@ic') then

			class.userInitialized = true
			class.name = match(s, '@ic (%w+)')
			for parent in s:gmatch('x (%w+)') do
				table.insert(class.parents, parent)
			end

		elseif checkType(s, '@c') then

			class.name = match(s, '@c (%w+)')
			for parent in s:gmatch('x (%w+)') do
				table.insert(class.parents, parent)
			end
			class.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')

		elseif checkType(s, '@m') then

			local method = {parameters = {}}
			method.name = match(s, '@m (%w+)')
			for paramName, paramType in s:gmatch('@p (%w+)%s+(%w+)') do
				table.insert(method.parameters, {paramName, paramType}) -- required
			end
			for paramName, paramType in s:gmatch('@op (%w+)%s+(%w+)') do
				table.insert(method.parameters, {paramName, paramType, true}) -- optional
			end
			method.returnType = s:match('@r (%w+)')
			method.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')
			table.insert(class.methods, method)

		elseif checkType(s, '@p') then

			local property = {s:match('@p (%w+)%s+([%w%p]+)%s+(.+)')}
			assert(property[1], s)
			table.insert(class.properties, property)

		elseif checkType(s, '@sm') then

			local static = {parameters = {}}
			static.name = match(s, '@sm (%w+)')
			for paramName, paramType in s:gmatch('@p (%w+)%s+(%w+)') do
				table.insert(static.parameters, {paramName, paramType}) -- required
			end
			for paramName, paramType in s:gmatch('@op (%w+)%s+(%w+)') do
				table.insert(static.parameters, {paramName, paramType, true}) -- optional
			end
			static.returnType = match(s, '@r (%w+)')
			static.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')
			table.insert(class.statics, static)

		end

	end

	if class.name then
		table.insert(docs, class)
	end

end

-- TODO: use docs table to generate markdown files
