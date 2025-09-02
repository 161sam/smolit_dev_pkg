# Example Plugin

Enhanced demo plugin for the smolit_dev CLI system, demonstrating all available plugin API features.

## Commands

- `sd example:echo [text]` - Say hello and show available API functions
- `sd example:workspace` - Show workspace info and available commands
- `sd example:config {get|set} [key] [value]` - Configuration demo
- `sd example:bridge [text]` - Send message via Claude bridge
- `sd example:docker` - Run hello-world container
- `sd example:template [name]` - Template rendering demo

## API Features Demonstrated

This plugin showcases all available plugin API functions:

### Logging
- `sd_log()` - Info logging
- `sd_warn()` - Warning messages  
- `sd_die()` - Error messages with exit

### Integration
- `sd_bridge_send()` - Send prompts to Claude bridge
- `sd_docker_run()` - Run Docker containers
- `sd_template_render()` - Render templates with variables

### Configuration
- `sd_config_get()` - Read configuration values
- `sd_config_set()` - Write configuration values

## Development

This plugin serves as a reference implementation for new plugins. 
Copy this structure and modify the functions to create your own plugins.

## Installation

This plugin is included by default with smolit_dev.
