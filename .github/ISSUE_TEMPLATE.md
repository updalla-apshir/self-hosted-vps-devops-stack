---
name: Bug Report
about: Report a bug or issue with the VPS/Dokploy setup
title: "[BUG] "
labels: bug
assignees: ''
---

# Issue Description

**Describe the issue:**  
Deployment fails when pulling Docker image, and the container does not start.

**Expected behavior:**  
Deployment should complete successfully, and the application should start without errors.

**Actual behavior:**  
Deployment stops with error message:  

Error: Failed to pull image

The app container does not start.

---

# Environment

- **Server OS:** Ubuntu 22.04 LTS
- **VPS Provider:** Hetzner
- **Dokploy Version:** v0.28.3
- **Docker Version:** 26.0.1

---

# Steps to Reproduce

1. Log in to the Dokploy dashboard at `https://dokploy.myvps.com`
2. Navigate to **Applications → MyApp**
3. Click **Deploy**
4. Wait for the deployment logs to appear
5. Observe error: "Failed to pull image"

---

# Screenshots

If applicable, add screenshots to help explain your problem:


[Upload screenshot here, e.g., dokploy-logs.png]


---

# Logs

Include relevant log output:


[2026-03-07 15:22:10] Pulling image myapp:latest...
[2026-03-07 15:22:11] Error: Failed to pull image


---

# Additional Context

- **Related services running:**
  - [x] Uptime Kuma
  - [x] Beszel
  - [ ] Umami
  - [ ] Other: None

- **Recent changes:**
  - [ ] System updates
  - [x] Configuration changes
  - [ ] New deployments
  - [ ] None

---

# Resolution Checklist

For maintainers to track progress:

- [ ] Investigated the issue
- [ ] Identified root cause
- [ ] Implemented fix
- [ ] Tested solution
- [ ] Updated documentation (if needed)

---

# How to Contribute

1. Fork the repository
2. Create a new branch (`git checkout -b fix/deployment-error`)
3. Make your changes
4. Test the fix (if applicable)
5. Commit and push your changes
6. Open a Pull Request

---

# Related Issues

- Related to #<!-- issue number -->

---

# Quick Links

- [Documentation](./docs)
- [Setup Guide](./docs/setup-guide.md)
- [Deployment Guide](./docs/deployment.md)
- [Monitoring Guide](./docs/monitoring.md)

---

**Thank you for helping improve this project!**
