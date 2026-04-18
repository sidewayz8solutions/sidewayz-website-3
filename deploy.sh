#!/bin/bash

# ============================================================================
# Sidewayz8Solutions Deployment Script
# ============================================================================
# This script validates, optimizes, and packages the website for deployment
# to various hosting platforms (GitHub Pages, Vercel, Netlify, Cloudflare Pages)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR"
DIST_DIR="$SCRIPT_DIR/dist"
ASSETS_DIR="$SRC_DIR/assets"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Sidewayz8Solutions Deploy Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Validation Functions
# ============================================================================

validate_html() {
    log_info "Validating HTML structure..."
    
    local html_file="$SRC_DIR/index.html"
    
    if [ ! -f "$html_file" ]; then
        log_error "index.html not found in $SRC_DIR"
        return 1
    fi
    
    # Check for essential HTML5 elements
    local checks=(
        "<!DOCTYPE html>:doctype"
        "<html:html_tag"
        "<head:head_tag"
        "<body:body_tag"
        "<title:title_tag"
        "charset:charset"
        "viewport:viewport_meta"
    )
    
    local failed=0
    for check in "${checks[@]}"; do
        IFS=':' read -r pattern name <<< "$check"
        if ! grep -qi "$pattern" "$html_file"; then
            log_error "Missing: $name"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "HTML structure validated"
        return 0
    else
        log_error "HTML validation failed with $failed errors"
        return 1
    fi
}

validate_css() {
    log_info "Checking CSS files..."
    
    local css_files=("$SRC_DIR"/*.css)
    local found=0
    
    for file in "${css_files[@]}"; do
        if [ -f "$file" ]; then
            found=1
            log_success "Found CSS: $(basename "$file")"
        fi
    done
    
    if [ $found -eq 0 ]; then
        log_warn "No CSS files found (inline styles may be used)"
    fi
}

validate_js() {
    log_info "Checking JavaScript files..."
    
    local js_files=("$SRC_DIR"/*.js)
    local found=0
    
    for file in "${js_files[@]}"; do
        if [ -f "$file" ]; then
            found=1
            log_success "Found JS: $(basename "$file")"
            
            # Basic syntax check if node is available
            if command_exists node; then
                if node --check "$file" 2>/dev/null; then
                    log_success "JS syntax valid: $(basename "$file")"
                else
                    log_warn "JS syntax issues in: $(basename "$file")"
                fi
            fi
        fi
    done
    
    if [ $found -eq 0 ]; then
        log_warn "No JS files found (may be inline or not needed)"
    fi
}

validate_meta_tags() {
    log_info "Validating SEO meta tags..."
    
    local html_file="$SRC_DIR/index.html"
    local meta_checks=(
        "description:meta description"
        "og:title:Open Graph title"
        "og:description:Open Graph description"
        "og:image:Open Graph image"
        "twitter:card:Twitter card"
    )
    
    local failed=0
    for check in "${meta_checks[@]}"; do
        IFS=':' read -r pattern name <<< "$check"
        if ! grep -qi "$pattern" "$html_file"; then
            log_warn "Missing meta tag: $name"
            failed=$((failed + 1))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_success "All SEO meta tags present"
    else
        log_warn "Some SEO meta tags missing ($failed)"
    fi
}

# ============================================================================
# Optimization Functions
# ============================================================================

optimize_images() {
    log_info "Optimizing images..."
    
    local img_dir="$SRC_DIR/images"
    
    if [ ! -d "$img_dir" ]; then
        log_warn "No images directory found"
        return 0
    fi
    
    # Check for optimization tools
    if command_exists imagemin; then
        log_info "Using imagemin for optimization..."
        imagemin "$img_dir/*" --out-dir="$DIST_DIR/images" || true
    elif command_exists npx; then
        log_info "Using npx imagemin..."
        npx imagemin-cli "$img_dir/*" --out-dir="$DIST_DIR/images" || true
    else
        log_warn "No image optimizer found. Copying images as-is."
        mkdir -p "$DIST_DIR/images"
        cp -r "$img_dir"/* "$DIST_DIR/images/" 2>/dev/null || true
    fi
    
    # Optimize SVGs if svgo is available
    if command_exists svgo || command_exists npx; then
        log_info "Optimizing SVG files..."
        find "$img_dir" -name "*.svg" -exec sh -c '
            if command_exists svgo; then
                svgo "$1" -o "$2/$(basename "$1")"
            else
                npx svgo "$1" -o "$2/$(basename "$1")"
            fi
        ' _ {} "$DIST_DIR/images" \; 2>/dev/null || true
    fi
    
    log_success "Image optimization complete"
}

minify_assets() {
    log_info "Minifying assets..."
    
    # CSS minification
    if [ -f "$SRC_DIR/style.css" ]; then
        if command_exists npx; then
            npx clean-css-cli "$SRC_DIR/style.css" -o "$DIST_DIR/style.min.css" 2>/dev/null || \
                cp "$SRC_DIR/style.css" "$DIST_DIR/style.min.css"
        else
            cp "$SRC_DIR/style.css" "$DIST_DIR/style.css"
        fi
    fi
    
    # JS minification
    if [ -f "$SRC_DIR/script.js" ]; then
        if command_exists npx; then
            npx terser "$SRC_DIR/script.js" -o "$DIST_DIR/script.min.js" 2>/dev/null || \
                cp "$SRC_DIR/script.js" "$DIST_DIR/script.js"
        else
            cp "$SRC_DIR/script.js" "$DIST_DIR/script.js"
        fi
    fi
    
    log_success "Asset minification complete"
}

# ============================================================================
# Build Functions
# ============================================================================

clean_dist() {
    log_info "Cleaning dist directory..."
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    log_success "Dist directory cleaned"
}

copy_assets() {
    log_info "Copying assets to dist..."
    
    # Copy HTML
    cp "$SRC_DIR/index.html" "$DIST_DIR/"
    
    # Copy assets
    if [ -d "$ASSETS_DIR" ]; then
        cp -r "$ASSETS_DIR" "$DIST_DIR/"
    fi
    
    # Copy any other static files
    for file in "$SRC_DIR"/*.{css,js,json,xml,txt}; do
        if [ -f "$file" ]; then
            cp "$file" "$DIST_DIR/"
        fi
    done 2>/dev/null || true
    
    log_success "Assets copied"
}

generate_sitemap() {
    log_info "Generating sitemap.xml..."
    
    local domain="${DEPLOY_DOMAIN:-sidewayz8solutions.com}"
    local date=$(date +%Y-%m-%d)
    
    cat > "$DIST_DIR/sitemap.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://$domain/</loc>
    <lastmod>$date</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
EOF
    
    log_success "Sitemap generated"
}

generate_robots() {
    log_info "Generating robots.txt..."
    
    local domain="${DEPLOY_DOMAIN:-sidewayz8solutions.com}"
    
    cat > "$DIST_DIR/robots.txt" << EOF
User-agent: *
Allow: /

Sitemap: https://$domain/sitemap.xml
EOF
    
    log_success "robots.txt generated"
}

# ============================================================================
# Deployment Instructions
# ============================================================================

print_deployment_instructions() {
    local platform="$1"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Instructions: $platform${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    case "$platform" in
        github)
            echo -e "${YELLOW}GitHub Pages Deployment:${NC}"
            echo ""
            echo "1. Create a repository: github.com/new"
            echo "2. Push your dist folder to the repository:"
            echo "   git init"
            echo "   git add dist/"
            echo "   git commit -m \"Initial commit\""
            echo "   git remote add origin https://github.com/YOUR_USERNAME/sidewayz8solutions.git"
            echo "   git push -u origin main"
            echo ""
            echo "3. Enable GitHub Pages:"
            echo "   - Go to Settings > Pages"
            echo "   - Source: Deploy from a branch"
            echo "   - Branch: main /root"
            echo ""
            echo "4. Your site will be at: https://YOUR_USERNAME.github.io/sidewayz8solutions"
            echo ""
            echo -e "${BLUE}Alternative: Use GitHub Actions for automatic deployment${NC}"
            ;;
            
        vercel)
            echo -e "${YELLOW}Vercel Deployment:${NC}"
            echo ""
            echo "1. Install Vercel CLI:"
            echo "   npm i -g vercel"
            echo ""
            echo "2. Deploy from dist folder:"
            echo "   cd dist && vercel --prod"
            echo ""
            echo "3. Or connect your Git repo:"
            echo "   - Go to vercel.com/new"
            echo "   - Import your Git repository"
            echo "   - Framework Preset: Other"
            echo "   - Build Command: (leave empty or echo 'No build needed')"
            echo "   - Output Directory: dist"
            echo ""
            echo "4. Custom domain:"
            echo "   - Go to Project Settings > Domains"
            echo "   - Add: sidewayz8solutions.com"
            ;;
            
        netlify)
            echo -e "${YELLOW}Netlify Deployment:${NC}"
            echo ""
            echo "1. Install Netlify CLI:"
            echo "   npm i -g netlify-cli"
            echo ""
            echo "2. Deploy:"
            echo "   netlify deploy --prod --dir=dist"
            echo ""
            echo "3. Or drag-and-drop:"
            echo "   - Go to app.netlify.com/drop"
            echo "   - Drag your dist folder"
            echo ""
            echo "4. Connect Git repo for CI/CD:"
            echo "   - Go to Site settings > Build & deploy"
            echo "   - Build command: (leave empty)"
            echo "   - Publish directory: dist"
            ;;
            
        cloudflare)
            echo -e "${YELLOW}Cloudflare Pages Deployment:${NC}"
            echo ""
            echo "1. Via Dashboard:"
            echo "   - Go to dash.cloudflare.com"
            echo "   - Pages > Create a project"
            echo "   - Upload dist folder directly"
            echo ""
            echo "2. Via Wrangler CLI:"
            echo "   npm i -g wrangler"
            echo "   wrangler pages deploy dist --project-name=sidewayz8solutions"
            echo ""
            echo "3. Build settings (if connecting Git):"
            echo "   - Build command: (leave empty)"
            echo "   - Build output directory: dist"
            echo ""
            echo "4. Custom domain:"
            echo "   - Custom domains > Set up a custom domain"
            echo "   - Add: sidewayz8solutions.com"
            ;;
            
        *)
            echo -e "${YELLOW}General Deployment:${NC}"
            echo "Your dist/ folder is ready for deployment!"
            echo "Upload the contents of dist/ to your hosting provider."
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    local action="${1:-all}"
    local deploy_target="${2:-}"
    
    case "$action" in
        validate)
            validate_html
            validate_css
            validate_js
            validate_meta_tags
            ;;
            
        optimize)
            optimize_images
            minify_assets
            ;;
            
        build)
            clean_dist
            validate_html
            validate_css
            validate_js
            copy_assets
            optimize_images
            minify_assets
            generate_sitemap
            generate_robots
            log_success "Build complete! Check the dist/ folder."
            ;;
            
        deploy)
            clean_dist
            validate_html
            validate_css
            validate_js
            copy_assets
            optimize_images
            minify_assets
            generate_sitemap
            generate_robots
            
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}  Build Complete!${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            
            print_deployment_instructions "$deploy_target"
            ;;
            
        all|*)
            clean_dist
            validate_html
            validate_css
            validate_js
            validate_meta_tags
            copy_assets
            optimize_images
            minify_assets
            generate_sitemap
            generate_robots
            
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}  All Tasks Complete!${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            echo "Your dist/ folder is ready for deployment."
            echo ""
            echo "Usage: ./deploy.sh deploy [platform]"
            echo "Platforms: github, vercel, netlify, cloudflare"
            echo ""
            ;;
    esac
}

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Sidewayz8Solutions Deployment Script"
    echo ""
    echo "Usage: ./deploy.sh [action] [platform]"
    echo ""
    echo "Actions:"
    echo "  validate    - Validate HTML/CSS/JS only"
    echo "  optimize    - Optimize images and assets"
    echo "  build       - Build production package"
    echo "  deploy      - Build and show deployment instructions"
    echo "  all         - Run all tasks (default)"
    echo ""
    echo "Platforms (for deploy action):"
    echo "  github      - GitHub Pages"
    echo "  vercel      - Vercel"
    echo "  netlify     - Netlify"
    echo "  cloudflare  - Cloudflare Pages"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh                    # Run all tasks"
    echo "  ./deploy.sh validate           # Validate only"
    echo "  ./deploy.sh deploy vercel      # Build + Vercel instructions"
    exit 0
fi

main "$@"
