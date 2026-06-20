#ifndef INFRA_H
#define INFRA_H

#include <stdint.h>

void setup_meter_pwm(void);
void set_meter(uint8_t port, uint8_t value127);

#endif