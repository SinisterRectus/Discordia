local ffi = require('ffi')
local lib = ffi.load('libopus')

ffi.cdef[[
typedef int16_t opus_int16;
typedef int32_t opus_int32;
typedef uint16_t opus_uint16;
typedef uint32_t opus_uint32;

typedef struct OpusEncoder OpusEncoder;

int opus_encoder_get_size(int channels);
OpusEncoder *opus_encoder_create(opus_int32 Fs, int channels, int application, int *error);
int opus_encoder_init(OpusEncoder *st, opus_int32 Fs, int channels, int application);
opus_int32 opus_encode(OpusEncoder *st, const opus_int16 *pcm, int frame_size, unsigned char *data, opus_int32 max_data_bytes);
opus_int32 opus_encode_float(OpusEncoder *st, const float *pcm, int frame_size, unsigned char *data, opus_int32 max_data_bytes);
void opus_encoder_destroy(OpusEncoder *st);
int opus_encoder_ctl(OpusEncoder *st, int request, ...);

const char *opus_strerror(int error);
const char *opus_get_version_string(void);
]]

local function throw(code)
	local version = ffi.string(lib.opus_get_version_string())
	local message = ffi.string(lib.opus_strerror(code))
	return error(string.format('[%s] %s', version, message))
end

local int_ptr = ffi.typeof('int[1]')

local Encoder = {}
Encoder.__index = Encoder

function Encoder:__new(sample_rate, channels, app)

	app = app or 2049

	local err = int_ptr()
	local state = lib.opus_encoder_create(sample_rate, channels, app, err)
	if err[0] < 0 then return throw(err[0]) end

	err = lib.opus_encoder_init(state, sample_rate, channels, app)
	if err < 0 then return throw(err) end

	return state

end

function Encoder:encode(input, frame_size, max_data_bytes)

	if type(input) == 'string' then
		input = {input:byte(1, #input)}
	end

	local pcm = ffi.new('opus_int16[?]', #input, input)
	local data = ffi.new('unsigned char[?]', max_data_bytes)

	local ret = lib.opus_encode(self, pcm, frame_size, data, max_data_bytes)
	if ret < 0 then return throw(ret) end

	return ffi.string(data, ret)

end

return {
	Encoder = ffi.metatype('OpusEncoder', Encoder)
}
