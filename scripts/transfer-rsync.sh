#!/bin/bash
#
# Transfer file from one location to another using rsync
#
echoWithDate() {
  echo "$(date '+%Y-%m-%d-%H-%M-%S'): ${1}"
}

# SET AND CHECK EXPECTED ENVIRONMENT VARIABLES

for i in "$@"
do
case $i in
    --sourceFile=*)
      SOURCE_FILE="${i#*=}"
      shift # past argument=value
    ;;
    --targetFile=*)
      TARGET_FILE="${i#*=}"
      shift # past argument=value
    ;;
    *)
      echoWithDate "Unknown input argument specified"
      exit 1
    ;;
esac
done

if [ -z "${SOURCE_FILE}" ]; then
  echoWithDate "You must have SOURCE_FILE defined to execute this script"; exit 1
  if [ ! -f $FILE ]; then
    echoWithDate "The given SOURCE_FILE of $SOURCE_FILE does not exist"; exit 1
  fi
fi
if [ -z "${TARGET_FILE}" ]; then
  echoWithDate "You must have TARGET_FILE defined to execute this script"; exit 1
fi

echoWithDate "Rsyncing ${SOURCE_FILE} to ${TARGET_FILE}"
rsync -a ${SOURCE_FILE} ${TARGET_FILE}
