local loaded, lib

return setmetatable({}, {__call = function(opus, path)

if loaded then return opus end

local ffi = require('ffi')

loaded, lib = pcall(ffi.load, path)
if not loaded then
	return nil, lib
end

local new, typeof, gc = ffi.new, ffi.typeof, ffi.gc

ffi.cdef[[
typedef int16_t opus_int16;
typedef int32_t opus_int32;
typedef uint16_t opus_uint16;
typedef uint32_t opus_uint32;

typedef struct OpusEncoder OpusEncoder;

const char *opus_strerror(int error);
const char *opus_get_version_string(void);

OpusEncoder *opus_encoder_create(opus_int32 Fs, int channels, int application, int *error);
int opus_encoder_init(OpusEncoder *st, opus_int32 Fs, int channels, int application);
int opus_encoder_get_size(int channels);
int opus_encoder_ctl(OpusEncoder *st, int request, ...);
void opus_encoder_destroy(OpusEncoder *st);

opus_int32 opus_encode(
	OpusEncoder *st,
	const opus_int16 *pcm,
	int frame_size,
	unsigned char *data,
	opus_int32 max_data_bytes
);

opus_int32 opus_encode_float(
	OpusEncoder *st,
	const float *pcm,
	int frame_size,
	unsigned char *data,
	opus_int32 max_data_bytes
);
]]

local OPUS_OK      = 0
local OPUS_BAD_ARG = -1

-- local OPUS_APPLICATION_VOIP                 = 2048
local OPUS_APPLICATION_AUDIO                = 2049
-- local OPUS_APPLICATION_RESTRICTED_LOWDELAY  = 2051

local int_ptr_t = typeof('int[1]')
local opus_int32_t = typeof('opus_int32')
local opus_int32_ptr_t = typeof('opus_int32[1]')

local function throw(code)
	local version = ffi.string(lib.opus_get_version_string())
	local message = ffi.string(lib.opus_strerror(code))
	return error(string.format('[%s] %s', version, message))
end

local Encoder = {}
Encoder.__index = Encoder

function Encoder:__new(sample_rate, channels, app) -- luacheck: ignore self

	app = app or OPUS_APPLICATION_AUDIO -- TODO: test different appplications

	local err = int_ptr_t()
	local state = lib.opus_encoder_create(sample_rate, channels, app, err)
	err = err[0]
	if err < OPUS_OK then return throw(err) end

	err = lib.opus_encoder_init(state, sample_rate, channels, app)
	if err < OPUS_OK then return throw(err) end

	return gc(state, lib.opus_encoder_destroy)

end

function Encoder:encode(input, input_len, frame_size, max_data_bytes)

	local pcm = new('opus_int16[?]', input_len, input)
	local data = new('unsigned char[?]', max_data_bytes)

	local ret = lib.opus_encode(self, pcm, frame_size, data, max_data_bytes)
	if ret < OPUS_OK then return throw(ret) end

	return data, ret

end

function Encoder:get(id)
	local ret = opus_int32_ptr_t()
	lib.opus_encoder_ctl(self, id, ret)
	ret = ret[0]
	if ret < OPUS_OK then return throw(ret) end
	return ret
end

function Encoder:set(id, value)
	if type(value) ~= 'number' then return throw(OPUS_BAD_ARG) end
	local ret = lib.opus_encoder_ctl(self, id, opus_int32_t(value))
	if ret < OPUS_OK then return throw(ret) end
	return ret
end

opus.Encoder = ffi.metatype('OpusEncoder', Encoder)

return opus

end})
