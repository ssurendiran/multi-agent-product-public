# Security

This document describes the security posture of the platform at a high level. Implementation details and sensitive configurations are maintained in the private repository.

## Security Overview

The platform implements multiple layers of security to protect user data, API endpoints, and infrastructure.

## Authentication & Authorization

### Public Endpoints

**Current Implementation**:
- **Basic Authentication**: Caddy reverse proxy with basic auth for protected services (Qdrant Dashboard)
- **No User Authentication**: Public API endpoints do not require user authentication
- **Rate Limiting**: IP-based rate limiting via Caddy

**Future Enhancements** (planned):
- OAuth 2.0 / JWT for user authentication
- Role-Based Access Control (RBAC)
- Multi-Factor Authentication (MFA) for admin users
- User-based rate limiting

### API Security

**Request Validation**:
- Pydantic schema validation for all requests
- Type checking and format validation
- Input sanitization

**Response Security**:
- No sensitive data in responses
- Structured output validation
- Error messages do not leak internal details

## Rate Limiting

### Implementation

**Caddy Reverse Proxy**:
- IP-based rate limiting
- Configurable limits per endpoint
- Automatic blocking of excessive requests

**Current Limits** (example):
- `/rag` endpoint: X requests per minute per IP
- `/submit_feedback` endpoint: X requests per minute per IP

**Future Enhancements**:
- User-based rate limiting (with authentication)
- Tiered rate limits (free vs paid users)
- Dynamic rate limiting based on load

## Secrets Management

### Current Implementation

**Environment Variables**:
- API keys stored in `.env` file (local development)
- Environment variables in production (GCP VM)
- Not committed to version control

**Secrets**:
- OpenAI API key
- Groq API key
- LangSmith API key
- PostgreSQL credentials
- Qdrant credentials

### Production Security

**GCP Secret Manager** (planned):
- Migration from environment variables to Secret Manager
- Automatic secret rotation
- Access control via IAM
- Audit logging

**Best Practices**:
- Secrets never logged or exposed in traces
- Secrets not included in error messages
- Secrets rotated regularly

## Data Security

### Data in Transit

**TLS/HTTPS**:
- All external traffic encrypted via TLS
- Caddy handles TLS termination
- Let's Encrypt certificates (automatic renewal)
- HTTPS-only in production

**Internal Communication**:
- Docker network isolation
- Service-to-service communication within private network
- No external exposure of internal services

### Data at Rest

**Database Encryption**:
- PostgreSQL data at rest (future: encryption at rest)
- Qdrant vector data at rest (future: encryption at rest)

**Backup Security**:
- Regular backups of PostgreSQL
- Backup encryption (planned)
- Secure backup storage (planned)

### Data Privacy

**User Data**:
- Conversation history stored per `thread_id`
- No personal identifiable information (PII) required
- Cart data stored per user session
- Data retention policies (to be defined)

**Observability Data**:
- Traces do not include full conversation content
- User feedback anonymized
- Metrics aggregated (no individual user tracking)

## Infrastructure Security

### Network Security

**Firewall Rules**:
- Only HTTPS (443) exposed externally
- Internal services not publicly accessible
- Database access restricted to application layer

**Docker Network**:
- Services isolated in Docker network
- No direct external access to databases
- Reverse proxy as single entry point

### Container Security

**Image Security**:
- Base images from official sources
- Regular updates for security patches
- Minimal attack surface (alpine-based images where possible)

**Runtime Security**:
- Containers run with non-root users (where possible)
- Resource limits configured
- No privileged containers

## API Security

### Input Validation

**Schema Validation**:
- All requests validated against Pydantic schemas
- Type checking (string, int, float, etc.)
- Format validation (URLs, emails, etc.)
- Length limits on input fields

**SQL Injection Prevention**:
- Parameterized queries (via SQLAlchemy/psycopg2)
- No raw SQL string concatenation
- Input sanitization

**Vector Injection Prevention**:
- Query embedding validation
- Vector dimension checks
- Collection name validation

### Output Security

**Response Sanitization**:
- No sensitive data in responses
- Error messages do not leak internal details
- Structured output validation

**CORS Configuration**:
- Currently permissive (`allow_origins=["*"]`)
- Future: Restrictive CORS for production
- Origin validation

## Monitoring & Incident Response

### Security Monitoring

**Current**:
- LangSmith tracing (performance, errors)
- Application logs
- Error rate monitoring

**Planned**:
- Security event logging
- Anomaly detection
- Intrusion detection
- Audit trails

### Incident Response

**Process** (to be defined):
1. Security incident detection
2. Immediate containment
3. Investigation and root cause analysis
4. Remediation
5. Post-incident review

**Contact**:
- Security issues: See [SECURITY.md](../SECURITY.md) for reporting

## Compliance Considerations

### Data Protection

**GDPR** (if applicable):
- User data deletion capabilities
- Data export capabilities
- Privacy policy (to be created)

**Data Retention**:
- Conversation history retention (to be defined)
- Cart data retention (to be defined)
- Trace data retention (to be defined)

### Audit & Compliance

**Audit Logging** (planned):
- All API access logged
- Admin actions logged
- Security events logged
- Compliance reporting

## Security Best Practices

### Development

**Code Security**:
- No secrets in code
- Input validation at all layers
- Error handling without information leakage
- Regular dependency updates

**Code Review**:
- Security-focused code reviews
- Automated security scanning (planned)
- Dependency vulnerability scanning (planned)

### Deployment

**Production Security**:
- Secrets in Secret Manager (planned)
- TLS/HTTPS enforced
- Rate limiting enabled
- Monitoring and alerting

**Regular Updates**:
- Security patches applied promptly
- Dependency updates
- Infrastructure updates

## Known Limitations

**Current Security Posture**:
- Basic authentication (not enterprise-grade)
- No user authentication on public API
- Secrets in environment variables (not Secret Manager)
- Permissive CORS (needs restriction)
- No encryption at rest (planned)

**Risk Mitigation**:
- Rate limiting prevents abuse
- Input validation prevents injection
- Network isolation limits attack surface
- Monitoring detects anomalies

## Future Security Enhancements

**Planned Improvements**:
1. **Authentication**: OAuth 2.0 / JWT implementation
2. **Secrets Management**: GCP Secret Manager migration
3. **Encryption**: Data at rest encryption
4. **Monitoring**: Security event logging and alerting
5. **Compliance**: GDPR compliance features
6. **Audit**: Comprehensive audit logging
7. **Testing**: Security testing and penetration testing
8. **Documentation**: Security runbooks and incident response procedures

## Security Contact

For security issues, see [SECURITY.md](../SECURITY.md) for reporting procedures.

