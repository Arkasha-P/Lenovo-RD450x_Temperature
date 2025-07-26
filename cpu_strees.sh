#!/bin/bash

# Функция для аварийного завершения
cleanup() {
    echo -e "\n[!] Аварийная остановка... Завершаем все процессы."
    pkill -P $$  # Убиваем все дочерние процессы
    exit 1
}

trap cleanup SIGINT SIGTERM  # Перехватываем Ctrl+C

# Числа Фибоначчи (рекурсия + большие числа)
fib() {
    local n=$1
    if (( n <= 1 )); then
        echo $n
    else
        echo $(( $(fib $((n-1))) + $(fib $((n-2))) ))
    fi
}

# Тяжёлые вычисления с плавающей точкой (симуляция БПФ)
floating_point_stress() {
    local i
    for (( i=0; i<500; i++ )); do
        awk 'BEGIN {
            sum = 0
            for (j=0; j<1000; j++) {
                sum += sin(j) * cos(j) / (sqrt(j+1) + 0.0001)
            }
        }' >/dev/null
    done
}

# Генерация SHA-256 хешей
hash_stress() {
    local str="CPU_STRESS_TEST_$RANDOM"
    for (( i=0; i<1000; i++ )); do
        echo "$str$i" | sha256sum >/dev/null
    done
}

# Проверка простых чисел (упрощённый тест)
is_prime() {
    local n=$1
    if (( n < 2 )); then
        return 1
    fi
    for (( i=2; i*i<=n; i++ )); do
        if (( n % i == 0 )); then
            return 1
        fi
    done
    return 0
}

prime_stress() {
    local i
    for (( i=2; i<5000; i++ )); do
        is_prime $i
    done
}

# Запуск нагрузочных тестов в параллельных подпроцессах
run_stress_test() {
    echo "[+] Запуск сложного CPU-теста (алгоритмы: Фибоначчи, плавающая арифметика, SHA-256, простые числа)..."
    echo "[!] Нажмите Ctrl+C для остановки."

    # Запускаем нагрузку на всех ядрах
    for (( core=0; core<$(nproc); core++ )); do
        (
            while true; do
                fib 20 >/dev/null
                floating_point_stress
                hash_stress
                prime_stress
            done
        ) &
    done

    wait  # Ждём завершения (никогда не произойдёт, пока не нажмём Ctrl+C)
}

run_stress_test
