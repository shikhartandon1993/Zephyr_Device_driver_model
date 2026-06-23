#include <zephyr/kernel.h> /*for kernel calls like k_msleep()*/
#include <zephyr/device.h> /*for struct device, DEVICE_DT_GET()*/
#include <zephyr/devicetree.h> /* for DT_NODELABEL() */
#include <zephyr/logging/log.h> /*for LOG_() calls*/
#include "my_led_driver.h"

LOG_MODULE_REGISTER(app, LOG_LEVEL_INF);

#define USER_STACK_SIZE 1024
K_THREAD_STACK_DEFINE(user_stack,USER_STACK_SIZE);
static struct k_thread user_thread_data;

//Sub-Step 4(lab 2)
static void user_thread_fn(void *led_dev,void *b,void *c)
{
    ARG_UNUSED(b);
    ARG_UNUSED(c);

    //user call(will go thru syscall, then will be executed inside kernel by z_impl_my_led_blink_user)
    LOG_INF("User thread:");
    (void)my_led_blink_user((const struct device *)led_dev,10,500);

    LOG_INF("User thread: done\n");
    /*If you uncomment the below code it will give Data access violation 
    because you are calling a supervisor call from user thread*/
    // LOG_INF("User thread: Attempting supervisor-only API expected to have data access violation");
    // my_led_blink((struct device *)led_dev,3,200);
    // LOG_INF("If you see this something is wrong in the code!");
 while (1) {
  k_msleep(1000);
 }
}

int main(void)
{
    //Sub-Step 1(lab 2)
    const struct device *led_dev = DEVICE_DT_GET(DT_NODELABEL(my_led0));
    if (!device_is_ready(led_dev)) {
        LOG_INF("LED device not ready\n");
        return -1;
    }

    //Sub-Step 2(lab 2)
    LOG_INF("Supervisor thread:\n");
    my_led_blink(led_dev,3,200);

    //Sub-Step 3(lab 2)
    k_tid_t tid = k_thread_create(&user_thread_data,user_stack,K_THREAD_STACK_SIZEOF(user_stack),
                    user_thread_fn,(void*)led_dev,NULL,NULL,
                    2,K_USER,K_FOREVER);//wait for the thread to finish

    //(for device-specific API) k_object_access_grant() adds "led_dev" to the allowed kernel objects list for that user thread.
    k_object_access_grant(led_dev, &user_thread_data);

    k_thread_start(tid);

    LOG_INF("After my_led_init\n");
    while (1) {
        k_msleep(1000);
    }

    return 0;
}
