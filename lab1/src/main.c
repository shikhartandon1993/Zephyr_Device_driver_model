#include <zephyr/kernel.h> /*for k_msleep()*/
#include <zephyr/device.h> /*for struct device, DEVICE_DT_GET()*/
#include <zephyr/devicetree.h> /* for DT_NODELABEL() */
#include <zephyr/logging/log.h>
#include "my_led_driver.h"

LOG_MODULE_REGISTER(app,LOG_LEVEL_INF);

int main(void)
{
    //Sub-Step 1
    const struct device *led_dev = DEVICE_DT_GET(DT_NODELABEL(my_led0));
    if (!device_is_ready(led_dev)) {
        LOG_INF("LED device not ready\n");
        return -1;
    }

    //Sub-Step 2
    printk("After my_led_init\n");
    while (1) {
        my_led_on(led_dev);
        // my_led_off(led_dev);
        // my_led_toggle(led_dev);
        if(my_led_val(led_dev) == 0)
        {
            /* active low */
            printk("LED ON\n");
            printk("-----\n");
        }
        else
        {
            printk("LED OFF\n");
            printk("-----\n");
        }

        k_msleep(1000);
    }

    return 0;
}
