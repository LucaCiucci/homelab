# Power Control TODO

This service can restart or shut down the host, so keep it reachable only from
trusted paths. Ideas to explore before exposing it more broadly:

- Keep the container port private to the Docker network. Caddy should be the
  only service that can reach `power-control:5000`; avoid publishing this port
  directly on the host.
- Add a Caddy source IP allowlist for `/power/*`, for example LAN ranges and the
  Tailscale CGNAT range (`100.64.0.0/10`).
- Require a shared secret header such as `X-Power-Token` in the Flask app. Store
  the token in `.env`, not in Git.
- Consider Caddy basic auth if browser-based manual access becomes useful.
  Store only the hashed password in configuration.
- Consider serving `/power/*` only from internal hostnames such as `localhost`
  or `raspberrypi`, and not from externally routable names.
- Prefer a custom header or token over plain browser form posts, so normal
  cross-site form submissions cannot trigger shutdown or restart actions.

Suggested first step: add both a Caddy `remote_ip` allowlist and a shared secret
header. The allowlist reduces network exposure, while the token protects against
accidental routing mistakes.
