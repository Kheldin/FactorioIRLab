#include <stdint.h>

#define RCC_APB2ENR (*((volatile uint32_t *)0x40021018))
#define PA5  (*((volatile uint32_t * ) 0x40010800))
#define PA5_ODR  (*((volatile uint32_t * ) 0x4001080c))

void delay(volatile uint32_t count) {
    while (count--) {
        __asm__ volatile ("nop"); 
    }
}
int main(void)
{
    RCC_APB2ENR |= (0b1 << 2);  // Enable port A

    PA5 &= ~(0b1111 << 20);
    PA5 |= (0b0010 << 20);

    while (1)
    {
        PA5_ODR &= (0b0 << 5);

        delay(500000);

        PA5_ODR |= (0b1 << 5);
        
        delay(500000);
    }
    return 0;
}   
