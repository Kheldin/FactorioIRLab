#include <stdint.h>

// RCC_APB2ENR = Reset and Clock Control _ Advanced Peripheral Bus 2 Enable
// Register
#define RCC_APB2ENR (*((volatile uint32_t *)0x40021018))
#define RCC_APB1ENR (*((volatile uint32_t *)0x4002101c))

#define USART2_SR                                                              \
  (*((volatile uint32_t *)0x40004400)) // Status Register (and base adress)
#define USART2_BRR (*((volatile uint32_t *)0x40004408)) // Baud Rate Register
#define USART2_CR1 (*((volatile uint32_t *)0x4000440c)) // Control Register
#define USART2_DR (*((volatile uint32_t *)0x40004404))  // Data Register

#define GPIOA_CRH                                                              \
  (*((volatile uint32_t *)0x40010804)) // GPIOA Control Register High
#define GPIOA_CRL                                                              \
  (*((volatile uint32_t *)0x40010800)) // GPIOA Control Register Low
#define PA_ODR                                                                 \
  (*((volatile uint32_t *)0x4001080c)) // Port A Output Data Register

int main(void) {
  RCC_APB2ENR |= (0b1 << 2);  // Enable port A
  RCC_APB1ENR |= (0b1 << 17); // Enable USART2

  // Reset the configuration of PA8,9,10
  GPIOA_CRH &= ~(0b111111111111);

  // Set all threes to Push Pull output at 2 Mhz max speed
  GPIOA_CRH |= (0b001000100010);

  // Set PA2 (tx) to Alternate Func push-pull 2 MHZ
  // And set PA3 (rx) to Input Floating
  GPIOA_CRL &= ~(0b11111111 << 8);
  GPIOA_CRL |= (0b01001010 << 8);

  // Formula: USARTDIV = f_CK / (16 * baud)
  // USARTDIV = 4,34027
  USART2_BRR &= ~(0b1111111111111111);
  USART2_BRR |= (0b0000000001000101);

  // Enable the usart and the receiver
  USART2_CR1 &= ~(0b1111111111111);
  USART2_CR1 |= ((0b1 << 13) | (0b1 << 2));

  int val;

  while (1) {
    // 5th bit of Status register is set to 1
    // if the Data register is not empty
    if (USART2_SR >> 5 & 1) {
      val = USART2_DR;
      if (val == '1') {
        PA_ODR &= ~(0b1 << 9);
        PA_ODR &= ~(0b1 << 10);
        PA_ODR |= (0b1 << 8);
      } else if (val == '2') {
        PA_ODR &= ~(0b1 << 10);
        PA_ODR &= ~(0b1 << 8);
        PA_ODR |= (0b1 << 9);
      } else if (val == '3') {
        PA_ODR &= ~(0b1 << 8);
        PA_ODR &= ~(0b1 << 9);
        PA_ODR |= (0b1 << 10);
      }
    }
  }
  return 0;
}
