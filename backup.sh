#!/bin/bash

# Define variables
BASTION_USER=bastion_username
BASTION_IP=bastion_ip_address
RDS_USER=rds_username
RDS_HOST=rds_host
RDS_DB=rds_database
LOCAL_RDS_USER=local_rds_username
LOCAL_RDS_HOST=local_rds_host
LOCAL_RDS_DB=local_rds_database
LOCAL_DIR=./
PRIVATE_KEY_PATH=./key.pem
DOCKER_CONTAINER=docker_container_name_or_id

# Define current date for the backup file name
DATE=$(date +%Y%m%d%H%M%S)

# Define file name for the dump file
DUMP_FILE="$RDS_DB"_"$DATE".sql

# SSH to the bastion host and execute pg_dump
ssh -v -i $PRIVATE_KEY_PATH -l $BASTION_USER $BASTION_IP "PGPASSWORD=lynk_api1234! pg_dump -h $RDS_HOST -U $RDS_USER -F p -f /tmp/$DUMP_FILE -d $RDS_DB"

# Copy the dump file from bastion host to the local machine
scp -v -i $PRIVATE_KEY_PATH $BASTION_USER@$BASTION_IP:/tmp/$DUMP_FILE $LOCAL_DIR

# Copy the dump file from local machine into the Docker container
docker cp $LOCAL_DIR/$DUMP_FILE $DOCKER_CONTAINER:/tmp/$DUMP_FILE


# Drop the existing database and create a new one
#docker exec -it $DOCKER_CONTAINER psql -h $LOCAL_RDS_HOST -U $LOCAL_RDS_USER -c "DROP DATABASE IF EXISTS $LOCAL_RDS_DB; CREATE DATABASE $LOCAL_RDS_DB;"
docker exec -it $DOCKER_CONTAINER dropdb -h $LOCAL_RDS_HOST -U $LOCAL_RDS_USER --if-exists $LOCAL_RDS_DB


# Create a new database
docker exec -it $DOCKER_CONTAINER createdb -h $LOCAL_RDS_HOST -U $LOCAL_RDS_USER $LOCAL_RDS_DB


# Restore the database using the dump file
docker exec -it $DOCKER_CONTAINER psql -h $LOCAL_RDS_HOST -U $LOCAL_RDS_USER -d $LOCAL_RDS_DB -f /tmp/$DUMP_FILE

# Remove the dump file from the bastion host
ssh -v -i $PRIVATE_KEY_PATH -l $BASTION_USER $BASTION_IP "rm -f /tmp/$DUMP_FILE"

# Remove the dump file from the local machine
rm -f $LOCAL_DIR/$DUMP_FILE

echo "Backup has been created, copied to Docker container $DOCKER_CONTAINER, and used to restore the database"
