# ds-dkms

Hiro-owned Helm chart for a KERI DKMS stack — the identity backbone of the NextGen EU dataspace. Packages the upstream [THCLab keriox](https://github.com/THCLab/keriox) witness + watcher and the [THCLab mesagkesto](https://github.com/THCLab/mesagkesto) message box into one deployable unit, so a HIRO-managed site (or a federated partner) can bring up DKMS with a single `helm install`.

| Component  | Image                                       | Default state |
|------------|---------------------------------------------|---------------|
| Witness    | `ghcr.io/thclab/keriox-witness:0.18.0`      | **enabled**, 3 replicas |
| Watcher    | `ghcr.io/thclab/keriox-watcher:0.18.0`      | **disabled** (see architecture note) |
| Mesagkesto | `ghcr.io/thclab/mesagkesto:v0.2.1-alpha.1`  | **enabled**, 1 replica |

## Architecture note — why watcher is off by default

The NextGen verifier (`ds-login`) accepts credentials issued by **any** DKMS-anchored party, not just the three HIRO sites. The verify flow extracts witness URLs from the OOBIs embedded in each IPEX grant and queries those witnesses directly for live KEL + TEL state. A HIRO-side watcher would only matter if we were trying to cache or pre-subscribe to known witnesses — which this open-federation model does not require.

Enable the watcher once you want per-site caching, witness-reachability shielding, or an independent "second opinion" verifier layer. Set `watcher.enabled: true` and populate `watcher.initialOobis`.

## Install

```bash
helm repo add ds-dkms https://hiro-microdatacenters-bv.github.io/ds-dkms
helm repo update

helm install ds-dkms ds-dkms/ds-dkms \
  --namespace dkms --create-namespace \
  --values my-site-values.yaml
```

A minimum site values file:

```yaml
baseDomain: hus.nextgen.hiro-develop.nl

witness:
  seedSecretName: dkms-witness-seeds   # must exist in `dkms` namespace
  ingress:
    tls:
      enabled: true
      secretNamePattern: "dkms-witness-{idx}-tls"

mesagkesto:
  seedSecretName: dkms-mesagkesto-seed
  ingress:
    tls:
      enabled: true
      secretName: dkms-mesagkesto-tls
```

That renders:

- `StatefulSet ds-dkms-witness` with 3 pods, each exposed at `dkms-witness-{1,2,3}.hus.nextgen.hiro-develop.nl`
- `Deployment ds-dkms-mesagkesto` at `dkms-mesagkesto.hus.nextgen.hiro-develop.nl`
- Per-pod Services + per-pod Ingresses so each witness URL maps to a single AID (witnesses are not interchangeable)
- One PVC per witness pod (`data-ds-dkms-witness-0/1/2`) for the KERIpy LMDB

## Seeds

The chart does **not** ship plaintext seeds. Each component reads its KERI seed from a Kubernetes `Secret`:

| Secret name (default)      | Keys                               |
|----------------------------|------------------------------------|
| `dkms-witness-seeds`       | `witness-seed` (shared) or `witness1`/`witness2`/`witness3` |
| `dkms-watcher-seed`        | `watcher-seed`                     |
| `dkms-mesagkesto-seed`     | `mesagkesto-seed`                  |

Generate seeds once per site and commit them as SealedSecret or ExternalSecret manifests in `ds-gitops`. See the [KERI owner's manual §13.2](../repro/dkms-keri-owners-manual.md) for the generation procedure.

## Local dev

```bash
docker compose up -d
# 3 witnesses on 3232/3233/3234, mesagkesto on 8081

# Add the watcher as well:
WATCHER=1 docker compose --profile watcher up -d
```

Hitting a witness:

```bash
curl http://localhost:3232/oobi      # introduce yourself to this witness
```

## GitOps

Per-site values live in `HIRO-MicroDataCenters-BV/ds-gitops` under `{hus,ki,uva}-services/dkms/`. Fleet pulls the chart from this repo's gh-pages Helm registry (`https://hiro-microdatacenters-bv.github.io/ds-dkms`).

## Dependencies

- Kubernetes 1.26+ (uses `statefulset.kubernetes.io/pod-name` label for per-pod routing — stable since 1.26)
- An IngressClass available in the target cluster (`nginx` by default)
- cert-manager if you want TLS secrets provisioned automatically

## License

MIT — see [LICENSE](LICENSE).
