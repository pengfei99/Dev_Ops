
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

static void err(int val, const char *fmt, ...) {
  int sav;
  va_list ap;

  sav = errno;
  (void)fprintf(stderr, "%s: ", "xxx");
  if (fmt != NULL) {
    va_start(ap, fmt);
    (void)vfprintf(stderr, fmt, ap);
    va_end(ap); }
  (void)fprintf(stderr, ": %s\n", strerror(sav));

  exit(val); }

static void errx(int val, const char *fmt, ...) {
  va_list ap;

  (void)fprintf(stderr, "%s: ", "xxx");
  if (fmt != NULL) {
    va_start(ap, fmt);
    (void)vfprintf(stderr, fmt, ap);
    va_end(ap); }
  (void)fprintf(stderr, "\n");

  exit(val); }

static void warn(const char *fmt, ...) {
  int sav;
  va_list ap;

  sav = errno;
  (void)fprintf(stderr, "%s: ", "xxx");
  if (fmt != NULL) {
    va_start(ap, fmt);
    (void)vfprintf(stderr, fmt, ap);
    va_end(ap); }
  (void)fprintf(stderr, ": %s\n", strerror(sav));

  return; }

static void warnx(const char *fmt, ...) {
  va_list ap;

  (void)fprintf(stderr, "%s: ", "xxx");
  if (fmt != NULL) {
    va_start(ap, fmt);
    (void)vfprintf(stderr, fmt, ap);
    va_end(ap); }
  (void)fprintf(stderr, "\n");

  return; }

