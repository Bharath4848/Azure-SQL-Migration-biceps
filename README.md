# Azure-SQL-Migration-biceps
# 🚀 Azure SQL Server Migration – Bicep Templates

This repository contains **modular, production-ready Azure Bicep templates** designed to automate the infrastructure deployment for SQL Server migration projects. It provides everything needed to create and manage resources like Virtual Networks, SQL Managed Instances, Private DNS Zones, Private Endpoints, and Storage Accounts using CI/CD pipelines.

> 💡 It supports both **Dev** and **Prod** environments with separate parameter files and flexible deployments via Azure CLI or DevOps pipelines.

---

## 📂 Repository Structure

```text
azure-sql-migration-bicep/
├── bicep/
│   ├── main.bicep                      # Entry point for deployments
│   └── modules/                        # Modular, reusable Bicep templates
│       ├── Vnet.bicep
│       ├── sqlmi.bicep
│       ├── dnsZones.bicep
|       ├── storageAccount.bicep
│       └── privateEndpoints.bicep
├── variables/                          # Parameter files per environment
│   ├── dev-config.yml
│   └── prd-config.yml
├── pipelines/                          # Azure DevOps pipeline definition
│   └── azure-pipelines.yml
├── .github/                            # (Optional) GitHub Actions workflows
│   └── workflows/
│       └── deploy.yml
├── .gitignore
├── LICENSE
├── CONTRIBUTING.md
└── README.md
```

---

##  🤝 Contributing

We welcome contributions to improve this project! Whether it's fixing bugs, adding new features, improving documentation, or providing examples, your help is appreciated.

##  🧱 Code Contributions

Fork the repository

Create a new branch: git checkout -b feature/your-feature-name

Make your changes with clear, modular commits

Run any relevant tests or validation (e.g., Bicep linting)

Submit a Pull Request (PR) to the main branch

## ✅ PR Requirements

All pull requests must:

Be reviewed and approved by at least one reviewer (see PR Review section below)

Pass all CI checks (if defined, e.g., Azure pipelines or GitHub Actions)

Follow consistent formatting and naming conventions

Please include a description of the change and why it’s needed

## 🔍 Pull Request Reviews

To maintain code quality and consistency:

PRs must be reviewed before merging

Approvers should:

Validate that templates are clean, modular, and production-ready

Ensure secrets are not hardcoded and Key Vault is used

Confirm deployment compatibility with both Dev and Prod

## 🛠️ Development Tips

Use the Bicep Linter for static analysis

Test deployments using az deployment sub create before pushing

Keep modules small, composable, and reusable

## 📁 Directory Guidelines

All reusable modules go inside bicep/modules/

Environment-specific parameters go into variables/

Keep main.bicep clean by importing modules

Store CI pipeline YAML in pipelines/

🧾 License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for helping us build something great! 🙌

