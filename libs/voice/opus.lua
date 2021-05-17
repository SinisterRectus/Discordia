local ffi = require('ffi')

local loaded, lib = pcall(ffi.load, 'opus')
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
typedef struct OpusDecoder OpusDecoder;

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

OpusDecoder *opus_decoder_create(opus_int32 Fs, int channels, int *error);
int opus_decoder_init(OpusDecoder *st, opus_int32 Fs, int channels);
int opus_decoder_get_size(int channels);
int opus_decoder_ctl(OpusDecoder *st, int request, ...);
void opus_decoder_destroy(OpusDecoder *st);

int opus_decode(
	OpusDecoder *st,
	const unsigned char *data,
	opus_int32 len,
	opus_int16 *pcm,
	int frame_size,
	int decode_fec
);

int opus_decode_float(
	OpusDecoder *st,
	const unsigned char *data,
	opus_int32 len,
	float *pcm,
	int frame_size,
	int decode_fec
);
]]

local opus = {}

opus.OK                                   = 0
opus.BAD_ARG                              = -1
opus.BUFFER_TOO_SMALL                     = -2
opus.INTERNAL_ERROR                       = -3
opus.INVALID_PACKET                       = -4
opus.UNIMPLEMENTED                        = -5
opus.INVALID_STATE                        = -6
opus.ALLOC_FAIL                           = -7

opus.APPLICATION_VOIP                     = 2048
opus.APPLICATION_AUDIO                    = 2049
opus.APPLICATION_RESTRICTED_LOWDELAY      = 2051

opus.AUTO                                 = -1000
opus.BITRATE_MAX                          = -1

opus.SIGNAL_VOICE                         = 3001
opus.SIGNAL_MUSIC                         = 3002
opus.BANDWIDTH_NARROWBAND                 = 1101
opus.BANDWIDTH_MEDIUMBAND                 = 1102
opus.BANDWIDTH_WIDEBAND                   = 1103
opus.BANDWIDTH_SUPERWIDEBAND              = 1104
opus.BANDWIDTH_FULLBAND                   = 1105

opus.SET_APPLICATION_REQUEST              = 4000
opus.GET_APPLICATION_REQUEST              = 4001
opus.SET_BITRATE_REQUEST                  = 4002
opus.GET_BITRATE_REQUEST                  = 4003
opus.SET_MAX_BANDWIDTH_REQUEST            = 4004
opus.GET_MAX_BANDWIDTH_REQUEST            = 4005
opus.SET_VBR_REQUEST                      = 4006
opus.GET_VBR_REQUEST                      = 4007
opus.SET_BANDWIDTH_REQUEST                = 4008
opus.GET_BANDWIDTH_REQUEST                = 4009
opus.SET_COMPLEXITY_REQUEST               = 4010
opus.GET_COMPLEXITY_REQUEST               = 4011
opus.SET_INBAND_FEC_REQUEST               = 4012
opus.GET_INBAND_FEC_REQUEST               = 4013
opus.SET_PACKET_LOSS_PERC_REQUEST         = 4014
opus.GET_PACKET_LOSS_PERC_REQUEST         = 4015
opus.SET_DTX_REQUEST                      = 4016
opus.GET_DTX_REQUEST                      = 4017
opus.SET_VBR_CONSTRAINT_REQUEST           = 4020
opus.GET_VBR_CONSTRAINT_REQUEST           = 4021
opus.SET_FORCE_CHANNELS_REQUEST           = 4022
opus.GET_FORCE_CHANNELS_REQUEST           = 4023
opus.SET_SIGNAL_REQUEST                   = 4024
opus.GET_SIGNAL_REQUEST                   = 4025
opus.GET_LOOKAHEAD_REQUEST                = 4027
opus.GET_SAMPLE_RATE_REQUEST              = 4029
opus.GET_FINAL_RANGE_REQUEST              = 4031
opus.GET_PITCH_REQUEST                    = 4033
opus.SET_GAIN_REQUEST                     = 4034
opus.GET_GAIN_REQUEST                     = 4045
opus.SET_LSB_DEPTH_REQUEST                = 4036
opus.GET_LSB_DEPTH_REQUEST                = 4037
opus.GET_LAST_PACKET_DURATION_REQUEST     = 4039
opus.SET_EXPERT_FRAME_DURATION_REQUEST    = 4040
opus.GET_EXPERT_FRAME_DURATION_REQUEST    = 4041
opus.SET_PREDICTION_DISABLED_REQUEST      = 4042
opus.GET_PREDICTION_DISABLED_REQUEST      = 4043
opus.SET_PHASE_INVERSION_DISABLED_REQUEST = 4046
opus.GET_PHASE_INVERSION_DISABLED_REQUEST = 4047

opus.FRAMESIZE_ARG                        = 5000
opus.FRAMESIZE_2_5_MS                     = 5001
opus.FRAMESIZE_5_MS                       = 5002
opus.FRAMESIZE_10_MS                      = 5003
opus.FRAMESIZE_20_MS                      = 5004
opus.FRAMESIZE_40_MS                      = 5005
opus.FRAMESIZE_60_MS                      = 5006
opus.FRAMESIZE_80_MS                      = 5007
opus.FRAMESIZE_100_MS                     = 5008
opus.FRAMESIZE_120_MS                     = 5009

local int_ptr_t = typeof('int[1]')
local opus_int32_t = typeof('opus_int32')
local opus_int32_ptr_t = typeof('opus_int32[1]')

local function throw(code)
	local version = ffi.string(lib.opus_get_version_string())
	local message = ffi.string(lib.opus_strerror(code))
	return error(string.format('[%s] %s', version, message))
end

local function check(value)
	return value >= opus.OK and value or throw(value)
end

local Encoder = {}
Encoder.__index = Encoder

function Encoder:__new(sample_rate, channels, app) -- luacheck: ignore self

	app = app or opus.APPLICATION_AUDIO -- TODO: test different applications

	local err = int_ptr_t()
	local state = lib.opus_encoder_create(sample_rate, channels, app, err)
	check(err[0])

	check(lib.opus_encoder_init(state, sample_rate, channels, app))

	return gc(state, lib.opus_encoder_destroy)

end

function Encoder:encode(input, input_len, frame_size, max_data_bytes)

	local pcm = new('opus_int16[?]', input_len, input)
	local data = new('unsigned char[?]', max_data_bytes)

	local ret = lib.opus_encode(self, pcm, frame_size, data, max_data_bytes)

	return data, check(ret)

end

function Encoder:get(id)
	local ret = opus_int32_ptr_t()
	lib.opus_encoder_ctl(self, id, ret)
	return check(ret[0])
end

function Encoder:set(id, value)
	if type(value) ~= 'number' then return throw(opus.BAD_ARG) end
	local ret = lib.opus_encoder_ctl(self, id, opus_int32_t(value))
	return check(ret)
end

opus.Encoder = ffi.metatype('OpusEncoder', Encoder)

local Decoder = {}
Decoder.__index = Decoder

function Decoder:__new(sample_rate, channels) -- luacheck: ignore self

	local err = int_ptr_t()
	local state = lib.opus_decoder_create(sample_rate, channels, err)
	check(err[0])

	check(lib.opus_decoder_init(state, sample_rate, channels))

	return gc(state, lib.opus_decoder_destroy)

end

function Decoder:decode(data, len, frame_size, output_len)

	local pcm = new('opus_int16[?]', output_len)

	local ret = lib.opus_decode(self, data, len, pcm, frame_size, 0)

	return pcm, check(ret)

end

function Decoder:get(id)
	local ret = opus_int32_ptr_t()
	lib.opus_decoder_ctl(self, id, ret)
	return check(ret[0])
end

function Decoder:set(id, value)
	if type(value) ~= 'number' then return throw(opus.BAD_ARG) end
	local ret = lib.opus_decoder_ctl(self, id, opus_int32_t(value))
	return check(ret)
end

opus.Decoder = ffi.metatype('OpusDecoder', Decoder)

return opus
