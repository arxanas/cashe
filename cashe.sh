#!/bin/bash
set -e

readonly CONFIG_DIR="$HOME/.cashe"

readonly ERR_NO_OUTPUT_YET=1
readonly ERR_UNKNOWN_MODE=2
readonly ERR_BAD_TARGET=3
readonly ERR_BAD_SETTING=4

print_error()
{
    echo >/dev/stderr "$@"
}

# Gets a given setting from a given target. Returns `ERR_BAD_TARGET` if the
# given target doesn't exist.
#
# target: The name of the target.
# setting: The name of the setting. If the setting is not present, returns the
#     default for that setting.
get_setting()
{
    local target_name="$1"
    local setting="$2"

    get_setting_without_default()
    {
        if [[ -z "$target_name" ]]; then
            print_error 'No target given for get_setting.'
            return $ERR_BAD_TARGET
        fi

        if [[ -z "$setting" ]]; then
            print_error "No setting given for target '$target_name'."
            return $ERR_BAD_SETTING
        fi

        local target_file_name="${target_name}.cashe"

        if [[ ! -f "$target_file_name" ]]; then
            print_error "No target named '$target_name'."
            return $ERR_BAD_TARGET
        fi

        grep -e "^$setting" "$target_file_name" |\
            cut -d' ' -f2- |\
            tail -1
    }

    local setting_output
    setting_output="$(get_setting_without_default)"
    local status="$?"
    if [[ "$status" != "0" ]]; then
        return "$status"
    fi

    if [[ -z "$setting_output" ]]; then
        case "$setting" in
        "command")
            print_error "No setting for required setting '$setting'."
            return "$ERR_BAD_SETTING"
            ;;

        "time-to-live")
            echo "1"
            ;;

        "output-file")
            echo "${target_name}.output"
            ;;

        *)
            print_error "Unknown setting '$setting'."
            return "$ERR_BAD_SETTING"
            ;;
        esac
    fi
}

# Read the given target output.
# target: The name of the target.
mode_read()
{
    local target_name="$1"

    if [[ -z "$target_name" ]]; then
        print_error 'No target given.'
        return $ERR_BAD_TARGET
    fi

    local output_file_name
    output_file_name="$(get_setting $target_name output-file)"
    local status="$?"
    if [[ "$status" != 0 ]]; then
        return "$status"
    fi

    if [[ ! -f "$output_file_name" ]]; then
        print_error "No output file '$output_file_name'."
        return "$ERR_NO_OUTPUT_YET"
    fi

    cat "$output_file_name"
}

# Main.
main()
{
    local mode="$1"

    # Ignore the return value; we check for empty modes anyways.
    shift || true

    cd "$CONFIG_DIR"
    local status

    case "$mode" in
    "update")
        mode_update "$@"
        status="$?"
        ;;

    "read")
        mode_read "$@"
        status="$?"
        ;;

    *)
        print_error "Unknown mode '$mode'."
        status="$ERR_UNKNOWN_MODE"
        ;;
    esac

    return "$status"
}

main "$@"
