#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "itch/byteorder.h"

static int failures = 0;

static void check(const char *name, uint16_t got, uint16_t want)
{
	if (got == want) {
		printf("PASS %-10s got %u\n", name, (unsigned)got);
	} else {
		printf("FAIL %-10s got %u, want %u", name, (unsigned)got, (unsigned)want);
		failures++;
	}
}

int main(void)
{
	const uint8_t a[2] = {0x00, 0x27};
	const uint8_t b[2] = {0x01, 0x00};
	const uint8_t c[2] = {0xFF, 0xFF};

	/* Step 1: see the values before the byte-order */
	uint16_t raw;
	memcpy(&raw, a, sizeof(raw));
	printf("raw BEFORE be16toh: %u (0x%04x)\n", (unsigned)raw, (unsigned)raw);

	/* Step 2: Check the three known inputs */
	check("00 27", load_be16(a), 39);
	check("01 00", load_be16(b), 256);
	check("FF FF", load_be16(c), 65535);

	/*Step 3: an odd address. _Alignas(16) makes buf start with a multiple 
	  of 16, so buf + 55 is guaranteed to be odd. */
	_Alignas(16) uint8_t buf[64] = {0};
	buf[55] = 0x00;
	buf[56] = 0x27;
	printf("buf+55 is odd: %s\n", ((uintptr_t)(buf + 55) & 1u) ? "yes" : "no");
	check("offset 55", load_be16(buf + 55), 39);

#ifdef SHOW_BAD_CAST
	/* Deliberately wrong: pretend a uint16_t lives at an odd address */
	uint16_t bad = *(const uint16_t *)(buf + 55);
	printf("bad cast gave %u\n", (unsigned)bad);

#endif
	return failures ? 1 : 0;
}

