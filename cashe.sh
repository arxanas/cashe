#!/bin/bash
set -eo pipefail
shopt -s nullglob

readonly CONFIG_DIR="$HOME/.cashe"

get_file_mtime()
{
    local stat_command

    if command -v gstat >/dev/null; then
        stat_command="gstat"
    else
        stat_command="stat"
    fi

    # Assume that GNU stat has a version option and BSD stat doesn't.
    if "$stat_command" --version >/dev/null; then
        gstat -c%Y "$1"
    else
        stat -f'%m' "$1"
    fi
}

readonly ERR_NO_OUTPUT_YET=1
readonly ERR_UNKNOWN_MODE=2
readonly ERR_BAD_TARGET=3
readonly ERR_BAD_SETTING=4

print_error()
{
    echo >/dev/stderr "cashe error: $@"
}

log_message()
{
    echo >/dev/stderr "cashe: $@"
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
            exit "$ERR_BAD_TARGET"
        fi

        if [[ -z "$setting" ]]; then
            print_error "No setting given for target '$target_name'."
            exit "$ERR_BAD_SETTING"
        fi

        local target_file_name="${target_name}.cashe"

        if [[ ! -f "$target_file_name" ]]; then
            print_error "No target named '$target_name'."
            exit "$ERR_BAD_TARGET"
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

    if [[ -n "$setting_output" ]]; then
        echo "$setting_output"
    else
        case "$setting" in
        "command")
            print_error "No setting for required setting '$setting' in target '$target_name'."
            exit "$ERR_BAD_SETTING"
            ;;

        "time-to-live")
            echo "1"
            ;;

        "output-file")
            echo "${target_name}.output"
            ;;

        *)
            print_error "Unknown setting '$setting'."
            exit "$ERR_BAD_SETTING"
            ;;
        esac
    fi
}

# Update the given target, or all targets if no target is given. Regenerates
# any output files which are out of date.
#
# target: Optional. The name of the target to regenerate.
mode_update()
{
    local target_name="$1"

    # Updates the given target, if necessary.
    #
    # target: The name of the target to update.
    update_single_target()
    {
        local target_name="$1"
        log_message "Running target $target_name"

        local time_to_live="$(get_setting $target_name time-to-live)"
        local output_file_name="$(get_setting $target_name output-file)"

        do_update()
        {
            # `command` is a builtin, apparently.
            local command_="$(get_setting $target_name command)"

            # If the script terminates before the job completes, the job doesn't
            # ever finish. This isn't really a concern since the caching is not
            # meant to be very precise.
            bash -c "$command_" >"$output_file_name" &
        }

        if [[ ! -f "$output_file_name" ]]; then
            log_message "Generating output for target $target_name"
            do_update
            return
        fi

        local last_updated="$(($(date +%s)-$(get_file_mtime $output_file_name)))"
        log_message "Last update $target_name $last_updated seconds in the past, with $time_to_live seconds per refresh."
        if [[ "$last_updated" -gt "$time_to_live" ]]; then
            log_message "Updating output for target $target_name"
            do_update
        fi
    }

    local target_name="$1"

    # Run every second for the next minute.
    for i in {1..60}; do
        if [[ -n "$target_name" ]]; then
            update_single_target "$target_name"
        else
            for i in ./*.cashe; do
                update_single_target "$(basename ${i%.cashe})"
            done
        fi
        sleep 1
    done
}

# Read the given target output.
# target: The name of the target.
mode_read()
{
    local target_name="$1"

    if [[ -z "$target_name" ]]; then
        print_error 'No target given.'
        exit "$ERR_BAD_TARGET"
    fi

    local output_file_name="$(get_setting $target_name output-file)"

    if [[ ! -f "$output_file_name" ]]; then
        print_error "No output file '$output_file_name'."
        exit "$ERR_NO_OUTPUT_YET"
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

    case "$mode" in
    "update")
        mode_update "$@"
        ;;

    "read")
        mode_read "$@"
        ;;

    *)
        print_error "Unknown mode '$mode'."
        return "$ERR_UNKNOWN_MODE"
        ;;
    esac
}

main "$@"
