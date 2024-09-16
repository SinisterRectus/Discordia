local ffi = require('ffi')
local bit = require('bit')

local loaded, lib = pcall(ffi.load, 'sodium')
if not loaded then
	return nil, lib
end

local typeof = ffi.typeof

ffi.cdef [[
int sodium_init(void);

size_t crypto_aead_xchacha20poly1305_ietf_npubbytes(void);
size_t crypto_aead_xchacha20poly1305_ietf_keybytes(void);
size_t crypto_aead_xchacha20poly1305_ietf_abytes(void);

size_t crypto_aead_xchacha20poly1305_ietf_messagebytes_max(void);

int crypto_aead_xchacha20poly1305_ietf_encrypt(unsigned char *c,
											   unsigned long long *clen_p,
											   const unsigned char *m,
											   unsigned long long mlen,
											   const unsigned char *ad,
											   unsigned long long adlen,
											   const unsigned char *nsec,
											   const unsigned char *npub,
											   const unsigned char *k);

int crypto_aead_xchacha20poly1305_ietf_decrypt(unsigned char *m,
											   unsigned long long *mlen_p,
											   unsigned char *nsec,
											   const unsigned char *c,
											   unsigned long long clen,
											   const unsigned char *ad,
											   unsigned long long adlen,
											   const unsigned char *npub,
											   const unsigned char *k);

int crypto_aead_aes256gcm_is_available(void);
size_t crypto_aead_aes256gcm_npubbytes(void);
size_t crypto_aead_aes256gcm_keybytes(void);
size_t crypto_aead_aes256gcm_abytes(void);

size_t crypto_aead_aes256gcm_messagebytes_max(void);


int crypto_aead_aes256gcm_encrypt(unsigned char *c,
								  unsigned long long *clen_p,
								  const unsigned char *m,
								  unsigned long long mlen,
								  const unsigned char *ad,
								  unsigned long long adlen,
								  const unsigned char *nsec,
								  const unsigned char *npub,
								  const unsigned char *k);

int crypto_aead_aes256gcm_decrypt(unsigned char *m,
								  unsigned long long *mlen_p,
								  unsigned char *nsec,
								  const unsigned char *c,
								  unsigned long long clen,
								  const unsigned char *ad,
								  unsigned long long adlen,
								  const unsigned char *npub,
								  const unsigned char *k);

]]

local unsigned_char_array_t = typeof('unsigned char[?]')

if lib.sodium_init() < 0 then
	return nil, 'libsodium initialization failed'
end

local sodium = {}
do -- AEAD XChaCha20 Poly1305
	local NPUBBYTES = tonumber(lib.crypto_aead_xchacha20poly1305_ietf_npubbytes())
	local KEYBYTES = tonumber(lib.crypto_aead_xchacha20poly1305_ietf_keybytes())
	local ABYTES = tonumber(lib.crypto_aead_xchacha20poly1305_ietf_abytes())

	local MAX_MESSAGEBYTES = tonumber(lib.crypto_aead_xchacha20poly1305_ietf_messagebytes_max())

	local key_t = typeof('const unsigned char[' .. KEYBYTES .. ']')
	local nonce_t = typeof('unsigned char[' .. NPUBBYTES .. ']')

	sodium.aead_xchacha20_poly1305 = {}
	function sodium.aead_xchacha20_poly1305.key(key)
		assert(#key == KEYBYTES, 'invalid key size')
		return key_t(key)
	end

	function sodium.aead_xchacha20_poly1305.nonce(nonce)

		local buf = nonce_t()

		-- write u32 nonce as big-endian
		buf[3] = bit.band(nonce, 0xFF)
		buf[2] = bit.band(bit.rshift(nonce, 8), 0xFF)
		buf[1] = bit.band(bit.rshift(nonce, 16), 0xFF)
		buf[0] = bit.band(bit.rshift(nonce, 24), 0xFF)
		for i = 4, NPUBBYTES - 1 do
			buf[i] = 0
		end

		return buf

	end

	function sodium.aead_xchacha20_poly1305.encrypt(message, message_len, nonce, key, additional_data)
		assert(message_len <= MAX_MESSAGEBYTES, 'message too long')
		assert(ffi.istype(nonce_t, nonce), 'invalid nonce')
		assert(ffi.istype(key_t, key), 'invalid key')

		local additional_data_len = additional_data and #additional_data or 0

		local ciphertext_len = message_len + ABYTES
		local ciphertext = unsigned_char_array_t(ciphertext_len)
		local ciphertext_len_p = ffi.new('unsigned long long[1]', ciphertext_len)

		if lib.crypto_aead_xchacha20poly1305_ietf_encrypt(ciphertext, ciphertext_len_p, message, message_len, additional_data, additional_data_len, nil, nonce, key) < 0 then
			return nil, 'libsodium encryption failed'
		end

		return ciphertext, tonumber(ciphertext_len_p[0])

	end

	function sodium.aead_xchacha20_poly1305.decrypt(ciphertext, ciphertext_len, nonce, key, additional_data)
		assert(ffi.istype(nonce_t, nonce), 'invalid nonce')
		assert(ffi.istype(key_t, key), 'invalid key')

		local additional_data_len = additional_data and #additional_data or 0

		local message_len = ciphertext_len - ABYTES
		local message = unsigned_char_array_t(message_len)
		local message_len_p = ffi.new('unsigned long long[1]', message_len)

		if lib.crypto_aead_xchacha20poly1305_ietf_decrypt(message, message_len_p, nil, ciphertext, ciphertext_len, additional_data, additional_data_len, nonce, key) < 0 then
			return nil, 'libsodium decryption failed'
		end

		return message, tonumber(message_len_p[0])

	end
end

if lib.crypto_aead_aes256gcm_is_available() ~= 0 then -- AEAD AES256-GCM

	local NPUBBYTES = tonumber(lib.crypto_aead_aes256gcm_npubbytes())
	local KEYBYTES = tonumber(lib.crypto_aead_aes256gcm_keybytes())
	local ABYTES = tonumber(lib.crypto_aead_aes256gcm_abytes())

	local MAX_MESSAGEBYTES = tonumber(lib.crypto_aead_aes256gcm_messagebytes_max())

	local key_t = typeof('const unsigned char[' .. KEYBYTES .. ']')
	local nonce_t = typeof('unsigned char[' .. NPUBBYTES .. ']')

	sodium.aead_aes256_gcm = {}
	function sodium.aead_aes256_gcm.key(key)
		assert(#key == KEYBYTES, 'invalid key size')
		return key_t(key)
	end

	function sodium.aead_aes256_gcm.nonce(nonce)

		local buf = nonce_t()

		-- write u32 nonce as big-endian
		buf[3] = bit.band(nonce, 0xFF)
		buf[2] = bit.band(bit.rshift(nonce, 8), 0xFF)
		buf[1] = bit.band(bit.rshift(nonce, 16), 0xFF)
		buf[0] = bit.band(bit.rshift(nonce, 24), 0xFF)
		for i = 4, NPUBBYTES - 1 do
			buf[i] = 0
		end

		return buf

	end

	function sodium.aead_aes256_gcm.encrypt(message, message_len, nonce, key, additional_data)
		assert(message_len <= MAX_MESSAGEBYTES, 'message too long')
		assert(ffi.istype(nonce_t, nonce), 'invalid nonce')
		assert(ffi.istype(key_t, key), 'invalid key')

		local additional_data_len = additional_data and #additional_data or 0

		local ciphertext_len = message_len + ABYTES
		local ciphertext = unsigned_char_array_t(ciphertext_len)
		local ciphertext_len_p = ffi.new('unsigned long long[1]', ciphertext_len)

		if lib.crypto_aead_aes256gcm_encrypt(ciphertext, ciphertext_len_p, message, message_len, additional_data, additional_data_len, nil, nonce, key) < 0 then
			return nil, 'libsodium encryption failed'
		end

		return ciphertext, tonumber(ciphertext_len_p[0])

	end

	function sodium.aead_aes256_gcm.decrypt(ciphertext, ciphertext_len, nonce, key, additional_data)
		assert(ffi.istype(nonce_t, nonce), 'invalid nonce')
		assert(ffi.istype(key_t, key), 'invalid key')

		local additional_data_len = additional_data and #additional_data or 0

		local message_len = ciphertext_len - ABYTES
		local message = unsigned_char_array_t(message_len)
		local message_len_p = ffi.new('unsigned long long[1]', message_len)

		if lib.crypto_aead_aes256gcm_decrypt(message, message_len_p, nil, ciphertext, ciphertext_len, additional_data, additional_data_len, nonce, key) < 0 then
			return nil, 'libsodium decryption failed'
		end

		return message, tonumber(message_len_p[0])

	end

end

return sodium
