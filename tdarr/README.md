# Tdarr — Media Transcoding

Distributed transcoding using Intel Quick Sync Video (QSV) on the i9-12900H iGPU.

## Flows

| File | Purpose |
|---|---|
| `flows/hevc-qsv-transcode.json` | Main transcode flow — H.264 → HEVC via QSV |

---

## Flow: HEVC QSV Transcode

### Logic

```
Input File
    │
    ▼
Already AV1? ──yes──► SKIP (AV1 is more efficient than HEVC, leave it alone)
    │ no
    ▼
Already HEVC? ──yes──► SKIP
    │ no
    ▼
FFmpeg: Begin Command
    │
    ▼
FFmpeg: Set Encoder
    │  hevc_qsv | ICQ 28 | HW decode ON | force encode ON
    ▼
FFmpeg: Execute
    │
    ▼
Compare File Size Ratio ──larger──► SKIP (don't replace if transcode bloated)
    │ smaller
    ▼
Replace Original File ✓
```

### Encoder settings

| Setting | Value | Notes |
|---|---|---|
| Output codec | `hevc` | H.265 |
| Hardware type | `qsv` | Intel Quick Sync — i9-12900H iGPU |
| Hardware decoding | ON | Full QSV pipeline — decode + encode on iGPU |
| Quality (ICQ) | `28` | Aggressive. Consider `23–25` for better quality |
| Preset | `veryfast` | Minimal effect on QSV — hardware speed is fixed |
| Force encoding | ON | Safe here — AV1/HEVC skips are handled upstream |

### Quality guidance

QSV uses ICQ (Intelligent Constant Quality) mode — **not** the same scale as `libx265` CRF.

| Goal | ICQ value |
|---|---|
| Archival / transparent | 18–22 |
| Balanced (recommended) | 23–25 |
| Aggressive compression | 26–28 |

---

## Host requirements

```bash
# Verify iGPU device exists on Unraid host
ls /dev/dri
# Expected output: card0  renderD128

# Verify i915 driver is loaded
lsmod | grep i915

# Check QSV is working inside the container
docker exec tdarr ffmpeg -hwaccels | grep qsv
docker exec tdarr vainfo
```

The Tdarr container in `docker-compose/media-stack/docker-compose.yml` maps `/dev/dri:/dev/dri`.

---

## Importing a flow into Tdarr

1. Open Tdarr UI → **Flows**
2. Click **+** (New Flow) or open an existing one
3. Click ⋮ menu → **Import Flow**
4. Paste the contents of the JSON file from this repo

## Exporting a flow from Tdarr (to keep this repo in sync)

1. Tdarr UI → **Flows** → your flow
2. Click ⋮ → **Export Flow**
3. Copy the JSON
4. Paste into `tdarr/flows/<flow-name>.json` and commit

```bash
# After pasting the exported JSON:
git add tdarr/flows/
git commit -m "chore(tdarr): update hevc-qsv-transcode flow"
git push
```
