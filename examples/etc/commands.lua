local commands = {
    {
        trigger = ".ping";
        defined = "";
        process = function(bot, message)
            message.channel:sendMessage("Pong!")
        end
    };
    
    {
        trigger = ".s-game";
        defined = "";
        process = function(bot, message)
            local name = getArguments(message);
            
            bot:setGameName(name)
        end
    };
}

local function splice(array, index)
   if type(array == "table") then
       index = tonumber(index)
       
       array[index] = nil
       
       return array
    end
end

local function split(line, sep)
    local array = {};
    
    if not sep then
        sep = "%s"
    end

    local div = "([^"..sep.."]+)"

    for text in string.gmatch(line, div) do
        array[#array + 1] = text
    end
    
    return array
end

local function join(list, sep)
   return table.concat(list, sep) 
end

local function getArguments(message)
    local list = split(message, " ")
    local args = splice(list, 1)
    
    return join(args, " ")
end

return function(bot, message)
    local prefix = split(message, " ")[1];
    
    if prefix then
        for i,v in next, commands do
            if v.trigger == prefix then
                v.process(bot, message)
            end
        end
    end
end
