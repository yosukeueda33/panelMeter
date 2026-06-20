/*
 * echo2313.c
 *
 * ATtiny2313 UART echo-back using a 4-byte TX ring buffer.
 *
 * F_CPU: 10 MHz
 * Baud : 9600 bps
 *
 * RX  : PD0
 * TX  : PD1
 */

#ifndef F_CPU
#define F_CPU 10000000UL
#endif

#define BAUD 9600UL
#define UBRR_VALUE ((F_CPU / (16UL * BAUD)) - 1UL)

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include <stdbool.h>
#include <stdint.h>
#include "infra.h"
#include "generated/Communicate.h"

/* -----------------------------
 * TX ring buffer
 * 容量4、ただし1スロット空ける方式なので実効容量は3バイト
 * ----------------------------- */

// #define TX_BUFFER_SIZE 4

// static volatile uint8_t txBuffer[TX_BUFFER_SIZE];
// static volatile uint8_t txBufferHead = 0;
// static volatile uint8_t txBufferTail = 0;

/* -----------------------------
 * USART
 * ----------------------------- */

static void uart_init(void)
{
    uint16_t ubrr = (uint16_t)UBRR_VALUE;

    UBRRH = (uint8_t)(ubrr >> 8);
    UBRRL = (uint8_t)(ubrr & 0xFF);

    /*
     * 8N1:
     * - asynchronous
     * - no parity
     * - 1 stop bit
     * - 8 data bits
     */
    UCSRC = (uint8_t)(_BV(UCSZ1) | _BV(UCSZ0));

    /*
     * Enable RX, TX, RX complete interrupt.
     * UDRE interrupt is enabled only when TX buffer has data.
     */
    UCSRB = (uint8_t)(_BV(RXEN) | _BV(TXEN) | _BV(RXCIE));
}

static void uart_enable_udre_interrupt(void)
{
    UCSRB |= _BV(UDRIE);
}

static void uart_disable_udre_interrupt(void)
{
    UCSRB &= (uint8_t)~_BV(UDRIE);
}

/* -----------------------------
 * Interrupt vectors
 * avr-libcのデバイス定義差分吸収
 * ----------------------------- */

#if defined(USART_RX_vect)
#define UART_RX_VECTOR USART_RX_vect
#elif defined(USART0_RX_vect)
#define UART_RX_VECTOR USART0_RX_vect
#elif defined(USART_RXC_vect)
#define UART_RX_VECTOR USART_RXC_vect
#else
#error "No USART RX vector name found for this device"
#endif

#if defined(USART_UDRE_vect)
#define UART_UDRE_VECTOR USART_UDRE_vect
#elif defined(USART0_UDRE_vect)
#define UART_UDRE_VECTOR USART0_UDRE_vect
#elif defined(USART_DRE_vect)
#define UART_UDRE_VECTOR USART_DRE_vect
#else
#error "No USART UDRE vector name found for this device"
#endif

/*
 * 1バイト受信したら、そのままTXバッファへ積む。
 * バッファ満杯なら捨てる。
 */
ISR(UART_RX_VECTOR)
{
    uint8_t x_rx = UDR;
    uint8_t x_tx = UDR;

    x_tx = parseByte(x_rx);

    if (pushTxBuffer(x_tx)) {
        uart_enable_udre_interrupt();
    }
}

/*
 * 送信データレジスタが空になったら、TXバッファから1バイト送る。
 * 空ならUDRE割り込みを止める。
 */
ISR(UART_UDRE_VECTOR)
{
    uint8_t x;

    if (popTxBuffer(&x)) {
        UDR = x;

        /*
         * 送った結果、空になったなら次のUDRE割り込みは不要。
         * UDRに書いたバイト自体はこの後ハードウェアが送信する。
         */
        if (txBufferHead == txBufferTail) {
            uart_disable_udre_interrupt();
        }
    } else {
        uart_disable_udre_interrupt();
    }
}

/* -----------------------------
 * main
 * ----------------------------- */

int main(void)
{
    uart_init();

    setup_meter_pwm();
    set_sleep_mode(SLEEP_MODE_IDLE);
    sleep_enable();

    sei();

    for (;;) {
        sleep_cpu();
    }
}