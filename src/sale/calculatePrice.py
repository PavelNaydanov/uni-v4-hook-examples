# Скрипт для того, чтобы рассчитать starting price для пула
# python3 ./src/sale/calculatePrice.py

from decimal import Decimal, getcontext

getcontext().prec = 50  # Точность в 50 знаков

tokenA = 2
tokenB = 1

sqrt_price_x96 = Decimal(tokenA/tokenB).sqrt() * (Decimal(2)**96)

print(int(sqrt_price_x96))  # 112045541949572279837463876454