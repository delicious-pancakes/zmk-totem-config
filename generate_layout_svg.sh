#!/bin/bash
# Generate SVG and JPG layout visualization from ZMK keymap
# Usage: ./generate_layout_svg.sh [keymap_file] [output_base]
# Example: ./generate_layout_svg.sh config/totem.keymap totem_layout
#          Generates totem_layout.svg and totem_layout.jpg

KEYMAP_FILE="${1:-config/totem.keymap}"
OUTPUT_BASE="${2:-totem_layout}"
SVG_FILE="${OUTPUT_BASE}.svg"
JPG_FILE="${OUTPUT_BASE}.jpg"

if [[ ! -f "$KEYMAP_FILE" ]]; then
    echo "Error: Keymap file not found: $KEYMAP_FILE" >&2
    exit 1
fi

echo "Generating ${SVG_FILE}..." >&2

awk '
BEGIN {
    init_labels()
    layer_count = 0
    in_bindings = 0
    layer_names[0] = "BASE"
    layer_names[1] = "NAV"
    layer_names[2] = "1HAND"
    layer_names[3] = "1HAND2"
    # Map #define names to layer indices
    layer_defines["BASE"] = 0
    layer_defines["NAV"] = 1
    layer_defines["ONEHAND"] = 2
    layer_defines["ONEHAND2"] = 3
}

# Parse #define for layer indices
/^#define [A-Z]+ [0-9]+/ {
    name = $2
    idx = $3
    layer_defines[name] = idx
}

function init_labels() {
    labels["&kp Q"] = "Q"; labels["&kp W"] = "W"; labels["&kp E"] = "E"; labels["&kp R"] = "R"; labels["&kp T"] = "T"
    labels["&kp Y"] = "Y"; labels["&kp U"] = "U"; labels["&kp I"] = "I"; labels["&kp O"] = "O"; labels["&kp P"] = "P"
    labels["&kp A"] = "A"; labels["&kp S"] = "S"; labels["&kp D"] = "D"; labels["&kp F"] = "F"; labels["&kp G"] = "G"
    labels["&kp H"] = "H"; labels["&kp J"] = "J"; labels["&kp K"] = "K"; labels["&kp L"] = "L"; labels["&kp M"] = "M"
    labels["&kp N"] = "N"; labels["&kp Z"] = "Z"; labels["&kp X"] = "X"; labels["&kp C"] = "C"; labels["&kp V"] = "V"
    labels["&kp B"] = "B"
    labels["&kp N0"] = "0"; labels["&kp N1"] = "1"; labels["&kp N2"] = "2"; labels["&kp N3"] = "3"; labels["&kp N4"] = "4"
    labels["&kp N5"] = "5"; labels["&kp N6"] = "6"; labels["&kp N7"] = "7"; labels["&kp N8"] = "8"; labels["&kp N9"] = "9"
    labels["&kp SEMI"] = ";"
    labels["&kp COMMA"] = ","
    labels["&kp DOT"] = "."
    labels["&kp SLASH"] = "/"
    labels["&kp GRAVE"] = "`"
    labels["&kp EQUAL"] = "="
    labels["&kp MINUS"] = "-"
    labels["&kp APOS"] = "QUOT"
    labels["&kp LPAR"] = "("
    labels["&kp RPAR"] = ")"
    labels["&kp LBRC"] = "{"
    labels["&kp RBRC"] = "}"
    labels["&kp LBKT"] = "["
    labels["&kp RBKT"] = "]"
    labels["&kp LSHIFT"] = "SHIFT"
    labels["&kp RSHIFT"] = "SHIFT"
    labels["&kp LCTRL"] = "CTRL"
    labels["&kp RCTRL"] = "CTRL"
    labels["&kp LALT"] = "ALT"
    labels["&kp RALT"] = "ALT"
    labels["&kp LGUI"] = "WIN"
    labels["&kp RGUI"] = "WIN"
    labels["&kp SPACE"] = "SPACE"
    labels["&kp BSPC"] = "BSPC"
    labels["&kp DEL"] = "DEL"
    labels["&kp ENTER"] = "ENTER"
    labels["&kp TAB"] = "TAB"
    labels["&kp ESC"] = "ESC"
    labels["&kp UP"] = "UP"
    labels["&kp DOWN"] = "DOWN"
    labels["&kp LEFT"] = "LEFT"
    labels["&kp RIGHT"] = "RIGHT"
    labels["&kp HOME"] = "HOME"
    labels["&kp END"] = "END"
    labels["&kp PG_UP"] = "PGUP"
    labels["&kp PG_DN"] = "PGDN"
    labels["&kp F1"] = "F1"; labels["&kp F2"] = "F2"; labels["&kp F3"] = "F3"; labels["&kp F4"] = "F4"
    labels["&kp F5"] = "F5"; labels["&kp F6"] = "F6"; labels["&kp F7"] = "F7"; labels["&kp F8"] = "F8"
    labels["&kp F9"] = "F9"; labels["&kp F10"] = "F10"; labels["&kp F11"] = "F11"; labels["&kp F12"] = "F12"
    labels["&trans"] = ""
    labels["&none"] = ""
}

/label = "/ {
    # Extract label name without gawk-specific match() syntax
    s = $0
    sub(/.*label = "/, "", s)
    sub(/".*/, "", s)
    if (s != "") {
        layer_names[layer_count] = s
    }
}

# Match bindings that span multiple lines (not single-line combo bindings)
/bindings = </ && !/>;/ {
    in_bindings = 1
    key_index = 0
    next
}

in_bindings && />;/ {
    in_bindings = 0
    layer_count++
    next
}

in_bindings {
    gsub(/^[ \t]+/, "")
    gsub(/[ \t]+$/, "")
    if ($0 == "") next

    n = split($0, tokens, /[ \t]+/)

    for (i = 1; i <= n; i++) {
        token = tokens[i]
        if (token == "") continue

        if (token ~ /^&kp$/ || token ~ /^&mo$/ || token ~ /^&to$/ || token ~ /^&tog$/ || token ~ /^&lt$/ || token ~ /^&mt$/ || token ~ /^&sk$/ || token ~ /^&sl$/) {
            if (i + 1 <= n) {
                i++
                full_key = token " " tokens[i]
            } else {
                full_key = token
            }
        } else if (token ~ /^&/) {
            full_key = token
        } else {
            continue
        }

        layer_keys[layer_count, key_index] = full_key
        key_index++
    }
}

END {
    print_svg_header()

    title_colors[0] = "#ff0080"; title_glows[0] = "pinkGlow"
    title_colors[1] = "#00ffff"; title_glows[1] = "blueGlow"
    title_colors[2] = "#ff9933"; title_glows[2] = "orangeGlow"
    title_colors[3] = "#ff3366"; title_glows[3] = "redGlow"

    layer_y[0] = 20; layer_y[1] = 290; layer_y[2] = 560; layer_y[3] = 830

    for (layer = 0; layer < layer_count; layer++) {
        y_offset = layer_y[layer]
        layer_name = layer_names[layer]

        printf "\n  <!-- ==================== %s LAYER ==================== -->\n", layer_name
        printf "  <g transform=\"translate(50, %d)\">\n", y_offset
        printf "    <text x=\"400\" y=\"25\" text-anchor=\"middle\" fill=\"%s\" font-family=\"system-ui, sans-serif\" font-size=\"16\" font-weight=\"bold\" filter=\"url(#%s)\">%s</text>\n", title_colors[layer], title_glows[layer], layer_name

        for (k = 0; k < 5; k++) render_key(layer, k, 60 + k * 55, 40, 50, 50)
        for (k = 5; k < 10; k++) render_key(layer, k, 470 + (k - 5) * 55, 40, 50, 50)
        for (k = 10; k < 15; k++) render_key(layer, k, 60 + (k - 10) * 55, 95, 50, 50)
        for (k = 15; k < 20; k++) render_key(layer, k, 470 + (k - 15) * 55, 95, 50, 50)

        row3_lx[1] = 5; row3_lx[2] = 60; row3_lx[3] = 115; row3_lx[4] = 170; row3_lx[5] = 225; row3_lx[6] = 280
        for (k = 20; k < 26; k++) render_key(layer, k, row3_lx[k - 19], 150, 50, 50)

        row3_rx[1] = 470; row3_rx[2] = 525; row3_rx[3] = 580; row3_rx[4] = 635; row3_rx[5] = 690; row3_rx[6] = 745
        for (k = 26; k < 32; k++) render_key(layer, k, row3_rx[k - 25], 150, 50, 50)

        for (k = 32; k < 35; k++) render_thumb_key(layer, k, 170 + (k - 32) * 55, 210, 50, 45)
        for (k = 35; k < 38; k++) render_thumb_key(layer, k, 470 + (k - 35) * 55, 210, 50, 45)

        print "  </g>"
    }

    print "</svg>"
}

function print_svg_header() {
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    print "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 900 1100\" width=\"900\" height=\"1100\">"
    print "  <defs>"
    print "    <linearGradient id=\"keyGrad\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">"
    print "      <stop offset=\"0%\" style=\"stop-color:#2d2d3d\"/>"
    print "      <stop offset=\"100%\" style=\"stop-color:#1a1a24\"/>"
    print "    </linearGradient>"
    print "    <linearGradient id=\"thumbGrad\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">"
    print "      <stop offset=\"0%\" style=\"stop-color:#00e6e6\"/>"
    print "      <stop offset=\"100%\" style=\"stop-color:#00e6e6\"/>"
    print "    </linearGradient>"
    print "    <linearGradient id=\"layerGrad\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">"
    print "      <stop offset=\"0%\" style=\"stop-color:#ff2090\"/>"
    print "      <stop offset=\"100%\" style=\"stop-color:#ff2090\"/>"
    print "    </linearGradient>"
    print "    <linearGradient id=\"orangeGrad\" x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\">"
    print "      <stop offset=\"0%\" style=\"stop-color:#ff9922\"/>"
    print "      <stop offset=\"100%\" style=\"stop-color:#ff9922\"/>"
    print "    </linearGradient>"
    print "    <filter id=\"keyShadow\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\">"
    print "      <feDropShadow dx=\"0\" dy=\"2\" stdDeviation=\"3\" flood-color=\"#ff0080\" flood-opacity=\"0.3\"/>"
    print "    </filter>"
    print "    <filter id=\"pinkGlow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">"
    print "      <feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#ff0080\" flood-opacity=\"0.7\"/>"
    print "    </filter>"
    print "    <filter id=\"blueGlow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">"
    print "      <feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#00ffff\" flood-opacity=\"0.7\"/>"
    print "    </filter>"
    print "    <filter id=\"orangeGlow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">"
    print "      <feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#ff8800\" flood-opacity=\"0.7\"/>"
    print "    </filter>"
    print "    <filter id=\"redGlow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">"
    print "      <feDropShadow dx=\"0\" dy=\"0\" stdDeviation=\"5\" flood-color=\"#ff3366\" flood-opacity=\"0.7\"/>"
    print "    </filter>"
    print "  </defs>"
    print ""
    print "  <rect width=\"900\" height=\"1100\" fill=\"#0a0a14\"/>"
}

function get_layer_name(ref) {
    # ref can be a number or a #define name like ONEHAND
    if (ref ~ /^[0-9]+$/) {
        return layer_names[int(ref)]
    }
    if (ref in layer_defines) {
        return layer_names[layer_defines[ref]]
    }
    return ref
}

function get_label(keycode) {
    if (keycode in labels) {
        return labels[keycode]
    }

    if (keycode ~ /^&mo /) {
        layer_ref = keycode
        gsub(/^&mo /, "", layer_ref)
        return get_layer_name(layer_ref)
    }
    if (keycode ~ /^&to /) {
        layer_ref = keycode
        gsub(/^&to /, "", layer_ref)
        return get_layer_name(layer_ref)
    }
    if (keycode ~ /^&tog /) {
        layer_ref = keycode
        gsub(/^&tog /, "", layer_ref)
        return get_layer_name(layer_ref)
    }
    if (keycode ~ /^&sl /) {
        layer_ref = keycode
        gsub(/^&sl /, "", layer_ref)
        return get_layer_name(layer_ref)
    }
    if (keycode ~ /^&lt /) {
        n = split(keycode, parts, " ")
        if (n >= 3 && parts[3] != "") {
            return parts[3]
        }
        return "LT"
    }

    if (keycode ~ /^&kp /) {
        lbl = keycode
        gsub(/^&kp /, "", lbl)
        return lbl
    }

    return ""
}

function get_key_type(keycode) {
    if (keycode ~ /^&mo /) return "layer_mo"
    if (keycode ~ /^&sl /) return "layer_sl"
    if (keycode ~ /^&to /) return "layer_to"
    if (keycode ~ /^&tog /) return "layer_to"
    if (keycode == "&trans" || keycode == "&none") return "trans"
    return "normal"
}

function render_key(layer, key_idx, x, y, w, h) {
    keycode = layer_keys[layer, key_idx]
    label = get_label(keycode)
    key_type = get_key_type(keycode)

    fill = "url(#keyGrad)"
    stroke = "#3d3d4d"
    opacity = 1
    text_fill = "#e6b3cc"
    font_size = 16
    text_y = y + 32

    if (key_type == "trans") {
        opacity = 0.5
        label = ""
    } else if (length(label) > 2) {
        text_fill = "#9999b3"
        font_size = 10
        text_y = y + 28
    }

    printf "    <g filter=\"url(#keyShadow)\">\n"
    if (opacity < 1) {
        printf "      <rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" rx=\"6\" fill=\"%s\" stroke=\"%s\" stroke-width=\"1\" opacity=\"%.1f\"/>\n", x, y, w, h, fill, stroke, opacity
    } else {
        printf "      <rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" rx=\"6\" fill=\"%s\" stroke=\"%s\" stroke-width=\"1\"/>\n", x, y, w, h, fill, stroke
    }
    if (label != "") {
        label = escape_xml(label)
        if (font_size == 16) {
            printf "      <text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"%s\" font-family=\"monospace\" font-size=\"%d\" font-weight=\"bold\">%s</text>\n", x + w/2, text_y, text_fill, font_size, label
        } else {
            printf "      <text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"%s\" font-family=\"system-ui, sans-serif\" font-size=\"%d\">%s</text>\n", x + w/2, text_y, text_fill, font_size, label
        }
    }
    printf "    </g>\n"
}

function render_thumb_key(layer, key_idx, x, y, w, h) {
    keycode = layer_keys[layer, key_idx]
    label = get_label(keycode)
    key_type = get_key_type(keycode)

    fill = "#00d4d4"
    stroke = "#00ffff"
    text_fill = "#0a0a14"
    font_size = 10
    text_y = y + 28

    if (key_type == "layer_mo") {
        fill = "#dd1080"
        stroke = "#ff40aa"
        font_size = 9
    } else if (key_type == "layer_sl") {
        fill = "#00cc00"
        stroke = "#39ff14"
        font_size = 9
    } else if (key_type == "layer_to") {
        fill = "#dd7700"
        stroke = "#ffaa33"
        font_size = 9
    }

    printf "    <g filter=\"url(#keyShadow)\">\n"
    printf "      <rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" rx=\"6\" fill=\"%s\" stroke=\"%s\" stroke-width=\"1\"/>\n", x, y, w, h, fill, stroke
    if (label != "") {
        label = escape_xml(label)
        printf "      <text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"%s\" font-family=\"system-ui, sans-serif\" font-size=\"%d\">%s</text>\n", x + w/2, text_y, text_fill, font_size, label
    }
    printf "    </g>\n"
}

function escape_xml(str) {
    gsub(/&/, "\\&amp;", str)
    gsub(/</, "\\&lt;", str)
    gsub(/>/, "\\&gt;", str)
    return str
}
' "$KEYMAP_FILE" > "$SVG_FILE"

echo "Generating ${JPG_FILE}..." >&2
convert -density 150 -background '#0a0a14' "$SVG_FILE" "$JPG_FILE"

echo "Done: ${SVG_FILE}, ${JPG_FILE}" >&2
