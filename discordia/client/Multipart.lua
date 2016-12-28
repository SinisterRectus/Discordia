local Multipart = {}

function Multipart:attach(data, name, field)
	
	local boundary = "Discordia"
	local str = "\r\n--" .. boundary .. "\r\nContent-Disposition: form-data; name=\"" .. (field or "file") .."\""

	str = str .. "; filename=\"" .. name .. "\"\r\nContent-Type: application/octet-stream"

	str = str .. "\r\n\r\n"..data.."\r\n--"..boundary.."--"

	return str

end

return Multipart
