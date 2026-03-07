# Architecture Diagram

This folder should contain system architecture diagrams.

## Required Images

### 1. architecture.png

A comprehensive diagram showing:

- Hetzner VPS as the host
- Docker container runtime
- Traefik reverse proxy
- All services (Dokploy, Uptime Kuma, Beszel, Umami)
- Network flow and port mappings
- Data flow between components

## Recommended Tools

- **Draw.io / diagrams.net**: Free online diagramming tool
- **Lucidchart**: Professional diagramming
- **Mermaid**: Markdown-based diagrams (see ../diagrams/)
- **Excalidraw**: Hand-drawn style diagrams

## Diagram Guidelines

1. Use consistent color scheme
2. Include all network connections
3. Label all components
4. Show data flow direction
5. Include port numbers

## Example Diagram Structure

```
┌─────────────────────────────────────────────┐
│              Internet                        │
└────────────────────┬────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│           Traefik (Reverse Proxy)            │
│        Ports: 80, 443, 8080                  │
└────────────────────┬────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
         ▼           ▼           ▼
┌─────────────┐ ┌─────────┐ ┌────────────┐
│  Dokploy    │ │  Umami  │ │ Uptime Kuma│
│  Port:3000  │ │ Port:3001│ │ Port:3002  │
└─────────────┘ └─────────┘ └────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│          Docker Daemon                       │
│     Container Runtime                        │
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│         Hetzner VPS (Ubuntu)                 │
└─────────────────────────────────────────────┘
```

## Create Your Own

1. Visit https://app.diagrams.net/
2. Create new diagram
3. Export as PNG
4. Save in this folder as `architecture.png`
