#ifndef MY_LED_DRIVER_H_
#define MY_LED_DRIVER_H_

#include <zephyr/device.h>
#include <zephyr/syscall.h>

#ifdef __cplusplus
extern "C" {
#endif

//Sub-Step 1
typedef struct{
    uintptr_t port_base;
    uint8_t pin;
}my_led_config_t;

typedef struct {
    struct k_mutex lock;
} my_led_data_t;

//Sub-Step 2
__subsystem struct my_led_driver_api { //"my_led" is the subsystem whose drivers will be impemented.
    int (*on)(const struct device *dev);
    int (*off)(const struct device *dev);
    int (*toggle)(const struct device *dev);
    int (*get_val)(const struct device *dev);
};

//Sub-Step 3
// Inline wrapper/Subsytem wrapper: This is what the application actually calls
static inline int my_led_on(const struct device *dev)
{
    return DEVICE_API_GET(my_led, dev)->on(dev);
    // This fetches the API struct from the device instance at runtime
    // Conceptually similar to: ((const struct my_led_driver_api *)dev->api)->on(dev);
}

static inline int my_led_off(const struct device *dev)
{
    // This fetches the API struct from the device instance at runtime
    return DEVICE_API_GET(my_led, dev)->off(dev);
}

static inline int my_led_toggle(const struct device *dev)
{
    // This fetches the API struct from the device instance at runtime
    return DEVICE_API_GET(my_led, dev)->toggle(dev);
}

static inline int my_led_val(const struct device* dev)
{
    return DEVICE_API_GET(my_led, dev)->get_val(dev);
}

/**********LAB 2***********/
//Sub-Step 1(lab 2)
/* ---- Device-specific API extensions ---- */

/* Supervisor-only extension (callable from kernel/supervisor threads) */
int my_led_blink(const struct device *dev, uint32_t times, uint32_t delay_ms);

//Sub-Step 2(lab 2)
/*
 * User-mode callable extension:
 * - When CONFIG_USERSPACE=y, expose it as a syscall.
 * - When CONFIG_USERSPACE=n, make it a simple inline wrapper so builds still work.
 */
__syscall int my_led_blink_user(const struct device *dev, uint32_t times, uint32_t delay_ms);


#ifdef CONFIG_USERSPACE
/* Pulls in the generated syscall stubs (created by Zephyr build) */
#include <zephyr/syscalls/my_led_driver.h>
#else
static inline int my_led_blink_user(const struct device *dev, uint32_t times, uint32_t delay_ms)
{
    return my_led_blink(dev, times, delay_ms);
}
#endif
/**********LAB 2***********/

#ifdef __cplusplus
}
#endif

#endif /* MY_LED_DRIVER_H_ */

