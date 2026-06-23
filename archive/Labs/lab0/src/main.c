#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/devicetree.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>

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
            //dont let it goto if statement again for next 100ms
            while(count < 10)
            {
                count++;
                if(gpio_pin_get_dt((const struct gpio_dt_spec*)press) > 0)
                {
                    count = 0;
                }
                k_msleep(10);
            }
            count = 0;
        }
        k_msleep(1);
    }
}

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
