local loaded, lib

return setmetatable({}, {__call = function(sodium, path)

if loaded then return sodium end

local ffi = require('ffi')

loaded, lib = pcall(ffi.load, path)
if not loaded then
	return nil, lib
end

local new = ffi.new

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
]]

local MACBYTES = lib.crypto_secretbox_macbytes()

local function encrypt(decrypted, decrypted_len, nonce, key)

	local encrypted_len = decrypted_len + MACBYTES
	local encrypted = new('unsigned char[?]', encrypted_len)

	if lib.crypto_secretbox_easy(encrypted, decrypted, decrypted_len, nonce, key) < 0 then
		return error('libsodium encryption failed')
	end

	return encrypted, encrypted_len

end

local function decrypt(encrypted, encrypted_len, nonce, key)

	local decrypted_len = encrypted_len - MACBYTES
	local decrypted = new('unsigned char[?]', decrypted_len)

	if lib.crypto_secretbox_open_easy(decrypted, encrypted, encrypted_len, nonce, key) < 0 then
		return error('libsodium decryption failed')
	end

	return decrypted, decrypted_len

end

sodium.encrypt = encrypt
sodium.decrypt = decrypt

return sodium

end})
