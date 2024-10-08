#!/bin/bash

if [ -z "$1" ] ; then
    echo "Usage: $0 <ota zip>"
    exit 1
fi

ROM="$1"

METADATA=$(unzip -p "$ROM" META-INF/com/android/metadata)
SDK_LEVEL=$(echo "$METADATA" | grep post-sdk-level | cut -f2 -d '=')
TIMESTAMP=$(echo "$METADATA" | grep post-timestamp | cut -f2 -d '=')

FILENAME=$(basename $ROM)
DEVICE=lancelot
ROMTYPE=$(echo $FILENAME | cut -f4 -d '-')
DATE=$(echo $FILENAME | cut -f3 -d '-')
ID=$(echo ${TIMESTAMP}${DEVICE}${SDK_LEVEL} | sha256sum | cut -f 1 -d ' ')
SIZE=$(du -b $ROM | cut -f1 -d '	')
TYPE=$(echo $FILENAME | cut -f4 -d '-')
VERSION=$(echo $FILENAME | cut -f2 -d '-')
RELASE_TAG=${DEVICE}_lmodroid-${VERSION}_${TIMESTAMP}

URL="https://drive.orkunergun.eu.org/api/raw/?path=/LMODroid/lancelot/${FILENAME}"

response=$(jq -n --arg datetime $TIMESTAMP \
        --arg filename $FILENAME \
        --arg id $ID \
        --arg romtype $ROMTYPE \
        --arg size $SIZE \
        --arg url $URL \
        --arg version $VERSION \
        '$ARGS.named'
)
wrapped_response=$(jq -n --argjson response "[$response]" '$ARGS.named')

echo "$wrapped_response" > $VERSION/$DEVICE.json
git add $VERSION/$DEVICE.json
git commit -m "Update autogenerated json for $DEVICE $VERSION ${DATE}/${TIMESTAMP}"
git push origin master -f

gh release create $RELASE_TAG $ROM --notes "Automated release for $DEVICE $VERSION ${DATE}/${TIMESTAMP}"
