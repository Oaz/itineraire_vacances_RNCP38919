#!/bin/bash
set -e

echo "Processing Mermaid diagrams..."
echo "Current user: $(id)"
echo "Google Chrome path: $(which google-chrome)"
echo "Google Chrome version: $(google-chrome --version)"

# Make a copy of the config file in the user's home directory for accessibility
mkdir -p $HOME/.config
cp /etc/puppeteer/config.json $HOME/.config/puppeteer-config.json

# Create a temporary directory for dimension analysis
mkdir -p $HOME/temp_mermaid

# Use a two-pass approach to generate optimally sized PNGs
find . -name "*.mmd" | while read -r file; do
    base_name=$(basename "$file" .mmd)
    dir_name=$(dirname "$file")
    temp_svg="$HOME/temp_mermaid/${base_name}_temp.svg"
    output_file="${dir_name}/gen/${base_name}.png"
    mkdir -p "${dir_name}/gen"

    echo "Analyzing dimensions for $file"
    
    # First pass: Generate an SVG to analyze dimensions
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    mmdc -i "$file" -o "$temp_svg" -b transparent \
         --puppeteerConfigFile $HOME/.config/puppeteer-config.json
         
    # Extract width and height from the SVG
    if [ -f "$temp_svg" ]; then
        # Extract width and height attributes from SVG
        width=$(grep -oP 'width="\K[^"]+' "$temp_svg" | head -1 | sed 's/pt//g')
        height=$(grep -oP 'height="\K[^"]+' "$temp_svg" | head -1 | sed 's/pt//g')
        echo "Extracted dimensions: ${width}x${height} for $file"

        # Check if we got valid numbers
        if [[ -n "$width" && -n "$height" && "$width" =~ ^[0-9]+(\.[0-9]+)?$ && "$height" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            # Calculate higher resolution (multiply by 4 for print quality ~300 DPI)
            width=$(echo "$width * 4" | bc | cut -d'.' -f1)
            height=$(echo "$height * 4" | bc | cut -d'.' -f1)
            
            # Ensure minimum dimensions
            width=$(( width > 800 ? width : 800 ))
            height=$(( height > 600 ? height : 600 ))
            
            echo "Detected dimensions: ${width}x${height} for $file"
        else
            # Default dimensions if extraction failed
            width=2400
            height=1800
            echo "Could not detect dimensions, using defaults: ${width}x${height} for $file"
        fi
    else
        # Default dimensions if SVG generation failed
        width=2400
        height=1800
        echo "Could not generate temporary SVG, using defaults: ${width}x${height} for $file"
    fi
    
    # Second pass: Generate the final PNG with calculated dimensions
    echo "Converting $file to $output_file with dimensions ${width}x${height}"
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome \
    mmdc -i "$file" -o "$output_file" -b transparent \
         --puppeteerConfigFile $HOME/.config/puppeteer-config.json \
         -w "$width" -H "$height"
         
    # Clean up temporary SVG
    rm -f "$temp_svg"
done

# Clean up temporary directory
rm -rf $HOME/temp_mermaid

echo "Compiling Typst document..."
# Check if a specific file was provided as an argument
if [ $# -ge 1 ]; then
    input_file="$1"
    shift
    # Compile with any additional arguments passed to the container
    typst compile --font-path /fonts "$input_file" "$@"
else
    # Look for .typ files in the current directory and compile the first one found
    files=(*.typ)
    if [ -f "${files[0]}" ]; then
        typst compile --font-path /fonts "${files[0]}"
    else
        echo "No .typ file found in the current directory. Please provide a file to compile."
        exit 1
    fi
fi