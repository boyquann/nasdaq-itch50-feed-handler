#ifndef BYTEORDER_H
#define BYTEORDER_H

#include <stdint.h>
#include <string.h>
#include <endian.h>

static inline uint16_t load_be16(const uint8_t *p)
{
	uint16_t raw;
	memcpy(&raw, p, sizeof(raw));
	return (uint16_t)be16toh(raw);
}

#endif /* ITCH_BYTEORDER_H */
