#!/bin/bash

# ===== DEFAULTS =====
LOGFILE="/var/log/apache2/access.log"
SORT="desc"
DATE=""
IP=""
UA=""
STATUS=""
LIVE=0

# ===== ARG PARSER =====
for arg in "$@"; do
    case $arg in
        --path=*)
            LOGFILE="${arg#*=}"
            ;;
        --date=*)
            DATE="${arg#*=}"
            ;;
        --ip=*)
            IP="${arg#*=}"
            ;;
        --ua=*)
            UA="${arg#*=}"
            ;;
        --status=*)
            STATUS="${arg#*=}"
            ;;
        --asc)
            SORT="asc"
            ;;
        --desc)
            SORT="desc"
            ;;
        --live)
            LIVE=1
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

if [ ! -f "$LOGFILE" ]; then
    echo "Log file not found!"
    exit 1
fi

# ===== BUILD FILTER =====
FILTER_CMD="cat $LOGFILE"

if [ "$LIVE" -eq 1 ]; then
    FILTER_CMD="tail -f $LOGFILE"
fi

if [ -n "$DATE" ]; then
    FILTER_CMD="$FILTER_CMD | grep \"$DATE\""
fi

if [ -n "$IP" ]; then
    FILTER_CMD="$FILTER_CMD | grep \"^$IP \""
fi

if [ -n "$UA" ]; then
    FILTER_CMD="$FILTER_CMD | grep -i \"$UA\""
fi

if [ -n "$STATUS" ]; then
    FILTER_CMD="$FILTER_CMD | awk '\$9 == $STATUS'"
fi

# ===== SORTING =====
if [ "$SORT" == "asc" ]; then
    FILTER_CMD="$FILTER_CMD | sort"
else
    FILTER_CMD="$FILTER_CMD | sort -r"
fi

# ===== EXECUTE =====
eval $FILTER_CMD
