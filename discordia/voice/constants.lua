local fs = require('fs')
local pathjoin = require('pathjoin')

local stat = fs.statSync
local pathJoin = pathjoin.pathJoin
local isWindows = pathjoin.isWindows

local FFMPEG
local pre = isWindows and '' or './'
local exe = isWindows and 'ffmpeg.exe' or 'ffmpeg'
local sep = isWindows and ';' or ':'

local function exists(path)
	local data = stat(path)
	return data and data.type == 'file'
end

if exists(exe) then
	FFMPEG = pre .. exe
else
	for dir in (process.env.PATH .. sep):gmatch('(.-)' .. sep) do
		if exists(pathJoin(dir, exe)) then
			FFMPEG = exe
			break
		end
	end
end

local CHANNELS = 2
local SAMPLE_RATE = 48000
local FRAME_DURATION = 20 -- ms
local FRAME_SIZE = SAMPLE_RATE * FRAME_DURATION / 1000
local PCM_SIZE = FRAME_SIZE * CHANNELS * 2

return {
	CHANNELS = CHANNELS,
	SAMPLE_RATE = SAMPLE_RATE,
	MAX_DURATION = math.huge,
	FRAME_DURATION = FRAME_DURATION,
	FRAME_SIZE = FRAME_SIZE,
	PCM_SIZE = PCM_SIZE,
	PCM_LEN = PCM_SIZE / 2,
	SILENCE = '\xF8\xFF\xFE',
	FFMPEG = FFMPEG,
	MAX_BITRATE = 128000,
	MIN_BITRATE = 8000,
	MODE = 'xsalsa20_poly1305',
}
