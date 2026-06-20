#include <avr/io.h>
#include "infra.h"

void setup_meter_pwm(void)
{
    DDRB |= (1 << PB2) | (1 << PB3) | (1 << PB4);
    DDRD |= (1 << PD5);

    OCR0A = 0;
    OCR0B = 0;
    OCR1A = 0;
    OCR1B = 0;

    TCCR0A =
        (1 << COM0A1) |
        (1 << COM0B1) |
        (1 << WGM01)  |
        (1 << WGM00);

    TCCR0B = (1 << CS00);

    TCCR1A =
        (1 << COM1A1) |
        (1 << COM1B1) |
        (1 << WGM10);

    TCCR1B =
        (1 << WGM12) |
        (1 << CS10);
}

void set_meter(uint8_t port, uint8_t value127)
{
    if (value127 > 127) {
        value127 = 127;
    }

    uint8_t duty = value127 * 2; // 0..254

    switch (port) {
    case 0:
        OCR0A = duty;
        break;
    case 1:
        OCR0B = duty;
        break;
    case 2:
        OCR1A = duty;
        break;
    case 3:
        OCR1B = duty;
        break;
    default:
        break;
    }
}