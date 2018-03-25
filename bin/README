Discordia loads dynamic libraries using LuaJIT's `ffi.load` function. On Windows, you must rename your libopus file to `opus.dll` and your libsodium file to `sodium.dll`. They must both be placed in a proper directory. Use your main application directory if you are unsure of which to use. Also be sure to use the appropriate file for your architecture. This can be checked at `jit.arch`.

From http://luajit.org/ext_ffi_api.html:

`clib = ffi.load(name [,global])`

This loads the dynamic library given by name and returns a new C library namespace which binds to its symbols. On POSIX systems, if global is true, the library symbols are loaded into the global namespace, too.

If name is a path, the library is loaded from this path. Otherwise name is canonicalized in a system-dependent way and searched in the default search path for dynamic libraries:

On POSIX systems, if the name contains no dot, the extension .so is appended. Also, the lib prefix is prepended if necessary. So ffi.load("z") looks for "libz.so" in the default shared library search path.

On Windows systems, if the name contains no dot, the extension .dll is appended. So ffi.load("ws2_32") looks for "ws2_32.dll" in the default DLL search path.

From http://luajit.org/ext_jit.html:

`jit.arch`

Contains the target architecture name: "x86", "x64", "arm", "ppc", "ppcspe", or "mips".
