#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FLOWS_DIR=".maestro/flows"

print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

check_maestro() {
    if ! command -v maestro &> /dev/null; then
        print_error "Maestro not installed! Run: curl -Ls https://get.maestro.mobile.dev | bash"
        exit 1
    fi
}

run_flow() {
    local flow=$1
    print_info "Running: $flow"
    if maestro test "$FLOWS_DIR/$flow"; then
        print_success "Passed: $flow"
        return 0
    else
        print_error "Failed: $flow"
        return 1
    fi
}

run_all() {
    print_info "Running all tests..."
    local failed=0 passed=0
    
    for flow in "$FLOWS_DIR"/*.yaml; do
        if run_flow "$(basename "$flow")"; then
            ((passed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    echo "======================================"
    print_success "Passed: $passed"
    [ $failed -gt 0 ] && print_error "Failed: $failed"
    echo "======================================"
    return $failed
}

list_flows() {
    print_info "Available flows:"
    ls -1 "$FLOWS_DIR"/*.yaml 2>/dev/null | xargs -n1 basename || print_error "No flows found"
}

show_usage() {
    cat << EOF
${GREEN}Maestro Test Runner${NC}

Usage: $0 [command]

Commands:
    all           Run all test flows
    flow <name>   Run specific test flow
    list          List all flows
    help          Show this help

Examples:
    $0 all
    $0 flow 01_login.yaml
    $0 list

EOF
}

check_maestro

case "${1:-help}" in
    all)
        run_all
        ;;
    flow)
        [ -z "$2" ] && { print_error "Usage: $0 flow <name>"; exit 1; }
        run_flow "$2"
        ;;
    list)
        list_flows
        ;;
    help|*)
        show_usage
        ;;
esac
    for flow in "$FLOWS_DIR"/*.yaml; do
        echo "  - $(basename "$flow")"
    done
}

# Main script
main() {
    check_maestro
    load_env
    setup_directories
    
    case "${1:-}" in
        all)
            run_all_flows
            ;;
        flow)
            if [ -z "${2:-}" ]; then
                print_error "Please specify a flow name"
                exit 1
            fi
            run_flow "$2"
            ;;
        pattern)
            if [ -z "${2:-}" ]; then
                print_error "Please specify a pattern"
                exit 1
            fi
            run_flows_by_pattern "$2"
            ;;
        env)
            if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
                print_error "Please specify environment and command"
                print_info "Example: $0 env dev all"
                exit 1
            fi
            env_name=$2
            shift 2
            run_with_env "$env_name" "$0" "$@"
            ;;
        cleanup)
            cleanup
            ;;
        list)
            list_flows
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Invalid command: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
