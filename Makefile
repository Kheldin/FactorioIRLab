NAME    = firmware.elf
BIN     = firmware.bin

CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

CFLAGS  = -mcpu=cortex-m3 -mthumb -Wall -Wextra -Werror -O0 -g3

LDFLAGS = -T script.ld -nostdlib -Wl,-Map=firmware.map

SRCS    = main.c startup_stm32f103xb.s
OBJS    = main.o startup_stm32f103xb.o

all: $(NAME) $(BIN)

$(NAME): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(NAME)
	$(OBJCOPY) -O binary $< $@

clean:
	rm -f $(OBJS) firmware.map

fclean: clean
	rm -f $(NAME) $(BIN)

re: fclean all

flash: $(BIN)
	st-flash write $(BIN) 0x08000000

.PHONY: all clean fclean re flash