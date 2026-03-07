# Monitoring Guide

Comprehensive guide to setting up and configuring monitoring tools for your production VPS.

## Overview

This guide covers three monitoring tools installed in our stack:

1. **Uptime Kuma** - Service uptime monitoring
2. **Beszel** - Server resource monitoring
3. **Umami** - Web analytics

## Uptime Kuma

### Accessing Uptime Kuma

- **URL**: `https://uptime.yourdomain.com`
- **Initial Setup**: Create admin account on first login

### Adding Your First Monitor

1. Click "+" button to add a monitor
2. Configure the following:

```yaml
Monitor Name: My Application
URL: https://app.yourdomain.com
Monitoring Type: HTTP(s)
Heartbeat Interval: 60 seconds
Timeout: 30 seconds
Retries: 3
```

### Monitor Types

#### HTTP(s) Monitor

Best for web applications and APIs:

```yaml
Type: HTTP(s)
URL: https://api.yourdomain.com/health
Method: GET
Expected Status Code: 200
SSL Expiry Notification: 30 days before expiry
```

#### TCP Port Monitor

Monitor services by port:

```yaml
Type: TCP
Hostname: localhost
Port: 5432
```

#### Ping Monitor

Simple ICMP monitoring:

```yaml
Type: Ping
Hostname: yourserver.com
```

#### Keyword Monitor

Check for specific content:

```yaml
Type: HTTP(s)
URL: https://yourdomain.com
Keyword: "Welcome"
```

### Alerting Setup

#### Discord Webhook

```json
{
  "content": null,
  "embeds": [
    {
      "title": "🔴 Service Down",
      "description": "{msg}",
      "color": 16711680,
      "fields": [
        {
          "name": "Monitor",
          "value": "{name}"
        },
        {
          "name": "URL",
          "value": "{url}"
        },
        {
          "name": "Time",
          "value": "{time}"
        }
      ]
    }
  ]
}
```

#### Telegram Notification

1. Create a Telegram bot via @BotFather
2. Get your chat ID
3. Configure in Uptime Kuma > Settings > Notifications

```yaml
Bot Token: your-bot-token
Chat ID: your-chat-id
```

### Status Pages

Create a public status page:

1. Go to "Status Pages"
2. Click "Add Status Page"
3. Configure title and description
4. Add monitors to display
5. Customize with your branding

### Best Practices

- Set heartbeat interval to 60 seconds for critical services
- Use keyword monitoring for API health checks
- Configure multiple alert channels
- Create separate status pages for different service groups

## Beszel

### Accessing Beszel

- **URL**: `https://beszel.yourdomain.com`
- **Default Port**: 3003

### Adding Your First Server

1. Click "Add Server"
2. Enter server details:

```yaml
Name: Production VPS
Hostname: yourserver.com
SSH Port: 22
SSH Key: (paste private key)
```

### Metrics Monitored

Beszel collects:

| Metric                   | Description                     |
| ------------------------ | ------------------------------- | -------------- |
| CPU Usage                | Percentage of CPU utilization   |
| Memory                   | RAM usage in GB/percentage      |
| Disk                     | Storage usage per mount         | Incoming point |
| Network/outgoing traffic |
| Load Average             | System load over 1/5/15 minutes |
| Processes                | Top processes by CPU/memory     |
| Docker                   | Container resource usage        |

### Docker Integration

Enable Docker monitoring:

```bash
# Add Docker socket access to Beszel
docker run -d \
  --name beszel-agent \
  -v /var/run/docker.sock:/var/run/docker.sock \
  henrywhittaker/beszel-agent:latest
```

Configure in Beszel UI to collect Docker metrics.

### Alerts

Configure alerts in Settings > Alerts:

```yaml
CPU Usage > 80% for 5 minutes
Memory Usage > 90% for 5 minutes
Disk Usage > 85% for 5 minutes
```

### Agent Installation (Alternative)

For additional servers:

```bash
# Install Beszel agent
curl -L https://get.beszel.dev | bash
```

## Umami Analytics

### Accessing Umami

- **URL**: `https://umami.yourdomain.com`
- **Default Credentials**: Created during setup

### Adding Your First Website

1. Click "+" to add website
2. Configure:

```yaml
Name: My Website
Domain: yourdomain.com
Enable JS Tracking: Yes
```

### Tracking Code

Umami provides a tracking script:

```html
<script
  defer
  async
  src="https://umami.yourdomain.com/script.js"
  data-website-id="your-website-id"
></script>
```

### For React/Next.js

Install npm package:

```bash
npm install @umami/react
```

Add to your app:

```jsx
import UmamiProvider from "@umami/react";

function App() {
  return (
    <UmamiProvider
      websiteId="your-website-id"
      url="https://umami.yourdomain.com"
    >
      <YourApp />
    </UmamiProvider>
  );
}
```

### For PHP/Laravel

Add to your layout blade file:

```php
<script defer async src="https://umami.yourdomain.com/script.js" data-website-id="{{ env('UMAMI_WEBSITE_ID') }}"></script>
```

### Events

Track custom events:

```javascript
umami.track(); // Page view (automatic)
umami.track("signup"); // Custom event
umami.track("button_click", { id: "hero-button" }); // With properties
```

### Dashboards

View analytics in the Umami dashboard:

- **Realtime**: Live visitor count
- **Overview**: Key metrics and trends
- **Visitors**: Visitor geography and devices
- **Behavior**: Page views and events
- **Referrers**: Traffic sources

### Data Export

Export data from Settings > Data:

- Export to CSV
- Export to Excel
- Date range selection

### Privacy

Umami is GDPR compliant:

- No cookie consent required
- No personal data stored
- IP addresses anonymized
- No cross-site tracking

## Integrated Dashboard

Create a comprehensive monitoring overview:

```markdown
## System Status

### Uptime

- Production API: ✅ Online
- Web Application: ✅ Online
- Database: ✅ Online

### Resources

- CPU: 45%
- Memory: 6.2GB / 8GB
- Disk: 78GB / 160GB

### Analytics (Last 30 Days)

- Total Visits: 15,432
- Unique Visitors: 8,234
- Bounce Rate: 42%
```

## Alerting Strategy

### Critical Alerts (Immediate)

- Service down
- Server unreachable
- Disk space critical (>95%)

### Warning Alerts (15 min delay)

- High CPU (>80%)
- High memory (>90%)
- SSL certificate expiring (<14 days)

### Info Alerts (Daily digest)

- Traffic spikes
- New referrers
- Analytics summary

## Grafana Integration

For advanced visualization:

1. Install Grafana:

   ```bash
   docker run -d --name grafana -p 3004:3000 grafana/grafana
   ```

2. Add data sources:
   - Beszel (via Prometheus)
   - Uptime Kuma (via API)
   - Umami (via API)

## Troubleshooting

### Uptime Kuma Issues

**Notifications not sending:**

- Check webhook configuration
- Verify network connectivity
- Check Uptime Kuma logs

### Beszel Issues

**No data showing:**

- Verify SSH connectivity
- Check agent status
- Review agent logs

### Umami Issues

**No tracking data:**

- Verify script is loading
- Check browser console for errors
- Confirm website ID matches

## Maintenance

### Backup Uptime Kuma

```bash
docker stop uptime-kuma
docker cp uptime-kuma:/app/data backup/
docker start uptime-kuma
```

### Backup Beszel

```bash
docker cp beszel:/app/data backup/beszel-data/
```

### Backup Umami

```bash
docker stop umami
docker cp umami-db:/var/lib/postgresql/data backup/umami-db/
docker start umami
```

## Next Steps

- Configure all your applications with Uptime Kuma
- Set up Beszel on all your servers
- Add tracking code to all your websites
- Review [Architecture](./architecture.md) for system details
