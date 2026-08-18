# Project Instructions

## Rails file generation

- Always create Rails framework artifacts with the appropriate `bin/rails generate ...` command before editing them.
- This includes migrations, models, controllers, jobs, mailers, channels, and generated tests or scaffolds.
- Never hand-create a Rails-owned artifact as a substitute for running its generator.
- After generation, use normal patches to customize the generated file.
- If the generator cannot run or there is no clear appropriate generator for a Rails-owned artifact, stop and ask the user to generate it or provide direction.
