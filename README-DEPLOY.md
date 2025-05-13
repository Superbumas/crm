# Deploying LT CRM to Fly.io

This guide provides step-by-step instructions for deploying the LT CRM application to Fly.io.

## Prerequisites

- A Fly.io account (sign up at [fly.io](https://fly.io/))
- Fly CLI installed (installed automatically by the scripts if not present)
- PowerShell 5.1 or higher

## Deployment Steps

### 1. Setup Project Structure

Ensure your project structure is correct:

```
D:/GitHub/crm/
├── Dockerfile              # Project root Dockerfile
├── fly.toml                # Project root fly.toml
├── setup-fly-infra.ps1     # Infrastructure setup script
├── setup-fly-secrets.ps1   # Secrets setup script
├── deploy-fly.ps1          # Deployment script
└── lt_crm/                 # Application code directory
    ├── app/
    ├── infra/
    ├── pyproject.toml
    └── ...
```

### 2. Setup Infrastructure

Run the infrastructure setup script:

```powershell
.\setup-fly-infra.ps1
```

This script will:
- Create a PostgreSQL database app on Fly.io
- Create a Redis instance on Fly.io
- Create a volume for persistent storage
- Attach the PostgreSQL database to your main app

### 3. Set Up Secrets

Run the secrets setup script:

```powershell
.\setup-fly-secrets.ps1
```

This script will:
- Generate a random secret key for your application
- Prompt you for your PostgreSQL password
- Prompt you for an optional Sentry DSN
- Set all necessary environment variables as secrets in Fly.io

### 4. Deploy the Application

Run the deployment script:

```powershell
.\deploy-fly.ps1
```

This script will:
- Verify that all necessary files exist
- Check if you're logged into Fly.io
- Deploy your application to Fly.io
- Check the status of your application

## Troubleshooting

### Error: Could not detect runtime or Dockerfile

If you receive an error about not being able to detect a runtime or Dockerfile, make sure you're running the scripts from the project root directory (where the Dockerfile and fly.toml files are located).

### Permission Denied Errors

If you encounter "Access is denied" errors when running the scripts, try running PowerShell as Administrator, or check file permissions.

### Deployment Fails

If deployment fails, check the logs:

```powershell
$env:USERPROFILE\.fly\bin\flyctl.exe logs
```

## Maintenance

### Viewing Logs

To view application logs:

```powershell
$env:USERPROFILE\.fly\bin\flyctl.exe logs
```

### Accessing the Console

To access an interactive console on your app:

```powershell
$env:USERPROFILE\.fly\bin\flyctl.exe ssh console
```

### Database Migrations

After deploying, you may need to run database migrations:

```powershell
$env:USERPROFILE\.fly\bin\flyctl.exe ssh console -C "flask db upgrade"
```

### Seeding Demo Data

To seed demo data after deployment:

```powershell
$env:USERPROFILE\.fly\bin\flyctl.exe ssh console -C "flask seed-demo"
```

## Additional Resources

- [Fly.io Documentation](https://fly.io/docs/)
- [PostgreSQL on Fly.io](https://fly.io/docs/postgres/)
- [Monitoring Applications on Fly.io](https://fly.io/docs/reference/metrics/) 