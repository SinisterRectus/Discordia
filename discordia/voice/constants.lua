local fs = require('fs')
local pathjoin = require('pathjoin')

local exists = fs.existsSync
local pathJoin = pathjoin.pathJoin
local isWindows = pathjoin.isWindows

local FFMPEG
local pre = isWindows and '' or './'
local exe = isWindows and 'ffmpeg.exe' or 'ffmpeg'
local sep = isWindows and ';' or ':'

if exists(exe) then
	FFMPEG = pre .. 'ffmpeg'
else
	for dir in (process.env.PATH .. sep):gmatch('(.-)' .. sep) do
		if exists(pathJoin(dir, exe)) then
			FFMPEG = 'ffmpeg'
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
}
