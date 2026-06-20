#ifndef INFRA_H
#define INFRA_H

#include <stdint.h>
#include <stdbool.h>

void setup_meter_pwm(void);
void set_meter(uint8_t port, uint8_t value127);

void setup_gpio(void);
void read_inputs(void);
// void set_output(uint8_t out0, uint8_t out1, uint8_t out2, uint8_t out3);


#endif