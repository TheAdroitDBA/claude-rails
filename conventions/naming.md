# Hostname Naming Conventions

Stack-agnostic principles for naming hosts in any infrastructure repo. Loaded between `rules/` (invariants) and sibling docs in the token hierarchy.

Conventions are principles, not invariants. A repo that cannot honor a convention declares a one-line deviation in its local naming doc.

## Two Names, Not One

Every host has two distinct identities:

- **Canonical hostname** -- anchored to the hardware. What the OS reports, what Prometheus labels, what nginx upstream blocks reference, what SSH connects to. Stable across role changes.
- **Friendly alias** -- mutable, human-pleasing. What humans say out loud (`brain`, `wakko`). Implemented as a DNS CNAME (or local-zone alias) pointing at the canonical hostname.

Conflating the two causes pain: a role change drags every Prometheus target, nginx upstream, terraform reference, and operator muscle-memory along with it. Splitting them lets the friendly part change at the speed of taste, while the wired-up part changes at the speed of hardware.

## Canonical Hostname Format

```
<role>-<form>-<instance>
```

| Field | Type | Notes |
|-------|------|-------|
| `role` | Closed vocabulary | Fixed list of role classes the repo supports. Add new entries only with a written justification in the local naming doc. |
| `form` | Short alphanumeric model code | Lowercase, no inner hyphens. Use the motherboard model when distinct enough; the chassis or product line otherwise. |
| `instance` | Two-digit zero-padded integer | Increments per (role, form) tuple. Never reused, even for decommissioned hosts -- gaps signal history. |

Hyphen-separated, lowercase, DNS-safe. Pattern lifted from AWS resource tags and Kubernetes naming -- well-trodden ground.

### Suggested Role Vocabulary

A small fixed vocabulary covers most homelabs and small-team infrastructure. Each repo picks the subset it uses and writes it down:

| Role | Definition |
|------|------------|
| `host` | Hypervisor running VMs/CTs |
| `worker` | Compute drone -- transcode, build, render -- not running other workloads |
| `client` | Daily-driver workstation, kids' PC, dev machine |
| `srv` | Bare-metal server running a single primary service |
| `kiosk` | Dedicated display / fixed-purpose endpoint |
| `db` | Database-only LXC or VM |

The vocabulary is **additive and non-breaking** by design. Adding a new role never invalidates existing names.

## Hardware Identity Lives in Inventory, Not in the Hostname

The canonical hostname is anchored to hardware, but the hardware is identified by the inventory row, not by the name. Every host record carries:

- **Serial / Service Tag / Motherboard Serial / System UUID** -- the unforgeable identity. Read from BIOS/SMBIOS via `dmidecode -s system-uuid` (Linux) or `Get-CimInstance Win32_ComputerSystemProduct` (Windows).
- **All physical NIC MACs** -- one per physical NIC, not per virtual interface.
- **Build/install date.**
- **Canonical hostname.**
- **Friendly alias(es)**, if any.

The serial/UUID is the bedrock. The canonical hostname is what every system tool prints. The friendly alias is what humans say. Inventory is the place where all three meet.

## Friendly Aliases via DNS CNAME

Friendly aliases live in the network's DNS layer (Pi-hole, Unbound, Bind, internal AD DNS -- whichever the homelab uses). Two records per alias:

- **Short alias** at the LAN domain (`<alias>` -> `<canonical>.<lan-suffix>`)
- **FQDN alias** at the internal-services domain (`<alias>.<internal-suffix>` -> `<canonical>.<internal-suffix>`)

Both halves required so `ssh wakko` and `ssh wakko.internal.example.com` both resolve. The local naming doc records which DNS layer manages aliases and what the caveats are (e.g. Pi-hole v6's array-replace gotcha for `dns.cnameRecords`).

A friendly alias must:

- Be lowercase, alphanumeric, hyphens only
- Be unique across the homelab/network
- Not collide with any service short-name in the local DNS map

Theme is the operator's choice. A coherent theme (cartoon characters, drinks, geographic features) is a quality-of-life win because it reduces "what should we call this one" friction. Themes are taste; the convention does not enforce them.

## Migration Policy

Renaming an existing host is expensive: every Prometheus target, nginx upstream, dashboard label, terraform reference, monitoring rule, backup script, and operator's muscle memory needs touching. Apply the convention forward, not retroactively:

- **New builds and reinstalls** adopt the canonical convention. Hostname is set during OS install or first boot.
- **Existing hosts with friendly-as-canonical names** keep their current names until something else forces a rename (motherboard swap, full reinstall, role change).
- **When a server eventually does flip**, the old friendly name (`brain`, `pinky`, ...) becomes the friendly CNAME alias of the new canonical hostname. Backward compatibility costs nothing once the alias layer exists.

## Where the Local Naming Doc Lives

Each repo that adopts this convention has its own naming doc -- typically at `docs/network/naming.md` -- that:

1. References this convention as the framework.
2. Declares which subset of the role vocabulary the repo uses (and any local additions, with a one-line rationale).
3. Lists the local hosts in a table with their canonical name, hardware identity fields, and friendly aliases.
4. Documents the local DNS layer's caveats for managing CNAME records.
5. Notes the migration policy chosen (which existing hosts are exempt, which are scheduled for rename).

The framework moves slowly and lives here. The instantiation moves with the homelab and lives in the repo.

## Litmus Tests

- Can you rename a friendly alias without touching any monitoring, automation, or wiring? If no, the alias is masquerading as canonical -- collapse the split or fix the references.
- Does every host's hostname tell you (a) what role it plays, (b) roughly what hardware it is, (c) which instance it is among peers? If no, the format is being shortened for taste -- and friendly aliases exist for that.
- Does the inventory row identify the same hardware after a full OS reinstall? If no, you're tracking the install, not the hardware.

## Common Mistakes

- Putting the friendly name in the canonical slot. The cartoon character on the rack label is fine; the hostname the OS reports should still be `host-r710-01`.
- Embedding role-specific data in the form code (`worker-r710-prod-01`). The role field is what `role` is for; environment dimensions belong in a tag/label, not the hostname.
- Skipping the inventory row's serial/UUID field. Without that, two hosts of the same model are indistinguishable across reinstalls.
- Reusing a decommissioned instance number. Gaps are evidence; reuse erases history.
- Locking down the role vocabulary so tightly that no one ever extends it -- and then watching ad-hoc roles appear in the form field instead.
