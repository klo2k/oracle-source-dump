# Dump Oracle database objects to file (e.g. packages, tables, views, functions, procedures etc...)

Time-saver scripts to dump Oracle database objects to file.

I created this to start revision controlling database objects.

## Current Status

I'll work on things as they are needed - PR welcome 🙂.

We can dump ✅:

- [Package](#dump-packages)
- [Table](#dump-tables)
- [View](#dump-views)

TODO 🗒:

- Function
- Procedures
- ...

## Setup

1. Docker Engine on Ubuntu is [installed](https://docs.docker.com/engine/install/ubuntu/) (needed to run my `sqlplus` image)
2. Configure your dump parameters (connection string etc...)

    ```bash
    cp dump_parameters.template dump_parameters
    vim dump_parameters
    ```

## Usage

### Dump Packages

Dump single package

```bash
./dump_packages.sh SCHEMA_NAME PACKAGE_NAME
```

Dump all packages from a schema

```bash
./dump_packages.sh SCHEMA_NAME
```

### Dump Tables

Dump single table

```bash
./dump_tables.sh SCHEMA_NAME TABLE_NAME
```

Dump all tables from a schema

```bash
./dump_tables.sh SCHEMA_NAME
```

### Dump Views

Dump single view

```bash
./dump_views.sh SCHEMA_NAME VIEW_NAME
```

Dump all view from a schema

```bash
./dump_views.sh SCHEMA_NAME
```
