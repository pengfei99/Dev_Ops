# Process this file with autoconf to produce a configure script.
AC_INIT([fqtools], [1.0], [njoly@pasteur.fr])
AM_INIT_AUTOMAKE
AC_CONFIG_HEADERS([src/config.h])

# Checks for programs.
AC_PROG_CC
AC_CHECK_PROG(POD2MAN, pod2man, pod2man, :)
AC_PATH_PROG(PERL, perl, , )

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([err.h stddef.h stdint.h stdlib.h string.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T
AC_TYPE_UINT64_T

# Checks for library functions.
AC_CHECK_FUNCS([memmove strndup strrchr])

# fqduplicate needs MD5 functions
SAVLIBS=$LIBS; LIBS=""; md5_lib=0; md5_hdr=0
if test $md5_lib -eq 0 -o $md5_hdr -eq 0; then
  md5_lib=0; md5_hdr=0
  AC_SEARCH_LIBS([MD5Init], [md5 bsd], [md5_lib=1; MD5LIB=$LIBS])
  AC_CHECK_HEADERS([md5.h bsd/md5.h], [md5_hdr=1; break])
  AH_TEMPLATE([USE_BSDMD5], [Use BSD like MD5 API])
  test $md5_lib -eq 1 -a $md5_hdr -eq 1 &&
    AC_DEFINE_UNQUOTED([USE_BSDMD5])
fi
if test $md5_lib -eq 0 -o $md5_hdr -eq 0; then
  md5_lib=0; md5_hdr=0
  AC_SEARCH_LIBS([MD5_Init], [crypto], [md5_lib=1; MD5LIB=$LIBS])
  AC_CHECK_HEADERS([openssl/md5.h], [md5_hdr=1; break])
  AH_TEMPLATE([USE_SSLMD5], [Use SSL like MD5 API])
  test $md5_lib -eq 1 -a $md5_hdr -eq 1 &&
    AC_DEFINE_UNQUOTED([USE_SSLMD5])
fi
if test $md5_lib -eq 0 -o $md5_hdr -eq 0; then
  AC_MSG_ERROR([No MD5 library/include found])
fi
AC_SUBST([MD5LIB], [$MD5LIB])
LIBS=$SAVLIBS

# Compatibility
test $ac_cv_header_err_h != yes && \
  AC_CONFIG_FILES([src/err.h:src/compat/err.h])

AC_CONFIG_FILES([Makefile doc/Makefile src/Makefile test/Makefile])
AC_OUTPUT
