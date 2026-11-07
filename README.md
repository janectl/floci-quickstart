# AWS Sandbox (Floci)

Local-first Infrastructure as Code (IaC) playground using **Terraform** and the **Floci** AWS emulator. Run and test AWS resources (S3, SQS, etc.) locally via Docker/Podman (container at your choice)

---

## 1. Prerequisites

Ensure the following tools are installed on your workstation:

* **Docker & Docker Compose** (`docker compose version`) / **Podman**
* **Terraform** >= v1.5.0 (`terraform version`)
* **AWS CLI v2** (`aws --version`)
* **Git**

---

## 2. Environment Setup: The `awslocal` Alias

Standard `aws` CLI commands target the real AWS cloud by default. Configure an alias that injects local dummy credentials and routes API requests to your local emulator on port `4566`. I use Linux, convert to Powershell command if needed

### Add the alias to `~/.bashrc`:
```bash
echo "alias awslocal='AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws --endpoint-url=http://localhost:4566'" >> ~/.bashrc
source ~/.bashrc
```

### Verify the alias:
```bash
awslocal sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "000000000000",
    "Account": "000000000000",
    "Arn": "arn:aws:iam::000000000000:root"
}
```

---

## 3. Quickstart

### Step 1: Start the Local Cloud
Spin up Floci in the background:
```bash
docker compose up -d
```
* **AWS API Endpoint:** `http://localhost:4566`
* **Web Management Console:** `http://localhost:4566/_floci/ui` (or `http://localhost:4500`)

### Step 2: Deploy Infrastructure
Initialize the Terraform providers and apply the configuration:
```bash
terraform init
terraform apply -auto-approve
```

---

## 4. Verifying Resources

### Check State with Terraform:
```bash
terraform state list
terraform output
```

### Test via AWS CLI (`awslocal`):

#### S3 Operations:
```bash
# List buckets
awslocal s3 ls

# Upload a test file
echo "Hello from Floci!" > test.txt
awslocal s3 cp test.txt s3://my-floci-test-bucket/

# List objects inside the bucket
awslocal s3 ls s3://my-floci-test-bucket/
```

#### SQS Operations:
```bash
# List active queues
awslocal sqs list-queues

# Send a test JSON message
awslocal sqs send-message \
  --queue-url http://localhost:4566/000000000000/my-floci-test-queue \
  --message-body '{"event": "test_ping", "status": "ok"}'

# Receive and inspect the message
awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/my-floci-test-queue
```

---

## 5. Important Gotchas & Configuration Notes

### 1. S3 Path-Style Addressing
By default, the AWS provider attempts to use **virtual-hosted-style addressing** (e.g., `http://bucket-name.localhost:4566`), which fails external DNS resolution (`no such host`). 

To prevent this, the provider configuration in `main.tf` explicitly enables:
```hcl
s3_use_path_style = true
```

### 2. SQS Region Binding
Unlike S3 bucket operations which are global, SQS queue lookups are strictly regional. If queries return empty arrays (`"QueueUrls": []`), ensure requests pass `--region us-east-1` or use the `awslocal` alias configured above.

---

## 6. Teardown & Cleanup

Destroy the simulated AWS resources:
```bash
terraform destroy -auto-approve
```

Stop the Floci emulator container:
```bash
docker compose down
```