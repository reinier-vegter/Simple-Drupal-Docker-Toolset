backend default {
  .host = "127.0.0.1";
  .port = "90";
  .connect_timeout = 600s;
  .first_byte_timeout = 600s;
  .between_bytes_timeout = 600s;
  .max_connections = 800;
}
## Internal IPs (office etc)
acl internal {
  "212.78.164.66";
  "185.54.180.250";
  "176.74.250.121";
}
## Purges are allowed from these IPs, as well as from 'internal' IPs.
acl purge {
  "localhost";
  "127.0.0.1";
}
# Code determining what to do when serving items from the Apache servers.
# beresp == Back-end response from the web server.
sub vcl_fetch {


  # Default TTL + max-age header.
  # set beresp.ttl = 600s;
  # set beresp.http.Cache-Control = "public,max-age=600";

  # We need this to cache 404s, 301s, 500s. Otherwise, depending on backend but
  # definitely in Drupal's case these responses are not cacheable by default.
  if (beresp.status == 404 || beresp.status == 301 || beresp.status == 500) {
    set beresp.ttl = 10m;
  }
  ## 403's mogen niet gecached worden
  if (beresp.status == 403) {
     return (hit_for_pass);
  }
  # Don't allow static files to set cookies.
  # (?i) denotes case insensitive in PCRE (perl compatible regular expressions).
  # This list of extensions appears twice, once here and again in vcl_recv so
  # make sure you edit both and keep them equal.
  if (req.url ~ "(?i)\.(pdf|asc|dat|txt|doc|xls|ppt|tgz|csv|png|gif|jpeg|jpg|ico|swf|svg|css|js|woff|eot|ttf)(\?.*)?$") {
    unset beresp.http.set-cookie;
  }
  # Allow items to be stale if needed.
  set beresp.grace = 10m;
  #set beresp.http.Cache-Control = "max-age=600,public";
  #set beresp.ttl = 24h;
  ## Custom TTLS.
  ## Rest is controlled from Drupal.
  # if (  req.url ~ "^/$" ||
  #   req.url ~ "^/realtime-info/.*$") {
  #       set beresp.ttl = 30s;
  #       set beresp.http.Cache-Control = "public,max-age=30";
  # }
  if(req.url == "/robots.txt") {
    # Robots.txt is updated rarely and should be cached for 4 days
    # Purge manually as required
    set beresp.ttl = 3600s;
  }
}
# Respond to incoming requests.
sub vcl_recv {
  ## Allow purging from drupal.
  # Check the incoming request type is "PURGE", not "GET" or "POST"
  if (req.request == "PURGE") {
    # Check if the ip coresponds with the acl purge
    if (!client.ip ~ purge && !client.ip ~ internal) {
    # Return error code 405 (Forbidden) when not
      error 405 "Not allowed.";
    }
    return (lookup);
  }
  # Get rid of progress.js query params
  if (req.url ~ "^/misc/progress\.js\?[0-9]+$") {
    set req.url = "/misc/progress.js";
  }

  # Pipe these paths directly to Apache for streaming.
  if (req.url ~ "^/admin/content/backup_migrate/export") {
    return (pipe);
  }

  #  If global redirect is on
  #  if (req.url ~ "node\?page=[0-9]+$") {
  #    set req.url = regsub(req.url, "node(\?page=[0-9]+$)", "\1");
  #    return (lookup);
  #  }

  # Do not cache these paths.
  if (req.url ~ "^/status\.php$" ||
    req.url ~ "^/update\.php" ||
    req.url ~ "^/install\.php" ||
    req.url ~ "^/admin" ||
    req.url ~ "^/admin/.*$" ||
    req.url ~ "^/user" ||
    req.url ~ "^/user/.*$" ||
    req.url ~ "^/users/.*$" ||
    req.url ~ "^/info/.*$" ||
    req.url ~ "^/flag/.*$" ||
    req.url ~ "^.*/ajax/.*$" ||
    req.url ~ "^.*/ahah/.*$") {
    return (pass);
  }

  # Disallow outside access to cron.php or install.php
  if (req.url ~ "^/(cron|install)\.php$" && !client.ip ~ internal) {
    # Either let Varnish throw the error directly,
    error 404 "Page not found.";
    # Or, use a custom error page that you've defined in Drupal at the path "404".
    # set req.url = "/404";
  }

  # Always cache the following file types for all users.
  if (req.url ~ "(?i)\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm)(\?[a-z0-9]+)?$") {
    unset req.http.Cookie;
  }
  # Remove all cookies that Drupal doesn't need to know about. ANY remaining
  # cookie will cause the request to pass-through to Apache. For the most part
  # we always set the NO_CACHE cookie after any POST request, disabling the
  # Varnish cache temporarily. The session cookie allows all authenticated users
  # to pass through as long as they're logged in.
  # @see http://drupal.stackexchange.com/questions/53467
  #
  # 1. Append a semi-colon to the front of the cookie string.
  # 2. Remove all spaces that appear after semi-colons.
  # 3. Match the cookies we want to keep, adding the space we removed
  # previously, back. (\1) is first matching group in the regsuball.
  # 4. Remove all other cookies, identifying them by the fact that they have
  # no space after the preceding semi-colon.
  # 5. Remove all spaces and semi-colons from the beginning and end of the
  # cookie string.
  if (req.http.Cookie) {
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(S{1,2}ESS[a-z0-9]+|NO_CACHE)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    # Remove the "has_js" cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");
    # Remove the "Drupal.toolbar.collapsed" cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "Drupal.toolbar.collapsed=[^;]+(; )?", "");
    # Remove AdminToolbar cookie for drupal6
    set req.http.Cookie = regsuball(req.http.Cookie, "DrupalAdminToolbar=[^;]+(; )?", "");
    # Remove any Google Analytics based cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    # Remove the Quant Capital cookies (added by some plugin, all __qca)
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

    # If there are no remaining cookies, remove the cookie header. If there
    # aren't any cookie headers, Varnish's default behavior will be to cache
    # the page.
    if (req.http.Cookie == "") {
      unset req.http.Cookie;
    }

    # If there are any cookies left (a session or NO_CACHE cookie), do not
    # cache the page; pass it on to Apache directly.
    else {
      return (pass);
    }
  }
}
# Set a header to track a cache HIT/MISS.
sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  }
  else {
    set resp.http.X-Varnish-Cache = "MISS";
  }
}
## Purging responses.
sub vcl_hit {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}
sub vcl_miss {
  if (req.request == "PURGE") {
    purge;
    error 200 "Purged.";
  }
}