import serial
import time
import os
import logging

PORT = "COM7"
BAUD_RATE = 115200
DATA_FILE = "C:\\Users\\kheld\\AppData\\Roaming\\Factorio\\script-output\\disco_science_color.txt"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def uart_com():
    ser = None
    while (1):
        try:
            if ser is None or not ser.is_open:
                logging.info(f"Searching the board on port {PORT}...")
                last_color = None
                while True:
                    try:
                        ser = serial.Serial(PORT, BAUD_RATE)
                        break
                    except serial.SerialException:
                            time.sleep(1)        
            with open(DATA_FILE, "r") as f:
                color = f.read().strip()

            if int(color) in [1, 2, 3] and color != last_color:
                ser.write(color.encode('utf-8'))
                logging.info(f"[{time.strftime('%H:%M:%S')}] Sent to STM32 : {color}")
                last_color = color
            time.sleep(0.01)

        except serial.SerialException:
            logging.info(f"Board on port {PORT} unpluged !")
            if ser:
                ser.close()
            break
        except KeyboardInterrupt:
            logging.info("CTRL+C: Stopping the transmission !")
            if ser:
                ser.close()
            break


if __name__ == "__main__":
    uart_com()
