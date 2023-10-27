/*
 * adv7393 - ADV7393 Video Encoder Driver
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation version 2.
 *
 * This program is distributed .as is. WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/ctype.h>
#include <linux/slab.h>
#include <linux/i2c.h>
#include <linux/device.h>
#include <linux/gpio/consumer.h>
#include <linux/delay.h>
#include <linux/module.h>
#include <linux/videodev2.h>
#include <linux/uaccess.h>

#include <media/i2c/adv739x.h>
#include <media/v4l2-device.h>
#include <media/v4l2-ctrls.h>

#include "adv739x_regs.h"

MODULE_DESCRIPTION("ADV739X video encoder driver");
MODULE_LICENSE("GPL");

static bool debug;
module_param(debug, bool, 0644);
MODULE_PARM_DESC(debug, "Debug level 0-1");

struct adv739x_reg_val {
	u8 reg;
	u8 val;
};

static const struct adv739x_reg_val adv7390_init_reg_val[] = {
	{ADV739X_SOFT_RESET, ADV739X_SOFT_RESET_DEFAULT},
	{ADV739X_POWER_MODE_REG, ADV739X_POWER_MODE_REG_DEFAULT},

	{ADV739X_HD_MODE_REG1, ADV739X_HD_MODE_REG1_DEFAULT},
	{ADV739X_HD_MODE_REG2, ADV739X_HD_MODE_REG2_DEFAULT},
	{ADV739X_HD_MODE_REG3, ADV739X_HD_MODE_REG3_DEFAULT},
	{ADV739X_HD_MODE_REG4, ADV739X_HD_MODE_REG4_DEFAULT},
	{ADV739X_HD_MODE_REG5, ADV739X_HD_MODE_REG5_DEFAULT},
	{ADV739X_HD_MODE_REG6, ADV739X_HD_MODE_REG6_DEFAULT},
	{ADV739X_HD_MODE_REG7, ADV739X_HD_MODE_REG7_DEFAULT},

	{ADV739X_SD_MODE_REG1, ADV7391_SD_MODE_REG1_DEFAULT},
	{ADV739X_SD_MODE_REG2, ADV7391_SD_MODE_REG2_DEFAULT},
	{ADV739X_SD_MODE_REG3, ADV7391_SD_MODE_REG3_DEFAULT},
	{ADV739X_SD_MODE_REG4, ADV7391_SD_MODE_REG4_DEFAULT},
	{ADV739X_SD_MODE_REG5, ADV7391_SD_MODE_REG5_DEFAULT},
	{ADV739X_SD_MODE_REG6, ADV7391_SD_MODE_REG6_DEFAULT},
	{ADV739X_SD_MODE_REG7, ADV7391_SD_MODE_REG7_DEFAULT},
	{ADV739X_SD_MODE_REG8, ADV7391_SD_MODE_REG8_DEFAULT},

	{ADV739X_SD_TIMING_REG0, ADV7391_SD_TIMING_REG0_DEFAULT},

	{ADV739X_SD_HUE_ADJUST, ADV739X_SD_HUE_ADJUST_DEFAULT},
	{ADV739X_SD_CGMS_WSS0, ADV739X_SD_CGMS_WSS0_DEFAULT},
	{ADV739X_SD_BRIGHTNESS_WSS, ADV739X_SD_BRIGHTNESS_WSS_DEFAULT},
};

static const struct adv739x_reg_val adv7391_init_reg_val[] = {
	{ADV739X_SOFT_RESET, ADV739X_SOFT_RESET_DEFAULT},
	{ADV739X_POWER_MODE_REG, ADV739X_POWER_MODE_REG_DEFAULT},

	{ADV739X_HD_MODE_REG1, ADV739X_HD_MODE_REG1_DEFAULT},
	{ADV739X_HD_MODE_REG2, ADV739X_HD_MODE_REG2_DEFAULT},
	{ADV739X_HD_MODE_REG3, ADV739X_HD_MODE_REG3_DEFAULT},
	{ADV739X_HD_MODE_REG4, ADV739X_HD_MODE_REG4_DEFAULT},
	{ADV739X_HD_MODE_REG5, ADV739X_HD_MODE_REG5_DEFAULT},
	{ADV739X_HD_MODE_REG6, ADV739X_HD_MODE_REG6_DEFAULT},
	{ADV739X_HD_MODE_REG7, ADV739X_HD_MODE_REG7_DEFAULT},

	{ADV739X_SD_MODE_REG1, ADV7391_SD_MODE_REG1_DEFAULT},
	{ADV739X_SD_MODE_REG2, ADV7391_SD_MODE_REG2_DEFAULT},
	{ADV739X_SD_MODE_REG3, ADV7391_SD_MODE_REG3_DEFAULT},
	{ADV739X_SD_MODE_REG4, ADV7391_SD_MODE_REG4_DEFAULT},
	{ADV739X_SD_MODE_REG5, ADV7391_SD_MODE_REG5_DEFAULT},
	{ADV739X_SD_MODE_REG6, ADV7391_SD_MODE_REG6_DEFAULT},
	{ADV739X_SD_MODE_REG7, ADV7391_SD_MODE_REG7_DEFAULT},
	{ADV739X_SD_MODE_REG8, ADV7391_SD_MODE_REG8_DEFAULT},

	{ADV739X_SD_TIMING_REG0, ADV7391_SD_TIMING_REG0_DEFAULT},

	{ADV739X_SD_HUE_ADJUST, ADV739X_SD_HUE_ADJUST_DEFAULT},
	{ADV739X_SD_CGMS_WSS0, ADV739X_SD_CGMS_WSS0_DEFAULT},
	{ADV739X_SD_BRIGHTNESS_WSS, ADV739X_SD_BRIGHTNESS_WSS_DEFAULT},
};

static const struct adv739x_reg_val adv7393_init_reg_val[] = {
	{ADV739X_SOFT_RESET, ADV739X_SOFT_RESET_DEFAULT},
	{ADV739X_POWER_MODE_REG, ADV739X_POWER_MODE_REG_DEFAULT},

	{ADV739X_HD_MODE_REG1, ADV739X_HD_MODE_REG1_DEFAULT},
	{ADV739X_HD_MODE_REG2, ADV739X_HD_MODE_REG2_DEFAULT},
	{ADV739X_HD_MODE_REG3, ADV739X_HD_MODE_REG3_DEFAULT},
	{ADV739X_HD_MODE_REG4, ADV739X_HD_MODE_REG4_DEFAULT},
	{ADV739X_HD_MODE_REG5, ADV739X_HD_MODE_REG5_DEFAULT},
	{ADV739X_HD_MODE_REG6, ADV739X_HD_MODE_REG6_DEFAULT},
	{ADV739X_HD_MODE_REG7, ADV739X_HD_MODE_REG7_DEFAULT},

	{ADV739X_SD_MODE_REG1, ADV7393_SD_MODE_REG1_DEFAULT},
	{ADV739X_SD_MODE_REG2, ADV7393_SD_MODE_REG2_DEFAULT},
	{ADV739X_SD_MODE_REG3, ADV7393_SD_MODE_REG3_DEFAULT},
	{ADV739X_SD_MODE_REG4, ADV7393_SD_MODE_REG4_DEFAULT},
	{ADV739X_SD_MODE_REG5, ADV7393_SD_MODE_REG5_DEFAULT},
	{ADV739X_SD_MODE_REG6, ADV7393_SD_MODE_REG6_DEFAULT},
	{ADV739X_SD_MODE_REG7, ADV7393_SD_MODE_REG7_DEFAULT},
	{ADV739X_SD_MODE_REG8, ADV7393_SD_MODE_REG8_DEFAULT},

	{ADV739X_SD_TIMING_REG0, ADV7393_SD_TIMING_REG0_DEFAULT},

	{ADV739X_SD_HUE_ADJUST, ADV739X_SD_HUE_ADJUST_DEFAULT},
	{ADV739X_SD_CGMS_WSS0, ADV739X_SD_CGMS_WSS0_DEFAULT},
	{ADV739X_SD_BRIGHTNESS_WSS, ADV739X_SD_BRIGHTNESS_WSS_DEFAULT},
};

enum adv739x_chips {
	ADV7390,
	ADV7391,
	ADV7393,

	ADV739X_COUNT			/* Last entry */
};

struct adv739x_info_type {
	enum adv739x_chips chip;
	const char *name;
	const struct adv739x_reg_val *init_reg_vals;
	unsigned int init_reg_val_count;
};

static const struct adv739x_info_type adv739x_info[ADV739X_COUNT] = {
	[ADV7390] = {
		.chip = ADV7390,
		.name = "ADV7390",
		.init_reg_vals = &adv7390_init_reg_val[0],
		.init_reg_val_count = ARRAY_SIZE(adv7390_init_reg_val),
	},
	[ADV7391] = {
		.chip = ADV7391,
		.name = "ADV7391",
		.init_reg_vals = &adv7391_init_reg_val[0],
		.init_reg_val_count = ARRAY_SIZE(adv7391_init_reg_val),
	},
	[ADV7393] = {
		.chip = ADV7393,
		.name = "ADV7393",
		.init_reg_vals = &adv7393_init_reg_val[0],
		.init_reg_val_count = ARRAY_SIZE(adv7393_init_reg_val),
	},
};

struct adv739x_state {
	struct v4l2_subdev sd;
	struct v4l2_ctrl_handler hdl;
	u8 reg00;
	u8 reg01;
	u8 reg02;
	u8 reg35;
	u8 reg80;
	u8 reg82;
	u32 output;
	v4l2_std_id std;
	const struct adv739x_info_type *devdata;
};

static inline struct adv739x_state *to_state(struct v4l2_subdev *sd)
{
	return container_of(sd, struct adv739x_state, sd);
}

static inline struct v4l2_subdev *to_sd(struct v4l2_ctrl *ctrl)
{
	return &container_of(ctrl->handler, struct adv739x_state, hdl)->sd;
}

static inline int adv739x_write(struct v4l2_subdev *sd, u8 reg, u8 value)
{
	struct i2c_client *client = v4l2_get_subdevdata(sd);

	return i2c_smbus_write_byte_data(client, reg, value);
}

/*
 * 			    2^32
 * FSC(reg) =  FSC (HZ) * --------
 *			  27000000
 */
static const struct adv739x_std_info stdinfo[] = {
	{
		/* FSC(Hz) = 4,433,618.75 Hz */
		SD_STD_NTSC, 705268427, V4L2_STD_NTSC_443,
	}, {
		/* FSC(Hz) = 3,579,545.45 Hz */
		SD_STD_NTSC, 569408542, V4L2_STD_NTSC,
	}, {
		/* FSC(Hz) = 3,575,611.00 Hz */
		SD_STD_PAL_M, 568782678, V4L2_STD_PAL_M,
	}, {
		/* FSC(Hz) = 3,582,056.00 Hz */
		SD_STD_PAL_N, 569807903, V4L2_STD_PAL_Nc,
	}, {
		/* FSC(Hz) = 4,433,618.75 Hz */
		SD_STD_PAL_N, 705268427, V4L2_STD_PAL_N,
	}, {
		/* FSC(Hz) = 4,433,618.75 Hz */
		SD_STD_PAL_M, 705268427, V4L2_STD_PAL_60,
	}, {
		/* FSC(Hz) = 4,433,618.75 Hz */
		SD_STD_PAL_BDGHI, 705268427, V4L2_STD_PAL,
	},
};

static int adv739x_setstd(struct v4l2_subdev *sd, v4l2_std_id std)
{
	struct adv739x_state *state = to_state(sd);
	const struct adv739x_std_info *std_info;
	int num_std;
	u8 reg;
	u32 val;
	int err = 0;
	int i;

	num_std = ARRAY_SIZE(stdinfo);

	for (i = 0; i < num_std; i++) {
		if (stdinfo[i].stdid & std)
			break;
	}

	if (i == num_std) {
		v4l2_dbg(1, debug, sd,
				"Invalid std or std is not supported: %llx\n",
						(unsigned long long)std);
		return -EINVAL;
	}

	std_info = &stdinfo[i];

	/* Set the standard */
	val = state->reg80 & ~SD_STD_MASK;
	val |= std_info->standard_val3;
	err = adv739x_write(sd, ADV739X_SD_MODE_REG1, val);
	if (err < 0)
		goto setstd_exit;

	state->reg80 = val;

	/* Configure the input mode register */
	val = state->reg01 & ~INPUT_MODE_MASK;
	val |= SD_INPUT_MODE;
	err = adv739x_write(sd, ADV739X_MODE_SELECT_REG, val);
	if (err < 0)
		goto setstd_exit;

	state->reg01 = val;

	/* Program the sub carrier frequency registers */
	val = std_info->fsc_val;
	for (reg = ADV739X_FSC_REG0; reg <= ADV739X_FSC_REG3; reg++) {
		err = adv739x_write(sd, reg, val);
		if (err < 0)
			goto setstd_exit;
		val >>= 8;
	}

	val = state->reg82;

	/* Pedestal settings */
	if (std & (V4L2_STD_NTSC | V4L2_STD_NTSC_443))
		val |= SD_PEDESTAL_EN;
	else
		val &= SD_PEDESTAL_DI;

	err = adv739x_write(sd, ADV739X_SD_MODE_REG2, val);
	if (err < 0)
		goto setstd_exit;

	state->reg82 = val;

setstd_exit:
	if (err != 0)
		v4l2_err(sd, "Error setting std, write failed\n");

	return err;
}

static int adv739x_setoutput(struct v4l2_subdev *sd, u32 output_type)
{
	struct adv739x_state *state = to_state(sd);
	u8 val;
	int err = 0;

	if (output_type > ADV739X_SVIDEO_ID) {
		v4l2_dbg(1, debug, sd,
			"Invalid output type or output type not supported:%d\n",
								output_type);
		return -EINVAL;
	}

	/* Enable Appropriate DAC */
	val = state->reg00 & 0x03;

	if (output_type == ADV739X_COMPOSITE_ID)
		val |= ADV739X_COMPOSITE_POWER_VALUE;
	else if (output_type == ADV739X_COMPONENT_ID)
		val |= ADV739X_COMPONENT_POWER_VALUE;
	else
		val |= ADV739X_SVIDEO_POWER_VALUE;

	err = adv739x_write(sd, ADV739X_POWER_MODE_REG, val);
	if (err < 0)
		goto setoutput_exit;

	state->reg00 = val;

	/* Enable YUV output */
	val = state->reg02 | YUV_OUTPUT_SELECT;
	err = adv739x_write(sd, ADV739X_MODE_REG0, val);
	if (err < 0)
		goto setoutput_exit;

	state->reg02 = val;

	/* configure SD DAC Output 1 bit */
	val = state->reg82;
	if (output_type == ADV739X_COMPONENT_ID)
		val &= SD_DAC_OUT1_DI;
	else
		val |= SD_DAC_OUT1_EN;
	err = adv739x_write(sd, ADV739X_SD_MODE_REG2, val);
	if (err < 0)
		goto setoutput_exit;

	state->reg82 = val;

	/* configure ED/HD Color DAC Swap bit to zero */
	val = state->reg35 & HD_DAC_SWAP_DI;
	err = adv739x_write(sd, ADV739X_HD_MODE_REG6, val);
	if (err < 0)
		goto setoutput_exit;

	state->reg35 = val;

setoutput_exit:
	if (err != 0)
		v4l2_err(sd, "Error setting output, write failed\n");

	return err;
}

static int adv739x_log_status(struct v4l2_subdev *sd)
{
	struct adv739x_state *state = to_state(sd);

	v4l2_info(sd, "Standard: %llx\n", (unsigned long long)state->std);
	v4l2_info(sd, "Output: %s\n", (state->output == 0) ? "Composite" :
			((state->output == 1) ? "Component" : "S-Video"));
	return 0;
}

static int adv739x_s_ctrl(struct v4l2_ctrl *ctrl)
{
	struct v4l2_subdev *sd = to_sd(ctrl);

	switch (ctrl->id) {
	case V4L2_CID_BRIGHTNESS:
		return adv739x_write(sd, ADV739X_SD_BRIGHTNESS_WSS,
					ctrl->val & SD_BRIGHTNESS_VALUE_MASK);

	case V4L2_CID_HUE:
		return adv739x_write(sd, ADV739X_SD_HUE_ADJUST,
					ctrl->val - ADV739X_HUE_MIN);

	case V4L2_CID_GAIN:
		return adv739x_write(sd, ADV739X_DAC123_OUTPUT_LEVEL,
					ctrl->val);
	}
	return -EINVAL;
}

static const struct v4l2_ctrl_ops adv739x_ctrl_ops = {
	.s_ctrl = adv739x_s_ctrl,
};

static const struct v4l2_subdev_core_ops adv739x_core_ops = {
	.log_status = adv739x_log_status,
};

static int adv739x_s_std_output(struct v4l2_subdev *sd, v4l2_std_id std)
{
	struct adv739x_state *state = to_state(sd);
	int err = 0;

	if (state->std == std)
		return 0;

	err = adv739x_setstd(sd, std);
	if (!err)
		state->std = std;

	return err;
}

static int adv739x_s_routing(struct v4l2_subdev *sd,
		u32 input, u32 output, u32 config)
{
	struct adv739x_state *state = to_state(sd);
	int err = 0;

	if (state->output == output)
		return 0;

	err = adv739x_setoutput(sd, output);
	if (!err)
		state->output = output;

	return err;
}

static const struct v4l2_subdev_video_ops adv739x_video_ops = {
	.s_std_output	= adv739x_s_std_output,
	.s_routing	= adv739x_s_routing,
};

static const struct v4l2_subdev_ops adv739x_ops = {
	.core	= &adv739x_core_ops,
	.video	= &adv739x_video_ops,
};

static int adv739x_initialize(struct v4l2_subdev *sd)
{
	struct adv739x_state *state = to_state(sd);
	int err = 0;
	int i;
	const struct adv739x_reg_val *regval;

	regval = state->devdata->init_reg_vals;
	for (i = 0; i < state->devdata->init_reg_val_count; i++) {
		err = adv739x_write(sd, regval[i].reg, regval[i].val);
		if (err) {
			v4l2_err(sd, "Error initializing\n");
			return err;
		}
	}

	/* Configure for default video standard */
	err = adv739x_setoutput(sd, state->output);
	if (err < 0) {
		v4l2_err(sd, "Error setting output during init\n");
		return -EINVAL;
	}

	err = adv739x_setstd(sd, state->std);
	if (err < 0) {
		v4l2_err(sd, "Error setting std during init\n");
		return -EINVAL;
	}

	return err;
}


static const struct i2c_device_id adv739x_id[] = {
	{"adv739x", 0},
	{},
};

static const struct of_device_id adv739x_id_table[] = {
	{
		.compatible = "adi,adv7390",
		.data = &adv739x_info[ADV7390],
	}, {
		.compatible = "adi,adv7391",
		.data = &adv739x_info[ADV7391],
	}, {
		.compatible = "adi,adv7393",
		.data = &adv739x_info[ADV7393],
	}, { /* sentinel */ }
};
MODULE_DEVICE_TABLE(i2c, adv739x_id_table);

static int adv739x_parse_dt(struct adv739x_state *state)
{
	/*
	 * This function can be used to read parameters from the device tree
	 * node, e.g. whether to start in NTSC or PAL mode.
	 */

	return 0;
}

static int adv739x_probe(struct i2c_client *client,
				const struct i2c_device_id *id)
{
	struct adv739x_state *state;
	int err;
	const struct of_device_id *of_id;
	struct device *dev = &client->dev;
	struct gpio_desc *reset_gpio;
	reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
	if (IS_ERR(reset_gpio))
		dev_warn(dev, "Failed to get reset-gpios\n");
	else {
		dev_info(dev, "Reset\n");
		gpiod_set_value_cansleep(reset_gpio, 0);
		usleep_range(1000, 1500);
		gpiod_set_value_cansleep(reset_gpio, 1);
	}

	if (!i2c_check_functionality(client->adapter, I2C_FUNC_SMBUS_BYTE_DATA))
		return -EIO;

	state = devm_kzalloc(&client->dev, sizeof(*state), GFP_KERNEL);
	if (state == NULL)
		return -ENOMEM;

	if (IS_ENABLED(CONFIG_OF) && client->dev.of_node) {
		of_id = of_match_node(adv739x_id_table, client->dev.of_node);
		err = adv739x_parse_dt(state);
		if (err < 0) {
			v4l_err(client, "DT parsing error\n");
			return err;
		}
		state->devdata = of_id->data;
	} else
		state->devdata = &adv739x_info[ADV7393];
		

	v4l_info(client, "detecting %s @ 0x%x (%s)\n", state->devdata->name,
		 client->addr << 1, client->adapter->name);

	state->reg00	= ADV739X_POWER_MODE_REG_DEFAULT;
	state->reg01	= 0x00;
	state->reg02	= 0x20;
	state->reg35	= ADV739X_HD_MODE_REG6_DEFAULT;

	if (state->devdata->chip == ADV7390) {
		state->reg80	= ADV7390_SD_MODE_REG1_DEFAULT;
		state->reg82	= ADV7390_SD_MODE_REG2_DEFAULT;
		state->output = ADV739X_COMPOSITE_ID;
		state->std = V4L2_STD_NTSC;
	} else if (state->devdata->chip == ADV7391) {
		state->reg80	= ADV7391_SD_MODE_REG1_DEFAULT;
		state->reg82	= ADV7391_SD_MODE_REG2_DEFAULT;
		state->output = ADV739X_COMPOSITE_ID;
		state->std = V4L2_STD_PAL;
	} else {
		state->reg80	= ADV7393_SD_MODE_REG1_DEFAULT;
		state->reg82	= ADV7393_SD_MODE_REG2_DEFAULT;
		state->output = ADV739X_COMPOSITE_ID;
		state->std = V4L2_STD_PAL;
	}

	v4l2_i2c_subdev_init(&state->sd, client, &adv739x_ops);

	v4l2_ctrl_handler_init(&state->hdl, 3);
	v4l2_ctrl_new_std(&state->hdl, &adv739x_ctrl_ops,
			V4L2_CID_BRIGHTNESS, ADV739X_BRIGHTNESS_MIN,
					     ADV739X_BRIGHTNESS_MAX, 1,
					     ADV739X_BRIGHTNESS_DEF);
	v4l2_ctrl_new_std(&state->hdl, &adv739x_ctrl_ops,
			V4L2_CID_HUE, ADV739X_HUE_MIN,
				      ADV739X_HUE_MAX, 1,
				      ADV739X_HUE_DEF);
	v4l2_ctrl_new_std(&state->hdl, &adv739x_ctrl_ops,
			V4L2_CID_GAIN, ADV739X_GAIN_MIN,
				       ADV739X_GAIN_MAX, 1,
				       ADV739X_GAIN_DEF);
	state->sd.ctrl_handler = &state->hdl;
	if (state->hdl.error) {
		int err = state->hdl.error;

		v4l2_ctrl_handler_free(&state->hdl);
		return err;
	}
	v4l2_ctrl_handler_setup(&state->hdl);

	err = adv739x_initialize(&state->sd);
	if (err)
		v4l2_ctrl_handler_free(&state->hdl);
	return err;
}

static int adv739x_remove(struct i2c_client *client)
{
	struct v4l2_subdev *sd = i2c_get_clientdata(client);
	struct adv739x_state *state = to_state(sd);

	v4l2_device_unregister_subdev(sd);
	v4l2_ctrl_handler_free(&state->hdl);

	return 0;
}
static struct i2c_driver adv739x_driver = {
	.driver = {
		.owner	= THIS_MODULE,
		.name	= "adv739x",
		.of_match_table = adv739x_id_table,
	},
	.probe		= adv739x_probe,
	.remove		= adv739x_remove,
	.id_table	= adv739x_id,
};
module_i2c_driver(adv739x_driver);
