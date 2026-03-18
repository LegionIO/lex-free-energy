# Changelog

## [0.1.1] - 2026-03-18

### Fixed
- Validate `mode` against `INFERENCE_MODES` in `FreeEnergyEngine#minimize` and `minimize_free_energy` runner — rejects modes not in `[:perceptual, :active]`

## [0.1.0] - 2026-03-13

### Added
- Initial release: Free Energy Principle modeling (Friston)
- Generative beliefs, prediction error, perceptual and active inference
- Surprise labels, precision tracking, domain-scoped free energy
- Standalone Client
