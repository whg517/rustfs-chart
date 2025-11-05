# RustFS Helm Chart

A comprehensive Helm chart for deploying [RustFS](https://github.com/rustfs/rustfs) object storage on Kubernetes with high availability support.

## Description

RustFS is a high-performance, S3-compatible object storage system written in Rust. This Helm chart provides enterprise-grade deployment capabilities including:

- **High Availability**: Multi-replica StatefulSet deployment with configurable replica count
- **Multi-Drive Support**: Configure multiple drives per node for improved performance and redundancy
- **Security**: Built-in secret management for access credentials with optional existing secret support
- **Flexible Networking**: Separate services for API and Console with independent Ingress support
- **Production Ready**: Comprehensive resource management, security contexts, and health checks

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if using persistent storage)
- Optional: Prometheus Operator (for monitoring integration)

## Installing the Chart

To install the chart with the release name `my-rustfs`:

```bash
helm install my-rustfs ./rustfs
```

## Uninstalling the Chart

To uninstall/delete the `my-rustfs` deployment:

```bash
helm uninstall my-rustfs
```

## Configuration

The following table lists the configurable parameters of the RustFS chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicas` | Number of StatefulSet replicas | `1` |
| `image.repository` | RustFS image repository | `rustfs/rustfs` |
| `image.tag` | RustFS image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the chart | `""` |
| `clusterDomain` | Cluster domain suffix | `cluster.local` |

### RustFS Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `rootUser` | RustFS admin username (RUSTFS_ACCESS_KEY) | `""` |
| `rootPassword` | RustFS admin password (RUSTFS_SECRET_KEY) | `""` |
| `existingSecret` | Name of existing secret containing credentials | `""` |
| `mountPath` | Base path where PVs will be mounted | `/data` |
| `driverPerNode` | Number of drives per node | `1` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type for API | `ClusterIP` |
| `service.annotations` | Service annotations | `{}` |
| `consoleService.type` | Kubernetes service type for console | `ClusterIP` |
| `consoleService.annotations` | Console service annotations | `{}` |

### Persistence Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.storageClass` | Storage class name | `""` (uses default) |
| `persistence.accessModes` | Access modes | `["ReadWriteOnce"]` |
| `persistence.size` | Storage size per drive | `10Gi` |
| `persistence.annotations` | PVC annotations | `{}` |
| `persistence.existingClaim` | Use existing PVC | `""` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress for API | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | `[]` |
| `consoleIngress.enabled` | Enable Ingress for console | `false` |
| `consoleIngress.className` | Console ingress class name | `""` |
| `consoleIngress.annotations` | Console ingress annotations | `{}` |
| `consoleIngress.hosts` | Console ingress hosts configuration | See values.yaml |
| `consoleIngress.tls` | Console ingress TLS configuration | `[]` |

### Monitoring Configuration

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.memory` | Memory request | `128Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.limits.cpu` | CPU limit | `100m` |

### Security Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.automount` | Auto mount service account token | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | See values.yaml |

### Configuration Management

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.enabled` | Enable ConfigMap for RustFS configuration | `true` |
| `config.apiPort` | S3 API port | `9000` |
| `config.consolePort` | Management console port | `9001` |
| `config.address` | Server address binding | `""` (defaults to `:apiPort`) |
| `config.consoleAddress` | Console address binding | `""` (defaults to `:consolePort`) |
| `config.consoleEnable` | Enable console interface | `true` |
| `config.corsAllowedOrigins` | CORS allowed origins for S3 API | `""` |
| `config.consoleCorsAllowedOrigins` | CORS allowed origins for console | `""` |
| `config.logLevel` | Log level (trace, debug, info, warn, error) | `info` |
| `config.extraConfig` | Additional configuration key-value pairs | `{}` |

### Environment Variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env` | Custom environment variables | `[]` |
| `envFrom` | Environment variables from ConfigMap/Secret | `[]` |

## Usage Examples

### Basic Installation with Credentials

```bash
helm install my-rustfs ./rustfs \
  --set rootUser=myadmin \
  --set rootPassword=mypassword123
```

### High Availability Production Setup

```bash
helm install my-rustfs ./rustfs \
  --set replicas=4 \
  --set driverPerNode=2 \
  --set rootUser=admin \
  --set rootPassword=securepassword123 \
  --set persistence.storageClass=fast-ssd \
  --set persistence.size=50Gi \
  --set resources.requests.memory=1Gi \
  --set resources.requests.cpu=500m \
  --set resources.limits.memory=2Gi \
  --set resources.limits.cpu=1000m
```

### Configuration with Existing Secret

```bash
# Create secret first
kubectl create secret generic rustfs-credentials \
  --from-literal=RUSTFS_ACCESS_KEY=myadmin \
  --from-literal=RUSTFS_SECRET_KEY=mypassword123

# Install with existing secret
helm install my-rustfs ./rustfs \
  --set existingSecret=rustfs-credentials
```

### Enable Monitoring and Ingress

```bash
helm install my-rustfs ./rustfs \
  --set rootUser=admin \
  --set rootPassword=password123 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=rustfs.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set consoleIngress.enabled=true \
  --set consoleIngress.hosts[0].host=rustfs-console.example.com \
  --set consoleIngress.hosts[0].paths[0].path=/ \
  --set consoleIngress.hosts[0].paths[0].pathType=Prefix
```

### Custom Configuration with ConfigMap

```bash
helm install my-rustfs ./rustfs \
  --set rootUser=admin \
  --set rootPassword=password123 \
  --set config.enabled=true \
  --set config.apiPort=8000 \
  --set config.consolePort=8001 \
  --set config.logLevel=debug \
  --set 'config.corsAllowedOrigins=https://example.com,https://app.example.com' \
  --set config.consoleCorsAllowedOrigins=https://console.example.com
```

### Custom Environment Variables

```bash
helm install my-rustfs ./rustfs \
  --set rootUser=admin \
  --set rootPassword=password123 \
  --set env[0].name=RUSTFS_REGION \
  --set env[0].value=us-east-1 \
  --set env[1].name=RUSTFS_LOG_LEVEL \
  --set env[1].value=debug
```

## Accessing RustFS

After installation, you can access RustFS:

### Internal Access (within cluster)
- **S3 API:** `http://<release-name>-rustfs:9000`
- **Management Console:** `http://<release-name>-rustfs-console:9001`

### External Access (with Ingress)
Configure the ingress hosts in values.yaml or via --set parameters during installation.

## High Availability Architecture

This chart supports highly available deployments:

- **StatefulSet**: Ensures stable network identities and persistent storage
- **Multiple Replicas**: Configure `replicas` for horizontal scaling
- **Multi-Drive Support**: Use `driverPerNode` for multiple volumes per pod
- **Rolling Updates**: Controlled updates with zero downtime
- **Health Checks**: Comprehensive liveness and readiness probes

### Deployment Modes

The chart automatically configures RustFS based on your replica and drive settings:

#### Single Node Single Drive (replicas=1, driverPerNode=1)
- **Volume Mount**: Single volume mounted at `/data`
- **Container Args**: Default RustFS startup (no special args)
- **Use Case**: Development, testing, small deployments

#### Multi-Node or Multi-Drive (replicas>1 or driverPerNode>1)
- **Volume Mounts**: Multiple volumes mounted at `{mountPath}/rustfs{0...N}`
- **Container Args**: `rustfs http://rustfs-{0...N}.rustfs:9000{mountPath}/rustfs{0...M}`
- **Use Case**: Production deployments with high availability and performance

Examples:
- `replicas=3, driverPerNode=1`: `rustfs http://rustfs-{0...2}.rustfs:9000/data/rustfs0`
- `replicas=4, driverPerNode=2`: `rustfs http://rustfs-{0...3}.rustfs:9000/data/rustfs{0...1}`

## Security Best Practices

1. **Always set custom credentials**: Never use default passwords in production
2. **Use existing secrets**: Store sensitive data in Kubernetes secrets
3. **Enable security contexts**: The chart includes secure defaults
4. **Network policies**: Configure appropriate network policies for your environment
5. **TLS termination**: Use ingress with TLS for external access

## Persistence

The chart uses StatefulSet with PersistentVolumeClaims:

- **Multiple drives**: Each pod can have multiple PVCs based on `driverPerNode`
- **Dynamic provisioning**: Supports any storage class with dynamic provisioning
- **Stateful scaling**: Pods maintain their storage during scaling operations

## Testing

The chart includes comprehensive test pods that verify:

- S3 API health endpoint connectivity
- Console port accessibility

Run tests with:

```bash
helm test my-rustfs
```

## Troubleshooting

### Common Issues

1. **PVC not bound**: Check storage class configuration and available storage
2. **Image pull errors**: Verify image repository accessibility
3. **Port conflicts**: Ensure ports 9000 and 9001 are available
4. **Secret not found**: Verify secret exists if using `existingSecret`
5. **Permission errors**: Check security contexts and pod security policies

### Logs

View pod logs:

```bash
kubectl logs statefulset/my-rustfs
```

Check events:

```bash
kubectl describe statefulset my-rustfs
kubectl describe pod my-rustfs-0
```

### Debug Configuration

Test configuration without deployment:

```bash
helm template my-rustfs ./rustfs --debug
```

## Migration from v0.1.0

If upgrading from version 0.1.0, note these breaking changes:

1. Service configuration has changed - separate API and console services
2. Persistence configuration moved from `rustfs.persistence` to `persistence`
3. New credential management with `rootUser`/`rootPassword`
4. Multi-drive support requires configuration review

## Support

For issues with this Helm chart, please check:

- [Chart Documentation](https://github.com/tendata/infra-ops/tree/main/prod-kube0/infra-storage/rustfs/helm)
- [RustFS Project](https://github.com/rustfs/rustfs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Contributing

Contributions are welcome! Please read the contribution guidelines and submit pull requests to the repository.

## License

This chart is licensed under the Apache 2.0 license.
