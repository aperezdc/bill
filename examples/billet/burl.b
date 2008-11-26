#! /usr/bin/env bill

use burl
use www/form
use www/billet
use data/hash


function billet.hook.setup
{
    burl_init "$BILLET_DATA"
}


function billet:add
{
    local args=$(hash_new)
    form_urldecode $args <<< "$QUERY_STRING"

    if $(hash_has $args url) ; then
        local url=$(hash_get $args url)
        local key=$(burl_add "$BILLET_DATA" "$url")
        http_response
        http_header Content-Type text/html
        http_body
        cat <<EOF
<html>
 <head>
  <title>bURL</title>
  <link rel="stylesheet" type="text/css" href="$(billet_url rsrc/grey.css)"/>
 </head>
 <body>
  <h1>Shortened URL</h1>
  <p>Link address is a shortened URL:<br/>
    <a href="/$BILLET_CONTEXT/$key">$url</a>
  </p>
  <p><a href="/$BILLET_CONTEXT">Go back</a></p>
 </body>
</html>
EOF
    fi
}


function billet:
{
    if [[ ${#BILLET_TRAIL[@]} -gt 1 ]]
    then
        local url=$(burl_find "$BILLET_DATA" "${BILLET_TRAIL[1]}")
        if [ -n "$url" ]
        then
            http_redirect "$url"
        else
            cat <<EOF
<html>
 <head>
  <title>bURL</title>
  <link rel="stylesheet" type="text/css" href="$(billet_url rsrc/grey.css)"/>
 </head>
 <body>
  <h1>Oooops</h1>
  <p>No such URL!</p>
 </body>
</html>
EOF
        fi
    else
        cat <<EOF
<html>
 <head>
  <title>bURL</title>
  <link rel="stylesheet" type="text/css" href="$(billet_url rsrc/grey.css)"/>
 </head>
 <body>
  <h1>bURL</h1>
  <form method="GET" action="$(billet_url add)">
   <fieldset>
    <legend>Submit URL</legend>
    <input type="text" size="70" name="url"/>
    <input type="submit" value="Shorten!"/>
   </fieldset>
  </form>
 </body>
</html>
EOF
    fi
}

