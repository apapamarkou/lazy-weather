#!/usr/bin/env bash
# ui.sh — FZF interactive city picker and display helpers

# ── FZF city picker ───────────────────────────────────────────────────────────

# Show fzf city picker; prints selected city name to stdout
pick_city() {
    local cities=("$@")

    if [[ ${#cities[@]} -eq 0 ]]; then
        lw_error "No cities configured. Add cities to ${LW_CONFIG_FILE}"
        return 1
    fi

    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/lazy-weather"

    while true; do
        local result
        result=$({ printf '%s\n' "${cities[@]}"; echo "── Exit ──"; } | \
            fzf \
                --ansi \
                --reverse \
                --height=100% \
                --border=rounded \
                --prompt="  City > " \
                --header="$(echo -e "${C_CYAN}${C_BOLD}lazy-weather${C_RESET}  ${C_DIM}Enter:default · ^R:refresh · ^N:new · ^X:delete · ^U:up · ^D:down · ^O:options · ESC:quit${C_RESET}")" \
                --preview="[[ {} == '── Exit ──' ]] && echo 'Quit lazy-weather' || ${script_path} --preview-city {}" \
                --preview-window="right:55%:wrap:border-left" \
                --color="header:cyan:bold,prompt:yellow:bold,pointer:magenta:bold" \
                --pointer="▶" \
                --no-info \
                --bind="ctrl-r:execute-silent(${script_path} -c {} -r &>/dev/null)+refresh-preview" \
                --expect=enter,ctrl-n,ctrl-x,ctrl-u,ctrl-d,ctrl-o) || return 1

        local key choice
        key=$(sed -n '1p' <<< "$result")
        choice=$(sed -n '2p' <<< "$result")

        [[ -z "$choice" && -z "$key" ]] && return 1
        [[ -z "$choice" ]] && choice="$key" && key=""
        [[ "$choice" == "── Exit ──" ]] && return 1

        case "$key" in
            enter)
                [[ "$choice" == "── Exit ──" ]] && return 1
                # Move chosen city to top and save
                cities=("$choice" $(printf '%s\n' "${cities[@]}" | grep -vxF "$choice"))
                save_config_value "CITIES" "$(IFS=','; echo "${cities[*]}")"
                ;;
            ctrl-n)
                read -rp $'\nNew city name: ' new_city
                if [[ -n "$new_city" ]]; then
                    cities+=("$new_city")
                    save_config_value "CITIES" "$(IFS=','; echo "${cities[*]}")"
                fi
                ;;
            ctrl-x)
                cities=($(printf '%s\n' "${cities[@]}" | grep -vxF "$choice"))
                [[ ${#cities[@]} -eq 0 ]] && { lw_error "No cities left"; return 1; }
                save_config_value "CITIES" "$(IFS=','; echo "${cities[*]}")"
                ;;
            ctrl-u)
                local idx
                for idx in "${!cities[@]}"; do
                    [[ "${cities[$idx]}" == "$choice" ]] && break
                done
                if (( idx > 0 )); then
                    local tmp="${cities[$((idx-1))]}"
                    cities[$((idx-1))]="$choice"
                    cities[$idx]="$tmp"
                    save_config_value "CITIES" "$(IFS=','; echo "${cities[*]}")"
                fi
                ;;
            ctrl-d)
                local idx
                for idx in "${!cities[@]}"; do
                    [[ "${cities[$idx]}" == "$choice" ]] && break
                done
                if (( idx < ${#cities[@]} - 1 )); then
                    local tmp="${cities[$((idx+1))]}"
                    cities[$((idx+1))]="$choice"
                    cities[$idx]="$tmp"
                    save_config_value "CITIES" "$(IFS=','; echo "${cities[*]}")"
                fi
                ;;
            ctrl-o)
                local opt
                opt=$(printf 'Forecast Days: %s\nVersion: %s\nUnits: %s\nBack to cities\n' \
                        "${LW_FORECAST_DAYS}" "${LW_WTTR_VERSION}" "${LW_UNITS}" | \
                    fzf --ansi --reverse --height=40% --border=rounded \
                        --prompt="  Options > " --no-info \
                        --header="$(echo -e "${C_DIM}Select option · ESC cancel${C_RESET}")" \
                        --color="header:cyan,prompt:yellow:bold,pointer:magenta:bold" \
                        --pointer="▶") || true
                case "$opt" in
                    Forecast\ Days:*)
                        local days
                        days=$(printf '0\n1\n2\n3\n' | \
                            fzf --ansi --reverse --height=30% --border=rounded \
                                --prompt="  Forecast Days > " --no-info \
                                --color="prompt:yellow:bold,pointer:magenta:bold" \
                                --pointer="▶") || true
                        [[ -n "$days" ]] && LW_FORECAST_DAYS="$days" && save_config_value "FORECAST_DAYS" "$days"
                        ;;
                    Version:*)
                        local ver
                        ver=$(printf 'narrow\nwide\n' | \
                            fzf --ansi --reverse --height=30% --border=rounded \
                                --prompt="  Version > " --no-info \
                                --color="prompt:yellow:bold,pointer:magenta:bold" \
                                --pointer="▶") || true
                        [[ -n "$ver" ]] && LW_WTTR_VERSION="$ver" && save_config_value "WTTR_VERSION" "$ver"
                        ;;
                    Units:*)
                        local units
                        units=$(printf 'metric (m)\nUSCS (u)\n' | \
                            fzf --ansi --reverse --height=30% --border=rounded \
                                --prompt="  Units > " --no-info \
                                --color="prompt:yellow:bold,pointer:magenta:bold" \
                                --pointer="▶") || true
                        if [[ -n "$units" ]]; then
                            local flag; [[ "$units" == *"(m)"* ]] && flag="m" || flag="u"
                            LW_UNITS="$flag" && save_config_value "UNITS" "$flag"
                        fi
                        ;;
                    Back\ to\ cities|"")
                        ;;
                esac
                ;;
            *)
                ;;
        esac
    done
}

# ── Preview (called by fzf --preview) ────────────────────────────────────────

show_preview() {
    local city="$1"
    local data

    # Prefer cached data for instant preview
    if data="$(cache_read "$city" "$LW_CACHE_TTL" 2>/dev/null)"; then
        local age
        age="$(cache_age "$city")"
        echo -e "${C_DIM}Cached $(elapsed_human "$(($(now_epoch) - age))" 2>/dev/null || echo "${age}s ago")${C_RESET}\n"
        echo "$data"
    else
        echo -e "${C_YELLOW}Fetching ${city}...${C_RESET}"
        get_weather "$city" 0 2>/dev/null || echo "No data available"
    fi
}

# ── Output formatters ─────────────────────────────────────────────────────────

print_weather() {
    local city="$1"
    local data="$2"
    local age
    age="$(cache_age "$city")"

    echo -e "${C_BOLD}${C_CYAN}${city}${C_RESET}"
    if (( age >= 0 )); then
        echo -e "${C_DIM}Last updated: $(elapsed_human "$(($(now_epoch) - age))")${C_RESET}"
    fi
    echo ""
    echo "$data"
}

print_mini() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g' | grep -m1 .
}
