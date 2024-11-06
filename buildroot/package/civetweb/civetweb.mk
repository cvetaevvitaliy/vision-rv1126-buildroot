################################################################################
#
# civetweb
#
################################################################################

CIVETWEB_VERSION = v1.16
CIVETWEB_SITE = $(call github,civetweb,civetweb,$(CIVETWEB_VERSION))
CIVETWEB_LICENSE = MIT
CIVETWEB_LICENSE_FILES = LICENSE.md
CIVETWEB_INSTALL_STAGING = YES

CIVETWEB_CONF_OPTS = TARGET_OS=LINUX WITH_IPV6=1
CIVETWEB_COPT = -DHAVE_POSIX_FALLOCATE=0 -fPIC
CIVETWEB_LIBS = -lpthread -lm
CIVETWEB_SYSCONFDIR = /etc
CIVETWEB_HTMLDIR = /var/www

ifeq ($(BR2_PACKAGE_CIVETWEB_WITH_LUA),y)
CIVETWEB_CONF_OPTS += WITH_LUA=1
CIVETWEB_LIBS += -ldl
endif

ifeq ($(BR2_PACKAGE_OPENSSL),y)
CIVETWEB_COPT += -DNO_SSL_DL
CIVETWEB_LIBS += -lssl -lcrypto -lz
CIVETWEB_DEPENDENCIES += openssl
else
CIVETWEB_COPT += -DNO_SSL
endif

define CIVETWEB_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) build slib \
		$(CIVETWEB_CONF_OPTS) \
		COPT="$(CIVETWEB_COPT)" LIBS="$(CIVETWEB_LIBS)"
endef

define CIVETWEB_INSTALL_TARGET_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) install \
		DOCUMENT_ROOT="$(CIVETWEB_HTMLDIR)" \
		CONFIG_FILE2="$(CIVETWEB_SYSCONFDIR)/civetweb.conf" \
		HTMLDIR="$(TARGET_DIR)$(CIVETWEB_HTMLDIR)" \
		SYSCONFDIR="$(TARGET_DIR)$(CIVETWEB_SYSCONFDIR)" \
		PREFIX="$(TARGET_DIR)/usr" \
		$(CIVETWEB_CONF_OPTS) \
		COPT='$(CIVETWEB_COPT)'
	# Install shared library to the target's /usr/lib directory
    $(TARGET_CONFIGURE_OPTS) $(INSTALL) -D -m 0755 $(@D)/libcivetweb.so $(TARGET_DIR)/usr/lib/libcivetweb.so
    # Optional: If there are additional headers, install them to /usr/include
    $(TARGET_CONFIGURE_OPTS) $(INSTALL) -D -m 0644 $(@D)/include/civetweb.h $(TARGET_DIR)/usr/include/civetweb.h
endef

define CIVETWEB_INSTALL_STAGING_CMDS
    # Install shared library to the staging directory (for SDK)
    $(TARGET_CONFIGURE_OPTS) $(INSTALL) -D -m 0755 $(@D)/libcivetweb.so $(STAGING_DIR)/usr/lib/libcivetweb.so
    $(TARGET_CONFIGURE_OPTS) $(INSTALL) -D -m 0644 $(@D)/include/civetweb.h $(STAGING_DIR)/usr/include/civetweb.h
endef

$(eval $(generic-package))
