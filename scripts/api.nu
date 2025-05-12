# Ensure that the input starts with a slash
def ensure_leading_slash [] {
    if ($in | str starts-with "/") { echo $in } else { echo $"/($in)" }
}
# Apply the given `func` if `ok` is true and just pass the input if not
def maybe_apply [ ok: bool func: closure ] {
    if $ok { do $func $in } else { $in }
}
# Main function
def main [ path: string ...select: cell-path --token (-t): string --explore (-x) --host: string = "http://localhost:8000" --raw (-r) --dbdebug (-d) ] {
    # Extract token from environment if not passed explicitely
    let token = if $token != null {
    echo $token
    } else if "TOKEN_L2" in $env {
    echo $env.TOKEN_L2
    } else {
    error make { msg: "TOKEN_L2 environment variable is not set. Provide a token with `--token TOKEN`" label: { span: (metadata $token).span, text: "--token TOKEN not provided" }}
    }
    # Construct the url
    let url = $"($host)/api($path | ensure_leading_slash)"
    # Fetch from the api!
    http get $url --allow-errors --full --headers [
        "Accept" "application/json"
        "Authorization" $"Bearer ($token)"
    ]
    | if $in.status == 200 {
        $in.body.data | maybe_apply ($select != null) { select ...$select }
    } else {
        $in.body | maybe_apply ("trace" in $in) {
        update trace {
            # Only include entries where a file is specified and where the file is not in vendor package
            where {
            "file" in $in and $in.file !~ "/vendor/"
            }
            # remove the PWD from the path to the file
            | each {
            update file { str replace $"($env.PWD)/" "" | str replace "/var/www/html/" "" }
            }
        }
        }
        # same as above for main file of error
        | maybe_apply ("file" in $in) { 
        update file { str replace $"($env.PWD)/" "" | str replace "/var/www/html/" "" }
        }
    }
    # remove the debug section from the response if not specified
    | maybe_apply (not $dbdebug and "debug" in $in) { reject "debug" }
    | maybe_apply $explore { explore }
    | maybe_apply $raw { to json }
}