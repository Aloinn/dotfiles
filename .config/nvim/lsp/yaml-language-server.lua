return {
    cmd = { "yaml-language-server", "--stdio" },
    filetypes = { "yaml", "yml" },
    settings = {
        yaml = {
            yamlVersion = 1.1,
            customTags = {
                "!call mapping",
                "!eval scalar",
                "!set_override mapping",
                "!merge sequence",
                "!map mapping",
            },
            schemas = {
                ["https://json.schemastore.org/yamllint.json"] = {
                    "*.yaml",
                    "*.yml",
                },
            },
        },
        redhat = { telemetry = { enabled = false } },
    },
}
