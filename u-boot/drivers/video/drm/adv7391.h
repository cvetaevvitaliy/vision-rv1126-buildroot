/**
 * @file adv7391.h
 * @author Mykola Bykov (berkut.362@gmail.com)
 * @brief 
 * @version 0.1
 * @date 2024-05-09
 * 
 * @copyright Copyright (c) 2024
 * 
 */

#ifndef _ADV7391_H_
#define _ADV7391_H_

#include <clk.h>
#include <asm/gpio.h>
#include <dm/device.h>

struct adv7391 {
	struct udevice *dev;
	struct gpio_desc reset_gpio;
	struct udevice *rgb_dev;

	// uint8_t address;
};

#endif // _ADV7391_H_