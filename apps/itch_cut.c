#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "itch/byteorder.h"
#include <limits.h>
#include <unistd.h>

#define BASE 10
#define LEN_PREFIX 2
#define SYSTEM_EVENT_LEN 12
#define EVENT_CODE_OFFSET 11

static int fail_cleanup(FILE *in, FILE *out, const char *tmp);

int main(int argc, char *argv[])
{
	uint8_t len_buf[LEN_PREFIX];
	uint8_t msg[UINT16_MAX];
	char tmp[PATH_MAX];
	FILE *fp, *out;

	if (argc != 4) {
		fprintf(stderr, "usage: <input file> <output file> <msgnum>\n");
		return 1;
	}

	char *endptr;
	int long msgnum;

	if ((msgnum = strtol(argv[3], &endptr, BASE)) <= 0) {
		fprintf(stderr, "error: no message length entry\n");
		return 1;
	}

	if (*endptr != '\0') {
		fprintf(stderr, "error: invalid msgnum\n");
		return 1;
	} 

	int pathlen = snprintf(tmp, sizeof(tmp), "%s.tmp", argv[2]);

	if (pathlen < 0 || (size_t)pathlen >= sizeof(tmp)) {
		fprintf(stderr, "error: Output path too long\n");
		return 1;
	}

	fp = fopen(argv[1], "rb");

	if (!fp) {
		perror(argv[1]);
		return 1;
	}

	out = fopen(tmp, "wb");

	if (!out) {
		perror(tmp);
		fclose(fp);
		return 1;
	}

	size_t off = 0;
	long int count = 0;
	size_t bytes_read;

	while (count < msgnum) {
		if ((bytes_read = fread(len_buf, sizeof(len_buf[0]), LEN_PREFIX, fp)) < LEN_PREFIX) {
			if (bytes_read == 1) {
				if (feof(fp)) {
					fprintf(stderr, "error: truncated prefix at off %zu\n", off);
					return fail_cleanup(fp, out, tmp);
				} else {
					fprintf(stderr, "error: read error\n");
					return fail_cleanup(fp, out, tmp);
				}
			} else {
				if (feof(fp)) {
					break;
				} else {
					fprintf(stderr, "error: read error\n");
					return fail_cleanup(fp, out, tmp);
				}
			}
		}
			
		uint16_t len = load_be16(len_buf);

                if (len == 0) {
                        fprintf(stderr, "error: zero-byte length at offset %zu\n", off);
                        return fail_cleanup(fp, out, tmp);
                }

		if ((bytes_read = fread(msg, sizeof(msg[0]), len, fp)) < len) {
			if (feof(fp)) {
				fprintf(stderr, "error: message truncated at end of file on offset %zu\n", off);
				return fail_cleanup(fp, out, tmp);
			} else {
				fprintf(stderr, "error: read error\n");
				return fail_cleanup(fp, out, tmp);
			}
		}

		if (count == 0) {
			if (len != SYSTEM_EVENT_LEN) {
				fprintf(stderr, "error: invalid System Event Length Prefix\n");
				return fail_cleanup(fp, out, tmp);
			}

			if (msg[0] != 'S') {
				fprintf(stderr, "error: Invalid System Event Type\n");
				return fail_cleanup(fp, out, tmp);
			}

			if (msg[EVENT_CODE_OFFSET] != 'O') {
				fprintf(stderr, "error: Invalid Event Code\n");
				return fail_cleanup(fp, out, tmp);
			}
		}

		if (fwrite(len_buf, sizeof(len_buf[0]), LEN_PREFIX, out) != LEN_PREFIX || fwrite(msg, sizeof(msg[0]), len, out) != len) {
                        fprintf(stderr, "error: write error\n");
                        return fail_cleanup(fp, out, tmp);
                }

		off += len + LEN_PREFIX;
		count++;
	}

	if (count < msgnum) {
		fprintf(stderr, "End of File. Wrote %ld messages (requested %ld)\n", count, msgnum);
		return fail_cleanup(fp, out, tmp);
	}

	if (fclose(out) != 0) {
		perror("fclose");
		unlink(tmp);
		fclose(fp);
		return 1;
	}

	if (rename(tmp, argv[2]) != 0) {
		perror("rename");
		fprintf(stderr, "error: rename failed, try again\n");
		unlink(tmp);
		fclose(fp);
		return 1;
	}

	fprintf(stderr, "Cut %ld messages (%zu bytes)\n", count, off);

	fclose(fp);

	return 0;
}

static int fail_cleanup(FILE *in, FILE *out, const char *tmp) {
	fclose(out);
	unlink(tmp);
	fclose(in);
	return 1;
}
