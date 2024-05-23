################################################################################
#
# 
#
################################################################################

VISION_SERVICES_VERSION = 0.3.0
VISION_SERVICES_SITE = ssh://git@gitlab.hard-tech.org.ua/vision/vision-services.git
VISION_SERVICES_SITE_METHOD = git
VISION_SERVICES_INSTALL_STAGING = NO
VISION_SERVICES_INSTALL_TARGET = YES

# TODO: need to change to Release
VISION_SERVICES_CONF_OPTS += -DCMAKE_BUILD_TYPE=Debug

# all dependencies 
VISION_SERVICES_DEPENDENCIES = host-pkgconf syslog-ng rk_oem

# install to OEM dir
ifeq ($(BR2_PACKAGE_RK_OEM), y)
	VISION_SERVICES_TARGET_DESTDIR=$(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR)
	VISION_SERVICES_INSTALL_TARGET_OPTS = DESTDIR=$(BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR) install/fast
endif



ifeq ($(BR2_PACKAGE_VISION_AUTOPILOT_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_AUTOPILOT_SERVICE=ON"
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_AUTOPILOT_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_CAMERA_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_CAMERA_SERVICE=ON"
	VISION_SERVICES_DEPENDENCIES += rkmedia camera_engine_rkaiq libpng
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_CAMERA_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_DETECTION_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_DETECTION_SERVICE=ON"
	VISION_SERVICES_DEPENDENCIES += rknpu
	VISION_SERVICES_ENCRYPT_LIST += oem/usr/bin/vision-detection-service
	VISION_SERVICES_ENCRYPT_LIST += etc/init.d/S99vision-detection-service
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_DETECTION_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_TRACKER_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_TRACKER_SERVICE=ON"
	VISION_SERVICES_ENCRYPT_LIST += oem/usr/bin/vision-tracker-service
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_TRACKER_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_DISPALY_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_DISPLAY_SERVICE=ON"
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_DISPLAY_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_MSP_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_MSP_SERVICE=ON"
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_MSP_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_QR_SCAN_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_QR_SCAN_SERVICE=ON"
	VISION_SERVICES_DEPENDENCIES += zbar
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_QR_SCAN_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_VIDEO_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_VIDEO_SERVICE=ON"
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_VIDEO_SERVICE=OFF"
endif

ifeq ($(BR2_PACKAGE_VISION_OSD_SERVICE),y)
	VISION_SERVICES_CONF_OPTS += "-DBUILD_OSD_SERVICE=ON"
else
	VISION_SERVICES_CONF_OPTS += "-DBUILD_OSD_SERVICE=OFF"
endif


define VISION_SERVICES_INSTALL_CONFIG
	$(INSTALL) -D -m  644 $(@D)/assets/default_config.ini ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/etc/vision/config.ini  
endef

define VISION_SERVICES_INSTALL_ASSETS
	$(INSTALL) -D -m  644 $(@D)/assets/screensaver.png ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/assets/screensaver.png
	$(INSTALL) -D -m  755 $(@D)/assets/vision ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/usr/bin/vision
	$(INSTALL) -D -m  755 ${TOPDIR}/../tools/upgrade/mount.sdcard.sh ${BASE_DIR}/target/usr/bin/mount.sdcard.sh
	echo "${VISION_SERVICES_VERSION}" > ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/etc/vision/version # should be content of VISION_SERVICES_VERSION
endef

define VISION_SERVICES_INSTALL_SCRIPTS
	$(INSTALL) -D -m  755 $(@D)/assets/init.d/* "${TARGET_DIR}/etc/init.d/"
	$(INSTALL) -D -m  755 $(@D)/assets/osd_menu_nav.sh "${TARGET_DIR}/usr/bin/osd_menu_nav.sh"
endef

define VISION_SERVICES_INSTALL_AI_MODEL
	$(INSTALL) -D -m  644 $(@D)/assets/default_model.rknn ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/ai_model/default_model.rknn
endef

define VISION_SERVICES_INSTALL_LIBS
	$(INSTALL) -D -m  755 $(@D)/lib/bytetrack/libbytetrack.so ${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/usr/lib/libbytetrack.so
endef

define VISION_SERVICES_INSTALL_FONTS
	mkdir -p "${TARGET_DIR}/etc/displayport/"
	mkdir -p "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/fonts/" 
	$(INSTALL) -D -m  644 $(@D)/assets/fonts/* "${TARGET_DIR}/etc/displayport/"
	$(INSTALL) -D -m  644 $(@D)/assets/fonts/* "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/fonts/" 
endef


define VIS_SEC_PREPARE
	@echo ">> Prepare $(1)"
	mkdir -p "/tmp/vision_security/$(dir $(1))" "/tmp/vision_security/tmp/vision_security/$(dir $(1))"

	[ -n "$(filter oem/%,$(1))" ] && mv "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/$(subst oem/,,$(1))" "/tmp/vision_security/tmp/vision_security/$(1)" || \
					 mv "${TARGET_DIR}/$(1)" "/tmp/vision_security/tmp/vision_security/$(1)"
	ln -s "/tmp/vision_security/$(1)" "/tmp/vision_security/$(dir $(1))"
	@echo ">> Done"
endef

define VISION_SERVICES_QR_PROCESSING
	@echo "> QR Processing"

	cp -r $(@D)/assets/security/* "${TARGET_DIR}/"

	$(INSTALL) -D -m  644 "${TOPDIR}/../tools/Security/vision_public.pem" "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/assets/"
	$(INSTALL) -D -m  644 "${TOPDIR}/../tools/Security/pass_pub.txt" "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/assets/"
	$(INSTALL) -D -m  774 "${TOPDIR}/../tools/Security/activate_vision.sh" "${TARGET_DIR}/usr/bin/av"
	@echo "> QR Processing - Done"
endef

define VISION_SERVICES_ENCRYPT_SERVICES
	@echo "> Vision_security"
	rm -rf /tmp/vision_security

	$(foreach svc,$(VISION_SERVICES_ENCRYPT_LIST),$(call VIS_SEC_PREPARE,$(svc)))

	$(call VIS_SEC_PREPARE,oem/ai_model/default_model.rknn)

	tar cvzf /tmp/vision_security.tar.gz -C /tmp/vision_security/ .
	cd "${TOPDIR}/../tools/Security"; ./encrypt.sh /tmp/vision_security.tar.gz "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/assets/vs.bin"
	@echo "> Vision_security - Done"
endef


define VISION_SERVICES_INSTALL_BUILD_HOOKS
	$(INSTALL) -D -m  644 $(@D)/assets/build_datestamp "${BR2_PACKAGE_RK_OEM_INSTALL_TARGET_DIR}/etc/vision/build_datestamp" 
endef


VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_CONFIG

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_ASSETS

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_SCRIPTS

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_AI_MODEL

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_FONTS

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_INSTALL_BUILD_HOOKS

VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_QR_PROCESSING

ifeq ($(BR2_PACKAGE_VISION_ENCRYPTED),y)
	VISION_SERVICES_POST_INSTALL_TARGET_HOOKS += VISION_SERVICES_ENCRYPT_SERVICES
endif

$(eval $(cmake-package))
