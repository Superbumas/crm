# LT CRM - Lithuanian Customer Relationship Management

![License](https://img.shields.io/badge/license-MIT-blue.svg)

A comprehensive CRM system for Lithuanian businesses, featuring product management, order processing, and invoicing.

## Features

- **Product Management**: Add, edit, and manage products with pricing, stock levels, and variants
  - **Customizable Columns**: Personalize the product list view by selecting which columns to display
- **Order Processing**: Create and track customer orders from placement to fulfillment
- **Invoice Generation**: Automatically generate invoices for orders and track payment status
- **Customer Database**: Manage customer information and communication history
- **User Authentication**: Secure login and role-based access control
- **Localization**: Fully localized for the Lithuanian market (language, tax rates, etc.)
- **RESTful API**: Comprehensive API for integration with other systems
- **GDPR Compliance**: Tools for GDPR data export and deletion

## Technology Stack

- **Backend**: Flask (Python)
- **Database**: PostgreSQL
- **Task Queue**: Celery with Redis
- **Frontend**: Tailwind CSS, DaisyUI
- **Containerization**: Docker, Docker Compose
- **CI/CD**: GitHub Actions, Fly.io
- **Monitoring**: Sentry, Prometheus

## Setup and Installation

### Local Development Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/lt-crm.git
   cd lt-crm
   ```

2. Set up a virtual environment (recommended):
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install poetry
   poetry install
   ```

4. Set up environment variables:
   ```
   cp .env.example .env
   # Edit .env with your settings
   ```

5. Initialize the database:
   ```
   flask db upgrade
   flask setup-accounts
   ```

6. Seed demo data (optional):
   ```
   flask seed-demo
   ```

7. Run the development server:
   ```
   flask run
   ```

### Docker Deployment

1. Build and start the containers:
   ```
   cd infra
   docker-compose up -d
   ```

2. Initialize the database (first time only):
   ```
   docker-compose exec web flask db upgrade
   docker-compose exec web flask setup-accounts
   ```

## Production Deployment

### Fly.io Deployment

1. Install the Fly.io CLI:
   ```
   curl -L https://fly.io/install.sh | sh
   ```

2. Authenticate with Fly.io:
   ```
   fly auth login
   ```

3. Set up secrets:
   ```
   ./infra/deployment_scripts/setup_fly_secrets.sh
   ```

4. Deploy the application:
   ```
   fly deploy
   ```

### LetsEncrypt SSL Setup

For production deployments with Docker Compose:

1. Update domain settings in `infra/nginx/conf.d/app.conf`
2. Set your email and domain in `infra/certbot-renew.sh`
3. Run the certificate renewal script:
   ```
   cd infra
   ./certbot-renew.sh
   ```
4. Set up a cron job to automatically renew certificates:
   ```
   0 3 * * * /path/to/lt-crm/infra/certbot-renew.sh >> /path/to/lt-crm/infra/certbot-cron.log 2>&1
   ```

## GDPR Utilities

### Export User Data
To export a user's data (for GDPR compliance):
```
flask export-user-data USER_ID
```
This will create a ZIP file with all user data in JSON format.

### Delete/Anonymize User Data
To delete and anonymize a user's data:
```
flask delete-user-data USER_ID [--no-export] [--confirm]
```

## Monitoring and Security

### Security Features
- **CSP Headers**: Configured via Flask-Talisman
- **HTTPS Enforcement**: Redirects all HTTP traffic to HTTPS
- **Rate Limiting**: Prevents abuse of API endpoints
- **Secure Session Management**: HTTP-only, secure cookies

### Monitoring
- **Sentry Integration**: Real-time error tracking
- **Prometheus Metrics**: Performance monitoring (available at `/metrics`)
- **Health Checks**: System health endpoints (available at `/health`)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

Before deploying to production, check all items in our [QA Checklist](docs/qa_checklist.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details. 