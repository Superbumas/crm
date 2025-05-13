# LT CRM - QA Deployment Checklist

This document provides a comprehensive checklist for ensuring quality and security when deploying the LT CRM application.

## 1. Pre-Deployment Checks

### Database
- [ ] Run migrations and verify they apply cleanly: `flask db upgrade`
- [ ] Verify database backups are in place and working
- [ ] Test that database rollback procedures work if needed

### Security
- [ ] Verify all environment variables are set and not using defaults
- [ ] Audit all exposed API endpoints for proper authentication
- [ ] Confirm CSP headers are properly configured
- [ ] Check that user session management is secure
- [ ] Verify all resources require appropriate permissions

### Performance
- [ ] Run performance tests to establish baseline metrics
- [ ] Verify database query performance and optimize slow queries
- [ ] Check for N+1 query patterns in ORM usage
- [ ] Validate memory usage under expected load

### GDPR Compliance
- [ ] Test GDPR data export functionality: `flask export-user-data USER_ID`
- [ ] Verify GDPR data deletion works correctly: `flask delete-user-data USER_ID`
- [ ] Ensure all PII is properly protected in logs and error reports

## 2. Deployment Process

### Environment Setup
- [ ] Verify Fly.io secrets are properly configured using `setup_fly_secrets.sh`
- [ ] Confirm proper environment separation (dev/staging/prod)
- [ ] Check that production environment has debug mode disabled

### Deployment Steps
- [ ] Run CI/CD pipeline tests and confirm passing status
- [ ] Deploy to staging environment first
- [ ] Verify staging deployment functions correctly
- [ ] Schedule production deployment with appropriate stakeholders
- [ ] Back up production database before deployment
- [ ] Execute deployment to production
- [ ] Monitor logs during deployment for errors

## 3. Post-Deployment Verification

### Functionality
- [ ] Verify login and user authentication works
- [ ] Test core business workflows (order creation, product management)
- [ ] Validate integrations with external systems
- [ ] Test frontend functionality across supported browsers

### Security
- [ ] Run security scan on the deployed application
- [ ] Verify TLS/SSL configuration using SSL Labs test
- [ ] Check HTTP security headers using Security Headers test
- [ ] Verify rate limiting is working properly

### Monitoring
- [ ] Confirm Sentry error tracking is capturing data correctly
- [ ] Verify Prometheus metrics endpoint is accessible and secure
- [ ] Test alerting mechanisms for critical errors
- [ ] Validate that health check endpoints return correct status

## 4. Rollback Plan

### Triggers for Rollback
- [ ] Critical security vulnerability discovered
- [ ] Major functionality broken
- [ ] Performance degradation beyond acceptable thresholds

### Rollback Process
- [ ] Execute database rollback if schema changes were made
- [ ] Deploy previous version of the application
- [ ] Verify core functionality after rollback
- [ ] Communicate rollback to stakeholders

## 5. Final Approval

- [ ] Product Owner sign-off
- [ ] Technical Lead sign-off
- [ ] Security review sign-off
- [ ] Performance benchmarks reviewed and accepted

---

**Date Completed:** ________________

**Performed By:** ________________

**Signed Off By:** ________________ 