# rhoai-demo-setup

## Summary

This repository provides **automated setup and configuration tools for deploying Red Hat OpenShift AI (RHOAI) on OpenShift clusters**. It's designed to streamline the process of setting up a complete AI/ML platform with GPU support and related infrastructure.

### Key Purposes:

1. **Automated RHOAI Deployment**: Uses Ansible playbooks to automate the installation and configuration of Red Hat OpenShift AI and all its dependencies on OpenShift clusters.

2. **GPU-Enabled AI Infrastructure**: Sets up GPU nodes with NVIDIA operators, drivers, and monitoring dashboards to support AI/ML workloads that require GPU acceleration.

3. **Complete Platform Setup**: Installs and configures supporting components including:

   - Serverless and Service Mesh operators
   - Authentication and authorization (Authorino)
   - Object storage (MinIO)
   - Monitoring and observability tools
   - Web terminals and developer tooling

4. **Demo Capabilities**: Provides ready-to-use demos showcasing RHOAI capabilities, particularly model serving with vLLM.

### Main Components:

- **components**: Kustomize manifests for 16 different cluster components (prerequisites, GPU operators, RHOAI, monitoring, etc.)
- **playbooks**: Ansible automation scripts for full cluster setup, individual component installation, and demos
- **demos**: Sample applications and inference examples
- **docs**: Documentation and setup guides

### Primary Use Cases:

- **Full Cluster Setup**: One-command deployment of a complete RHOAI environment
- **Individual Component Setup**: Granular installation of specific components (GPU setup, MinIO, etc.)
- **AI/ML Demonstrations**: Pre-configured demos for model serving and inference

This repository essentially serves as a "one-stop-shop" for getting a production-ready AI/ML platform running on OpenShift with minimal manual configuration required.

## Pre-Requisites

Before using this repository, ensure you have the following:

### 1. OpenShift Cluster

- You must have access to a running OpenShift cluster
  ([Instructions on creating a cluster](/docs/info-create-openshift-cluster.md))
- You need the `kubeadmin` credentials for cluster administration.

### 2. Ansible and ansible-playbook

- Install Ansible on your local machine (macOS/Linux):
  ```sh
  pip install --user ansible
  ```
- Or, using Homebrew on macOS:
  ```sh
  brew install ansible
  ```
- Verify installation:
  ```sh
  ansible --version
  ansible-playbook --version
  ```

### 3. OpenShift CLI (`oc`)

- Install the OpenShift CLI
  - [Official documentation](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html).
  - Download [Link](https://access.redhat.com/downloads/content/290/ver=4.18/rhel---9/4.18.13/x86_64/product-software)
- Verify installation:
  ```sh
  oc version
  ```

---

## Automation

Below are the main Ansible files under the `playbooks/` directory (top-level only) that get run as part of the automation.

### Full Cluster Setup

**Run with:**

```sh
ansible-playbook playbooks/setup-cluster.ansible.yml
```

- Below components get installed:

  - Install cluster pre-reqs
  - Add user with cluster-admin role
  - Provision and configure GPU node
  - Install NFD and NIVIDIA GPU operator
  - Install Serverless and Servicemesh operator
  - Install RHOAI and depdendent components

> [!IMPORTANT]
> Don't run automation for individual components as they get run as part of full cluster setup.

### Individual Component Setup

- **Provision and configure GPU node**

  **Run with:**

  ```sh
  ansible-playbook playbooks/gpu-setup.ansible.yml
  ```

  - Below components get installed:
    - Add GPU node
    - Install NFD and NVIDIA GPU operator
    - Install NVIDIA DCGM dashboard
    - Configure timeslicing in GPU
    - Taint GPU nodes

- Provision MINIO object storage

  **Run with:**

  ```sh
  ansible-playbook playbooks/minio-setup.ansible.yml
  ```

### Demos

- **Demo model serving on vLLM**

  **Run with:**

  ```sh
  ansible-playbook playbooks/demo-vllm.ansible.yml
  ```

  - Below components get installed:
    - Install MINIO storage
    - Create DataScience project
    - Create data-connections
    - Create ServingRuntime
    - Create InferenceService

## Instructions

### 1. Clone the Repository

```sh
git clone https://github.com/redhat-ai-americas/rhoai-demo-setup.git
cd rhoai-demo-setup
```

### 2. Run the Ansible Playbooks

You can run any playbook using the following command:

```sh
ansible-playbook <path-to-playbook>
```

For example, to run the full cluster setup:

```sh
ansible-playbook playbooks/cluster-setup.ansible.yml
```

Or to run a specific setup or demo playbook:

```sh
ansible-playbook playbooks/gpu-setup.ansible.yml
ansible-playbook playbooks/minio-setup.ansible.yml
ansible-playbook playbooks/demo-vllm.ansible.yml
```

> [!NOTE]
> To save the output to a log file, use:
>
> ```sh
> ansible-playbook playbooks/cluster-setup.ansible.yml | tee cluster-setup.log
> ```
