#!/bin/bash

# Datadog Entity Generator Script
# This script generates entity.datadog.yaml file based on CI workflow information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Generate entity.datadog.yaml file based on CI workflow information"
    echo ""
    echo "Options:"
    echo "  -f, --force    Force overwrite existing entity.datadog.yaml file"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Generate entity.datadog.yaml (skip if exists)"
    echo "  $0 --force      # Generate entity.datadog.yaml (overwrite if exists)"
}

# Parse command line arguments
FORCE_OVERWRITE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Function to extract value from YAML using grep and sed
extract_yaml_value() {
    local file="$1"
    local key="$2"
    grep -E "^\s*${key}:" "$file" 2>/dev/null | head -1 | sed -E "s/^\s*${key}:\s*(.*)$/\1/" | sed 's/^["'\'']//' | sed 's/["'\'']*$//'
}

# Function to extract value from package.json using grep and sed
extract_package_json_value() {
    local file="$1"
    local key="$2"
    
    if [[ ! -f "$file" ]]; then
        echo ""
        return
    fi
    
    # Extract value from JSON using grep and sed (simple approach)
    grep -E "^\s*\"${key}\"\s*:" "$file" 2>/dev/null | head -1 | sed -E "s/^\s*\"${key}\"\s*:\s*\"?([^\"\,]*)\"?.*$/\1/"
}

# Function to detect Angular version from package.json
detect_angular_version() {
    local package_file="$1"
    
    if [[ ! -f "$package_file" ]]; then
        echo ""
        return
    fi
    
    # Look for Angular core dependency
    local angular_version=$(grep -E "@angular/core" "$package_file" 2>/dev/null | sed -E 's/.*"([0-9]+)\..*"/\1/')
    
    if [[ -n "$angular_version" ]]; then
        echo "$angular_version"
    else
        echo ""
    fi
}

# Function to detect Python version from requirements.txt or pyproject.toml
detect_python_version() {
    local project_dir="."
    
    # Check pyproject.toml first
    if [[ -f "pyproject.toml" ]]; then
        local python_version=$(grep -E "python\s*=" "pyproject.toml" 2>/dev/null | sed -E 's/.*"([0-9]+\.[0-9]+).*/\1/')
        if [[ -n "$python_version" ]]; then
            echo "$python_version"
            return
        fi
    fi
    
    # Check requirements.txt for python version comments
    if [[ -f "requirements.txt" ]]; then
        local python_version=$(grep -E "#.*python.*[0-9]+\.[0-9]+" "requirements.txt" 2>/dev/null | sed -E 's/.*([0-9]+\.[0-9]+).*/\1/' | head -1)
        if [[ -n "$python_version" ]]; then
            echo "$python_version"
            return
        fi
    fi
    
    echo ""
}

# Function to detect Python framework from requirements files
detect_python_framework() {
    local project_dir="."
    
    # Check for Django
    if [[ -f "requirements.txt" ]] && grep -q "Django" "requirements.txt" 2>/dev/null; then
        echo "django"
        return
    fi
    
    # Check for FastAPI
    if [[ -f "requirements.txt" ]] && grep -q "fastapi" "requirements.txt" 2>/dev/null; then
        echo "fastapi"
        return
    fi
    
    # Check for Flask
    if [[ -f "requirements.txt" ]] && grep -q "Flask" "requirements.txt" 2>/dev/null; then
        echo "flask"
        return
    fi
    
    # Check pyproject.toml for dependencies
    if [[ -f "pyproject.toml" ]]; then
        if grep -q "django" "pyproject.toml" 2>/dev/null; then
            echo "django"
            return
        elif grep -q "fastapi" "pyproject.toml" 2>/dev/null; then
            echo "fastapi"
            return
        elif grep -q "flask" "pyproject.toml" 2>/dev/null; then
            echo "flask"
            return
        fi
    fi
    
    echo "python"
}

# Function to extract value from Python files (pyproject.toml, setup.py)
extract_python_project_info() {
    local key="$1"
    
    # Try pyproject.toml first
    if [[ -f "pyproject.toml" ]]; then
        case "$key" in
            "name")
                grep -E "^name\s*=" "pyproject.toml" 2>/dev/null | sed -E 's/^name\s*=\s*"([^"]*)".*/\1/'
                ;;
            "version")
                grep -E "^version\s*=" "pyproject.toml" 2>/dev/null | sed -E 's/^version\s*=\s*"([^"]*)".*/\1/'
                ;;
        esac
    fi
}

# Function to detect project framework from package.json
detect_framework_from_package() {
    local package_file="$1"
    
    if [[ ! -f "$package_file" ]]; then
        echo "unknown"
        return
    fi
    
    # Check for Angular
    if grep -q "@angular/core" "$package_file" 2>/dev/null; then
        echo "angular"
        return
    fi
    
    # Check for NestJS
    if grep -q "@nestjs/core" "$package_file" 2>/dev/null; then
        echo "nestjs"
        return
    fi
    
    echo "unknown"
}

# Function to detect project type based on workflow template
detect_project_type() {
    local file="$1"
    
    if grep -q "angular-deploy" "$file" 2>/dev/null; then
        echo "angular"
    elif grep -q "container-nodejs-kubernetes" "$file" 2>/dev/null; then
        echo "nestjs"
    elif grep -q "container-dotnet-kubernetes" "$file" 2>/dev/null; then
        echo "dotnet"
    elif grep -q "container-python-kubernetes" "$file" 2>/dev/null; then
        echo "python"
    else
        echo "unknown"
    fi
}

# Function to extract project-specific information
extract_project_info() {
    local file="$1"
    local project_type="$2"
    
    declare -A project_info
    
    # Common fields for all project types
    project_info["namespace"]=$(extract_yaml_value "$file" "namespace")
    project_info["bu"]=$(extract_yaml_value "$file" "bu")
    project_info["team"]=$(extract_yaml_value "$file" "team")
    project_info["workflow_name"]=$(extract_yaml_value "$file" "name")
    
    # Check if package.json exists for additional information
    local package_json="package.json"
    local package_name=""
    local framework_from_package=""
    
    if [[ -f "$package_json" ]]; then
        package_name=$(extract_package_json_value "$package_json" "name")
        framework_from_package=$(detect_framework_from_package "$package_json")
        
        print_info "Found package.json with name: $package_name, framework: $framework_from_package"
    fi
    
    case "$project_type" in
        "angular")
            # For Angular, prefer datadog_service_name from workflow, fallback to package.json name
            local workflow_app_name=$(extract_yaml_value "$file" "datadog_service_name")
            project_info["app_name"]=${workflow_app_name:-$package_name}
            project_info["node_version"]=$(extract_yaml_value "$file" "node_version")
            project_info["subdomain"]=$(extract_yaml_value "$file" "subdomain")
            project_info["output_path"]=$(extract_yaml_value "$file" "output_path")
            project_info["language"]="typescript"
            project_info["service_type"]="web"
            
            # Add Angular version if detected
            if [[ -f "$package_json" ]]; then
                local angular_version=$(detect_angular_version "$package_json")
                if [[ -n "$angular_version" ]]; then
                    project_info["angular_version"]="$angular_version"
                fi
            fi
            ;;
        "nestjs")
            # For NestJS, prefer app_name from workflow, fallback to package.json name
            local workflow_app_name=$(extract_yaml_value "$file" "app_name")
            project_info["app_name"]=${workflow_app_name:-$package_name}
            project_info["node_version"]=$(extract_yaml_value "$file" "nodeVersion")
            project_info["language"]="javascript"
            project_info["service_type"]="web"
            ;;
        "dotnet")
            project_info["app_name"]=$(extract_yaml_value "$file" "app_name")
            project_info["dotnet_version"]=$(extract_yaml_value "$file" "dotnetVersion")
            project_info["dotnet_sln"]=$(extract_yaml_value "$file" "dotnetSln")
            project_info["language"]="csharp"
            project_info["service_type"]="web"
            ;;
        "python")
            # For Python, prefer app_name from workflow, fallback to pyproject.toml name
            local workflow_app_name=$(extract_yaml_value "$file" "app_name")
            local python_project_name=$(extract_python_project_info "name")
            project_info["app_name"]=${workflow_app_name:-$python_project_name}
            project_info["stack"]=$(extract_yaml_value "$file" "stack")
            project_info["language"]="python"
            project_info["service_type"]="web"
            
            # Add Python-specific information
            local python_version=$(detect_python_version)
            if [[ -n "$python_version" ]]; then
                project_info["python_version"]="$python_version"
            fi
            
            local python_framework=$(detect_python_framework)
            if [[ -n "$python_framework" ]]; then
                project_info["python_framework"]="$python_framework"
            fi
            ;;
        *)
            # Fallback for unknown types - try to get info from package.json
            local workflow_app_name=$(extract_yaml_value "$file" "app_name")
            project_info["app_name"]=${workflow_app_name:-$package_name}
            
            # Determine language based on detected framework
            case "$framework_from_package" in
                "angular")
                    project_info["language"]="typescript"
                    project_type="angular"
                    ;;
                "nestjs")
                    project_info["language"]="javascript"
                    project_type="nestjs"
                    ;;
                *)
                    project_info["language"]="unknown"
                    ;;
            esac
            project_info["service_type"]="web"
            ;;
    esac
    
    # Store the updated project type
    project_info["detected_project_type"]="$project_type"
    
    # Return the associative array as a string (bash limitation workaround)
    for key in "${!project_info[@]}"; do
        echo "${key}=${project_info[$key]}"
    done
}

# Function to find workflow files and extract information
find_workflow_info() {
    local workflows_dir=".github/workflows"
    
    if [[ ! -d "$workflows_dir" ]]; then
        print_error "Directory $workflows_dir not found!"
        exit 1
    fi
    
    print_info "Searching for workflow files in $workflows_dir..."
    
    # Find YAML files in workflows directory
    local workflow_files=($(find "$workflows_dir" -name "*.yml" -o -name "*.yaml"))
    
    if [[ ${#workflow_files[@]} -eq 0 ]]; then
        print_error "No workflow files found in $workflows_dir"
        exit 1
    fi
    
    # Variables to store extracted information
    declare -A extracted_info
    local project_type="unknown"
    local found_valid_workflow=false
    
    # Search through workflow files for relevant information
    for file in "${workflow_files[@]}"; do
        print_info "Analyzing workflow file: $file"
        
        # Check if file contains 'bu' field (indicator of our workflow structure)
        if grep -q "bu:" "$file" 2>/dev/null; then
            project_type=$(detect_project_type "$file")
            print_success "Found $project_type workflow with 'bu' field: $file"
            
            # Extract project-specific information
            while IFS='=' read -r key value; do
                if [[ -n "$key" && -n "$value" ]]; then
                    extracted_info["$key"]="$value"
                fi
            done < <(extract_project_info "$file" "$project_type")
            
            # Check if we have required fields
            if [[ -n "${extracted_info[app_name]}" && -n "${extracted_info[bu]}" ]]; then
                found_valid_workflow=true
                break
            fi
        fi
    done
    
    # Validate required fields
    if [[ "$found_valid_workflow" != true ]]; then
        print_error "Could not find valid workflow with required fields (app_name, bu)"
        exit 1
    fi
    
    # Set defaults for optional fields
    extracted_info["namespace"]=${extracted_info["namespace"]:-"default"}
    extracted_info["team"]=${extracted_info["team"]:-"unknown"}
    extracted_info["workflow_name"]=${extracted_info["workflow_name"]:-"Pipeline"}
    extracted_info["language"]=${extracted_info["language"]:-"unknown"}
    extracted_info["service_type"]=${extracted_info["service_type"]:-"web"}
    
    print_info "Extracted information:"
    echo "  - Project Type: $project_type"
    echo "  - App Name: ${extracted_info[app_name]}"
    echo "  - Namespace: ${extracted_info[namespace]}"
    echo "  - BU: ${extracted_info[bu]}"
    echo "  - Team: ${extracted_info[team]}"
    echo "  - Language: ${extracted_info[language]}"
    echo "  - Service Type: ${extracted_info[service_type]}"
    
    # Show version information if available
    if [[ -n "${extracted_info[node_version]}" ]]; then
        echo "  - Node Version: ${extracted_info[node_version]}"
    fi
    if [[ -n "${extracted_info[dotnet_version]}" ]]; then
        echo "  - .NET Version: ${extracted_info[dotnet_version]}"
    fi
    if [[ -n "${extracted_info[python_version]}" ]]; then
        echo "  - Python Version: ${extracted_info[python_version]}"
    fi
    if [[ -n "${extracted_info[python_framework]}" ]]; then
        echo "  - Python Framework: ${extracted_info[python_framework]}"
    fi
    if [[ -n "${extracted_info[angular_version]}" ]]; then
        echo "  - Angular Version: ${extracted_info[angular_version]}"
    fi
    if [[ -n "${extracted_info[subdomain]}" ]]; then
        echo "  - Subdomain: ${extracted_info[subdomain]}"
    fi
    
    # Generate the entity.datadog.yaml file
    generate_datadog_entity_v2 "$project_type" extracted_info
}

# Function to generate entity.datadog.yaml (new version)
generate_datadog_entity_v2() {
    local project_type="$1"
    local -n info_ref=$2
    
    local output_file="entity.datadog.yaml"
    
    # Check if file already exists
    if [[ -f "$output_file" ]] && [[ "$FORCE_OVERWRITE" != "true" ]]; then
        print_warning "File $output_file already exists. Skipping generation."
        print_info "To regenerate, use: $0 --force"
        print_info "Or delete the existing file first: rm $output_file"
        return 0
    elif [[ -f "$output_file" ]] && [[ "$FORCE_OVERWRITE" == "true" ]]; then
        print_warning "File $output_file already exists. Overwriting due to --force flag."
    fi
    
    print_info "Generating $output_file for $project_type project..."
    
    # Get repository URL if in git repository
    local repo_url=""
    if git remote get-url origin >/dev/null 2>&1; then
        repo_url=$(git remote get-url origin | sed 's/\.git$//')
        # Convert SSH URL to HTTPS if needed
        if [[ "$repo_url" =~ ^git@ ]]; then
            repo_url=$(echo "$repo_url" | sed 's/git@github.com:/https:\/\/github.com\//')
        fi
    fi
    
    # Determine service type based on project type and app name patterns
    local service_type="${info_ref[service_type]}"
    if [[ "${info_ref[app_name]}" =~ worker|job|cron ]]; then
        service_type="worker"
    elif [[ "${info_ref[app_name]}" =~ queue|kafka|redis ]]; then
        service_type="queue"
    fi
    
    # Determine tier based on BU
    local tier="2"
    
    # Build tags array
    local tags=""
    tags+="    - namespace:${info_ref[namespace]}\n"
    tags+="    - bu:${info_ref[bu]}\n"
    tags+="    - team:${info_ref[team]}\n"
    tags+="    - project-type:${project_type}\n"
    
    # Add version-specific tags
    if [[ -n "${info_ref[node_version]}" ]]; then
        tags+="    - node-version:${info_ref[node_version]}\n"
    fi
    if [[ -n "${info_ref[dotnet_version]}" ]]; then
        tags+="    - dotnet-version:${info_ref[dotnet_version]}\n"
    fi
    if [[ -n "${info_ref[python_version]}" ]]; then
        tags+="    - python-version:${info_ref[python_version]}\n"
    fi
    if [[ -n "${info_ref[python_framework]}" ]]; then
        tags+="    - python-framework:${info_ref[python_framework]}\n"
    fi
    if [[ -n "${info_ref[angular_version]}" ]]; then
        tags+="    - angular-version:${info_ref[angular_version]}\n"
    fi
    if [[ -n "${info_ref[subdomain]}" ]]; then
        tags+="    - subdomain:${info_ref[subdomain]}\n"
    fi
    
    # Build links section
    local links=""
    if [[ -n "$repo_url" ]]; then
        links+="    - name: Repository\n"
        links+="      type: repository\n"
        links+="      url: ${repo_url}\n"
        links+="    - name: CI/CD Pipeline\n"
        links+="      type: other\n"
        links+="      url: ${repo_url}/actions\n"
        links+="    - name: Documentation\n"
        links+="      type: documentation\n"
        links+="      url: ${repo_url}#readme\n"
    fi
    
    # Generate project-specific display name
    local display_name=""
    case "$project_type" in
        "angular")
            display_name="${info_ref[app_name]^} Frontend"
            ;;
        "nestjs")
            display_name="${info_ref[app_name]^} API"
            ;;
        "dotnet")
            display_name="${info_ref[app_name]^} Service"
            ;;
        *)
            display_name="${info_ref[app_name]^} Service"
            ;;
    esac
    
    # Generate project-specific description
    local description=""
    case "$project_type" in
        "angular")
            description="Frontend application ${info_ref[app_name]} built with Angular, managed by team ${info_ref[team]}"
            ;;
        "nestjs")
            description="NestJS API service ${info_ref[app_name]} managed by team ${info_ref[team]}"
            ;;
        "dotnet")
            description=".NET service ${info_ref[app_name]} managed by team ${info_ref[team]}"
            ;;
        *)
            description="Service ${info_ref[app_name]} managed by team ${info_ref[team]}"
            ;;
    esac
    
    # Generate the YAML content
    cat > "$output_file" << EOF
apiVersion: v3
kind: service
metadata:
  name: ${info_ref[app_name]}
  displayName: ${display_name}
  description: ${description}
  owner: ${info_ref[team]}
  tags:
$(echo -e "$tags" | sed 's/$//')
  links:
$(echo -e "$links" | sed 's/$//')
spec:
  type: ${service_type}
  lifecycle: production
  tier: ${tier}
  language: ${info_ref[language]}
  dependencies: []
EOF
    
    print_success "Generated $output_file successfully!"
    print_info "File contents:"
    echo "----------------------------------------"
    cat "$output_file"
    echo "----------------------------------------"
}

# Function to show help
show_help() {
    echo "Datadog Entity Generator"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script automatically generates entity.datadog.yaml based on CI workflow configuration."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "The script will:"
    echo "  1. Search for workflow files in .github/workflows/"
    echo "  2. Extract app_name, namespace, bu, team information"
    echo "  3. Generate entity.datadog.yaml in the project root"
    echo ""
}

# Main execution
main() {
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_info "Starting Datadog Entity Generator..."
    
    # Check if we're in a git repository (optional)
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_warning "Not in a git repository. Some features may be limited."
    fi
    
    # Find and process workflow information
    find_workflow_info
    
    print_success "Datadog entity generation completed!"
}

# Run main function with all arguments
main "$@"
