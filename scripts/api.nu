# Ensure that the input starts with a slash
def ensure_leading_slash [] {
    if ($in | str starts-with "/") { echo $in } else { echo $"/($in)" }
}
# Apply the given `func` if `ok` is true and just pass the input if not
def maybe_apply [ ok: bool func: closure ] {
    if $ok { do $func $in } else { $in }
}
# Main function
def main [
    path: string # The API endpoint without the base URL. For example "/users/create"
    ...select: cell-path # Reduce the output to this attribute. "id" would reduce the output to a list of ids.
    --token (-t): string # The auth token used in the 'Authorization' header. If not given the environment variable `TOKEN_L2` is tried.
    --no-auth (-n) # Do not do authentication with the 'Authorization' header
    --explore (-x) # Use the Nushell "explore" feature to navigate the output
    --host: string # The API base url. Something like: "http://localhost:8080" If not provided the .env file is searched for the `SERVER_URL` variable, if nothing was found "http://localhost:8000" is the default. 
    --raw (-r) # Do not format the output. Use that if you want to use `jq` to further parse the response.
    --dbdebug (-d) # Do not remove the `debug` attribute from the response.
    --body (-b): string # Body of the HTTP request
    --method (-m): string = "get" # Method of the HTTP request
] {
    # Extract token from environment if not passed explicitely
    let token = if $no_auth {
        null
    } else if $token != null {
    echo $token
    } else if "TOKEN_L2" in $env {
    echo $env.TOKEN_L2
    } else {
    error make { msg: "TOKEN_L2 environment variable is not set. Provide a token with `--token TOKEN`" label: { span: (metadata $token).span, text: "--token TOKEN not provided" }}
    }

    # load .env file if exists
    let dotEnv = if (".env" | path exists) {open .env | parse "{key}={value}" | transpose -r -d} else {{}}
    
    # get host from .env file if not defined
    let host = if $host != null {
        echo $host
    } else if "APP_URL" in $dotEnv {
        echo $dotEnv.APP_URL
    } else {
        echo "http://localhost:8000"
    }
    # Construct the url
    let url = $"($host)/api($path | ensure_leading_slash)"
    # Fetch from the api!
    # use post if post_body is defined
    let headers = {
        "Accept": "application/json"
        "Content-Type": "application/json"
    }
    | if ($token != null) {
        insert "Authorization" $"Bearer ($token)"
    }

    match ($method | str upcase) {
        "POST" => (http post $url --allow-errors --full --headers $headers $body),
        "PUT" => (http put $url --allow-errors --full --headers $headers $body),
        "GET" => (http get $url --allow-errors --full --headers $headers),
        _ => (error make {msg: $"HTTP method \"($method | str upcase)\" is not supported"})
    }
    | if $in.status == 200 {
        (if ("data" in $in.body) {$in.body.data} else {$in.body}) | maybe_apply ($select != null) { select ...$select }
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
