# Docker Monitoring Stack

A comprehensive monitoring solution for Docker containers using Nginx, Prometheus, Grafana, Node Exporter, and cAdvisor.

## Overview

This project provides a complete monitoring stack that collects and visualizes metrics from your Docker environment. It includes:

- **Nginx**: Reverse proxy serving all services on a single entry point
- **Prometheus**: Time-series database for metrics collection and storage
- **Grafana**: Visualization and dashboarding platform
- **Node Exporter**: Collects system-level metrics (CPU, memory, disk, network)
- **cAdvisor**: Collects Docker container-level metrics
- **Pre-built Dashboard**: Ready-to-use dashboard showing system and container metrics

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              User (Browser)                         │
└───────────────────┬─────────────────────────────────┘
                    │ :80
┌───────────────────▼─────────────────────────────────┐
│            Nginx (Reverse Proxy)                    │
├─────────────────────────────────────────────────────┤
│ /grafana*  → Grafana:3000                           │
│ /prometheus* → Prometheus:9090                      │
│ /health    → Health Check                           │
└┬──────────────────────┬───────────────┬─────────────┘
 │                      │               │
 ▼                      ▼               ▼
Grafana            Prometheus         Internal Services
:3000              :9090              (Node Exporter, cAdvisor)
  │                   │
  │                   ├──→ Scrapes → Node Exporter :9100
  │                   │
  │                   └──→ Scrapes → cAdvisor :8080
  │
  └─→ Queries

┌─────────────────────────────────────────────────────┐
│         Docker Host & Containers                    │
│                                                     │
│ Node Exporter: System metrics                       │
│ cAdvisor: Container metrics                         │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

- Docker (version 19.03 or later)
- Docker Compose (version 1.25 or later)
- Linux kernel 4.3+ (for full cAdvisor support)
- At least 2GB RAM available

## Quick Start

### Option 1: Using the initialization script

```bash
chmod +x scripts/init.sh
./scripts/init.sh
```

### Option 2: Manual startup

```bash
docker-compose up -d
```

### Access the Services

Once running, access the monitoring stack:

- **Grafana Dashboard**: http://localhost/grafana
- **Prometheus UI**: http://localhost/prometheus
- **Health Check**: http://localhost/health

## Default Credentials

- **Grafana**
  - Username: `admin`
  - Password: `admin` (change on first login!)

## Configuration

### Environment Variables

Edit the `.env` file to customize the deployment:

```env
# Grafana
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin

# Prometheus
PROMETHEUS_RETENTION_DAYS=30
PROMETHEUS_SCRAPE_INTERVAL=15s
PROMETHEUS_EVALUATION_INTERVAL=10s

# Service Ports
NGINX_PORT=80
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
```

### Prometheus Configuration

Edit `prometheus/prometheus.yml` to:
- Change scrape intervals
- Add new scrape targets
- Configure alerting rules

### Nginx Configuration

Edit `nginx/nginx.conf` to:
- Change routing rules
- Add SSL/TLS certificates
- Modify proxy settings

### Grafana Provisioning

Modify `grafana/provisioning/` to:
- Add custom datasources
- Add custom dashboards
- Configure authentication

## Common Tasks

### View Container Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
docker-compose logs -f prometheus
docker-compose logs -f nginx
```

### Stop the Stack

```bash
docker-compose stop
```

### Stop and Remove All Data

```bash
docker-compose down -v
```

### Restart a Service

```bash
docker-compose restart [service-name]
```

### Rebuild Images

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Monitoring Metrics

### System Metrics (from Node Exporter)
- CPU usage and load
- Memory usage
- Disk space and I/O
- Network traffic
- System uptime

### Docker Metrics (from cAdvisor)
- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O

### Application Metrics (from Prometheus)
- Prometheus scrape success rate
- Grafana uptime and performance

## Grafana Dashboard

The pre-built dashboard includes:

1. **CPU Usage** - System CPU utilization percentage
2. **Memory Usage** - System memory utilization percentage
3. **Disk Usage** - Root filesystem utilization percentage
4. **Container Memory** - Individual container memory usage
5. **Running Containers** - Pie chart of active containers
6. **Network I/O** - System network receive traffic

### Creating Custom Dashboards

1. Log in to Grafana at http://localhost/grafana
2. Click "Create" → "Dashboard"
3. Add panels with PromQL queries
4. Save the dashboard

### Example PromQL Queries

```promql
# CPU usage percentage (5-minute average)
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage percentage
(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100

# Container memory usage
container_memory_usage_bytes

# Network bytes received (5-minute rate)
rate(node_network_receive_bytes_total[5m])
```

## Troubleshooting

### Services won't start

```bash
# Check logs
docker-compose logs

# Verify Docker daemon is running
docker ps

# Rebuild images
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Can't access Grafana

1. Check if containers are running: `docker-compose ps`
2. Check Nginx logs: `docker-compose logs nginx`
3. Verify port 80 is available: `lsof -i :80` (on macOS/Linux)
4. Test connectivity: `curl http://localhost/health`

### Prometheus shows no metrics

1. Wait 2-3 minutes for metrics to be scraped
2. Check Prometheus targets: http://localhost/prometheus/targets
3. Verify Node Exporter and cAdvisor are running: `docker-compose ps`
4. Check Prometheus logs: `docker-compose logs prometheus`

### Out of disk space

Prometheus stores data by default. To reduce storage:

1. Reduce retention: Edit `prometheus/prometheus.yml`
   ```yaml
   - '--storage.tsdb.retention.time=7d'  # Change from 30d
   ```
2. Restart Prometheus: `docker-compose restart prometheus`

### cAdvisor issues (especially on macOS)

cAdvisor has limited support on Docker Desktop due to how Docker is virtualized on macOS. Node Exporter will work fine, but container metrics may be limited.

## Security Considerations

### Before Production Use

1. **Change Default Credentials**
   - Change Grafana password in `.env`
   - Restart: `docker-compose restart grafana`

2. **Enable SSL/TLS**
   - Add certificates to `nginx/` directory
   - Update `nginx/nginx.conf` with SSL configuration

3. **Restrict Network Access**
   - Use firewall rules to limit access to port 80
   - Modify Docker Compose to use internal networks

4. **Secure Prometheus**
   - Add authentication to Prometheus (via Nginx proxy)
   - Use reverse proxy password protection

5. **Enable Persistence**
   - Ensure volumes are backed up
   - Configure automated backups

### Example: Basic Auth in Nginx

```nginx
location /prometheus/ {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://prometheus/;
}
```

## Volume Data

The stack uses Docker named volumes for data persistence:

- `prometheus_data` - Prometheus time-series database
- `grafana_data` - Grafana dashboards and datasources

View volumes:
```bash
docker volume ls
docker volume inspect docker-monitoring_prometheus_data
```

## Performance Tuning

### For large environments

1. **Increase Prometheus storage**:
   ```yaml
   - '--storage.tsdb.retention.size=50GB'
   ```

2. **Adjust scrape intervals**:
   ```yaml
   scrape_interval: 30s  # Default is 15s
   ```

3. **Increase resources**:
   ```yaml
   services:
     prometheus:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 2G
   ```

## Contributing

To extend this monitoring stack:

1. Add new Prometheus scrape targets in `prometheus/prometheus.yml`
2. Create custom dashboards in `grafana/provisioning/dashboards/`
3. Add alerting rules in a new `prometheus/alert_rules.yml`

## License

MIT License

## Support

For issues or questions:

1. Check the Troubleshooting section
2. Review Docker and Docker Compose logs
3. Consult Prometheus documentation: https://prometheus.io/docs/
4. Consult Grafana documentation: https://grafana.com/docs/

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Nginx Documentation](https://nginx.org/en/docs/)
