#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/logging/log.h>

#include <zephyr/drivers/i2c.h>
#include <zephyr/net/net_if.h>/*includes #include <zephyr/net/net_ip.h> for net_addr_ntop*/
#include <zephyr/net/http/server.h>/*for http_server_start()*/
#include <zephyr/net/http/service.h>/*HTTP_SERVICE_DEFINE and HTTP_RESOURCE_DEFINE*/
#include <zephyr/sys/atomic.h>

#include <stdlib.h>

LOG_MODULE_REGISTER(app, LOG_LEVEL_INF);

/* register "Accept" header to be captured */
/*"Accept" is a request header sent from browser to MCU letting it know it expects text/plain kind of response */
HTTP_SERVER_REGISTER_HEADER_CAPTURE(capture_accept, "Accept");

struct my_i2c_device_config {
 struct i2c_dt_spec i2c_dev;
 uint8_t temp_reg;
};

struct my_http_temp_config {
 const struct device *temp_dev;
 uint16_t port;
 uint8_t concurrent;
 uint8_t backlog;
};

static const struct my_i2c_device_config my_i2c_device_config_var = {
  .i2c_dev = {.bus = DEVICE_DT_GET(DT_ALIAS(sercom3)), .addr = DT_REG_ADDR(DT_NODELABEL(mytemp0))},
  .temp_reg = DT_PROP(DT_NODELABEL(mytemp0),temp_reg)
};

static const struct my_http_temp_config my_http_temp_config_var = {                            
 .port = DT_PROP(DT_NODELABEL(my_http0), port),                                                
 .concurrent = DT_PROP(DT_NODELABEL(my_http0), concurrent),                              
 .backlog = DT_PROP(DT_NODELABEL(my_http0), backlog),                                  
}; 

static const uint8_t welcome_html[] =
 "<!DOCTYPE html>\n"
 "<html><body>\n"
 "<h2>Welcome to Temperature monitor app</h2>\n"
 "</body></html>\n";

/**
 * Below array(temp_page_html) is stored in fimrware as text
 * When browser sends HTTP request(http://192.168.1.107:8080/temp) 
 * to board it gets back this array. Browser runs this below HTML text on the web page.
 * Current Temperature
 * Loading...
 * 
 * It then runs a Java Script b/w <script> </script>
 * fetch('/temp' - Tells browser to make an HTTP request to the board
 * the board sends http response body in a TCP packet over ethernet to browser
 * { headers: { 'Accept': 'text/plain' } }) - browser expects a temperature response in plain text
 * r=>r.text() - take http response body(the temperature text) from board and convert it into a string
 * t=>{document.getElementById('temp') --> put this temperature string on the web page,replace
 * "Loading..." with this temperature string, in here, <div id='temp'>Loading...</div>
 * SO "fetch('/temp'"(temp resource) basically calls temp_handler() function every 1 second to give
 * live temperature
 */
static const uint8_t temp_page_html[] =
 "<!DOCTYPE html>\n"
 "<html><head><title>Temperature Monitor</title>\n"
 "<script>\n"
 "function updateTemp(){\n"
 "  fetch('/temp', { headers: { 'Accept': 'text/plain' } })\n"
 "    .then(r=>r.text())\n"
 "    .then(t=>{document.getElementById('temp').textContent=t;});\n"
 "}\n"
 "setInterval(updateTemp,1000);\n"
 "window.onload=updateTemp;\n"
 "</script>\n"
 "</head><body>\n"
 "<h1>Current Temperature</h1>\n"
 "<div id='temp'>Loading...</div>\n"
 "</body></html>\n";

int16_t get_temp(uint8_t *buf)
{
 uint16_t raw = (int16_t)((buf[0] << 8) | (buf[1]));
 raw = raw/128;
 int16_t hundred_c = raw*50;
 int16_t hundred_f = (hundred_c * 9)/5 + 3200;
 return hundred_f/100;
}

static bool wants_plain(const struct http_client_ctx *client)
{
#if defined(CONFIG_HTTP_SERVER_CAPTURE_HEADERS)
 const struct http_header *hdrs = client->header_capture_ctx.headers;
 size_t n = client->header_capture_ctx.count;

 for (size_t i = 0; i < n; i++) {
  if (hdrs[i].name && hdrs[i].value && strcmp(hdrs[i].name, "Accept") == 0) {
   return (strstr(hdrs[i].value, "text/plain") != NULL);
  }
 }
#endif
 return false;
}

/**
 * In current design, /temp returns:
 * fixed HTML page (when browser loads /temp)
 * then temperature value in plain text (when JS fetch asks for Accept: text/plain) every 1 second
 */
static int temp_handler(struct http_client_ctx *client, enum http_transaction_status status,
   const struct http_request_ctx *request_ctx,
   struct http_response_ctx *response_ctx, void *user_data)
{
 char temperature_buf[24];
 uint8_t buf[2];

 ARG_UNUSED(request_ctx);
 if(wants_plain(client) == false)
 {
  response_ctx->status = 200;
  response_ctx->body = temp_page_html;
  response_ctx->body_len = sizeof(temp_page_html) - 1;
  response_ctx->final_chunk = true;
  return 0;
 }
 else{
  if (status == HTTP_SERVER_REQUEST_DATA_FINAL) {
  int ret = i2c_write_read_dt(&(my_i2c_device_config_var.i2c_dev),&(my_i2c_device_config_var.temp_reg),sizeof(my_i2c_device_config_var.temp_reg),buf,sizeof(buf)/sizeof(buf[0]));
  if (ret) {
   static const char err[] = "temp read error\n";
   response_ctx->status = 500;
   response_ctx->body = err;
   response_ctx->body_len = sizeof(err) - 1;
   response_ctx->final_chunk = true;
   return 0;
  }

  snprintk(temperature_buf, sizeof(temperature_buf), "%d F\n", get_temp(buf));

  response_ctx->status = 200;
  response_ctx->body = (const uint8_t *)temperature_buf;
  response_ctx->body_len = strlen(temperature_buf);
  response_ctx->final_chunk = true;
  }
  else{
   return 0;
  }
 }
 return 0;
}

/**
 *  Big picture
 * A service is made at build time by HTTP_SERVICE_DEFINE
 * When application starts, Zephyr HTTP server service starts running in main.c.
 * Use the running HTTP server service "my_http_svc_0" with either resource "/" or resource "/temp" when browser does either:
 * http://192.168.1.107:8080/
 * OR
 * http://192.168.1.107:8080/temp)
 * HTTP_SERVICE_DEFINE = “open a restaurant (port, concurrency, backlog)”
 * HTTP_RESOURCE_DEFINE = “add a menu item (URL path)”
 * STATIC resource = “serve a pre-made dish (fixed bytes)”
 * DYNAMIC resource = “cook it fresh each time (callback function)”
 * user_data = “kitchen ticket that says which branch/location this order is for (which device instance)”
 */
static uint16_t http_service_port = DT_PROP(DT_NODELABEL(my_http0), port);                              
HTTP_SERVICE_DEFINE(my_http_svc_0, "0.0.0.0", &http_service_port,                      
   DT_PROP(DT_NODELABEL(my_http0), concurrent),                                      
   DT_PROP(DT_NODELABEL(my_http0), backlog),                                         
   NULL, NULL, NULL);                                                        
                        
static struct http_resource_detail_static my_static_resource_detail = {                           
 .common = {                                                                          
  .type = HTTP_RESOURCE_TYPE_STATIC,                                           
  .bitmask_of_supported_http_methods = BIT(HTTP_GET),                          
  .content_type = "text/html",                                                
 },                                                                                  
 .static_data = welcome_html,                                                         
 .static_data_len = sizeof(welcome_html) - 1,                                         
};                                                                                         
HTTP_RESOURCE_DEFINE(my_static_resource, my_http_svc_0, "/", &my_static_resource_detail);     
                        
static struct http_resource_detail_dynamic my_temperature_resource_detail = {                           
 .common = {                                                                          
  .type = HTTP_RESOURCE_TYPE_DYNAMIC,                                          
  .bitmask_of_supported_http_methods = BIT(HTTP_GET),                          
  .content_type = "text/html",                                               
 },                                                                                  
 .cb = temp_handler,                                                                 
 .user_data = NULL,//(void *)DEVICE_DT_GET(DT_NODELABEL(my_http0)),                                     
};                                                                                         
HTTP_RESOURCE_DEFINE(my_temperature_resource, my_http_svc_0, "/temp", &my_temperature_resource_detail);   

#define USER_STACK_SIZE 1024
K_THREAD_STACK_DEFINE(user_stack,USER_STACK_SIZE);

/* One global HTTP server for all services/resources */
static atomic_t server_users;

int main(void)
{
 char addr_str[NET_IPV4_ADDR_LEN];
                                               
 uint8_t buf[2];
 int ret = -1;

//Sub-Step 1(lab 3)
/*Bring ethernet interface up*/
struct net_if *eth_interface = net_if_get_default();
if(eth_interface == NULL)
{
  LOG_ERR("Failed to bring up ethernet interface");
}
else{
  LOG_INF("Ethernet interface is up");
}

//Sub-Step 2(lab 3)
/*Print Board`s IP address*/
struct in_addr *addr = net_if_ipv4_get_global_addr(eth_interface, NET_ADDR_PREFERRED);
 if (!addr) {
  LOG_WRN("No IPv4 address yet");
  return -EAGAIN;
 }

net_addr_ntop(AF_INET, addr, addr_str, sizeof(addr_str));
LOG_INF("IPv4 addr: %s", addr_str);

//Sub-Step 3(lab 3)
/*Start HTTP server*/
 int old = atomic_inc(&server_users);                                              
 if (old == 0) {        
  /*The server runs in a background thread. Once started, the server will create
  * a server socket for all HTTP services registered in the system and accept
  * connections from clients*/                                                           
  ret = http_server_start();                                            
  if (ret) {                                                                
   (void)atomic_dec(&server_users);                                   
   return ret;                                                        
  }                                                                          
 }                                                                                                                                            
 LOG_INF("HTTP temp service started on port %u", my_http_temp_config_var.port);

//Sub-Step 4(lab 3)
 while(1)
 {
  ret = i2c_write_read_dt(&(my_i2c_device_config_var.i2c_dev),&(my_i2c_device_config_var.temp_reg),sizeof(my_i2c_device_config_var.temp_reg),buf,sizeof(buf)/sizeof(buf[0]));
  if(ret)
  {
  LOG_ERR("I2C write read failed!,Ensure extension is connected");
  continue;
  }

  LOG_INF("Temp: %d F",get_temp(buf));
  k_sleep(K_SECONDS(1));
 }
}
