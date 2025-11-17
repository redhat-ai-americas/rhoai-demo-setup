# Custom Notebook Image for Red Hat OpenShift AI

Follow these steps to create and register a custom notebook image in OpenShift AI.

## ✅ High-Level Steps

- [ ] Create a `requirements.txt` **or** `Pipfile` / `Pipfile.lock` listing all required Python packages  
- [ ] Identify the base OpenShift AI notebook image to extend  
- [ ] Create a `Containerfile` (or `Dockerfile`) using the selected base image  
- [ ] Install additional OS and Python packages as needed  
- [ ] Set correct permissions:   
  - [ ] Execute the OpenShift `fix-permissions` script to ensure writable directories  
- [ ] Build the image and push it to an accessible container registry  
- [ ] Create an ImageStream YAML referencing the custom image  
- [ ] Apply the ImageStream in the `redhat-ods-applications` namespace  
- [ ] Verify the image appears in the OpenShift AI dashboard under **Settings → Workbench Images**  
- [ ] Enable the image and create a new workbench using it  

---

## 🔗 Reference Links

- [AI on OpenShift — Custom Notebooks Guide](https://ai-on-openshift.io/odh-rhoai/custom-notebooks/)  
- [Red Hat OpenShift AI 2.25 — Creating a Workbench](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/creating_a_workbench/api-custom-image-creating_api-workbench)
