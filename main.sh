#!/bin/bash


# Path to the service account key file
SERVICE_ACCOUNT_KEY="/path/to/your/key.json"

# Logging Functions
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/vm_setup.log"

# Create a directory for logs
mkdir -p $LOG_DIR

function log_info {
    echo "[INFO] $1" | tee -a $LOG_FILE
}

function log_error {
    echo "[ERROR] $1" | tee -a $LOG_FILE
    exit 1
}

# Create the log file and initialize the script
touch $LOG_FILE || log_error "Failed to create the log file: $LOG_FILE"
log_info "VM Setup Script Starting..."

# Collect inputs from the user
#read -p "Enter the service account name (e.g., my-service-account): " SERVICE_ACCOUNT
read -p "Enter the snapshot name: " SNAPSHOT_NAME
read -p "Enter the new disk name: " DISK_NAME
read -p "Enter the temporary VM name: " TEMP_VM_NAME
read -p "Enter the final VM name: " FINAL_VM_NAME
read -p "Enter the zone (default: us-central1-a): " ZONE
ZONE=${ZONE:-us-central1-a}  # Default to us-central1-a if no input

# Wait time between steps
WAIT_TIME=240  # 4 minutes

# Startup Script Path
SETUP_SCRIPT="gs://bla-bla/setup.ps1"

# Configure service account
log_info "Configuring the service account: $SERVICE_ACCOUNT"
gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_KEY
if [[ $? -eq 0 ]]; then
    log_info "Service account successfully configured."
else
    log_error "Failed to configure the service account!"
fi

# Step 1: Create disk from snapshot
log_info "Creating disk from snapshot..."
gcloud compute disks create $DISK_NAME \
    --source-snapshot=$SNAPSHOT_NAME \
    --zone=$ZONE | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Disk successfully created."
else
    log_error "Error occurred while creating the disk!"
fi

log_info "Waiting for the disk creation to complete ($WAIT_TIME seconds)..."
#sleep $WAIT_TIME

# Step 2: Create temporary Windows VM and attach the disk
log_info "Creating temporary Windows VM and attaching the disk..."
gcloud compute instances create $TEMP_VM_NAME \
    --zone=$ZONE \
    --machine-type=n1-standard-1 \
    --image-family=windows-2022 \
    --image-project=windows-cloud \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-ssd \
    --boot-disk-device-name=temp-vm-boot-disk \
    --disk=name=$DISK_NAME,device-name=new-disk | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Temporary VM successfully created."
else
    log_error "Error occurred while creating the temporary VM!"
fi

log_info "Waiting for the temporary VM to start ($WAIT_TIME seconds)..."
#sleep $WAIT_TIME

# Step 3: Add startup script to temporary VM
log_info "Adding startup script to the temporary VM..."
gcloud compute instances add-metadata $TEMP_VM_NAME \
    --metadata=windows-startup-script-url=$SETUP_SCRIPT | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Startup script successfully added."
else
    log_error "Error occurred while adding the startup script!"
fi

log_info "Waiting for the startup script to complete ($WAIT_TIME seconds)..."
sleep $WAIT_TIME

# Step 4: Stop temporary VM and detach the disk
log_info "Stopping the temporary VM and detaching the disk..."
gcloud compute instances stop $TEMP_VM_NAME --zone=$ZONE | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Temporary VM successfully stopped."
else
    log_error "Error occurred while stopping the temporary VM!"
fi

log_info "Waiting for the VM to stop ($WAIT_TIME seconds)..."
#sleep $WAIT_TIME

gcloud compute instances detach-disk $TEMP_VM_NAME \
    --disk=$DISK_NAME --zone=$ZONE | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Disk successfully detached."
else
    log_error "Error occurred while detaching the disk!"
fi

# Step 5: Create final VM with the bootable disk
log_info "Creating the final VM with the bootable disk..."
gcloud compute instances create $FINAL_VM_NAME \
    --zone=$ZONE \
    --machine-type=n1-standard-1 \
    --disk=name=$DISK_NAME,boot=yes | tee -a $LOG_FILE
if [[ $? -eq 0 ]]; then
    log_info "Final VM successfully created."
else
    log_error "Error occurred while creating the final VM!"
fi

log_info "All steps completed successfully. Logs available at: $LOG_FILE"
