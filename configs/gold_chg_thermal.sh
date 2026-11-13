#!/vendor/bin/sh

SCONFIG="/sys/class/thermal/thermal_message/sconfig"
BATT_TEMP="/sys/class/power_supply/battery/temp"
CHG_CURR="/sys/class/power_supply/battery/constant_charge_current"
LAST_STATE=""
TARGET=""

while true; do
    if [ -f "$SCONFIG" ]; then
        CUR_SCONFIG=$(cat "$SCONFIG" 2>/dev/null)
        if [ "$CUR_SCONFIG" != "10" ]; then
            echo 10 > "$SCONFIG" 2>/dev/null
        fi
    fi

    if [ -f "$BATT_TEMP" ] && [ -f "$CHG_CURR" ]; then
        TEMP=$(cat "$BATT_TEMP")
        if [ "$TEMP" -ge 440 ]; then
            TARGET=2000000
            STATE="44"
        elif [ "$TEMP" -ge 420 ]; then
            TARGET=3300000
            STATE="42"
        elif [ "$TEMP" -ge 400 ]; then
            TARGET=4500000
            STATE="40"
        elif [ "$TEMP" -lt 395 ] || [ "$LAST_STATE" = "" ]; then
            TARGET=6000000
            STATE="FULL"
        fi

        if [ -n "$TARGET" ]; then
            LAST_STATE="$STATE"
            CUR_VAL=$(cat "$CHG_CURR" 2>/dev/null)
            if [ "$CUR_VAL" != "$TARGET" ]; then
                echo "$TARGET" > "$CHG_CURR" 2>/dev/null
            fi
        fi
    fi
    sleep 5
done
