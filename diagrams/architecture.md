# Architecture Diagram

This folder contains architecture diagrams in Mermaid format and other diagram definitions.

## Mermaid Architecture Diagram

```mermaid
flowchart TB
    subgraph INTERNET["Internet"]
        USER["User Browser"]
    end

    subgraph VPS["Hetzner VPS"]
        subgraph DOCKER["Docker Runtime"]
            TRAEFIK["Traefik<br/>Reverse Proxy<br/>Ports: 80, 443"]

            subgraph SERVICES["Managed Services"]
                DOKPLOY["Dokploy<br/>Port: 3000"]
                UPTIME["Uptime Kuma<br/>Port: 3002"]
                BESZEL["Beszel<br/>Port: 3003"]
            end

            subgraph APPS["User Applications"]
                WEBAPP["Web Application<br/>Port: 3000"]
                API["API Service<br/>Port: 3001"]
            end

            UMAMI["Umami<br/>Port: 3001"]
        end

        OS["Ubuntu 22.04 LTS"]
        FIREWALL["UFW Firewall"]
    end

    DNS["DNS Server"]
    GIT["Git Repository"]

    %% Connections
    USER -->|HTTPS Request| TRAEFIK
    TRAEFIK -->|Route by Hostname| DOKPLOY
    TRAEFIK -->|Route| UMAMI
    TRAEFIK -->|Route| UPTIME
    TRAEFIK -->|Route| BESZEL
    TRAEFIK -->|Route| WEBAPP
    TRAEFIK -->|Route| API

    DOKPLOY -->|Deploy| WEBAPP
    DOKPLOY -->|Deploy| API

    DNS -->|Resolve| USER
    GIT -->|Push Code| DOKPLOY

    %% Styling
    classDef service fill:#3498db,color:#fff,stroke:#2980b9
    classDef app fill:#27ae60,color:#fff,stroke:#229954
    classDef infrastructure fill:#95a5a6,color:#fff,stroke:#7f8c8d

    class TRAEFIK,DOKPLOY,UPTIME,BESZEL,UMAMI service
    class WEBAPP,API app
    class OS,FIREWALL,DOCKER,DNS infrastructure
```

## Network Flow Diagram

```mermaid
sequenceDiagram
    participant User as User Browser
    participant DNS as DNS
    participant Traefik as Traefik
    participant App as Application
    participant Docker as Docker
    participant DB as Database

    User->>DNS: Resolve domain
    DNS-->>User: Return IP

    User->>Traefik: HTTPS Request (443)
    Traefik->>Traefik: Check SSL Certificate

    alt Certificate exists
        Traefik->>App: Forward Request
        App->>Docker: Process Request
        Docker->>DB: Query Data
        DB-->>Docker: Return Data
        Docker-->>App: Response
        App-->>Traefik: HTTP Response
        Traefik-->>User: HTTPS Response
    else No certificate
        Traefik->>Traefik: Let's Encrypt Request
        Traefik-->>User: Redirect to HTTPS
    end
```

## Component Architecture

```mermaid
flowchart LR
    subgraph FRONTEND["Frontend Layer"]
        TRAEFIK[Traefik Reverse Proxy]
        SSL[SSL/TLS]
    end

    subgraph MIDDLE["Application Layer"]
        DOKPLOY[Dokploy]
        APPS[Your Applications]
    end

    subgraph BACKEND["Data Layer"]
        POSTGRES[(PostgreSQL)]
        REDIS[(Redis)]
        DOCKER[Docker Storage]
    end

    subgraph MON["Monitoring Layer"]
        KUMA[Uptime Kuma]
        BESZEL[Beszel]
        UMAMI[Umami Analytics]
    end

    FRONTEND --> MIDDLE
    MIDDLE --> BACKEND
    MIDDLE --> MON
```

## Deployment Pipeline

```mermaid
flowchart TB
    subgraph DEVELOPER["Developer"]
        CODE[Write Code]
        TEST[Local Test]
        COMMIT[Git Commit]
    end

    subgraph GIT["Git Platform"]
        REPO[Repository]
        PUSH[Push to Remote]
    end

    subgraph VPS["VPS - Dokploy"]
        BUILD[Build Image]
        DEPLOY[Deploy Container]
        VERIFY[Health Check]
    end

    subgraph MONITOR["Monitoring"]
        UPTIME[Uptime Kuma]
        ALERT[Send Alert]
    end

    CODE --> TEST
    TEST --> COMMIT
    COMMIT --> PUSH
    PUSH --> REPO
    REPO --> BUILD
    BUILD --> DEPLOY
    DEPLOY --> VERIFY
    VERIFY --> UPTIME
    UPTIME -->|Down| ALERT
```

## Server Resource Diagram

```mermaid
pie title Server Resource Allocation
    "Docker System" : 15
    "Traefik" : 5
    "Dokploy" : 10
    "Uptime Kuma" : 3
    "Beszel" : 2
    "Umami + PostgreSQL" : 8
    "Your Applications" : 40
    "Available" : 17
```

## Monitoring Architecture

```mermaid
flowchart TB
    subgraph MONITORING["Monitoring Stack"]
        UPTIME["Uptime Kuma"]
        BESZEL["Beszel"]
        UMAMI["Umami"]
    end

    subgraph TARGETS["Monitored Targets"]
        APPS["Applications"]
        SERVER["Server Resources"]
        WEBSITE["Websites"]
    end

    subgraph ALERTS["Alert Channels"]
        DISCORD["Discord"]
        TELEGRAM["Telegram"]
        EMAIL["Email"]
    end

    UPTIME --> APPS
    UPTIME --> ALERTS

    BESZEL --> SERVER
    BESZEL --> ALERTS

    UMAMI --> WEBSITE
```

## Customizing Diagrams

You can render these diagrams using:

1. **VS Code**: Install "Mermaid Preview" extension
2. **Online**: Visit [Mermaid Live Editor](https://mermaid.live)
3. **GitHub**: Add to README.md directly (GitHub renders Mermaid)

## Exporting

To export as PNG:

1. Open [Mermaid Live Editor](https://mermaid.live)
2. Paste diagram code
3. Click "Download PNG"
