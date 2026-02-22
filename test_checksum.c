#include <stdio.h>
#include <stdint.h>
#include <dlfcn.h>
int main() {
    void* handle = dlopen("/Applications/Opal.app/Contents/Frameworks/libopal_ffi.dylib", RTLD_NOW);
    if (!handle) { printf("Failed: %s
", dlerror()); return 1; }
    uint16_t (*fn)() = dlsym(handle, "uniffi_opal_ffi_checksum_constructor_commandhistory_new");
    if (!fn) { printf("Symbol not found
"); return 1; }
    printf("Checksum: %d
", fn());
    dlclose(handle);
    return 0;
}
