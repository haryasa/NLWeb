#!/bin/bash

# URL Replacer Script
# A utility script for replacing URLs and other text patterns in files
# Usage: ./url_replacer.sh [options]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Display usage information
show_usage() {
    echo "URL Replacer Script - A utility for text replacement operations"
    echo ""
    echo "Usage: $0 [OPTION] [ARGUMENTS]"
    echo ""
    echo "Options:"
    echo "  -r, --replace-url     Replace URLs in a file"
    echo "  -c, --count          Count occurrences of a pattern"
    echo "  -b, --backup         Create backup before replacement"
    echo "  -v, --verify         Verify replacement results"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -r old_url new_url file.json"
    echo "  $0 -c 'pattern' file.txt"
    echo "  $0 -b -r old_url new_url file.json"
    echo ""
}

# Create backup of file
create_backup() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup_file"
        print_info "Backup created: $backup_file"
    else
        print_error "File not found: $file"
        exit 1
    fi
}

# Replace URLs in file
replace_url() {
    local old_url="$1"
    local new_url="$2"
    local file="$3"
    local create_backup_flag="$4"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        exit 1
    fi
    
    # Create backup if requested
    if [ "$create_backup_flag" = "true" ]; then
        create_backup "$file"
    fi
    
    # Count occurrences before replacement
    local count_before=$(grep -o "$old_url" "$file" | wc -l)
    
    if [ "$count_before" -eq 0 ]; then
        print_warning "No occurrences of '$old_url' found in $file"
        return 0
    fi
    
    print_info "Found $count_before occurrences of '$old_url'"
    
    # Perform replacement using sed with | as delimiter to avoid issues with URLs
    sed -i "s|$old_url|$new_url|g" "$file"
    
    # Count occurrences after replacement
    local count_after=$(grep -o "$new_url" "$file" | wc -l)
    
    print_success "Replacement completed!"
    print_info "Replaced $count_before occurrences"
    print_info "Found $count_after occurrences of new URL"
}

# Count occurrences of a pattern
count_pattern() {
    local pattern="$1"
    local file="$2"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        exit 1
    fi
    
    local count=$(grep -o "$pattern" "$file" | wc -l)
    print_info "Pattern '$pattern' found $count times in $file"
}

# Verify replacement results
verify_replacement() {
    local old_url="$1"
    local new_url="$2"
    local file="$3"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        exit 1
    fi
    
    local old_count=$(grep -o "$old_url" "$file" | wc -l)
    local new_count=$(grep -o "$new_url" "$file" | wc -l)
    
    print_info "Verification Results:"
    print_info "Old URL '$old_url': $old_count occurrences"
    print_info "New URL '$new_url': $new_count occurrences"
    
    if [ "$old_count" -eq 0 ] && [ "$new_count" -gt 0 ]; then
        print_success "Replacement appears successful!"
    elif [ "$old_count" -gt 0 ]; then
        print_warning "Some old URLs may still exist"
    else
        print_warning "No URLs found"
    fi
}

# Main script logic
main() {
    local backup_flag="false"
    local operation=""
    local args=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--replace-url)
                operation="replace"
                shift
                ;;
            -c|--count)
                operation="count"
                shift
                ;;
            -b|--backup)
                backup_flag="true"
                shift
                ;;
            -v|--verify)
                operation="verify"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Execute based on operation
    case $operation in
        replace)
            if [ ${#args[@]} -lt 3 ]; then
                print_error "Replace operation requires: old_url new_url file"
                show_usage
                exit 1
            fi
            replace_url "${args[0]}" "${args[1]}" "${args[2]}" "$backup_flag"
            ;;
        count)
            if [ ${#args[@]} -lt 2 ]; then
                print_error "Count operation requires: pattern file"
                show_usage
                exit 1
            fi
            count_pattern "${args[0]}" "${args[1]}"
            ;;
        verify)
            if [ ${#args[@]} -lt 3 ]; then
                print_error "Verify operation requires: old_url new_url file"
                show_usage
                exit 1
            fi
            verify_replacement "${args[0]}" "${args[1]}" "${args[2]}"
            ;;
        *)
            print_error "No operation specified"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 