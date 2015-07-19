PROG=	scrypt
SRCS=	main.c
LDADD+=	-lcrypto
WARNS?=	6

# We have a config file for FreeBSD
CFLAGS	+=	-I .
CFLAGS	+=	-DCONFIG_H_FILE=\"config_freebsd.h\"

.PATH.c	:	libcperciva/alg
SRCS	+=	sha256.c
CFLAGS	+=	-I libcperciva/alg
.PATH.c	:	libcperciva/cpusupport
SRCS	+=	cpusupport_x86_aesni.c
SRCS	+=	cpusupport_x86_sse2.c
CFLAGS	+=	-I libcperciva/cpusupport
.PATH.c	:	libcperciva/crypto
SRCS	+=	crypto_aes.c
SRCS	+=	crypto_aes_aesni.c
SRCS	+=	crypto_aesctr.c
SRCS	+=	crypto_entropy.c
CFLAGS	+=	-I libcperciva/crypto
.PATH.c	:	libcperciva/util
SRCS	+=	entropy.c
SRCS	+=	insecure_memzero.c
SRCS	+=	readpass.c
SRCS	+=	warnp.c
CFLAGS	+=	-I libcperciva/util
.PATH.c	:	lib/crypto
SRCS	+=	crypto_scrypt.c
SRCS	+=	crypto_scrypt_smix.c
SRCS	+=	crypto_scrypt_smix_sse2.c
CFLAGS	+=	-I lib/crypto
.PATH.c	:	lib/scryptenc
SRCS	+=	scryptenc.c
SRCS	+=	scryptenc_cpuperf.c
CFLAGS	+=	-I lib/scryptenc
.PATH.c	:	lib/util
SRCS	+=	memlimit.c
CFLAGS	+=	-I lib/util

# CPU features compiler support detection
SRCS	+=	cpusupport-config.h
cpusupport-config.h:
	( export CC="${CC}"; export CFLAGS="${CFLAGS}"; cd libcperciva/cpusupport/Build && command -p sh cpusupport.sh ) > cpusupport-config.h
CLEANFILES+=	cpusupport-config.h
CFLAGS	+=	-I . -D CPUSUPPORT_CONFIG_FILE=\"cpusupport-config.h\"

# Building crypto_aes_aesni.o needs CFLAGS_X86_AESNI
crypto_aes_aesni.o: crypto_aes_aesni.c cpusupport-config.h
	. ./cpusupport-config.h; ${CC} ${CFLAGS} $${CFLAGS_X86_AESNI} -c $< -o $@

# Building crypto_scrypt_smix_sse2.o needs CFLAGS_X86_SSE2
crypto_scrypt_smix_sse2.o: crypto_scrypt_smix_sse2.c cpusupport-config.h
	. ./cpusupport-config.h; ${CC} ${CFLAGS} $${CFLAGS_X86_SSE2} -c $< -o $@

#======== public code ends here
SCRYPTVERSION!=basename `pwd` | cut -f 2 -d -
PKGNAME=scrypt-${SCRYPTVERSION}
PKGSIGS=scrypt-sigs-${SCRYPTVERSION}

publish-at:
	mkdir -p ${PKGNAME}
	cp -R lib libcperciva autocrap ${PKGNAME}
	cp scrypt_platform.h main.c FORMAT scrypt.1 ${PKGNAME}
	echo -n '${SCRYPTVERSION}' > scrypt-version
	mkdir -p config.aux
	aclocal -I .
	autoheader
	automake -a -c
	autoconf
	mv Makefile.in config.h.in configure ${PKGNAME}/
	rm aclocal.m4
	mv config.aux ${PKGNAME}/
	rm scrypt-version
	tar -czf ${PKGNAME}.tgz ${PKGNAME}
	rm -rf ${PKGNAME}

publish: publish-at
	sha256 ${PKGNAME}.tgz |			\
	    gpg --secret-keyring $GPGKEYFILE --clearsign -u $GPGKEYID \
	    > ${PKGSIGS}.asc

.include <bsd.prog.mk>
