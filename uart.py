import serial
import time
import os


PORT = "COM7"
BAUD_RATE = 115200
DATA_FILE = "C:\\Users\\kheld\\AppData\\Roaming\\Factorio\\script-output\\disco_science_color.txt"

def uart_com():
    ser = None
    last_color = None
    while (1):
        try:
            if ser is None or not ser.is_open:
                print(f"Searching the board on port {PORT}...")
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
                print(f"[{time.strftime('%H:%M:%S')}] Sent to STM32 : {color}")
                last_color = color
            time.sleep(0.1)

        except serial.SerialException:
            print(f"Board on port {PORT} unpluged !")
            if ser:
                ser.close()
        except KeyboardInterrupt:
            print("CTRL+C: Stopping the script.")
            if ser and ser.is_open():
                ser.close()

if __name__ == "__main__":
    uart_com()
