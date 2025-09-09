# Email Configuration Examples for Alertmanager

Este arquivo contém exemplos de configuração de email para diferentes provedores.

## 📧 Gmail Configuration

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'  # Use App Password, not regular password
  smtp_require_tls: true
```

**Nota**: Para Gmail, você precisa:
1. Ativar autenticação de dois fatores
2. Criar uma "App Password" específica para Alertmanager
3. Usar a App Password no campo `smtp_auth_password`

## 📧 Outlook/Hotmail Configuration

```yaml
global:
  smtp_smarthost: 'smtp-mail.outlook.com:587'
  smtp_from: 'your-email@outlook.com'
  smtp_auth_username: 'your-email@outlook.com'
  smtp_auth_password: 'your-password'
  smtp_require_tls: true
```

## 📧 Yahoo Configuration

```yaml
global:
  smtp_smarthost: 'smtp.mail.yahoo.com:587'
  smtp_from: 'your-email@yahoo.com'
  smtp_auth_username: 'your-email@yahoo.com'
  smtp_auth_password: 'your-app-password'  # Use App Password
  smtp_require_tls: true
```

## 📧 Custom SMTP Server

```yaml
global:
  smtp_smarthost: 'smtp.yourdomain.com:587'
  smtp_from: 'alerts@yourdomain.com'
  smtp_auth_username: 'alerts@yourdomain.com'
  smtp_auth_password: 'your-password'
  smtp_require_tls: true
  smtp_hello: 'yourdomain.com'
```

## 📧 Local SMTP (Testing)

```yaml
global:
  smtp_smarthost: 'localhost:1025'
  smtp_from: 'alertmanager@localhost'
  smtp_require_tls: false
```

Para testar localmente, você pode usar o MailHog:
```bash
docker run -d -p 1025:1025 -p 8025:8025 mailhog/mailhog
```

## 💡 Email Receiver Examples

### Simple Email Alert
```yaml
- name: 'email-alerts'
  email_configs:
  - to: 'admin@example.com'
    subject: '🚨 Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Status: {{ .Status }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Instance: {{ .Labels.instance }}
      Severity: {{ .Labels.severity }}
      Time: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
      {{ end }}
```

### HTML Email Alert
```yaml
- name: 'html-email-alerts'
  email_configs:
  - to: 'admin@example.com'
    subject: '🚨 Alert: {{ .GroupLabels.alertname }}'
    html: |
      <html>
      <body>
        <h2>Alert Notification</h2>
        <table border="1" style="border-collapse: collapse;">
          <tr><th>Field</th><th>Value</th></tr>
          {{ range .Alerts }}
          <tr><td>Status</td><td>{{ .Status }}</td></tr>
          <tr><td>Alert</td><td>{{ .Annotations.summary }}</td></tr>
          <tr><td>Description</td><td>{{ .Annotations.description }}</td></tr>
          <tr><td>Instance</td><td>{{ .Labels.instance }}</td></tr>
          <tr><td>Severity</td><td>{{ .Labels.severity }}</td></tr>
          <tr><td>Time</td><td>{{ .StartsAt.Format "2006-01-02 15:04:05" }}</td></tr>
          {{ end }}
        </table>
      </body>
      </html>
```

### Multiple Recipients
```yaml
- name: 'team-alerts'
  email_configs:
  - to: 'admin1@example.com'
    cc: 'admin2@example.com'
    bcc: 'manager@example.com'
    subject: 'Team Alert: {{ .GroupLabels.alertname }}'
    body: |
      Team notification for {{ .GroupLabels.alertname }}
      
      {{ range .Alerts }}
      - {{ .Annotations.summary }}
      {{ end }}
```

## 🔐 Security Best Practices

1. **Use App Passwords**: Para Gmail/Yahoo, sempre use App Passwords
2. **Environment Variables**: Store credentials em variáveis de ambiente
3. **TLS/SSL**: Sempre ative `smtp_require_tls: true` para produção
4. **Least Privilege**: Crie contas específicas para alertas
5. **Rate Limiting**: Configure adequadamente os intervalos de envio

## 🧪 Testing Email Configuration

### Test with swaks (SMTP test tool)
```bash
# Install swaks
sudo apt-get install swaks  # Ubuntu/Debian
brew install swaks          # macOS

# Test SMTP connection
swaks --to admin@example.com \
      --from alerts@yourdomain.com \
      --server smtp.yourdomain.com:587 \
      --auth LOGIN \
      --auth-user alerts@yourdomain.com \
      --auth-password your-password \
      --tls
```

### Test Alertmanager email
```bash
# Send test alert
curl -XPOST http://localhost:9093/api/v1/alerts -H 'Content-Type: application/json' -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "instance": "localhost:9090"
    },
    "annotations": {
      "summary": "This is a test alert",
      "description": "Testing email configuration"
    },
    "startsAt": "'$(date -Iseconds)'",
    "endsAt": "'$(date -d '+5 minutes' -Iseconds)'"
  }
]'
```

## 🔧 Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Check username/password
   - For Gmail/Yahoo: use App Password
   - Check 2FA settings

2. **Connection Timeout**
   - Verify SMTP server and port
   - Check firewall settings
   - Verify TLS/SSL settings

3. **TLS Errors**
   - Try with `smtp_require_tls: false` for testing
   - Check certificate validity
   - Verify SMTP server supports STARTTLS

4. **Email Not Delivered**
   - Check spam folder
   - Verify recipient email address
   - Check SMTP server logs
   - Verify sender reputation

### Debug Commands
```bash
# Check Alertmanager logs
docker compose logs alertmanager | grep -i smtp

# Test connectivity
telnet smtp.gmail.com 587

# Check TLS
openssl s_client -connect smtp.gmail.com:587 -starttls smtp
```
