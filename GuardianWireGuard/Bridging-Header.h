//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <stdbool.h>
#include <stdint.h>

#define WG_KEY_LEN (32)
#define WG_KEY_LEN_BASE64 (45)
#define WG_KEY_LEN_HEX (65)

void key_to_base64(char base64[WG_KEY_LEN_BASE64],
				   const uint8_t key[WG_KEY_LEN]);
bool key_from_base64(uint8_t key[WG_KEY_LEN], const char* base64);

void key_to_hex(char hex[WG_KEY_LEN_HEX], const uint8_t key[WG_KEY_LEN]);
bool key_from_hex(uint8_t key[WG_KEY_LEN], const char* hex);

bool key_eq(const uint8_t key1[WG_KEY_LEN], const uint8_t key2[WG_KEY_LEN]);

// Note from CJ 2021-12-14:
// the starting off point for this relative import starts at where we are in this file
// in the direcoty structure not anywhere in the derived data structure or anything else
// It is quite confusing
//#include "../macosglue.h"
#include "../wireguard/Sources/WireGuardKitC/WireGuardKitC.h"
#include "../wireguard/Sources/WireGuardKitGo/wireguard.h"
#include "../wireguard/Sources/Shared/Logging/ringlogger.h"
