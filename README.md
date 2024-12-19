# gcp-win-vm-booter
This script automates the creation of a bootable disk from a snapshot and sets up a Windows VM on Google Cloud Platform. It handles the disk creation, temporary VM setup, bootable disk preparation, and final VM deployment.

---

## Prerequisites

   
1. **Service Account**:
   - Create a service account with the following roles:
     - `roles/compute.admin` (Compute Engine management)
     - `roles/storage.admin` (Storage bucket access if required)
   - Example command:
     gcloud iam service-accounts create my-service-account \
         --display-name="Script Service Account"

   - Assign roles:
     gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
         --member="serviceAccount:my-service-account@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
         --role="roles/compute.admin"

     gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
         --member="serviceAccount:my-service-account@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
         --role="roles/storage.admin"

2. **Startup Script**:
   - Upload the PowerShell script (`setup.ps1`) to a Cloud Storage bucket:
     gsutil cp setup.ps1 gs://your-bucket-name/ 
   - Also please updated the bucket name on the main.sh file.


3. **Permissions**:
   - Ensure the script file has execution permissions:
     chmod +x main.sh
---

## How to Use

1. **Run the Script**:
   Execute the script and follow the prompts:
   ./main.sh
   
2. **Inputs Required**:
   - Service account name
   - Snapshot name
   - New disk name
   - Temporary VM name
   - Final VM name
   - Zone (default: `us-central1-a`)

3. **Logs**:
   - Logs are saved in `$HOME/logs/vm_setup.log`.

---

## Customization

You can modify the following parts of the script:
- **Machine Type**: Adjust the VM type (e.g., `n1-standard-1`) in the `gcloud compute instances create` commands.
- **Wait Time**: Change the `WAIT_TIME` variable for longer or shorter delays.
- **Startup Script Path**: Update the `SETUP_SCRIPT` variable to point to a different Cloud Storage bucket or script.

---

## Notes

- This script is designed to work in **Google Cloud Shell** or any system with the `gcloud` CLI authenticated.

Happy automating! 🚀

---

This setup ensures clarity and usability for users, even those new to GCP or scripting. If you have further refinements or questions, let me know! 😊
