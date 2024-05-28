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
#include "adv7391.h"

static int adv7391_probe(struct udevice *dev)
{
    printf("\t *******************************************\n");
    printf("\t ************** %s **************\n", __func__);
    printf("\t *******************************************\n");
    return 0;
}

static const struct udevice_id adv7391_of_match[] = {
	{ .compatible = "adi,adv7391" },
	{}
};

U_BOOT_DRIVER(adv7391) = {
    .name = "adv7391",
    .id = UCLASS_VIDEO_BRIDGE,
	.of_match = adv7391_of_match,
    .probe = adv7391_probe,
};
