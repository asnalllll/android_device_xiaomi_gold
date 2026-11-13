#!/vendor/bin/sh

# Pastikan mi_thermald tidak memutus arus secara tiba-tiba
echo 10 > /sys/class/thermal/thermal_message/sconfig 2>/dev/null

BATT_TEMP="/sys/class/power_supply/battery/temp"
CHG_CURR="/sys/class/power_supply/battery/constant_charge_current"
LAST_STATE=""

while true; do
    if [ -f "$BATT_TEMP" ] && [ -f "$CHG_CURR" ]; then
        TEMP=$(cat "$BATT_TEMP")
        # TEMP dalam satuan 0.1 C (contoh: 400 = 40.0 C)
        if [ "$TEMP" -ge 440 ]; then
            # >= 44.0 C: turun aman (~10W)
            TARGET=2000000
            STATE="44"
        elif [ "$TEMP" -ge 420 ]; then
            # 42.0 - 43.9 C: turun bertahap (~18W)
            TARGET=3300000
            STATE="42"
        elif [ "$TEMP" -ge 400 ]; then
            # 40.0 - 41.9 C: turun sedikit (~24W)
            TARGET=4500000
            STATE="40"
        elif [ "$TEMP" -lt 395 ] || [ "$LAST_STATE" = "" ]; then
            # < 39.5 C (hysteresis 0.5 C agar tidak naik-turun): Full Power 33W
            TARGET=6000000
            STATE="FULL"
        else
            # Antara 39.5 - 39.9 C: pertahankan state sebelumnya
            TARGET=""
        fi

        if [ -n "$TARGET" ] && [ "$STATE" != "$LAST_STATE" ]; then
            echo "$TARGET" > "$CHG_CURR" 2>/dev/null
            LAST_STATE="$STATE"
        fi
    fi
    sleep 5
done
