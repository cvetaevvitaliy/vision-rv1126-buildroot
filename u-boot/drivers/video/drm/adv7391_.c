/**
 * @file adv7391.c
 * @author Mykola Bykov (berkut.362@gmail.com)
 * @brief 
 * @version 0.1
 * @date 2024-05-09
 * 
 * @copyright Copyright (c) 2024
 * 
 */

#include <common.h>
#include <i2c.h>
#include <common.h>
#include <dm.h>
#include "adv739x_regs.h"
#include "adv7391.h"

#include <common.h>
#include <boot_rkimg.h>
#include <dm.h>
#include <errno.h>
#include <i2c.h>
#include <video_bridge.h>
#include <asm/io.h>
#include <dm/device.h>
#include <dm/device-internal.h>
#include <linux/media-bus-format.h>

#include "rockchip_bridge.h"
#include "rockchip_display.h"
#include "rockchip_panel.h"

static int adv7391_init(struct adv7391 *adv7391);
static void drm_adv7391_select_output(struct overscan *overscan,
				     struct drm_display_mode *mode);
static int adv7391_tve_get_timing(struct udevice *dev);

static int adv7391_probe(struct udevice *dev)
{
    int ret = 0;

    struct adv7391 *adv7391 = dev_get_priv(dev);
    adv7391->dev = dev;

	ret = gpio_request_by_name(adv7391->dev, "reset-gpio-pin", 0,
				   &adv7391->reset_gpio, GPIOD_IS_OUT);
	if (ret) {
		dev_err(dev, "\tCannot get reset GPIO: %d\n", ret);
		return ret;
	}

    return adv7391_init(adv7391);
}

static int adv7391_init(struct adv7391 *adv7391)
{
    int ret = 0;

    // adv7391_tve_get_timing(adv7391->dev);

    dm_gpio_set_value(&adv7391->reset_gpio, 1);
	mdelay(100);
    dm_gpio_set_value(&adv7391->reset_gpio, 0);
    mdelay(100);
    ret = dm_gpio_set_value(&adv7391->reset_gpio, 1);
    mdelay(100);
	if (ret) {
    	dev_err(dev, "\tCannot set value GPIO: %d\n", ret);
	    return ret;
    }
    else
    {
        printf("\tHW reset\n");
    }
    mdelay(100);


    u8 reg = 0x00;
    u8 val = 0x00;

    reg = 0x17; // Software reset
    val = 0x02; // resets the device
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    if (ret)
    {
        printf("SW reset ret FAIL, code %d)\n", ret);
        return ret;
    }
    else
    {
        printf("\tSW reset\n");
    }
    mdelay(100);

    static const u8 adv7390_init_reg_val[11][2] = {

    	{ADV739X_SOFT_RESET, ADV739X_SOFT_RESET_DEFAULT},
    	{ADV739X_POWER_MODE_REG, ADV739X_POWER_MODE_REG_DEFAULT},
    	{ADV739X_MODE_SELECT_REG, SD_INPUT_MODE}, // SD input
    	{ADV739X_SD_MODE_REG1, ADV7390_SD_MODE_REG1_DEFAULT}, // SD luma filter Luma SSAF
    	{ADV739X_SD_MODE_REG2, ADV7390_SD_MODE_REG2_DEFAULT}, // SD PrPb SSAF filter, SD DAC Output 1, SD pedestal, SD pixel data valid, SD active video edge control
    	{ADV739X_SD_MODE_REG6, ADV7390_SD_MODE_REG6_DEFAULT}, // SD PAL/SECAM input standard autodetection
    	{0x01, 0x00},
    	{0x80, 0x00},
        {0x82, 0xCB},
    	{0x84, 0x48}, /** test patern SD */
    	{0x87, 0x20},
    };


    for (int i = 0; i < 11; i++)
    {
        ret = dm_i2c_write(adv7391->dev,
                            adv7390_init_reg_val[i][0],
                            &adv7390_init_reg_val[i][1], 1);
        printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", adv7390_init_reg_val[i][0], adv7390_init_reg_val[i][1], ret ? "Fail" : "OK", ret);
    }
    
    return 0;

    reg = 0x00; // Power mode
    // val = 0x1C; // DAC 1, 2, 3 on, PLL enable
    val = 0x10; // DAC 1 on
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    reg = 0x01; // Mode select
    val = 0x00; // SD input
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    reg = 0x80; // SD Mode Register 1
    // SD standard: PAL B;
    // SD luma filter: Luma SSAF;
    // SD chroma filter: 1.3 MHz;
    val = 0x11; 

    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    reg = 0x82; // SD Mode Register 2
    // SD PrPb SSAF filter enable;+
    // SD DAC Output 1 ...;?
    // SD square pixel mode enable;+
    // SD pixel data valid enable;+
    // SD active video edge control enable + 
    val = 0xD3;
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);
    mdelay(100);

    reg = 0x8C; // SD FSC Register
    val = 0x0C; // Subcarrier Frequency Bits
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);
    mdelay(100);
    val = 0;
    ret = dm_i2c_read(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);
    mdelay(100);

    reg = 0x8D;
    val = 0x8C;
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    reg = 0x8E;
    val = 0x79;
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    reg = 0x8F;
    val = 0x26;
    ret = dm_i2c_write(adv7391->dev, reg, &val, 1);
    printf("\treg 0x%02X: \t0x%02X\t (ret %s, code %d)\n", reg, val, ret ? "Fail" : "OK", ret);

    mdelay(100);

    // for (reg = 0x00; reg < 0xDF; reg++)
    // {
    //     int ret = dm_i2c_read(adv7391->dev, reg, &val, 1);
    //     printf("\treg 0x%02X: \t0x%02X\t (ret %s, code: %d)\n", reg, val, ret ? "FAIL" : "OK", ret);
    // }

    return ret;
}

// static void rk1000_tve_bridge_enable(struct rockchip_bridge *bridge)
// {
// 	u8 tv_encoder_regs_pal[] = {0x06, 0x00, 0x00, 0x03, 0x00, 0x00};
// 	u8 tv_encoder_control_regs_pal[] = {0x41, 0x01};
// 	u8 tv_encoder_regs_ntsc[] = {0x00, 0x00, 0x00, 0x03, 0x00, 0x00};
// 	u8 tv_encoder_control_regs_ntsc[] = {0x43, 0x01};
// 	char data[4] = {0x88, 0x00, 0x22, 0x00};
// 	struct adv7391 *adv7391 = dev_get_priv(bridge->dev);
// 	struct connector_state *conn_state = &bridge->state->conn_state;
// 	struct drm_display_mode *mode = &conn_state->mode;
// 	// struct rk1000_ctl *rk1000_ctl = &rk1000_tve->rk1000_ctl;

// 	// rk1000_ctl_write_block(rk1000_ctl, 0, (u8 *)data, 4);

// 	/* rk1000 power down output dac */
// 	data[0] = 0x07;
// 	// rk1000_tv_write_block(adv7391, 0x03, (u8 *)data, 1);

// 	if (mode->vdisplay == 576) {
// 		// rk1000_tv_write_block(adv7391, 0, tv_encoder_regs_pal,
// 		// 		      sizeof(tv_encoder_regs_pal));
// 		// rk1000_ctl_write_block(rk1000_ctl, 3,
// 		// 		       tv_encoder_control_regs_pal,
// 		// 		       sizeof(tv_encoder_control_regs_pal));
// 	} else {
// 		// rk1000_tv_write_block(rk1000_tve, 0, tv_encoder_regs_ntsc,
// 		// 		      sizeof(tv_encoder_regs_ntsc));
// 		// rk1000_ctl_write_block(rk1000_ctl, 3,
// 		// 		       tv_encoder_control_regs_ntsc,
// 		// 		       sizeof(tv_encoder_control_regs_ntsc));
// 	}
// }

static int adv7391_tve_get_timing(struct udevice *dev)
{
    printf("\n\n\tAAAAAA\n\n");

	struct rockchip_bridge *bridge =
		(struct rockchip_bridge *)dev_get_driver_data(dev);

	struct connector_state *conn_state = &bridge->state->conn_state;
	struct drm_display_mode *mode = &conn_state->mode;
	struct overscan *overscan = &conn_state->overscan;

	drm_adv7391_select_output(overscan, mode);

	return 0;
}


static void drm_adv7391_select_output(struct overscan *overscan,
				     struct drm_display_mode *mode)
{
	char baseparameter_buf[8 * RK_BLK_SIZE] __aligned(ARCH_DMA_MINALIGN);
	struct base_screen_info *screen_info = NULL;
	struct base_disp_info base_parameter;
	struct blk_desc *dev_desc;
	const struct base_overscan *scan;
	disk_partition_t part_info;
	int ret, i, screen_size;
	int max_scan = 100;
	int min_scan = 51;

	overscan->left_margin = max_scan;
	overscan->right_margin = max_scan;
	overscan->top_margin = max_scan;
	overscan->bottom_margin = max_scan;

	mode->hdisplay = 720;
	mode->hsync_start = 732;
	mode->hsync_end = 738;
	mode->htotal = 864;
	mode->vdisplay = 576;
	mode->vsync_start = 582;
	mode->vsync_end = 588;
	mode->vtotal = 625;
	mode->clock = 27000;
	mode->flags = DRM_MODE_FLAG_NHSYNC | DRM_MODE_FLAG_NVSYNC;

	dev_desc = rockchip_get_bootdev();
	if (!dev_desc) {
		printf("%s: Could not find device\n", __func__);
		return;
	}

    ret = part_get_info_by_name(dev_desc, "baseparameter", &part_info);
	if (ret < 0) {
		printf("Could not find baseparameter partition, %d\n", ret);
		return;
	}

	ret = blk_dread(dev_desc, part_info.start, 1,
			(void *)baseparameter_buf);
	if (ret < 0) {
		printf("read baseparameter failed\n");
		return;
	}

	memcpy(&base_parameter, baseparameter_buf, sizeof(base_parameter));
	scan = &base_parameter.scan;

	screen_size = sizeof(base_parameter.screen_list) /
		sizeof(base_parameter.screen_list[0]);

	for (i = 0; i < screen_size; i++) {
		if (base_parameter.screen_list[i].type ==
		    DRM_MODE_CONNECTOR_TV) {
			screen_info = &base_parameter.screen_list[i];
			break;
		}
	}

	if (scan->leftscale < min_scan && scan->leftscale > 0)
		overscan->left_margin = min_scan;
	else if (scan->leftscale < max_scan)
		overscan->left_margin = scan->leftscale;

	if (scan->rightscale < min_scan && scan->rightscale > 0)
		overscan->right_margin = min_scan;
	else if (scan->rightscale < max_scan)
		overscan->right_margin = scan->rightscale;

	if (scan->topscale < min_scan && scan->topscale > 0)
		overscan->top_margin = min_scan;
	else if (scan->topscale < max_scan)
		overscan->top_margin = scan->topscale;

	if (scan->bottomscale < min_scan && scan->bottomscale > 0)
		overscan->bottom_margin = min_scan;
	else if (scan->bottomscale < max_scan)
		overscan->bottom_margin = scan->bottomscale;

	if (screen_info &&
	    (screen_info->mode.hdisplay == 720 &&
	     screen_info->mode.hsync_end == 742 &&
	     screen_info->mode.vdisplay == 480)) {
		mode->hdisplay = 720;
		mode->hsync_start = 736;
		mode->hsync_end = 742;
		mode->htotal = 858;
		mode->vdisplay = 480;
		mode->vsync_start = 494;
		mode->vsync_end = 500;
		mode->vtotal = 525;
		mode->clock = 27000;
	} else {
		mode->hdisplay = 720;
		mode->hsync_start = 732;
		mode->hsync_end = 738;
		mode->htotal = 864;
		mode->vdisplay = 576;
		mode->vsync_start = 582;
		mode->vsync_end = 588;
		mode->vtotal = 625;
		mode->clock = 27000;
	}
}

struct video_bridge_ops adv7391_ops = {
	.get_timing = adv7391_tve_get_timing,
};

static const struct udevice_id adv7391_of_match[] = {
	{ .compatible = "adi,adv7391" },
	{}
};

U_BOOT_DRIVER(adv7391) = {
    .name = "adv7391",
    .id = UCLASS_VIDEO_BRIDGE,
	.of_match = adv7391_of_match,
	.ops = &adv7391_ops,
    .probe = adv7391_probe,
    .priv_auto_alloc_size = sizeof(struct adv7391),
};
