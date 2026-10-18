#include <stdint.h>
#include <dlfcn.h>

typedef struct UBreakIterator UBreakIterator;
typedef struct UCalendar UCalendar;
typedef struct UDateIntervalFormat UDateIntervalFormat;
typedef struct UFormattedDateInterval UFormattedDateInterval;
typedef struct UNumberRangeFormatter UNumberRangeFormatter;
typedef struct UFormattedNumberRange UFormattedNumberRange;
typedef struct UFormattedValue UFormattedValue;
typedef struct UPluralRules UPluralRules;
typedef int32_t UErrorCode;

#define U_UNSUPPORTED_ERROR 16
#define UCAL_ZONE_OFFSET 15
#define UCAL_DST_OFFSET 16

extern UBreakIterator *ubrk_safeClone(const UBreakIterator *, void *, int32_t *, UErrorCode *);
extern UCalendar *ucal_clone(const UCalendar *, UErrorCode *);
extern void ucal_setMillis(UCalendar *, double, UErrorCode *);
extern int32_t ucal_get(const UCalendar *, int32_t, UErrorCode *);
extern void ucal_close(UCalendar *);

UBreakIterator *ubrk_clone(const UBreakIterator *bi, UErrorCode *status) {
  return ubrk_safeClone(bi, 0, 0, status);
}

int32_t ucal_getTimeZoneOffsetFromLocal(const UCalendar *cal, int32_t nonExistingTimeOpt,
                                        int32_t duplicatedTimeOpt, double millis,
                                        int32_t *rawOffset, int32_t *dstOffset, UErrorCode *status) {
  UErrorCode s = 0;
  UCalendar *c = ucal_clone(cal, &s);
  if (s > 0 || c == 0) {
    if (status) *status = U_UNSUPPORTED_ERROR;
    return 0;
  }
  ucal_setMillis(c, millis, &s);
  int32_t z = ucal_get(c, UCAL_ZONE_OFFSET, &s);
  int32_t d = ucal_get(c, UCAL_DST_OFFSET, &s);
  ucal_close(c);
  if (rawOffset) *rawOffset = z;
  if (dstOffset) *dstOffset = d;
  if (s > 0 && status) *status = s;
  return z + d;
}

void udtitvfmt_formatCalendarToResult(const UDateIntervalFormat *fmt, const UCalendar *from,
                                      const UCalendar *to, UFormattedDateInterval *res,
                                      UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
}

void unumrf_close(UNumberRangeFormatter *f) { (void)f; }
void unumrf_closeResult(UFormattedNumberRange *r) { (void)r; }

void unumrf_formatDecimalRange(const UNumberRangeFormatter *f, const char *a, int32_t al,
                               const char *b, int32_t bl, UFormattedNumberRange *r,
                               UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
}

void unumrf_formatDoubleRange(const UNumberRangeFormatter *f, double a, double b,
                              UFormattedNumberRange *r, UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
}

UNumberRangeFormatter *unumrf_openForSkeletonWithCollapseAndIdentityFallback(
    const void *skeleton, int32_t len, const char *locale, int32_t collapse, int32_t identity,
    const char *unit, void *parseErr, UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
  return 0;
}

UFormattedNumberRange *unumrf_openResult(UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
  return 0;
}

const UFormattedValue *unumrf_resultAsValue(const UFormattedNumberRange *r, UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
  return 0;
}

int32_t uplrules_selectForRange(const UPluralRules *pr, const UFormattedNumberRange *r, void *dest,
                                int32_t capacity, UErrorCode *status) {
  if (status) *status = U_UNSUPPORTED_ERROR;
  return 0;
}

/* Big Sur's ICU 66 returns a usable NumberFormatter for skeletons it does not fully
   recognize, but sets a non-fatal error status. Clear it so Bun's Intl.NumberFormat
   initialization succeeds. */
typedef void *(*unumf_open_t)(const void *, int32_t, const char *, UErrorCode *);
void *unumf_openForSkeletonAndLocale(const void *skeleton, int32_t len, const char *locale,
                                     UErrorCode *status) {
  static unumf_open_t real;
  if (!real) real = (unumf_open_t)dlsym(RTLD_NEXT, "unumf_openForSkeletonAndLocale");
  void *r = real ? real(skeleton, len, locale, status) : 0;
  if (r && status && *status > 0) *status = 0;
  return r;
}
