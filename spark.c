#define _POSIX_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
	if (isatty(fileno(stdin)) && (argc < 2 || !strcmp(argv[1], "-h") || !strcmp(argv[1], "--help"))) {
		fprintf(stderr, "Spark\n  by Jason A. Donenfeld <Jason@zx2c4.com>\n\n");
		fprintf(stderr, "Usage: %s [number] [number] [number] ...\n", argv[0]);
		fprintf(stderr, "If no arguments are given, read from stdin numbers delimited by\n");
		fprintf(stderr, "any characters except 0 1 2 3 4 5 6 7 8 9 . - e E.\n");
		return 1;
	}
	double *values;
	int total;
	double max = DBL_MIN;
	double min = DBL_MAX;
	if (argc > 1) {
		total = argc - 1;
		values = malloc(sizeof(double) * total);
		if (!values) {
			perror("malloc");
			return 2;
		}
		for (int i = 0; i < total; ++i) {
			values[i] = atof(argv[i + 1]);
			if (values[i] > max)
				max = values[i];
			if (values[i] < min)
				min = values[i];
		}
	} else {
		char buffer[32];
		int i = 0;
		int c = 0;
		int size = 16;
		total = 0;
		values = malloc(sizeof(double) * size);
		if (!values) {
			perror("malloc");
			return 2;
		}
		while (c != EOF) {
			for (;;) {
				c = getchar();
				if ((c >= '0' && c <= '9') || c == '.' || c == '-' || c == 'e' || c == 'E')
					buffer[i++] = c;
				else
					break;
				if (i == 31)
					break;
			}
			buffer[i] = '\0';
			if (i) {
				if (total == size) {
					size *= 2;
					values = realloc(values, sizeof(double) * size);
					if (!values) {
						perror("realloc");
						return 2;
					}
				}
				values[total] = atof(buffer);
				if (values[total] > max)
					max = values[total];
				if (values[total] < min)
					min = values[total];
				++total;
			}
			i = 0;
		}
	}

	double difference = max - min + 1;
	if (difference < 1)
		difference = 1;
	const int levels = 8;
	for (int i = 0; i < total; ++i) {
		putchar('\xe2');
		putchar('\x96');
		putchar('\x81' + (int)round((values[i] - min + 1) / difference * (levels - 1)));
	}
	putchar('\n');

	free(values);
	return 0;
}
