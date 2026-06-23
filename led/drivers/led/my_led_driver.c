#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/init.h>
#include <zephyr/sys/util.h>
#include <zephyr/devicetree.h>
#include <zephyr/logging/log.h>
#include "my_led_driver.h"

//Sub-Step 8(lab 1)
#define DT_DRV_COMPAT myvendor_mygpio_led

LOG_MODULE_REGISTER(myvendor_mygpio_led, LOG_LEVEL_DBG);


#warning "Compiling my_led_driver.c"

#define REG(dir,offset) *((volatile uint32_t*)(dir + offset))

#define PORT_DIRSET_OFFSET   0x08
#define PORT_DATA_OUT_OFFSET 0x10
#define PORT_OUTSET_OFFSET   0x18
#define PORT_OUTCLR_OFFSET   0x14
#define PORT_OUTTGL_OFFSET   0x1C

static const struct my_led_driver_api my_led_api_funcs;

//Sub-Step 4(lab 1)
static int my_led_on_impl(const struct device *dev)
{
     const my_led_config_t *cfg = dev->config;
    my_led_data_t *data = dev->data;
 
    k_mutex_lock(&data->lock,K_FOREVER);
    REG(cfg->port_base, PORT_OUTCLR_OFFSET) = BIT(cfg->pin);
    k_mutex_unlock(&data->lock);
 
    return 0;
}

//Sub-Step 5(lab 1)
static int my_led_off_impl(const struct device *dev)
{
     const my_led_config_t *cfg = dev->config;
    my_led_data_t *data = dev->data;
 
    k_mutex_lock(&data->lock,K_FOREVER);
    REG(cfg->port_base, PORT_OUTSET_OFFSET) = BIT(cfg->pin);
    k_mutex_unlock(&data->lock);
 
    return 0;
}

//Sub-Step 6(lab 1)
static int my_led_toggle_impl(const struct device *dev)
{
     const my_led_config_t *cfg = dev->config;
    my_led_data_t *data = dev->data;
 
    k_mutex_lock(&data->lock,K_FOREVER);
    REG(cfg->port_base, PORT_OUTTGL_OFFSET) = BIT(cfg->pin);
    k_mutex_unlock(&data->lock);
 
    return 0;
}

//Sub-Step 7(lab 1)
static int my_led_get_val_impl(const struct device *dev)
{
     const my_led_config_t *cfg = dev->config;
    my_led_data_t *data = dev->data;
 
    k_mutex_lock(&data->lock,K_FOREVER);
    if(REG(cfg->port_base,PORT_DATA_OUT_OFFSET) & BIT(cfg->pin))
    {
        k_mutex_unlock(&data->lock);
        return 1;
    }
    else
    {
        k_mutex_unlock(&data->lock);
        return 0;
    }
}

/**********LAB 2***********/
//Sub-Step 1(lab 2)
int my_led_blink(const struct device *dev, uint32_t times, uint32_t delay_ms)
{
    const my_led_config_t *cfg = dev->config;
    for (uint32_t i = 0; i < times; ++i) {
        REG(cfg->port_base, PORT_OUTTGL_OFFSET) = BIT(cfg->pin);        /* Toggle LED state */
        k_msleep(delay_ms);
    }
    LOG_INF("my_led_blink entered\n");
    return 0;
}

//Sub-Step 2(lab 2)
/* Actual implementation for the user-callable blink API */
int z_impl_my_led_blink_user(const struct device *dev, uint32_t times, uint32_t delay_ms)
{
    LOG_INF("z_impl_my_led_blink_user entered\n");
    /* Just call the core blink function */
    return my_led_blink(dev, times, delay_ms);
}

//Sub-Step 3(lab 2)
#ifdef CONFIG_USERSPACE
#include <zephyr/kernel.h>         /* For K_OOPS macro */
#include <zephyr/internal/syscall_handler.h>

int z_vrfy_my_led_blink_user(const struct device *dev, uint32_t times, uint32_t delay_ms)
{
    /* This macro checks at runtime that 
    1- dev is a pointer to a device object whose API pointer
     matches my_led_api_funcs (our driver’s API struct),
    2- and that the device is initialized */
    K_OOPS(K_SYSCALL_SPECIFIC_DRIVER(dev, K_OBJ_DRIVER_MY_LED, &my_led_api_funcs));
    /* (K_OBJ_DRIVER_MY_LED is used since this is a custom driver subsystem) */
    
    LOG_INF("z_vrfy_my_led_blink_user: verify entered\n");
    /* If validation passes, call the actual implementation */
    return z_impl_my_led_blink_user(dev, times, delay_ms);
}
/* Generate the marshalling code for the syscall */
#include <zephyr/syscalls/my_led_blink_user_mrsh.c>
#endif /* CONFIG_USERSPACE */
/**********LAB 2***********/



//Sub-Step 3(lab 1)
static DEVICE_API(my_led,my_led_api_funcs) = { //"my_led" is the subsystem
    .on = my_led_on_impl,
    .off = my_led_off_impl,
    .toggle = my_led_toggle_impl,
    .get_val = my_led_get_val_impl,
};

//Sub-Step 2(lab 1)
static int my_led_init(const struct device *dev)
{
    const my_led_config_t *cfg = dev->config;
    my_led_data_t *data = dev->data;
    
    //initialize the mutex
    k_mutex_init(&data->lock);

    // Set pin as output
    REG(cfg->port_base, PORT_DIRSET_OFFSET) = BIT(cfg->pin);
    // Turn OFF LED initially, OUTSET set, LED OFF, since LED active-low
    REG(cfg->port_base, PORT_OUTSET_OFFSET) = BIT(cfg->pin);
    return 0;
}

/*
 * MY_LED_DEVICE(inst)
 *
 * This macro creates one complete Zephyr device instance for each enabled
 * Devicetree node that matches this driver.
 *
 * DT_INST_FOREACH_STATUS_OKAY(MY_LED_DEVICE) calls this macro once for every
 * Devicetree instance whose:
 *
 *     compatible = "myvendor,mygpio-led";
 *     status = "okay";
 *
 * For each instance, this macro creates:
 *
 * 1. Runtime data object:
 *
 *        my_led_data_t my_led_data_<inst>;
 *
 *    This stores runtime information for the device, such as the mutex used
 *    to protect register access.
 *
 * 2. Configuration object:
 *
 *        static const my_led_config_t my_led_config_<inst>
 *
 *    This stores hardware-specific information from Devicetree:
 *
 *        port_base = base address from reg + port offset
 *        pin       = LED pin number
 *
 *    For example, if the Devicetree node has:
 *
 *        reg  = <0x41008000 ...>;
 *        port = <2>;
 *        pin  = <18>;
 *
 *    then:
 *
 *        port_base = 0x41008000 + (2 * 0x80)
 *        pin       = 18
 *
 * 3. Zephyr device object:
 *
 *        DEVICE_DT_INST_DEFINE(inst, ...)
 *
 *    This registers the device with Zephyr and connects it to:
 *
 *        init function  -> my_led_init
 *        runtime data   -> &my_led_data_<inst>
 *        config data    -> &my_led_config_<inst>
 *        API functions  -> &my_led_api_funcs
 *
 * During system boot, Zephyr calls my_led_init() for this device.
 * my_led_init() initializes the mutex, configures the pin as output,
 * and turns the active-low LED off initially.
 *
 * The exact generated symbol names are internal Zephyr details and should
 * not be used directly by application code.
 */



/* 
 * Normally,Zephyr automatically links the driver’s code to the app because the build system sees the instance
 * present in the Devicetree(overlay file) has status = "okay"
 * what we put in -b argument of west build so that , the node in it its compatible string is matched with the
 * DT_DRV_COMPAT string in the driver source file and then implementation in that driver source file is called
*/


//Sub-Step 1(lab 1)
#define MY_LED_DEVICE(inst) \
    my_led_data_t my_led_data_##inst; \
    static const my_led_config_t my_led_config_##inst = { \
        .port_base = DT_REG_ADDR(DT_INST(inst, myvendor_mygpio_led)) +    \
                     DT_PROP(DT_INST(inst,myvendor_mygpio_led),port)*0x80, \
        .pin = DT_PROP(DT_INST(inst, myvendor_mygpio_led), pin), \
    }; \
    DEVICE_DT_INST_DEFINE(inst, \
        my_led_init, \
        NULL, \
        &my_led_data_##inst, \
        &my_led_config_##inst, \
        POST_KERNEL, \
        CONFIG_KERNEL_INIT_PRIORITY_DEFAULT, \
        &my_led_api_funcs);

DT_INST_FOREACH_STATUS_OKAY(MY_LED_DEVICE)
#warning "Expanding MY_LED_DEVICE macro..."