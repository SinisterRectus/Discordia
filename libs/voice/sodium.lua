local ffi = require('ffi')

local loaded, lib = pcall(ffi.load, 'sodium')
if not loaded then
	return nil, lib
end

local typeof = ffi.typeof
local format = string.format

ffi.cdef[[
const char *sodium_version_string(void);
const char *crypto_secretbox_primitive(void);

size_t crypto_secretbox_keybytes(void);
size_t crypto_secretbox_noncebytes(void);
size_t crypto_secretbox_macbytes(void);
size_t crypto_secretbox_zerobytes(void);

int crypto_secretbox_easy(
	unsigned char *c,
	const unsigned char *m,
	unsigned long long mlen,
	const unsigned char *n,
	const unsigned char *k
);

int crypto_secretbox_open_easy(
	unsigned char *m,
	const unsigned char *c,
	unsigned long long clen,
	const unsigned char *n,
	const unsigned char *k
);

void randombytes(unsigned char* const buf, const unsigned long long buf_len);
]]

local sodium = {}

local MACBYTES = lib.crypto_secretbox_macbytes()
local NONCEBYTES = lib.crypto_secretbox_noncebytes()
local KEYBYTES = lib.crypto_secretbox_keybytes()

local key_t = typeof(format('const unsigned char[%i]', tonumber(KEYBYTES)))
local nonce_t = typeof(format('unsigned char[%i] const', tonumber(NONCEBYTES)))
local unsigned_char_array_t = typeof('unsigned char[?]')

function sodium.key(key)
	return key_t(key)
end

function sodium.nonce()
	local nonce = nonce_t()
	lib.randombytes(nonce, NONCEBYTES)
	return nonce, NONCEBYTES
end

function sodium.encrypt(decrypted, decrypted_len, nonce, key)

	local encrypted_len = decrypted_len + MACBYTES
	local encrypted = unsigned_char_array_t(encrypted_len)

	if lib.crypto_secretbox_easy(encrypted, decrypted, decrypted_len, nonce, key) < 0 then
		return error('libsodium encryption failed')
	end

	return encrypted, encrypted_len

end

function sodium.decrypt(encrypted, encrypted_len, nonce, key)

	local decrypted_len = encrypted_len - MACBYTES
	local decrypted = unsigned_char_array_t(decrypted_len)

	if lib.crypto_secretbox_open_easy(decrypted, encrypted, encrypted_len, nonce, key) < 0 then
		return error('libsodium decryption failed')
	end

	return decrypted, decrypted_len

end

return sodium
