local fs = require('fs')
local pathjoin = require('pathjoin')

local insert, sort, concat = table.insert, table.sort, table.concat
local format = string.format
local pathJoin = pathjoin.pathJoin

local function scan(dir)
	for fileName, fileType in fs.scandirSync(dir) do
		local path = pathJoin(dir, fileName)
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
		statics = {},
		properties = {},
		parents = {},
	}

	for s in d:gmatch('--%[=%[%s*(.-)%s*%]=%]') do

		if checkType(s, '@i?c') then

			class.name = match(s, '@i?c (%w+)')
			class.userInitialized = checkType(s, '@ic')
			for parent in s:gmatch('x (%w+)') do
				insert(class.parents, parent)
			end
			class.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')
			class.parameters = {}
			for optional, paramName, paramType in s:gmatch('@(o?)p ([%w%p]+)%s+([%w%p]+)') do
				insert(class.parameters, {paramName, paramType, optional == 'o'})
			end

		elseif checkType(s, '@s?m') then

			local method = {parameters = {}}
			method.name = match(s, '@s?m ([%w%p]+)')
			for optional, paramName, paramType in s:gmatch('@(o?)p ([%w%p]+)%s+([%w%p]+)') do
				insert(method.parameters, {paramName, paramType, optional == 'o'})
            end
            local returnTypes = {}
            for retType in s:gmatch('@r ([%w%p]+)') do
                insert(returnTypes, retType)
            end
			method.returnTypes = returnTypes
			method.desc = match(s, '@d (.+)'):gsub('\r?\n', ' ')
			insert(checkType(s, '@sm') and class.statics or class.methods, method)

		elseif checkType(s, '@p') then

			local propertyName, propertyType, propertyDesc = s:match('@p (%w+)%s+([%w%p]+)%s+(.+)')
			assert(propertyName, s); assert(propertyType, s); assert(propertyDesc, s)
			propertyDesc = propertyDesc:gsub('\r?\n', ' ')
			insert(class.properties, {
				name = propertyName,
				type = propertyType,
				desc = propertyDesc,
			})

		end

	end

	if class.name then
		docs[class.name] = class
	end

end

local function link(str)
	local ret = {}
	for t in str:gmatch('[^/]+') do
		insert(ret, docs[t] and format('[[%s]]', t) or t)
	end
	return concat(ret, '/')
end

local function sorter(a, b)
	return a.name < b.name
end

local function writeProperties(f, properties)
	sort(properties, sorter)
	f:write('| Name | Type | Description |\n')
	f:write('|-|-|-|\n')
	for _, v in ipairs(properties) do
		f:write('| ', v.name, ' | ', link(v.type), ' | ', v.desc, ' |\n')
	end
end

local function writeParameters(f, parameters)
	f:write('(')
	local optional
	if parameters[1] then
		for i, param in ipairs(parameters) do
			f:write(param[1])
			if i < #parameters then
				f:write(', ')
			end
			if param[3] then
				optional = true
			end
		end
		f:write(')\n')
		if optional then
			f:write('>| Parameter | Type | Optional |\n')
			f:write('>|-|-|:-:|\n')
			for _, param in ipairs(parameters) do
				local o = param[3] and '✔' or ''
				f:write('>| ', param[1], ' | ', param[2], ' | ', o, ' |\n')
			end
		else
			f:write('>| Parameter | Type |\n')
			f:write('>|-|-|\n')
			for _, param in ipairs(parameters) do
				f:write('>| ', param[1], ' | ', link(param[2]), '|\n')
			end
		end
	else
		f:write(')\n')
	end
end

local function writeMethods(f, methods)
	sort(methods, sorter)
	for _, method in ipairs(methods) do
		f:write('### ', method.name)
		writeParameters(f, method.parameters)
        f:write('>\n>', method.desc, '\n>\n')
        
        local returns = { }

        for i, retType in ipairs(method.returnTypes) do
            returns[i] = link(retType)
        end

        f:write('>Returns: ', concat(returns, ', '), '\n\n')
	end
end

if not fs.existsSync('docs') then
	fs.mkdirSync('docs')
end

local function clean(input, seen)
	local fields = {}
	for _, field in ipairs(input) do
		if not seen[field.name] then
			insert(fields, field)
		end
	end
	return fields
end

for _, class in pairs(docs) do

	local seen = {}
	for _, v in pairs(class.properties) do seen[v.name] = true end
	for _, v in pairs(class.statics) do seen[v.name] = true	end
	for _, v in pairs(class.methods) do seen[v.name] = true	end

	local f = io.open(pathJoin('docs', class.name .. '.md'), 'w')

	if next(class.parents) then
		f:write('#### *extends ', '[[', concat(class.parents, ']], [['), ']]*\n\n')
	end

	f:write(class.desc, '\n\n')

	if class.userInitialized then
		f:write('## Constructor\n\n')
		f:write('### ', class.name)
		writeParameters(f, class.parameters)
		f:write('\n')
	else
		f:write('*Instances of this class should not be constructed by users.*\n\n')
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].properties) then
			local properties = docs[parent].properties
			if next(properties) then
				f:write('## Properties Inherited From ', link(parent), '\n\n')
				writeProperties(f, clean(properties, seen))
			end
		end
	end

	if next(class.properties) then
		f:write('## Properties\n\n')
		writeProperties(f, class.properties)
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].statics) then
			local statics = docs[parent].statics
			if next(statics) then
				f:write('## Static Methods Inherited From ', link(parent), '\n\n')
				writeMethods(f, clean(statics, seen))
			end
		end
	end

	for _, parent in ipairs(class.parents) do
		if docs[parent] and next(docs[parent].methods) then
			local methods = docs[parent].methods
			if next(methods) then
				f:write('## Methods Inherited From ', link(parent), '\n\n')
				writeMethods(f, clean(methods, seen))
			end
		end
	end

	if next(class.statics) then
		f:write('## Static Methods\n\n')
		writeMethods(f, class.statics)
	end

	if next(class.methods) then
		f:write('## Methods\n\n')
		writeMethods(f, class.methods)
	end

	f:close()

end
