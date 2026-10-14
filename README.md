# ds-dkms

Hiro-owned Helm chart for a KERI DKMS stack — the identity backbone of the NextGen EU dataspace. Packages the upstream [THCLab keriox](https://github.com/THCLab/keriox) witness + watcher and the [THCLab mesagkesto](https://github.com/THCLab/mesagkesto) message box into one deployable unit, so a HIRO-managed site (or a federated partner) can bring up DKMS with a single `helm install`.

| Component  | Image                                       | Default state |
|------------|---------------------------------------------|---------------|
| Witness    | `ghcr.io/thclab/keriox-witness:0.18.0`      | **enabled**, 1 replica (scale to 3 when federating) |
| Watcher    | `ghcr.io/thclab/keriox-watcher:0.18.0`      | **enabled**, 1 replica |
| Mesagkesto | `ghcr.io/thclab/mesagkesto:v0.2.1-alpha.1`  | **enabled**, 1 replica |

## Architecture note — issuer side vs verifier side

A HIRO site plays two KERI roles simultaneously:

- **Verifier** (`ds-login`): accepts credentials issued by **any** DKMS-anchored party. The verify flow extracts witness URLs from the OOBIs embedded in each incoming IPEX grant and queries those witnesses directly for live KEL + TEL state — no local caching required.
- **Issuer** (`ds-credential-issuer`): before minting an ACDC for an arbitrary subject AID, needs to resolve that subject's current signing key from their KEL. Subjects live wherever DKMS runs (another site, a partner org), so an issuer process needs a stable, locally-reachable introduction point into the broader KERI network. That's the watcher.

So the chart ships watcher on by default — a Hiro site typically does both. For lightweight verifier-only sites (think: a partner institution that only consumes credentials, never issues), set `watcher.enabled: false`; see `ci/verifier-only-values.yaml` for that shape.

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

- `StatefulSet ds-dkms-witness` with 1 pod (scale `witness.replicaCount` for multi-witness topologies), exposed at `dkms-witness-1.hus.nextgen.hiro-develop.nl`
- `Deployment ds-dkms-watcher` at `dkms-watcher.hus.nextgen.hiro-develop.nl`
- `Deployment ds-dkms-mesagkesto` at `dkms-mesagkesto.hus.nextgen.hiro-develop.nl`
- Per-pod Services + per-pod Ingresses so each witness URL maps to a single AID (witnesses are not interchangeable)
- One PVC per witness pod (`data-ds-dkms-witness-0`) for the KERIpy LMDB

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
