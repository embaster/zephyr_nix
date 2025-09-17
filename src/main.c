#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/display.h>
#include <zephyr/logging/log.h>
#include <string.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

/* Display dimensions - match your overlay */
#define DISPLAY_WIDTH  172
#define DISPLAY_HEIGHT 320

/* RGB565 color definitions */
#define RGB565_RED     0xF800
#define RGB565_GREEN   0x07E0
#define RGB565_BLUE    0x001F
#define RGB565_WHITE   0xFFFF
#define RGB565_BLACK   0x0000
#define RGB565_YELLOW  0xFFE0
#define RGB565_CYAN    0x07FF
#define RGB565_MAGENTA 0xF81F

/* Small buffer for drawing operations - keep it small to avoid stack overflow */
#define BUFFER_SIZE 1024  /* 512 pixels * 2 bytes per pixel */

static uint16_t display_buffer[BUFFER_SIZE / 2];

/* Function to fill a rectangular area with a solid color */
static int fill_rect(const struct device *display, uint16_t x, uint16_t y, 
                     uint16_t width, uint16_t height, uint16_t color)
{
    struct display_buffer_descriptor desc;
    int ret;
    
    /* Fill our buffer with the color */
    for (int i = 0; i < ARRAY_SIZE(display_buffer); i++) {
        display_buffer[i] = color;
    }
    
    desc.buf_size = BUFFER_SIZE;
    desc.width = MIN(width, ARRAY_SIZE(display_buffer));
    desc.height = 1;
    desc.pitch = desc.width;
    
    /* Draw line by line to stay within buffer limits */
    for (uint16_t row = 0; row < height; row++) {
        uint16_t current_y = y + row;
        uint16_t remaining_width = width;
        uint16_t current_x = x;
        
        while (remaining_width > 0) {
            uint16_t chunk_width = MIN(remaining_width, desc.width);
            desc.width = chunk_width;
            desc.pitch = chunk_width;
            
            ret = display_write(display, current_x, current_y, &desc, display_buffer);
            if (ret < 0) {
                LOG_ERR("Failed to write to display: %d", ret);
                return ret;
            }
            
            remaining_width -= chunk_width;
            current_x += chunk_width;
        }
    }
    
    return 0;
}

/* Function to draw a simple pattern */
static int draw_pattern(const struct device *display)
{
    int ret;
    
    LOG_INF("Drawing test pattern...");
    
    /* Clear screen with black */
    ret = fill_rect(display, 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, RGB565_BLACK);
    if (ret < 0) {
        return ret;
    }
    
    /* Draw colored rectangles */
    ret = fill_rect(display, 10, 10, 50, 50, RGB565_RED);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 70, 10, 50, 50, RGB565_GREEN);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 130, 10, 30, 50, RGB565_BLUE);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 10, 70, 150, 30, RGB565_YELLOW);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 10, 110, 150, 30, RGB565_CYAN);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 10, 150, 150, 30, RGB565_MAGENTA);
    if (ret < 0) return ret;
    
    /* Draw a border around the screen */
    ret = fill_rect(display, 0, 0, DISPLAY_WIDTH, 2, RGB565_WHITE);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 0, DISPLAY_HEIGHT-2, DISPLAY_WIDTH, 2, RGB565_WHITE);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, 0, 0, 2, DISPLAY_HEIGHT, RGB565_WHITE);
    if (ret < 0) return ret;
    
    ret = fill_rect(display, DISPLAY_WIDTH-2, 0, 2, DISPLAY_HEIGHT, RGB565_WHITE);
    if (ret < 0) return ret;
    
    return 0;
}

/* Function to animate colors */
static int animate_colors(const struct device *display)
{
    uint16_t colors[] = {
        RGB565_RED, RGB565_GREEN, RGB565_BLUE,
        RGB565_YELLOW, RGB565_CYAN, RGB565_MAGENTA,
        RGB565_WHITE
    };
    
    const char* color_names[] = {
        "RED", "GREEN", "BLUE", "YELLOW", "CYAN", "MAGENTA", "WHITE"
    };
    
    for (int i = 0; i < ARRAY_SIZE(colors); i++) {
        LOG_INF("Filling screen with %s", color_names[i]);
        
        int ret = fill_rect(display, 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT, colors[i]);
        if (ret < 0) {
            LOG_ERR("Failed to fill screen with color %s: %d", color_names[i], ret);
            return ret;
        }
        
        k_sleep(K_MSEC(1000));
    }
    
    return 0;
}

int main(void)
{
    const struct device *display;
    struct display_capabilities caps;
    int ret;
    
    LOG_INF("ST7789V Display Demo Starting...");
    
    /* Get the display device */
    display = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));
    if (!device_is_ready(display)) {
        LOG_ERR("Display device not ready");
        return -1;
    }
    
    LOG_INF("Display device found and ready");
    
    /* Get display capabilities */
    display_get_capabilities(display, &caps);
    
    LOG_INF("Display capabilities:");
    LOG_INF("  Resolution: %dx%d", caps.x_resolution, caps.y_resolution);
    LOG_INF("  Supported pixel formats: 0x%x", caps.supported_pixel_formats);
    LOG_INF("  Current pixel format: %d", caps.current_pixel_format);
    LOG_INF("  Screen info: %d", caps.screen_info);
    LOG_INF("  Current orientation: %d", caps.current_orientation);
    
    /* Verify the display dimensions match our expectations */
    if (caps.x_resolution != DISPLAY_WIDTH || caps.y_resolution != DISPLAY_HEIGHT) {
        LOG_WRN("Display resolution mismatch! Expected %dx%d, got %dx%d", 
                DISPLAY_WIDTH, DISPLAY_HEIGHT, caps.x_resolution, caps.y_resolution);
    }
    
    /* Turn on display blanking (if supported) */
    ret = display_blanking_off(display);
    if (ret < 0) {
        LOG_WRN("Failed to turn off display blanking: %d", ret);
        /* Continue anyway, some displays don't support this */
    }
    
    /* Main demo loop */
    int demo_cycle = 0;
    while (1) {
        LOG_INF("=== Demo cycle %d ===", demo_cycle++);
        
        /* Draw test pattern */
        ret = draw_pattern(display);
        if (ret < 0) {
            LOG_ERR("Failed to draw pattern: %d", ret);
            break;
        }
        
        LOG_INF("Pattern drawn successfully, waiting 5 seconds...");
        k_sleep(K_MSEC(5000));
        
        /* Animate colors */
        ret = animate_colors(display);
        if (ret < 0) {
            LOG_ERR("Failed to animate colors: %d", ret);
            break;
        }
        
        LOG_INF("Color animation complete, waiting 2 seconds...");
        k_sleep(K_MSEC(2000));
    }
    
    LOG_ERR("Demo loop exited with error");
    return -1;
}