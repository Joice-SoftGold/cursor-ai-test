# DocuMind Azure Architecture

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          USERS                                  │
│                                                                 │
│  👤 Standard Users          👨‍💼 Administrators                    │
└────────────┬──────────────────────────┬─────────────────────────┘
             │                          │
             │         Internet         │
             │         (HTTPS)          │
             │                          │
┌────────────▼──────────────────────────▼─────────────────────────┐
│                   Azure Storage Static Website                  │
│  https://stdocumind[random].z13.web.core.windows.net           │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Static Website ($web container)                         │  │
│  │                                                          │  │
│  │  📄 login.html    (12 KB)                               │  │
│  │     └─ Entry point                                      │  │
│  │     └─ User authentication UI                           │  │
│  │     └─ Role selection (Standard/Admin)                  │  │
│  │                                                          │  │
│  │  📄 admin.html    (44 KB)                               │  │
│  │     └─ AI Search Console                                │  │
│  │     └─ Usage tracking & analytics                       │  │
│  │     └─ Data source integrations                         │  │
│  │     └─ User management                                  │  │
│  │     └─ Audit logs                                       │  │
│  │                                                          │  │
│  │  📄 user.html     (29 KB)                               │  │
│  │     └─ User portal                                      │  │
│  │     └─ AI-powered search                                │  │
│  │     └─ Document management                              │  │
│  │     └─ Chat interface                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Properties:                                                    │
│  • Storage Type: StorageV2                                     │
│  • Replication: LRS (Locally Redundant)                        │
│  • Tier: Standard                                              │
│  • Static Website: Enabled                                     │
│  • Index Document: login.html                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                   External Dependencies                         │
│                                                                 │
│  🌐 CDN Resources (loaded by browser):                         │
│     • Tailwind CSS (cdn.tailwindcss.com)                       │
│     • Lucide Icons (unpkg.com/lucide)                          │
└─────────────────────────────────────────────────────────────────┘
```

## Resource Hierarchy

```
Azure Subscription
└── Resource Group: rg-documind-static-website
    ├── Storage Account: stdocumind[random]
    │   ├── Static Website Configuration
    │   │   ├── Enabled: Yes
    │   │   ├── Index: login.html
    │   │   └── Error: login.html
    │   │
    │   └── $web Container (auto-created)
    │       ├── login.html (public)
    │       ├── admin.html (public)
    │       └── user.html (public)
    │
    └── Tags
        ├── environment: production
        └── project: DocuMind
```

## Data Flow

### 1. User Access Flow
```
User Browser
    │
    ├─→ GET https://.../login.html
    │       │
    │       ├─→ Load Tailwind CSS from CDN
    │       └─→ Load Lucide Icons from CDN
    │
    ├─→ User selects role (Standard/Admin)
    │
    ├─→ GET https://.../admin.html  (if Admin)
    │   OR
    └─→ GET https://.../user.html   (if Standard)
```

### 2. Deployment Flow
```
Local Machine
    │
    ├─→ Terraform Configuration (main.tf)
    │       │
    │       └─→ terraform apply
    │
    ├─→ Azure Provider Authentication
    │       │
    │       └─→ az login
    │
    └─→ Azure Resource Manager
            │
            ├─→ Create Resource Group
            ├─→ Create Storage Account
            ├─→ Enable Static Website
            ├─→ Upload login.html → $web
            ├─→ Upload admin.html → $web
            └─→ Upload user.html  → $web
```

## Component Details

### Frontend Components (Client-Side)

```
┌─────────────────────────────────────┐
│         login.html (12 KB)          │
├─────────────────────────────────────┤
│ • HTML5 structure                   │
│ • Tailwind CSS (CDN)                │
│ • Lucide Icons (CDN)                │
│ • JavaScript (inline)               │
│   ├─ Form validation                │
│   ├─ Role selection                 │
│   └─ Navigation logic               │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│         admin.html (44 KB)          │
├─────────────────────────────────────┤
│ • Modules:                          │
│   ├─ Usage Tracking                 │
│   │  ├─ Stats dashboard             │
│   │  └─ Charts (mock data)          │
│   ├─ Data Integrations              │
│   │  └─ Connection management       │
│   ├─ User Management                │
│   │  ├─ User CRUD                   │
│   │  ├─ Group management            │
│   │  └─ Role assignment             │
│   └─ Audit Logs                     │
│      └─ Activity tracking           │
│                                     │
│ • Mock Data (for demo):             │
│   ├─ mockUsers[]                    │
│   ├─ mockGroups[]                   │
│   ├─ mockAuditLogs[]                │
│   └─ usageData{}                    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│         user.html (29 KB)           │
├─────────────────────────────────────┤
│ • Modules:                          │
│   ├─ AI Search & Query              │
│   │  ├─ Natural language mode       │
│   │  ├─ Quick search mode           │
│   │  └─ Chat interface              │
│   ├─ Search History                 │
│   │  └─ Previous queries            │
│   └─ File Organizer                 │
│      ├─ File tree view              │
│      ├─ Upload interface            │
│      ├─ Drag & drop                 │
│      └─ Folder chat                 │
│                                     │
│ • Mock Data (for demo):             │
│   ├─ mockFileStructure[]            │
│   └─ mockChatHistory[]              │
└─────────────────────────────────────┘
```

## Infrastructure as Code

```terraform
main.tf
├─ Provider Configuration
│  └─ azurerm ~> 3.0
│
├─ Resources
│  ├─ azurerm_resource_group
│  ├─ azurerm_storage_account
│  ├─ random_string (naming)
│  ├─ azurerm_storage_blob (login)
│  ├─ azurerm_storage_blob (admin)
│  └─ azurerm_storage_blob (user)
│
└─ Outputs
   ├─ static_website_url
   ├─ login_page_url
   ├─ admin_page_url
   ├─ user_page_url
   ├─ storage_account_name
   └─ resource_group_name
```

## Technology Stack

### Frontend
- **HTML5**: Structure
- **Tailwind CSS**: Styling (CDN)
- **JavaScript**: Interactivity (vanilla JS, no frameworks)
- **Lucide Icons**: Icon library (CDN)

### Infrastructure
- **Azure Storage**: Static website hosting
- **Terraform**: Infrastructure as Code
- **Azure CLI**: Authentication & management

### Deployment
- **Terraform**: Automated deployment
- **Git**: Version control

## Network & Security

```
┌──────────────────────────────────────┐
│   Browser (User's Device)           │
└──────────────┬───────────────────────┘
               │
               │ HTTPS (Port 443)
               │ TLS 1.2+
               │
┌──────────────▼───────────────────────┐
│   Azure Edge Network                 │
│   (Content Delivery)                 │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│   Azure Storage Account              │
│   • Public access: Enabled           │
│   • HTTPS only: Enforced             │
│   • Anonymous read: $web only        │
└──────────────────────────────────────┘
```

## Scalability & Performance

| Metric | Value |
|--------|-------|
| **Storage Capacity** | Up to 5 PB |
| **Max file size** | Up to 195 GB per file |
| **Request throughput** | 20,000 requests/sec |
| **Bandwidth** | Unlimited (pay per GB) |
| **Global availability** | 99.9% SLA |
| **CDN support** | Optional (via Azure CDN) |

## Cost Breakdown

```
Monthly Cost Estimate (Low Traffic):

Storage:
  • 100 MB used × $0.02/GB = $0.002

Data Transfer:
  • 1 GB outbound (first 5 GB free) = $0.00

Transactions:
  • 10,000 read operations × $0.0004/10k = $0.004

Total: ~$0.01/month
```

## Disaster Recovery

```
┌──────────────────────────────────────┐
│   Local Backup Strategy              │
├──────────────────────────────────────┤
│ • Source files in Git                │
│ • Terraform state (backup)           │
│ • HTML files in workspace            │
└──────────────────────────────────────┘
           │
           │ Recovery Process
           ▼
┌──────────────────────────────────────┐
│   terraform apply                    │
│   (recreates all resources)          │
└──────────────────────────────────────┘
```

## Monitoring & Observability

```
Azure Storage Account
    │
    ├─→ Metrics (built-in)
    │   ├─ Request count
    │   ├─ Data egress
    │   ├─ Latency
    │   └─ Availability
    │
    └─→ Logs (optional)
        ├─ Storage Analytics
        └─ Azure Monitor integration
```

---

**Architecture Type**: Serverless Static Website
**Deployment Model**: Infrastructure as Code (Terraform)
**Hosting Provider**: Microsoft Azure
**Cost Model**: Pay-as-you-go (consumption-based)
