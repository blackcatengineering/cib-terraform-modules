# cib-terraform-modules

One repo, many modules, one version tag. Replaces the old pattern where
`start_here/github_module_upload.tf` created a GitHub repo per module and
pushed files into it with Terraform.

```
modules/
  tenant-network/    network, subnets, router, keypair         (openstack)
  k8s-cluster/       Magnum cluster from an undercloud template  (openstack)
  state-bucket/      private, versioned, policy-scoped S3 state bucket on RGW  (aws)
  gh-runner-vm/      GitHub Actions runner VM for one repo (used for tenant runners)
  platform-addons/   composite: toggles for everything below    (helm, kubernetes)
  traefik/  cnpg-operator/  cert-manager/  trust-manager/  istio/
  jaeger/  jenkins/  harness/  ip-masq-agent/  storage-classes/
```

Platform-only pieces (Backstage, the ARC platform runners) live in
`cib-undercloud/platform/modules`, not here: tenants never get them.

## Consuming

```hcl
module "network" {
  source      = "git::https://github.com/<org>/cib-terraform-modules.git//modules/tenant-network?ref=v1.0.0"
  name_prefix = var.domain
}
```

The `//modules/<name>` sub-path plus `?ref=<tag>` pins every module to one
release. Because Terraform downloads the whole repo, modules can reference
each other with relative paths (`source = "../cert-manager"`), so nothing has
to be templated with a GitHub URL any more (the old `main.tftpl` +
`templatefile()` step is gone).

## Two stages, on purpose

The old `builder-infra` module created the Magnum cluster **and** configured
the helm/kubernetes providers from it in the same run. That pattern is fragile
(providers are configured before the cluster exists, and a module with its own
provider blocks can't be used with `count`, `for_each` or `depends_on`).

Now:

1. **infra** stage: `tenant-network` + `k8s-cluster` → outputs `kubeconfig_path`
2. **platform** stage: root module configures `helm`/`kubernetes` from that
   kubeconfig and calls `platform-addons`

`cib-tenant-template` already has both stages wired up.

## Contract with cib-undercloud

`k8s-cluster` looks up `generic-k8s-<kubernetes_version>-template` by name.
If the undercloud renames templates, bump the major version here.

## Releasing

Merge to `main`, then `git tag v1.0.0 && git push --tags`. CI validates every
module and creates the GitHub release. Semver: breaking variable/output
changes are a major bump.

## Provider versions

| Provider | Constraint | Why |
|---|---|---|
| `hashicorp/helm` | `>= 3.3, < 4.0` | 3.x is the current line (3.3.0, Aug 2026). There is no 4.x provider yet; 3.3 embeds the Helm v3.20 SDK. |
| `hashicorp/kubernetes` | `>= 3.0, < 4.0` | 3.x is current (3.4.0). Only the `_v1` resource types are used. |
| `hashicorp/aws` | `>= 6.0, < 7.0` | `state-bucket` only, pointed at Ceph RGW. |

Helm provider 3.x changed `set {}` blocks to `set = [{ ... }]` and the provider's
`kubernetes {}` block to `kubernetes = { ... }`; both are migrated here and in
`cib-tenant-template`. The Harness delegate registry module moved 0.2.3 → 0.3.0
because 0.2.3 itself pinned helm `< 3.0` (0.3.0 only adds optional variables).

**On Helm 4:** Helm 3 gets security fixes only until 10 Feb 2027, so a Helm 4
based provider is the target. When HashiCorp ships one, it should be a
constraint bump in the `providers.tf` files: the charts used here are
`apiVersion: v2`, which Helm 4 still installs.

All Kubernetes resources use the `_v1` types (`kubernetes_daemon_set_v1`,
`kubernetes_storage_class_v1`, `kubernetes_config_map_v1`); the unversioned
names are deprecated as of kubernetes provider 3.0.

## Notable module defaults

- **ip-masq-agent**: image `v2.12.0` (newest promoted to registry.k8s.io;
  upstream's own manifest still says v2.8.0), unprivileged with
  `NET_ADMIN`/`NET_RAW` like upstream, tolerates all taints, optional config
  map via `nonmasquerade_cidrs`.
- **storage-classes**: one class per undercloud volume type, `standard` is
  the cluster default. The old module made `multiattach` the default, which
  is only safe with a cluster-aware filesystem. Off by default in
  `platform-addons`; check whether Magnum already created a default class.
- The unused `k8s_cluster` variable (default `builder-cluster-wxh7o`) is gone
  from every addon.
