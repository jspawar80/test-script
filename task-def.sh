#!/bin/bash

set -e

# $1 is the new image tag
newImage="$1"
# $2 is the file path of the task definition json
taskDefPath="$2"

taskDef=$(cat $taskDefPath)

# using jq to replace the image
newTaskDef=$(echo $taskDef | jq --arg newImage "$newImage" '.containerDefinitions[0].image = $newImage')

# write back to file
echo "$newTaskDef" > $taskDefPath
