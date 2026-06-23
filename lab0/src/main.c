#include <zephyr/kernel.h> /*for k_msleep()*/
#include <zephyr/device.h> /*for struct device, DEVICE_DT_GET()*/
#include <zephyr/devicetree.h> /* for DT_NODELABEL() */
#include <zephyr/logging/log.h> /*For logging*/
#include <zephyr/drivers/gpio.h> /*for button at gpio*/

LOG_MODULE_REGISTER(app, LOG_LEVEL_INF);
#define STACK_SIZE 1024

struct k_thread new_thread;
K_THREAD_STACK_DEFINE(new_stack,STACK_SIZE);
volatile bool pressed  = false;
const struct gpio_dt_spec press = GPIO_DT_SPEC_GET(DT_ALIAS(button0),gpios);

void entry_fn(void *press,void *arg2,void *arg3)
{
    static uint8_t count = 0;
    while(1)
    {
        if((gpio_pin_get_dt((const struct gpio_dt_spec*)press) > 0) && (count == 0))
        {
            pressed = true;
            //dont let it goto if statement again for next 100us
            while(count < 10)
            {
                count++;
                if(gpio_pin_get_dt((const struct gpio_dt_spec*)press) > 0)
                {
                    count = 0;
                }
                k_usleep(10);
            }
            count = 0;
        }
        k_msleep(1);
    }
}

// void callback_fn(const struct device *port,
// 					struct gpio_callback *cb,
// 					gpio_port_pins_t pins)
// {
//     pressed = true;
// }

// struct gpio_callback gpio_callback_var =
// {
//     .handler = callback_fn,
//     .pin_mask = 1 << 31
// };


int main(void)
{   
    LOG_INF("Started!");
    if(!(gpio_is_ready_dt(&press)))
    {
        LOG_ERR("Button init failed!");
    }
    printk("After button init\n");

    int ret = gpio_pin_configure_dt(&press,GPIO_INPUT | GPIO_PULL_UP);
    if(ret == 0)
    {
        LOG_INF("Button set as input");
    }
    else
    {
        LOG_INF("Button failed to be set as input");
    }

    // ret = gpio_pin_interrupt_configure_dt(&press,GPIO_INT_LEVEL_LOW);
    // LOG_INF("ret = %d",ret);
    // gpio_add_callback_dt(&press,&gpio_callback_var);
    k_tid_t t1 = k_thread_create(&new_thread,new_stack,K_THREAD_STACK_SIZEOF(new_stack),entry_fn,(void*)&press,NULL,NULL,2,K_USER,K_FOREVER);
    k_thread_start(t1);
    
    while (1) {
        if(pressed == true)
        {
            pressed = false;
            LOG_INF("Button is pressed!");
        }
        else{
            LOG_INF("Button is NOT PRESSED!");
        }

        k_msleep(500);
    }

    return 0;
}
