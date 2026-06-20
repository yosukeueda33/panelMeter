#include <avr/io.h>
#include "infra.h"
#include <stdbool.h>

extern volatile uint8_t input_0;
extern volatile uint8_t input_1;
extern uint8_t lightStates[4U];

void setup_gpio(void)
{
    // Inputs:
    // PD2, PD3 with internal pull-up
    DDRD &= ~((1 << PD2) | (1 << PD3));
    PORTD |= (1 << PD2) | (1 << PD3);

    // Outputs:
    // PD4, PD6, PB0, PB1
    DDRD |= (1 << PD4) | (1 << PD6);
    DDRB |= (1 << PB0) | (1 << PB1);

    // Initial output low
    PORTD &= ~((1 << PD4) | (1 << PD6));
    PORTB &= ~((1 << PB0) | (1 << PB1));
}

void read_inputs(void)
{
    // Pull-upなので、GNDに落ちたらON=1として扱う
    if ((PIND & (1 << PD2)) == 0) {
        input_0 = 1;
        for (uint8_t i = 0; i < 4; i++) {
            if (lightStates[i] > 3) {
                lightStates[i] = 0;
            }
        }
    } else {
        input_0 = 0;
    }

    if ((PIND & (1 << PD3)) == 0) {
        input_1 = 1;
    } else {
        input_1 = 0;
    }
}

void set_output(uint8_t out0, uint8_t out1, uint8_t out2, uint8_t out3)
{
    uint8_t d_set = 0;
    if (out0) d_set |= (1 << PD4);
    if (out1) d_set |= (1 << PD6);

    PORTD = (PORTD & ~((1 << PD4) | (1 << PD6))) | d_set;

    uint8_t b_set = 0;
    if (out2) b_set |= (1 << PB0);
    if (out3) b_set |= (1 << PB1);

    PORTB = (PORTB & ~((1 << PB0) | (1 << PB1))) | b_set;
}

void setup_meter_pwm(void)
{
    // OC0A = PB2
    // OC0B = PD5
    // OC1A = PB3
    // OC1B = PB4

    DDRB |= (1 << PB2) | (1 << PB3) | (1 << PB4);
    DDRD |= (1 << PD5);

    OCR0A = 0;
    OCR0B = 0;
    OCR1A = 0;
    OCR1B = 0;

    // Timer0: 8-bit Fast PWM, non-inverting OC0A/OC0B
    TCCR0A =
        (1 << COM0A1) |
        (1 << COM0B1) |
        (1 << WGM01)  |
        (1 << WGM00);

    // prescaler 64
    // PWM freq = 10MHz / 64 / 256 = 約610Hz
    TCCR0B = (1 << CS01) | (1 << CS00);

    // Timer1: 8-bit Fast PWM, non-inverting OC1A/OC1B
    TCCR1A =
        (1 << COM1A1) |
        (1 << COM1B1) |
        (1 << WGM10);

    // prescaler 64
    TCCR1B =
        (1 << WGM12) |
        (1 << CS11) |
        (1 << CS10);

    // Timer0 overflow interrupt for Copilot step tick
    TIMSK |= (1 << TOIE0);
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